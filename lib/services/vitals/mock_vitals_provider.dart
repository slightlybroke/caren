import 'dart:async';
import 'dart:math' as math;
import 'vitals_models.dart';
import 'vitals_provider.dart';

/// Clearly labeled Mock implementation of [VitalsProvider] for UI development,
/// automated testing, and offline previews.
///
/// ALL outputs from this provider carry `isSimulated: true` and are visibly tagged
/// to ensure simulated data is never mistaken for real physiological observations.
class MockVitalsProvider implements VitalsProvider {
  final bool shouldSimulateSuccess;
  final bool shouldSimulatePermissionDenial;
  final Duration updateInterval;

  StreamController<VitalsStreamData>? _streamController;
  Timer? _timer;
  int _ticks = 0;
  int _totalTicks = 30; // 30 steps by default
  bool _isDisposed = false;

  MockVitalsProvider({
    this.shouldSimulateSuccess = true,
    this.shouldSimulatePermissionDenial = false,
    this.updateInterval = const Duration(milliseconds: 300),
  });

  @override
  bool get isAvailable => true;

  @override
  String get providerName => 'Simulated Mock Vitals (Dev & Test Only)';

  @override
  Future<bool> initialize({String? apiKey}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return true;
  }

  @override
  Future<bool> requestCameraPermission() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return !shouldSimulatePermissionDenial;
  }

  @override
  Stream<VitalsStreamData> startMeasurement({
    MeasurementConfig config = const MeasurementConfig(),
  }) {
    _streamController?.close();
    _streamController = StreamController<VitalsStreamData>.broadcast();
    _ticks = 0;
    _totalTicks = (config.durationSeconds * 1000) ~/ updateInterval.inMilliseconds;
    if (_totalTicks <= 0) _totalTicks = 20;

    _timer?.cancel();
    _timer = Timer.periodic(updateInterval, (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      _ticks++;
      final progress = math.min(1.0, _ticks / _totalTicks);

      // Simulated sinusoidal photoplethysmography waveform
      final angle = _ticks * 0.45;
      final waveform = (math.sin(angle) * 0.5) + (math.sin(angle * 2.5) * 0.25);

      final isFaceDetected = _ticks > 2;
      final statusText = _ticks <= 2
          ? 'Centering face in frame...'
          : progress < 0.95
              ? 'Observing gentle pulse & breathing signals...'
              : 'Completing measurement...';

      final pulse = isFaceDetected ? 72.0 + (math.sin(_ticks * 0.2) * 3) : null;
      final breathing = isFaceDetected ? 15.0 + (math.cos(_ticks * 0.1) * 1.5) : null;

      _streamController?.add(
        VitalsStreamData(
          instantaneousPulse: pulse,
          instantaneousBreathing: breathing,
          waveformValue: waveform,
          isFaceDetected: isFaceDetected,
          progress: progress,
          statusText: statusText,
          isSimulated: true, // ALWAYS TRUE FOR MOCK
        ),
      );

      if (_ticks >= _totalTicks) {
        timer.cancel();
      }
    });

    return _streamController!.stream;
  }

  @override
  Future<MeasurementResult> stopMeasurement() async {
    _timer?.cancel();
    await Future.delayed(const Duration(milliseconds: 250));

    if (!shouldSimulateSuccess) {
      return MeasurementResult(
        timestamp: DateTime.now(),
        isSimulated: true,
        isSuccessful: false,
        notes: 'Simulated measurement was incomplete or interrupted.',
      );
    }

    // Realistic simulated spot-check values
    return MeasurementResult(
      pulseRateBpm: 71.0,
      breathingRateBpm: 15.0,
      hrvRmssdMs: 42.0,
      qualityScore: 0.94,
      timestamp: DateTime.now(),
      isSimulated: true, // Visibly simulated
      isSuccessful: true,
      notes: '[SIMULATED] Developer mock reading. Not clinical or physiological.',
    );
  }

  @override
  Future<void> cancelMeasurement() async {
    _timer?.cancel();
  }

  @override
  Future<void> dispose() async {
    _isDisposed = true;
    _timer?.cancel();
    await _streamController?.close();
  }
}

