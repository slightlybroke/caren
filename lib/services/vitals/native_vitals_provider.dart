import 'dart:async';
import 'package:flutter/services.dart';
import 'vitals_models.dart';
import 'vitals_provider.dart';

/// Production-ready Platform Channel implementation of [VitalsProvider].
/// Communicates with native Android Kotlin SmartSpectra SDK via MethodChannel
/// and EventChannel. Kept ready for Swift/iOS implementation.
class NativeVitalsProvider implements VitalsProvider {
  static const MethodChannel _methodChannel = MethodChannel('com.caren.app/smartspectra');
  static const EventChannel _eventChannel = EventChannel('com.caren.app/smartspectra_stream');

  bool _isAvailable = false;
  StreamSubscription? _eventSubscription;
  StreamController<VitalsStreamData>? _streamController;

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
    } on MissingPluginException {
      _isAvailable = false;
      return false;
    } on PlatformException {
      _isAvailable = false;
      return false;
    }
  }

  @override
  Future<bool> requestCameraPermission() async {
    try {
      final bool? granted = await _methodChannel.invokeMethod<bool>('requestCameraPermission');
      return granted ?? false;
    } on Exception {
      return false;
    }
  }

  @override
  Stream<VitalsStreamData> startMeasurement({
    MeasurementConfig config = const MeasurementConfig(),
  }) {
    _streamController?.close();
    _streamController = StreamController<VitalsStreamData>.broadcast();

    // Trigger start on native side
    _methodChannel.invokeMethod('startMeasurement', {
      'durationSeconds': config.durationSeconds,
      'requestPulseRate': config.requestPulseRate,
      'requestBreathingRate': config.requestBreathingRate,
      'requestHrv': config.requestHrv,
    }).catchError((e) {
      _streamController?.addError(e);
    });

    // Listen to native stream events
    _eventSubscription?.cancel();
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic data) {
        if (data is Map) {
          final streamData = VitalsStreamData(
            instantaneousPulse: (data['pulse'] as num?)?.toDouble(),
            instantaneousBreathing: (data['breathing'] as num?)?.toDouble(),
            waveformValue: (data['waveform'] as num?)?.toDouble(),
            isFaceDetected: data['isFaceDetected'] as bool? ?? false,
            progress: (data['progress'] as num?)?.toDouble() ?? 0.0,
            statusText: data['statusText'] as String? ?? 'Measuring...',
            isSimulated: false, // Genuine native reading
          );
          _streamController?.add(streamData);
        }
      },
      onError: (dynamic error) {
        _streamController?.addError(error);
      },
    );

    return _streamController!.stream;
  }

  @override
  Future<MeasurementResult> stopMeasurement() async {
    try {
      _eventSubscription?.cancel();
      final Map<dynamic, dynamic>? result =
          await _methodChannel.invokeMethod<Map<dynamic, dynamic>>('stopMeasurement');

      if (result == null) {
        return MeasurementResult(
          timestamp: DateTime.now(),
          isSimulated: false,
          isSuccessful: false,
          notes: 'No measurement data received from native SDK.',
        );
      }

      return MeasurementResult(
        pulseRateBpm: (result['pulseRateBpm'] as num?)?.toDouble(),
        breathingRateBpm: (result['breathingRateBpm'] as num?)?.toDouble(),
        hrvRmssdMs: (result['hrvRmssdMs'] as num?)?.toDouble(),
        qualityScore: (result['qualityScore'] as num?)?.toDouble(),
        timestamp: DateTime.now(),
        isSimulated: false,
        isSuccessful: result['isSuccessful'] as bool? ?? false,
        notes: result['notes'] as String?,
      );
    } on Exception catch (e) {
      return MeasurementResult(
        timestamp: DateTime.now(),
        isSimulated: false,
        isSuccessful: false,
        notes: 'Native measurement failed: $e',
      );
    }
  }

  @override
  Future<void> cancelMeasurement() async {
    try {
      _eventSubscription?.cancel();
      await _methodChannel.invokeMethod('cancelMeasurement');
    } on Exception {
      // Ignored on cancellation
    }
  }

  @override
  Future<void> dispose() async {
    try {
      _eventSubscription?.cancel();
      await _streamController?.close();
      await _methodChannel.invokeMethod('dispose');
    } on Exception {
      // Ignored on dispose
    }
  }
}

