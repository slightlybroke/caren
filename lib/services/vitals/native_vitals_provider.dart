import 'dart:async';
import 'package:flutter/services.dart';
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

  bool _isAvailable = false;
  bool _isSessionActive = false;
  StreamSubscription? _eventSubscription;
  StreamController<VitalsStreamData>? _streamController;
  MeasurementConfig _activeConfig = const MeasurementConfig();

  @override
  bool get isAvailable => _isAvailable;

  @override
  String get providerName => 'Presage SmartSpectra Native SDK';

  @override
  Future<bool> initialize({String? apiKey}) async {
    try {
      final bool? success = await _methodChannel.invokeMethod<bool>('initialize', {
        'apiKey': apiKey,
      });
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
    if (_isSessionActive) {
      throw StateError(
          'A SmartSpectra measurement session is already active. Cancel or stop the active session before starting a new one.');
    }

    _activeConfig = config;
    _isSessionActive = true;
    _streamController?.close();
    _streamController = StreamController<VitalsStreamData>.broadcast();

    // 1. Establish EventChannel subscription BEFORE calling startMeasurement
    // so no initial native frame events or validation events are dropped.
    _eventSubscription?.cancel();
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic data) {
        if (data is Map) {
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
          );
          _streamController?.add(streamData);
        }
      },
      onError: (dynamic error) {
        _isSessionActive = false;
        _streamController?.addError(error);
      },
      onDone: () {
        _isSessionActive = false;
      },
    );

    // 2. Invoke startMeasurement via MethodChannel
    _methodChannel.invokeMethod('startMeasurement', {
      'durationSeconds': config.durationSeconds,
      'target': config.target.name,
      'enableTelemetry': config.enableSdkTelemetry,
    }).catchError((dynamic e) {
      _isSessionActive = false;
      _eventSubscription?.cancel();
      _streamController?.addError(e);
    });

    return _streamController!.stream;
  }

  @override
  Future<MeasurementResult> stopMeasurement() async {
    if (!_isSessionActive) {
      // Idempotent stop: Return structured result without crashing
      return MeasurementResult(
        target: _activeConfig.target,
        durationSeconds: 0,
        timestamp: DateTime.now(),
        isSimulated: false,
        isSuccessful: false,
        failureReason: 'No active measurement session was running.',
      );
    }

    _isSessionActive = false;
    await _eventSubscription?.cancel();
    _eventSubscription = null;

    try {
      final Map<dynamic, dynamic>? result =
          await _methodChannel.invokeMethod<Map<dynamic, dynamic>>('stopMeasurement');

      if (result == null) {
        return MeasurementResult(
          target: _activeConfig.target,
          durationSeconds: 0,
          timestamp: DateTime.now(),
          isSimulated: false,
          isSuccessful: false,
          failureReason: 'No response received from native SmartSpectra SDK.',
        );
      }

      return MeasurementResult(
        target: _activeConfig.target,
        durationSeconds: (result['durationSeconds'] as num?)?.toInt() ?? 0,
        pulseRateBpm: (result['pulseRateBpm'] as num?)?.toDouble(),
        breathingRateBpm: (result['breathingRateBpm'] as num?)?.toDouble(),
        hrvRmssdMs: (result['hrvRmssdMs'] as num?)?.toDouble(),
        qualityScore: (result['qualityScore'] as num?)?.toDouble(),
        stabilityStatus: result['stabilityStatus'] as String?,
        timestamp: DateTime.now(),
        isSimulated: false, // Genuine
        isSuccessful: result['isSuccessful'] as bool? ?? false,
        failureReason: result['failureReason'] as String?,
        notes: result['notes'] as String?,
      );
    } on PlatformException catch (e) {
      return MeasurementResult(
        target: _activeConfig.target,
        durationSeconds: 0,
        timestamp: DateTime.now(),
        isSimulated: false,
        isSuccessful: false,
        failureReason: 'Native SDK error: ${e.message}',
      );
    }
  }

  @override
  Future<void> cancelMeasurement() async {
    _isSessionActive = false;
    try {
      await _eventSubscription?.cancel();
      _eventSubscription = null;
      await _methodChannel.invokeMethod('cancelMeasurement');
    } on Exception {
      // Idempotent cancellation
    }
  }

  @override
  Future<void> dispose() async {
    _isSessionActive = false;
    try {
      await _eventSubscription?.cancel();
      _eventSubscription = null;
      await _streamController?.close();
      await _methodChannel.invokeMethod('dispose');
    } on Exception {
      // Idempotent disposal
    }
  }
}
