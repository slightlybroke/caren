/// Status of a wellness spot-check measurement.
enum MeasurementStatus {
  idle,
  initializing,
  requestingPermission,
  detectingFace,
  measuring,
  completed,
  failed,
  cancelled,
}

/// Configuration options for SmartSpectra measurement session.
class MeasurementConfig {
  final int durationSeconds;
  final bool requestPulseRate;
  final bool requestBreathingRate;
  final bool requestHrv;

  const MeasurementConfig({
    this.durationSeconds = 30,
    this.requestPulseRate = true,
    this.requestBreathingRate = true,
    this.requestHrv = false,
  });
}

/// Instantaneous streaming telemetry emitted while a measurement is active.
class VitalsStreamData {
  final double? instantaneousPulse;
  final double? instantaneousBreathing;
  final double? waveformValue;
  final bool isFaceDetected;
  final double progress; // 0.0 to 1.0
  final String statusText;
  final bool isSimulated;

  const VitalsStreamData({
    this.instantaneousPulse,
    this.instantaneousBreathing,
    this.waveformValue,
    required this.isFaceDetected,
    required this.progress,
    required this.statusText,
    required this.isSimulated,
  });

  factory VitalsStreamData.initial() => const VitalsStreamData(
        instantaneousPulse: null,
        instantaneousBreathing: null,
        waveformValue: 0.0,
        isFaceDetected: false,
        progress: 0.0,
        statusText: 'Positioning camera...',
        isSimulated: false,
      );
}

/// Summary result generated at the conclusion of a spot-check measurement.
/// IMPORTANT: Never describes readings as medical diagnoses or clinical guarantees.
class MeasurementResult {
  final double? pulseRateBpm;
  final double? breathingRateBpm;
  final double? hrvRmssdMs;
  /// Quality or confidence score only if provided by upstream native SDK.
  /// Null if not reported by the SDK.
  final double? qualityScore;
  final DateTime timestamp;
  final bool isSimulated;
  final bool isSuccessful;
  final String? notes;

  const MeasurementResult({
    this.pulseRateBpm,
    this.breathingRateBpm,
    this.hrvRmssdMs,
    this.qualityScore,
    required this.timestamp,
    required this.isSimulated,
    required this.isSuccessful,
    this.notes,
  });

  String get summaryLabel {
    if (!isSuccessful) return 'Measurement incomplete';
    final p = pulseRateBpm != null ? '${pulseRateBpm!.toStringAsFixed(0)} bpm pulse' : null;
    final b = breathingRateBpm != null ? '${breathingRateBpm!.toStringAsFixed(0)} br/min breathing' : null;
    return [p, b].whereType<String>().join(' • ');
  }
}

