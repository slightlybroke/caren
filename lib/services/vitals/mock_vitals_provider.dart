import 'dart:async';
import 'dart:math' as math;
import 'vitals_models.dart';
import 'vitals_provider.dart';

/// Clearly labeled Mock implementation of [VitalsProvider] for UI development,
/// automated testing, and offline previews.
///
/// Enforces exact SmartSpectra documented confidence windows:
/// - Pulse rate: 12 seconds
/// - Breathing rate: 30 seconds
/// - HRV: 60 seconds
///
/// ALL outputs carry `isSimulated: true` and are visibly tagged.
class MockVitalsProvider implements VitalsProvider {
  final bool shouldSimulateSuccess;
  final bool shouldSimulatePermissionDenial;
  final Duration updateInterval;

  StreamController<VitalsStreamData>? _streamController;
  Timer? _timer;
  int _ticks = 0;
  int _totalTicks = 30;
  int _elapsedSeconds = 0;
  MeasurementConfig _activeConfig = const MeasurementConfig();
  bool _isDisposed = false;

  MockVitalsProvider({
    this.shouldSimulateSuccess = true,
    this.shouldSimulatePermissionDenial = false,
    this.updateInterval = const Duration(milliseconds: 250), // 4 ticks per sec
  });

  @override
  bool get isAvailable => true;

  @override
  String get providerName => 'Simulated Mock Vitals (Dev & Test Only)';

  @override
  Future<bool> initialize({String? apiKey}) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return true;
  }

  @override
  Future<bool> requestCameraPermission() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return !shouldSimulatePermissionDenial;
  }

  @override
  Stream<VitalsStreamData> startMeasurement({
    MeasurementConfig config = const MeasurementConfig(),
  }) {
    _activeConfig = config;
    _streamController?.close();
    _streamController = StreamController<VitalsStreamData>.broadcast();
    _ticks = 0;
    _elapsedSeconds = 0;

    final ticksPerSecond = 1000 ~/ updateInterval.inMilliseconds;
    _totalTicks = config.durationSeconds * ticksPerSecond;
    if (_totalTicks <= 0) _totalTicks = 15 * ticksPerSecond;

    _timer?.cancel();
    _timer = Timer.periodic(updateInterval, (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      _ticks++;
      _elapsedSeconds = _ticks ~/ ticksPerSecond;
      final progress = math.min(1.0, _ticks / _totalTicks);

      // Photoplethysmography waveform
      final angle = _ticks * 0.45;
      final waveform = (math.sin(angle) * 0.5) + (math.sin(angle * 2.5) * 0.25);

      final isFaceDetected = _elapsedSeconds >= 2;

      MeasurementStatus status;
      String statusText;
      double? pulse;
      double? breathing;

      if (_elapsedSeconds < 2) {
        status = MeasurementStatus.preparingCamera;
        statusText = 'Preparing camera sensor...';
      } else if (_elapsedSeconds < 4) {
        status = MeasurementStatus.positioningAndLightingGuidance;
        statusText = 'Aligning face in frame • Maintain steady lighting...';
      } else if (_elapsedSeconds < 12) {
        status = MeasurementStatus.waitingForReliableSignal;
        statusText = 'Observing pulse rhythm... (12s window: ${_elapsedSeconds}s elapsed)';
      } else {
        // >= 12 seconds: pulse confidence window reached!
        pulse = 72.0 + (math.sin(_ticks * 0.2) * 2.5);

        if (_activeConfig.target == MeasurementTarget.breathingAndPulse) {
          if (_elapsedSeconds < 30) {
            status = MeasurementStatus.measuring;
            statusText = 'Pulse locked. Observing breathing... (30s window: ${_elapsedSeconds}s elapsed)';
          } else {
            status = MeasurementStatus.validMeasurement;
            statusText = 'Pulse and breathing confidence windows reached.';
            breathing = 15.0 + (math.cos(_ticks * 0.1) * 1.0);
          }
        } else if (_activeConfig.target == MeasurementTarget.fullVitalsAndHrv) {
          if (_elapsedSeconds < 30) {
            status = MeasurementStatus.measuring;
            statusText = 'Observing breathing rhythm... (${_elapsedSeconds}s / 30s)';
          } else if (_elapsedSeconds < 60) {
            status = MeasurementStatus.measuring;
            statusText = 'Observing HRV interval stability... (${_elapsedSeconds}s / 60s)';
            breathing = 15.0;
          } else {
            status = MeasurementStatus.validMeasurement;
            statusText = 'All vital signs and HRV windows reached.';
            breathing = 15.0;
          }
        } else {
          status = MeasurementStatus.validMeasurement;
          statusText = 'Pulse spot-check validated (12s confidence window met).';
        }
      }

      _streamController?.add(
        VitalsStreamData(
          status: status,
          elapsedSeconds: _elapsedSeconds,
          instantaneousPulse: pulse,
          instantaneousBreathing: breathing,
          waveformValue: waveform,
          isFaceDetected: isFaceDetected,
          progress: progress,
          statusText: statusText,
          isSimulated: true, // ALWAYS true for Mock
          confidenceScore: pulse != null ? 0.95 : null,
          stabilityScore: isFaceDetected ? 0.92 : null,
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
    await Future.delayed(const Duration(milliseconds: 150));

    final requiredWindow = _activeConfig.target.requiredConfidenceWindowSeconds;
    final metWindow = _elapsedSeconds >= requiredWindow;

    if (!shouldSimulateSuccess || !metWindow) {
      return MeasurementResult(
        target: _activeConfig.target,
        durationSeconds: _elapsedSeconds,
        timestamp: DateTime.now(),
        isSimulated: true,
        isSuccessful: false,
        failureReason: !metWindow
            ? 'Stopped at ${_elapsedSeconds}s before required ${requiredWindow}s confidence window elapsed.'
            : 'Simulated spot-check failed due to excessive motion or camera shake.',
        notes: '[SIMULATED] Developer mock reading.',
      );
    }

    final double pulse = 72.0;
    final double? breathing = _elapsedSeconds >= 30 ? 15.0 : null;
    final double? hrv = _elapsedSeconds >= 60 ? 42.0 : null;

    return MeasurementResult(
      target: _activeConfig.target,
      durationSeconds: _elapsedSeconds,
      pulseRateBpm: pulse,
      breathingRateBpm: breathing,
      hrvRmssdMs: hrv,
      qualityScore: 0.94,
      stabilityStatus: 'Good lighting and stable posture observed',
      timestamp: DateTime.now(),
      isSimulated: true,
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
