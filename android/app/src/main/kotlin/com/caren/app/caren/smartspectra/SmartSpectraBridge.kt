package com.caren.app.caren.smartspectra

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import com.presagetech.smartspectra.CameraSelection
import com.presagetech.smartspectra.ProcessingStatus
import com.presagetech.smartspectra.SmartSpectraConfig
import com.presagetech.smartspectra.SmartSpectraError
import com.presagetech.smartspectra.SmartSpectraSdk
import com.presagetech.smartspectra.ValidationCode
import com.presagetech.smartspectra.ValidationStatus
import com.presagetech.smartspectra.proto.MetricTypesProto.MetricType
import com.presagetech.smartspectra.proto.MetricsProto.Metrics
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

/**
 * Authoritative native SmartSpectraBridge interfacing with Presage SmartSpectra SDK 3.4.0.
 *
 * Enforces:
 * - Single-owner measurement session lifecycle backed by an explicit [SessionState] state machine.
 * - Concurrency protection preventing duplicate or competing native measurement sessions.
 * - Idempotent start, stop, and cancellation handling without crashing or throwing unhandled errors.
 * - Automatic resource cleanup on route pop, app backgrounding, or SDK error.
 * - Pure SDK-derived data: NO fabricated values.
 * - Telemetry configuration (defaults to false for user privacy).
 */
class SmartSpectraBridge(
    private val activity: Activity,
    messenger: BinaryMessenger
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler, PluginRegistry.RequestPermissionsResultListener {

    enum class SessionState {
        UNINITIALIZED,
        INITIALIZING,
        IDLE,
        STARTING,
        ACTIVE,
        STOPPING,
        COMPLETED,
        INTERRUPTED,
        FAILED,
        DISPOSED
    }

    companion object {
        private const val METHOD_CHANNEL = "com.caren.app/smartspectra"
        private const val EVENT_CHANNEL = "com.caren.app/smartspectra_stream"
        const val CAMERA_PERMISSION_REQUEST_CODE = 4101
    }

    private val methodChannel = MethodChannel(messenger, METHOD_CHANNEL)
    private val eventChannel = EventChannel(messenger, EVENT_CHANNEL)
    private var eventSink: EventChannel.EventSink? = null

    private val bridgeScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private val sessionMutex = Mutex()

    @Volatile
    private var sessionState: SessionState = SessionState.UNINITIALIZED

    @Volatile
    private var currentSessionId: String? = null

    private var activeTarget = "pulseOnly"
    private var sessionStartTimeMs = 0L
    private var lastStartTimeMs = 0L
    private var lastStopTimeMs = 0L
    private var lastInterruptionReason: String? = null

    private var startRequestsCount = 0L
    private var rejectedDuplicateStartsCount = 0L

    private var pendingPermissionResult: MethodChannel.Result? = null
    private var activeCameraPlatformView: SmartSpectraCameraPlatformView? = null

    // Real-time SDK state tracking
    private var latestValidationStatus: ValidationStatus? = null
    private var latestProcessingStatus: ProcessingStatus? = null
    private var latestErrorCode: String? = null
    private var latestErrorMessage: String? = null
    private var latestMetrics: Metrics? = null
    private var observersAttached = false

    init {
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    fun registerCameraPlatformView(platformView: SmartSpectraCameraPlatformView) {
        this.activeCameraPlatformView = platformView
        try {
            platformView.attachToSdk()
        } catch (_: Exception) {}
    }

    private fun attachSdkObservers(sdk: SmartSpectraSdk) {
        if (activity is LifecycleOwner && !observersAttached) {
            observersAttached = true
            activity.runOnUiThread {
                sdk.validationStatus.observe(activity) { validation ->
                    latestValidationStatus = validation
                    dispatchStateUpdate()
                }

                sdk.processingStatus.observe(activity) { status ->
                    latestProcessingStatus = status
                    if (status == ProcessingStatus.ERROR) {
                        synchronized(this) {
                            if (sessionState == SessionState.ACTIVE || sessionState == SessionState.STARTING) {
                                sessionState = SessionState.FAILED
                                lastInterruptionReason = "SDK processing status entered ERROR"
                                bridgeScope.launch {
                                    try { sdk.stop() } catch (_: Exception) {}
                                }
                            }
                        }
                    }
                    dispatchStateUpdate()
                }

                sdk.error.observe(activity) { error: SmartSpectraError? ->
                    if (error != null) {
                        latestErrorCode = error.code.name
                        latestErrorMessage = error.message

                        synchronized(this) {
                            if (sessionState == SessionState.ACTIVE || sessionState == SessionState.STARTING) {
                                sessionState = SessionState.FAILED
                                lastInterruptionReason = "SDK Error: ${error.code.name} - ${error.message}"
                                bridgeScope.launch {
                                    try { sdk.stop() } catch (_: Exception) {}
                                }
                            }
                        }

                        val errMap = HashMap<String, Any?>()
                        errMap["isError"] = true
                        errMap["sdkErrorCode"] = error.code.name
                        errMap["sdkErrorMessage"] = error.message
                        errMap["isSessionActive"] = false
                        errMap["sessionStatus"] = SessionState.FAILED.name
                        errMap["status"] = 6 // measurementUnavailable
                        errMap["statusText"] = "SDK Error: ${error.code.name} - ${error.message}"
                        errMap["sessionId"] = currentSessionId
                        activity.runOnUiThread {
                            eventSink?.success(errMap)
                        }
                    }
                }

                sdk.metrics.observe(activity) { metrics ->
                    latestMetrics = metrics
                    if (sessionState == SessionState.ACTIVE) {
                        dispatchMetricsUpdate(metrics)
                    }
                }
            }
        }
    }

    private fun dispatchStateUpdate() {
        if (sessionState != SessionState.ACTIVE && sessionState != SessionState.STARTING) return
        dispatchMetricsUpdate(latestMetrics)
    }

    private fun dispatchMetricsUpdate(metrics: Metrics?) {
        val elapsedSeconds = if (sessionStartTimeMs > 0) {
            ((System.currentTimeMillis() - sessionStartTimeMs) / 1000).toInt()
        } else 0

        val pulseItem = metrics?.cardio?.pulseRateList?.lastOrNull()
        val breathingItem = metrics?.breathing?.rateList?.lastOrNull()
        val traceItem = metrics?.cardio?.arterialPressureTraceList?.lastOrNull()

        // Pulse confidence window is 12 seconds
        val validPulse = if (elapsedSeconds >= 12) pulseItem?.value?.toDouble() else null
        // Breathing confidence window is 30 seconds
        val validBreathing = if (elapsedSeconds >= 30) breathingItem?.value?.toDouble() else null

        // Genuine face detection from validationStatus
        val validation = latestValidationStatus
        val isFaceDetected = validation != null &&
                validation.code != ValidationCode.NO_FACE_FOUND &&
                validation.code != ValidationCode.CAMERA_TUNING

        // Genuine waveform from arterial pressure trace
        val waveform = traceItem?.value?.toDouble()
        val confidence = pulseItem?.confidence?.toDouble()
        val stability = if (pulseItem != null && pulseItem.stable) 1.0 else 0.0

        // Status enum mapping
        val statusIndex = when {
            latestErrorCode != null -> 6 // measurementUnavailable
            !isFaceDetected -> 2 // positioningAndLightingGuidance
            validPulse != null -> 5 // validMeasurement
            elapsedSeconds >= 4 -> 4 // waitingForReliableSignal
            else -> 3 // measuring
        }

        val statusText = when {
            latestErrorMessage != null -> "SDK Error: $latestErrorMessage"
            validation != null && validation.code != ValidationCode.OK ->
                validation.hint.ifBlank { validation.code.name }
            elapsedSeconds < 4 -> "Preparing camera and positioning face..."
            elapsedSeconds < 12 -> "Acquiring pulse rhythm... (${elapsedSeconds}s / 12s)"
            activeTarget == "breathingAndPulse" && elapsedSeconds < 30 ->
                "Pulse acquired. Observing breathing... (${elapsedSeconds}s / 30s)"
            activeTarget == "fullVitalsAndHrv" && elapsedSeconds < 60 ->
                "Observing vitals and HRV... (${elapsedSeconds}s / 60s)"
            else -> "Signal acquired."
        }

        val dataMap = HashMap<String, Any?>()
        dataMap["elapsedSeconds"] = elapsedSeconds
        dataMap["pulse"] = validPulse
        dataMap["breathing"] = validBreathing
        dataMap["isFaceDetected"] = isFaceDetected
        dataMap["waveform"] = waveform
        dataMap["confidence"] = confidence
        dataMap["stability"] = if (pulseItem != null) stability else null
        dataMap["status"] = statusIndex
        dataMap["statusText"] = statusText
        dataMap["validationCode"] = validation?.code?.name
        dataMap["validationHint"] = validation?.hint
        dataMap["processingStatus"] = latestProcessingStatus?.name ?: "IDLE"
        dataMap["sdkErrorCode"] = latestErrorCode
        dataMap["sdkErrorMessage"] = latestErrorMessage
        dataMap["sessionId"] = currentSessionId
        dataMap["sessionStatus"] = sessionState.name

        activity.runOnUiThread {
            eventSink?.success(dataMap)
        }
    }

    private fun ensureSdkInitialized(enableTelemetry: Boolean = false): SmartSpectraSdk {
        val apiKey = com.caren.app.caren.BuildConfig.SMARTSPECTRA_API_KEY
        if (apiKey.isBlank()) {
            throw IllegalStateException("SmartSpectra API key is missing or empty in android/local.properties (SMARTSPECTRA_API_KEY).")
        }

        val config = SmartSpectraConfig().apply {
            this.apiKey = apiKey
            this.enableTelemetry = enableTelemetry
        }

        val sdk = try {
            SmartSpectraSdk.initialize(activity.applicationContext, config)
        } catch (_: Exception) {
            SmartSpectraSdk.shared.apply {
                this.config.apiKey = apiKey
                this.config.enableTelemetry = enableTelemetry
            }
        }

        try {
            sdk.useCamera(CameraSelection.Front)
        } catch (_: Exception) {}

        activeCameraPlatformView?.attachToSdk()
        attachSdkObservers(sdk)
        return sdk
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> {
                val apiKey = com.caren.app.caren.BuildConfig.SMARTSPECTRA_API_KEY
                if (apiKey.isBlank()) {
                    sessionState = SessionState.UNINITIALIZED
                    result.error(
                        "CREDENTIALS_MISSING",
                        "SmartSpectra API key is missing or empty in android/local.properties (SMARTSPECTRA_API_KEY).",
                        null
                    )
                    return
                }

                sessionState = SessionState.INITIALIZING
                try {
                    ensureSdkInitialized(false)
                    sessionState = SessionState.IDLE
                    result.success(true)
                } catch (e: Exception) {
                    sessionState = SessionState.FAILED
                    latestErrorCode = "INIT_FAILED"
                    latestErrorMessage = e.message ?: "Unknown initialization error"
                    result.error("INIT_FAILED", "SmartSpectra SDK initialization failed: ${e.message}", null)
                }
            }

            "getDiagnostics" -> {
                val hasCamera = ContextCompat.checkSelfPermission(
                    activity,
                    android.Manifest.permission.CAMERA
                ) == PackageManager.PERMISSION_GRANTED

                val sdkVersion = try {
                    SmartSpectraSdk.shared.version
                } catch (_: Exception) {
                    "3.4.0 (AAR)"
                }

                val lastPulse = latestMetrics?.cardio?.pulseRateList?.lastOrNull()?.value?.toDouble()

                val diagMap = HashMap<String, Any?>()
                diagMap["isInitialized"] = (sessionState != SessionState.UNINITIALIZED && sessionState != SessionState.INITIALIZING)
                diagMap["sessionState"] = sessionState.name
                diagMap["hasApiKey"] = com.caren.app.caren.BuildConfig.SMARTSPECTRA_API_KEY.isNotBlank()
                diagMap["hasCameraPermission"] = hasCamera
                diagMap["isSessionActive"] = (sessionState == SessionState.ACTIVE)
                diagMap["currentSessionId"] = currentSessionId ?: "None"
                diagMap["activeTarget"] = activeTarget
                diagMap["sdkVersion"] = sdkVersion
                diagMap["cameraPreviewAttached"] = activeCameraPlatformView != null
                diagMap["processingStatus"] = latestProcessingStatus?.name ?: "IDLE"
                diagMap["validationCode"] = latestValidationStatus?.code?.name ?: "Not exposed by SDK"
                diagMap["validationHint"] = latestValidationStatus?.hint ?: "Not exposed by SDK"
                diagMap["latestErrorCode"] = latestErrorCode ?: "Not exposed by SDK"
                diagMap["latestErrorMessage"] = latestErrorMessage ?: "None"
                diagMap["startRequestsCount"] = startRequestsCount
                diagMap["rejectedDuplicateStartsCount"] = rejectedDuplicateStartsCount
                diagMap["lastStartTimeMs"] = lastStartTimeMs
                diagMap["lastStopTimeMs"] = lastStopTimeMs
                diagMap["lastInterruptionReason"] = lastInterruptionReason ?: "None"
                diagMap["authStatus"] = if (latestErrorCode == "AUTHENTICATION_FAILED") {
                    "Authentication Failed"
                } else if (sessionState != SessionState.UNINITIALIZED) {
                    "Key Configured (Presage 3.4.0)"
                } else {
                    "Uninitialized"
                }
                diagMap["latestPulse"] = lastPulse
                diagMap["telemetryConfigured"] = false

                result.success(diagMap)
            }

            "requestCameraPermission" -> {
                val granted = ContextCompat.checkSelfPermission(
                    activity,
                    android.Manifest.permission.CAMERA
                ) == PackageManager.PERMISSION_GRANTED

                if (granted) {
                    result.success(
                        mapOf(
                            "granted" to true,
                            "permanentlyDenied" to false
                        )
                    )
                } else {
                    if (pendingPermissionResult != null) {
                        result.error("CONCURRENT_REQUEST", "Permission request is already pending", null)
                        return
                    }
                    pendingPermissionResult = result
                    ActivityCompat.requestPermissions(
                        activity,
                        arrayOf(android.Manifest.permission.CAMERA),
                        CAMERA_PERMISSION_REQUEST_CODE
                    )
                }
            }

            "openAppSettings" -> {
                try {
                    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                        data = Uri.fromParts("package", activity.packageName, null)
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                    activity.startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("SETTINGS_FAILED", "Unable to open application settings: ${e.message}", null)
                }
            }

            "startMeasurement" -> {
                startRequestsCount++

                // Concurrency and Duplicate session guard:
                // Reject duplicate start requests deterministically without throwing fatal exceptions
                if (sessionState == SessionState.ACTIVE || sessionState == SessionState.STARTING) {
                    rejectedDuplicateStartsCount++
                    val resp = HashMap<String, Any?>()
                    resp["started"] = false
                    resp["alreadyActive"] = true
                    resp["sessionId"] = currentSessionId
                    resp["status"] = sessionState.name
                    resp["message"] = "A SmartSpectra measurement session is already active ($currentSessionId)."
                    result.success(resp)
                    return
                }

                val hasCamera = ContextCompat.checkSelfPermission(
                    activity,
                    android.Manifest.permission.CAMERA
                ) == PackageManager.PERMISSION_GRANTED

                if (!hasCamera) {
                    result.error(
                        "PERMISSION_DENIED",
                        "Camera permission is required before starting SmartSpectra measurement.",
                        null
                    )
                    return
                }

                val target = call.argument<String>("target") ?: "pulseOnly"
                val enableTelemetry = call.argument<Boolean>("enableTelemetry") ?: false
                val requestedSessionId = call.argument<String>("sessionId") ?: "sess_${System.currentTimeMillis()}"

                sessionState = SessionState.STARTING
                currentSessionId = requestedSessionId
                activeTarget = target
                sessionStartTimeMs = System.currentTimeMillis()
                lastStartTimeMs = sessionStartTimeMs
                lastInterruptionReason = null
                latestValidationStatus = null
                latestErrorCode = null
                latestErrorMessage = null

                bridgeScope.launch {
                    sessionMutex.withLock {
                        try {
                            val sdk = ensureSdkInitialized(enableTelemetry)
                            sdk.config.enableTelemetry = enableTelemetry

                            // Configure target metrics
                            when (target) {
                                "pulseOnly" -> {
                                    sdk.config.requestedMetrics = listOf(MetricType.PULSE_RATE)
                                }
                                "breathingAndPulse" -> {
                                    sdk.config.requestedMetrics = SmartSpectraConfig.breathingMetrics + listOf(MetricType.PULSE_RATE)
                                }
                                "fullVitalsAndHrv" -> {
                                    sdk.config.requestedMetrics = SmartSpectraConfig.breathingMetrics + listOf(
                                        MetricType.PULSE_RATE,
                                        MetricType.HRV
                                    )
                                }
                                else -> {
                                    sdk.config.requestedMetrics = listOf(MetricType.PULSE_RATE)
                                }
                            }

                            // Start SDK measurement loop
                            sdk.start()
                            sessionState = SessionState.ACTIVE

                            val resp = HashMap<String, Any?>()
                            resp["started"] = true
                            resp["alreadyActive"] = false
                            resp["sessionId"] = currentSessionId
                            resp["status"] = SessionState.ACTIVE.name
                            result.success(resp)
                        } catch (e: Exception) {
                            sessionState = SessionState.FAILED
                            latestErrorCode = "START_FAILED"
                            latestErrorMessage = e.message ?: "Failed to start camera capture"
                            lastInterruptionReason = "Start exception: ${e.message}"
                            val resp = HashMap<String, Any?>()
                            resp["started"] = false
                            resp["alreadyActive"] = false
                            resp["sessionId"] = currentSessionId
                            resp["status"] = SessionState.FAILED.name
                            resp["error"] = e.message
                            result.error("START_FAILED", "Failed to start SmartSpectra session: ${e.message}", null)
                        }
                    }
                }
            }

            "stopMeasurement" -> {
                val markInterrupted = call.argument<Boolean>("markInterrupted") ?: false
                val reason = call.argument<String>("interruptionReason")

                if (sessionState != SessionState.ACTIVE && sessionState != SessionState.STARTING) {
                    val emptyMap = HashMap<String, Any?>()
                    emptyMap["isSuccessful"] = false
                    emptyMap["failureReason"] = "No active session to stop."
                    emptyMap["sessionStatus"] = sessionState.name
                    emptyMap["sessionId"] = currentSessionId
                    result.success(emptyMap)
                    return
                }

                sessionState = SessionState.STOPPING
                lastStopTimeMs = System.currentTimeMillis()
                val elapsedSeconds = if (sessionStartTimeMs > 0) {
                    ((lastStopTimeMs - sessionStartTimeMs) / 1000).toInt()
                } else 0

                bridgeScope.launch {
                    sessionMutex.withLock {
                        try {
                            val sdk = SmartSpectraSdk.shared
                            sdk.stop()

                            val minWindow = when (activeTarget) {
                                "pulseOnly" -> 12
                                "breathingAndPulse" -> 30
                                "fullVitalsAndHrv" -> 60
                                else -> 12
                            }

                            val metWindow = elapsedSeconds >= minWindow && !markInterrupted
                            val lastMetrics = sdk.metrics.value
                            val lastPulseItem = lastMetrics?.cardio?.pulseRateList?.lastOrNull()
                            val lastBreathingItem = lastMetrics?.breathing?.rateList?.lastOrNull()
                            val lastHrvItem = lastMetrics?.cardio?.hrvList?.lastOrNull()

                            val lastPulse = if (elapsedSeconds >= 12) lastPulseItem?.value?.toDouble() else null
                            val lastBreathing = if (elapsedSeconds >= 30) lastBreathingItem?.value?.toDouble() else null
                            val lastHrv = if (elapsedSeconds >= 60) lastHrvItem?.rmssd else null

                            val qualityScore = lastPulseItem?.confidence?.toDouble()
                            val isStable = lastPulseItem?.stable ?: false
                            val isSuccessful = metWindow && lastPulse != null

                            if (markInterrupted) {
                                sessionState = SessionState.INTERRUPTED
                                lastInterruptionReason = reason ?: "Measurement was interrupted before completion."
                            } else if (isSuccessful) {
                                sessionState = SessionState.COMPLETED
                            } else {
                                sessionState = SessionState.INTERRUPTED
                                lastInterruptionReason = "Session stopped before meeting the required ${minWindow}s window."
                            }

                            val resultMap = HashMap<String, Any?>()
                            resultMap["sessionId"] = currentSessionId
                            resultMap["durationSeconds"] = elapsedSeconds
                            resultMap["pulseRateBpm"] = lastPulse
                            resultMap["breathingRateBpm"] = lastBreathing
                            resultMap["hrvRmssdMs"] = lastHrv
                            resultMap["qualityScore"] = qualityScore
                            resultMap["stabilityStatus"] = if (lastPulseItem != null) {
                                if (isStable) "Stable signal observed" else "Unstable signal observed"
                            } else null
                            resultMap["isSuccessful"] = isSuccessful
                            resultMap["sessionStatus"] = sessionState.name
                            resultMap["failureReason"] = when {
                                markInterrupted -> lastInterruptionReason
                                latestErrorMessage != null -> "SDK Error: $latestErrorMessage"
                                !metWindow -> "Session stopped at ${elapsedSeconds}s before the required ${minWindow}s confidence window elapsed."
                                lastPulse == null -> "Insufficient signal quality or subject movement."
                                else -> null
                            }
                            resultMap["notes"] = "SmartSpectra SDK 3.4.0 native measurement."

                            result.success(resultMap)
                        } catch (e: Exception) {
                            sessionState = SessionState.FAILED
                            lastInterruptionReason = "Error stopping SmartSpectra: ${e.message}"
                            val resultMap = HashMap<String, Any?>()
                            resultMap["sessionId"] = currentSessionId
                            resultMap["isSuccessful"] = false
                            resultMap["sessionStatus"] = SessionState.FAILED.name
                            resultMap["failureReason"] = "Error stopping SmartSpectra: ${e.message}"
                            result.success(resultMap)
                        }
                    }
                }
            }

            "cancelMeasurement" -> {
                val reason = call.argument<String>("reason") ?: "User cancelled"
                synchronized(this) {
                    sessionState = SessionState.INTERRUPTED
                    lastInterruptionReason = reason
                }

                bridgeScope.launch {
                    sessionMutex.withLock {
                        try {
                            SmartSpectraSdk.shared.stop()
                            result.success(true)
                        } catch (_: Exception) {
                            result.success(true)
                        }
                    }
                }
            }

            "dispose" -> {
                synchronized(this) {
                    sessionState = SessionState.DISPOSED
                    currentSessionId = null
                }
                bridgeScope.launch {
                    try {
                        SmartSpectraSdk.shared.stop()
                    } catch (_: Exception) {}
                    eventSink = null
                    result.success(true)
                }
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode == CAMERA_PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            val permanentlyDenied = !granted && !ActivityCompat.shouldShowRequestPermissionRationale(
                activity,
                android.Manifest.permission.CAMERA
            )

            pendingPermissionResult?.success(
                mapOf(
                    "granted" to granted,
                    "permanentlyDenied" to permanentlyDenied
                )
            )
            pendingPermissionResult = null
            return true
        }
        return false
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        this.eventSink = null
    }

    fun onPause() {
        synchronized(this) {
            if (sessionState == SessionState.ACTIVE || sessionState == SessionState.STARTING) {
                sessionState = SessionState.INTERRUPTED
                lastInterruptionReason = "Application moved to background"
                bridgeScope.launch {
                    try {
                        SmartSpectraSdk.shared.stop()
                    } catch (_: Exception) {}
                }
            }
        }
    }

    fun onResume() {
        // Safe: Retains configuration; will not resume until user starts a session
    }

    fun cleanup() {
        synchronized(this) {
            sessionState = SessionState.DISPOSED
        }
        bridgeScope.launch {
            try {
                SmartSpectraSdk.shared.stop()
            } catch (_: Exception) {}
            bridgeScope.cancel()
        }
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }
}
