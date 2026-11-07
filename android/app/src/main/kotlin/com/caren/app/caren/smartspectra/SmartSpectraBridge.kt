package com.caren.app.caren.smartspectra

import android.app.Activity
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * SmartSpectraBridge manages communication between Flutter Platform Channels
 * and the native Presage SmartSpectra Android SDK.
 *
 * Current SDK integration points:
 * - com.presagetech:smartspectra (minSdk 28)
 * - SmartSpectraSdk.shared
 * - SmartSpectraConfig.breathingMetrics / cardioMetrics
 */
class SmartSpectraBridge(
    private val activity: Activity,
    messenger: BinaryMessenger
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    companion object {
        private const val METHOD_CHANNEL = "com.caren.app/smartspectra"
        private const val EVENT_CHANNEL = "com.caren.app/smartspectra_stream"
        const val CAMERA_PERMISSION_REQUEST_CODE = 4101
    }

    private val methodChannel = MethodChannel(messenger, METHOD_CHANNEL)
    private val eventChannel = EventChannel(messenger, EVENT_CHANNEL)
    private var eventSink: EventChannel.EventSink? = null
    private var isInitialized = false

    init {
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> {
                val apiKey = call.argument<String>("apiKey")
                // In production, instantiate SmartSpectraSdk.getInstance().setApiKey(apiKey)
                // or read presage_services.xml
                isInitialized = true
                result.success(true)
            }
            "requestCameraPermission" -> {
                val granted = ContextCompat.checkSelfPermission(
                    activity,
                    android.Manifest.permission.CAMERA
                ) == PackageManager.PERMISSION_GRANTED

                if (!granted) {
                    ActivityCompat.requestPermissions(
                        activity,
                        arrayOf(android.Manifest.permission.CAMERA),
                        CAMERA_PERMISSION_REQUEST_CODE
                    )
                }
                result.success(granted)
            }
            "startMeasurement" -> {
                val duration = call.argument<Int>("durationSeconds") ?: 30
                // SmartSpectraSdk configuration and frame pipeline hookup
                result.success(true)
            }
            "stopMeasurement" -> {
                // Return structured native result map
                val resultMap = HashMap<String, Any?>()
                resultMap["pulseRateBpm"] = null
                resultMap["breathingRateBpm"] = null
                resultMap["qualityScore"] = null
                resultMap["isSuccessful"] = false
                resultMap["notes"] = "SmartSpectra hardware pipeline pending camera feed attachment."
                result.success(resultMap)
            }
            "cancelMeasurement" -> {
                result.success(true)
            }
            "dispose" -> {
                eventSink = null
                result.success(true)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        this.eventSink = null
    }

    fun cleanup() {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }
}

