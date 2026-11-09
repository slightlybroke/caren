import 'dart:async';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'session_repository.dart';
import 'vitals_models.dart';
import 'vitals_provider.dart';

/// Platform Channel implementation of [VitalsProvider] interfacing directly
/// with the native Presage SmartSpectra Android SDK (Kotlin) / iOS SDK (Swift).
///
/// Strictly surfaces genuine integration and hardware results.
/// NEVER silently falls back to simulated data.
class NativeVitalsProvider implements VitalsProvider {
  static const MethodChannel _methodChannel = MethodChannel('com.caren.app/smartspectra');
  static const EventChannel _eventChannel = EventChannel('com.caren.app/smartspectra_stream');
  static const _uuid = Uuid();

  final MeasurementSessionRepository? sessionRepository;

  bool _isAvailable = false;
  bool _isSessionActive = false;
  bool _isStarting = false;
  MeasurementSessionRecord? _activeSession;
  StreamSubscription? _eventSubscription;
  StreamController<VitalsStreamData>? _streamController;
  MeasurementConfig _activeConfig = const MeasurementConfig();

  NativeVitalsProvider({this.sessionRepository});

  @override
  bool get isAvailable => _isAvailable;

  @override
  String get providerName => 'Presage SmartSpectra Native SDK';

  @override
  MeasurementSessionRecord? get activeSession => _activeSession;

  @override
  Future<bool> initialize({String? apiKey}) async {
    try {
      final bool? success = await _methodChannel.invokeMethod<bool>('initialize');
      _isAvailable = success ?? false;
      return _isAvailable;
    } on MissingPluginException catch (e) {
      _isAvailable = false;
      throw UnsupportedError('SmartSpectra native plugin channel is not registered on this platform: $e');
    } on PlatformException catch (e) {
      _isAvailable = false;
      throw StateError('SmartSpectra native initialization failed: [${e.code}] ${e.message}');
    }
  }

  @override
  Future<CameraPermissionResult> requestCameraPermission() async {
    try {
      final dynamic result = await _methodChannel.invokeMethod('requestCameraPermission');
      if (result is Map) {
        return CameraPermissionResult(
          granted: result['granted'] as bool? ?? false,
          permanentlyDenied: result['permanentlyDenied'] as bool? ?? false,
        );
      } else if (result is bool) {
        return CameraPermissionResult(granted: result);
      }
      return const CameraPermissionResult(granted: false);
    } on PlatformException catch (e) {
      throw StateError('Failed to query camera permission: ${e.message}');
    }
  }

  @override
  Future<void> openAppSettings() async {
    try {
      await _methodChannel.invokeMethod('openAppSettings');
    } on PlatformException catch (e) {
      throw StateError('Failed to open application settings: ${e.message}');
    }
  }

  @override
  Stream<VitalsStreamData> startMeasurement({
    MeasurementConfig config = const MeasurementConfig(),
  }) {
    // 1. Concurrency Guard: If a session is already active or in-flight starting,
    // deterministically return the existing stream without throwing fatal errors.
    if (_isSessionActive && _streamController != null && !_streamController!.isClosed) {
      return _streamController!.stream;
    }

    if (_isStarting) {
      return _streamController?.stream ?? Stream.empty();
    }

    _isStarting = true;
    _activeConfig = config;
    final sessionId = config.sessionId ?? 'sess_${_uuid.v4().substring(0, 8)}';

    final sessionRecord = MeasurementSessionRecord(
      id: sessionId,
      target: config.target,
      createdAt: DateTime.now(),
      lastActivityAt: DateTime.now(),
      status: MeasurementSessionStatus.active,
    );
    _activeSession = sessionRecord;
    sessionRepository?.saveSession(sessionRecord);

    _isSessionActive = true;
    _streamController?.close();
    _streamController = StreamController<VitalsStreamData>.broadcast();

    // 2. Establish EventChannel subscription BEFORE calling startMeasurement
    // to guarantee no initial telemetry packets or validation codes are lost.
    _eventSubscription?.cancel();
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic data) {
        if (data is Map) {
          // Lifecycle protection: Discard stale telemetry from previous sessions
          final eventSessionId = data['sessionId'] as String?;
          if (eventSessionId != null && eventSessionId.isNotEmpty && eventSessionId != sessionId) {
            return;
          }

          final isError = data['isError'] as bool? ?? false;
          final sdkErrorCode = data['sdkErrorCode'] as String?;
          final sdkErrorMessage = data['sdkErrorMessage'] as String?;

          // If the native SDK reported an unrecoverable error:
          if (isError || (sdkErrorCode != null && sdkErrorCode.isNotEmpty)) {
            _isSessionActive = false;
            _activeSession = _activeSession?.copyWith(
              status: MeasurementSessionStatus.failed,
              errorCode: sdkErrorCode,
              errorMessage: sdkErrorMessage,
              lastActivityAt: DateTime.now(),
            );
            if (_activeSession != null) {
              sessionRepository?.saveSession(_activeSession!);
            }
          }

          final statusIndex = data['status'] as int? ?? 3;
          final status = statusIndex >= 0 && statusIndex < MeasurementStatus.values.length
              ? MeasurementStatus.values[statusIndex]
              : MeasurementStatus.measuring;

          final elapsed = (data['elapsedSeconds'] as num?)?.toInt() ?? 0;
          final progress = config.durationSeconds > 0
              ? (elapsed / config.durationSeconds).clamp(0.0, 1.0)
              : 0.0;

          final streamData = VitalsStreamData(
            status: status,
            elapsedSeconds: elapsed,
            instantaneousPulse: (data['pulse'] as num?)?.toDouble(),
            instantaneousBreathing: (data['breathing'] as num?)?.toDouble(),
            waveformValue: (data['waveform'] as num?)?.toDouble(),
            isFaceDetected: data['isFaceDetected'] as bool? ?? false,
            progress: progress,
            statusText: data['statusText'] as String? ?? 'Measuring physiological signals...',
            isSimulated: false, // Genuine native reading
            confidenceScore: (data['confidence'] as num?)?.toDouble(),
            stabilityScore: (data['stability'] as num?)?.toDouble(),
            validationCode: data['validationCode'] as String?,
            validationHint: data['validationHint'] as String?,
            processingStatus: data['processingStatus'] as String?,
            sdkErrorCode: sdkErrorCode,
            sdkErrorMessage: sdkErrorMessage,
            sessionId: sessionId,
            sessionStatus: _activeSession?.status ?? MeasurementSessionStatus.active,
            rawTelemetry: Map<String, dynamic>.from(data),
          );
          _streamController?.add(streamData);
        }
      },
      onError: (dynamic error) {
        _isSessionActive = false;
        _activeSession = _activeSession?.copyWith(
          status: MeasurementSessionStatus.failed,
          errorMessage: error.toString(),
          lastActivityAt: DateTime.now(),
        );
        if (_activeSession != null) {
          sessionRepository?.saveSession(_activeSession!);
        }
        _streamController?.addError(error);
      },
      onDone: () {
        _isSessionActive = false;
      },
    );

    // 3. Invoke native startMeasurement asynchronously
    _methodChannel.invokeMethod('startMeasurement', {
      'durationSeconds': config.durationSeconds,
      'target': config.target.name,
      'enableTelemetry': config.enableSdkTelemetry,
      'sessionId': sessionId,
    }).then((dynamic resp) {
      _isStarting = false;
      if (resp is Map) {
        final alreadyActive = resp['alreadyActive'] as bool? ?? false;
        if (alreadyActive) {
          // Native bridge already has an active session
          _activeSession = _activeSession?.copyWith(
            id: resp['sessionId'] as String? ?? sessionId,
            status: MeasurementSessionStatus.active,
          );
        }
      }
    }).catchError((dynamic e) {
      _isStarting = false;
      _isSessionActive = false;
      _eventSubscription?.cancel();
      _activeSession = _activeSession?.copyWith(
        status: MeasurementSessionStatus.failed,
        errorMessage: e.toString(),
        lastActivityAt: DateTime.now(),
      );
      if (_activeSession != null) {
        sessionRepository?.saveSession(_activeSession!);
      }
      _streamController?.addError(e);
    });

    return _streamController!.stream;
  }

  @override
  Future<MeasurementResult> stopMeasurement({
    bool markInterrupted = false,
    String? interruptionReason,
  }) async {
    _isStarting = false;
    if (!_isSessionActive && _activeSession?.status != MeasurementSessionStatus.active) {
      // Idempotent stop: Return structured result without throwing
      return MeasurementResult(
        target: _activeConfig.target,
        durationSeconds: 0,
        timestamp: DateTime.now(),
        isSimulated: false,
        isSuccessful: false,
        failureReason: interruptionReason ?? 'No active measurement session was running.',
      );
    }

    _isSessionActive = false;
    await _eventSubscription?.cancel();
    _eventSubscription = null;

    try {
      final dynamic raw = await _methodChannel.invokeMethod('stopMeasurement', {
        'markInterrupted': markInterrupted,
        'interruptionReason': interruptionReason,
      });

      final Map<dynamic, dynamic>? result = raw is Map ? raw : null;

      if (result == null) {
        final fallback = MeasurementResult(
          target: _activeConfig.target,
          durationSeconds: 0,
          timestamp: DateTime.now(),
          isSimulated: false,
          isSuccessful: false,
          failureReason: interruptionReason ?? 'No response received from native SmartSpectra SDK.',
        );
        _updateSessionOnStop(fallback, markInterrupted, interruptionReason);
        return fallback;
      }

      final measResult = MeasurementResult(
        target: _activeConfig.target,
        durationSeconds: (result['durationSeconds'] as num?)?.toInt() ?? 0,
        pulseRateBpm: (result['pulseRateBpm'] as num?)?.toDouble(),
        breathingRateBpm: (result['breathingRateBpm'] as num?)?.toDouble(),
        hrvRmssdMs: (result['hrvRmssdMs'] as num?)?.toDouble(),
        qualityScore: (result['qualityScore'] as num?)?.toDouble(),
        stabilityStatus: result['stabilityStatus'] as String?,
        timestamp: DateTime.now(),
        isSimulated: false,
        isSuccessful: result['isSuccessful'] as bool? ?? false,
        failureReason: result['failureReason'] as String?,
        notes: result['notes'] as String?,
      );

      _updateSessionOnStop(measResult, markInterrupted, interruptionReason);
      return measResult;
    } on PlatformException catch (e) {
      final errResult = MeasurementResult(
        target: _activeConfig.target,
        durationSeconds: 0,
        timestamp: DateTime.now(),
        isSimulated: false,
        isSuccessful: false,
        failureReason: 'Native SDK error: ${e.message}',
      );
      _updateSessionOnStop(errResult, markInterrupted, 'Platform error: ${e.message}');
      return errResult;
    }
  }

  void _updateSessionOnStop(
    MeasurementResult result,
    bool markInterrupted,
    String? reason,
  ) {
    if (result.isSuccessful && !markInterrupted) {
      _activeSession = _activeSession?.copyWith(
        status: MeasurementSessionStatus.completed,
        result: result,
        completedAt: DateTime.now(),
        lastActivityAt: DateTime.now(),
      );
    } else {
      _activeSession = _activeSession?.copyWith(
        status: MeasurementSessionStatus.interrupted,
        isInterrupted: true,
        interruptionReason: reason ?? result.failureReason ?? 'Measurement stopped before confidence window.',
        result: result.isSuccessful ? result : null,
        lastActivityAt: DateTime.now(),
      );
    }

    if (_activeSession != null) {
      sessionRepository?.saveSession(_activeSession!);
    }
  }

  @override
  Future<void> cancelMeasurement({String? reason}) async {
    _isStarting = false;
    _isSessionActive = false;
    try {
      await _eventSubscription?.cancel();
      _eventSubscription = null;
      await _methodChannel.invokeMethod('cancelMeasurement', {
        'reason': reason ?? 'User cancelled measurement',
      });
    } on Exception {
      // Idempotent cancellation
    }

    _activeSession = _activeSession?.copyWith(
      status: MeasurementSessionStatus.cancelled,
      userCancelled: true,
      interruptionReason: reason ?? 'User cancelled measurement',
      lastActivityAt: DateTime.now(),
    );
    if (_activeSession != null) {
      sessionRepository?.saveSession(_activeSession!);
    }
  }

  @override
  Future<void> dispose() async {
    _isStarting = false;
    if (_isSessionActive) {
      await cancelMeasurement(reason: 'Disposing vitals provider');
    }
    try {
      await _eventSubscription?.cancel();
      _eventSubscription = null;
      await _streamController?.close();
      await _methodChannel.invokeMethod('dispose');
    } on Exception {
      // Idempotent disposal
    }
  }

  @override
  Future<Map<String, dynamic>> getDiagnosticsState() async {
    try {
      final dynamic res = await _methodChannel.invokeMethod('getDiagnostics');
      if (res is Map) {
        return Map<String, dynamic>.from(res);
      }
      return {'error': 'Invalid diagnostics response format'};
    } on PlatformException catch (e) {
      return {
        'error': '[${e.code}] ${e.message}',
        'isInitialized': false,
        'hasApiKey': false,
        'sessionState': 'ERROR',
      };
    }
  }
}
