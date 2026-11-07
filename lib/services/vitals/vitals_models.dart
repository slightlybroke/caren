/// Target metrics for a SmartSpectra camera spot-check session.
/// Enforces documented confidence windows:
/// - Pulse rate: 12 seconds
/// - Breathing rate: 30 seconds
/// - HRV: 60 seconds
enum MeasurementTarget {
  pulseOnly,
  breathingAndPulse,
  fullVitalsAndHrv,
}

extension MeasurementTargetExtension on MeasurementTarget {
  int get defaultDurationSeconds {
    switch (this) {
      case MeasurementTarget.pulseOnly:
        return 15; // 15s session for 12s confidence window
      case MeasurementTarget.breathingAndPulse:
        return 30; // 30s required confidence window for breathing rate
      case MeasurementTarget.fullVitalsAndHrv:
        return 60; // 60s required confidence window for HRV
    }
  }

  int get requiredConfidenceWindowSeconds {
    switch (this) {
      case MeasurementTarget.pulseOnly:
        return 12;
      case MeasurementTarget.breathingAndPulse:
        return 30;
      case MeasurementTarget.fullVitalsAndHrv:
        return 60;
    }
  }

  String get displayName {
    switch (this) {
      case MeasurementTarget.pulseOnly:
        return 'Pulse Spot-Check (15s)';
      case MeasurementTarget.breathingAndPulse:
        return 'Breathing & Pulse Rhythm (30s)';
      case MeasurementTarget.fullVitalsAndHrv:
        return 'Comprehensive Vitals & HRV (60s)';
    }
  }

  String get description {
    switch (this) {
      case MeasurementTarget.pulseOnly:
        return 'Quick 15s spot observation. Pulse confidence window is 12 seconds.';
      case MeasurementTarget.breathingAndPulse:
        return 'Full 30s collection. Breathing rate requires a 30s window and a steady camera.';
      case MeasurementTarget.fullVitalsAndHrv:
        return 'Extended 60s collection. Heart Rate Variability (HRV) requires 60 continuous seconds.';
    }
  }
}

/// Explicit lifecycle states distinguishing camera preparation, positioning,
/// signal acquisition, and validation.
enum MeasurementStatus {
  idle,
  preparingCamera,
  positioningAndLightingGuidance,
  measuring,
  waitingForReliableSignal,
  validMeasurement,
  measurementUnavailable,
  measurementCancelled,
}

/// Result returned from camera permission requests.
class CameraPermissionResult {
  final bool granted;
  final bool permanentlyDenied;

  const CameraPermissionResult({
    required this.granted,
    this.permanentlyDenied = false,
  });
}

/// Configuration options for SmartSpectra measurement session.
class MeasurementConfig {
  final MeasurementTarget target;
  final int durationSeconds;
  /// Built-in SDK diagnostic telemetry setting (defaults to false in CAREN for privacy)
  final bool enableSdkTelemetry;

  const MeasurementConfig({
    this.target = MeasurementTarget.pulseOnly,
    this.durationSeconds = 15,
    this.enableSdkTelemetry = false,
  });
}

/// Instantaneous streaming telemetry emitted while a measurement is active.
class VitalsStreamData {
  final MeasurementStatus status;
  final int elapsedSeconds;
  final double? instantaneousPulse; // Null if elapsed < 12s or signal unreliable
  final double? instantaneousBreathing; // Null if elapsed < 30s or signal unreliable
  final double? waveformValue;
  final bool isFaceDetected;
  final double progress; // 0.0 to 1.0
  final String statusText;
  final bool isSimulated;
  final double? confidenceScore; // Only if SDK reports it
  final double? stabilityScore; // Only if SDK reports it

  const VitalsStreamData({
    required this.status,
    required this.elapsedSeconds,
    this.instantaneousPulse,
    this.instantaneousBreathing,
    this.waveformValue,
    required this.isFaceDetected,
    required this.progress,
    required this.statusText,
    required this.isSimulated,
    this.confidenceScore,
    this.stabilityScore,
  });

  factory VitalsStreamData.initial() => const VitalsStreamData(
        status: MeasurementStatus.preparingCamera,
        elapsedSeconds: 0,
        instantaneousPulse: null,
        instantaneousBreathing: null,
        waveformValue: 0.0,
        isFaceDetected: false,
        progress: 0.0,
        statusText: 'Preparing camera feed...',
        isSimulated: false,
      );
}

/// Summary result generated at the conclusion of a spot-check measurement.
/// IMPORTANT:
/// - Never describes readings as medical diagnoses or clinical guarantees.
/// - Never manufactures timestamps or confidence values.
class MeasurementResult {
  final MeasurementTarget target;
  final int durationSeconds;
  final double? pulseRateBpm; // Null if stopped before 12s window
  final double? breathingRateBpm; // Null if stopped before 30s window
  final double? hrvRmssdMs; // Null if stopped before 60s window
  final double? qualityScore; // Reported ONLY if native SDK provided confidence
  final String? stabilityStatus; // Reported ONLY if native SDK provided stability
  final DateTime timestamp;
  final bool isSimulated;
  final bool isSuccessful;
  final String? failureReason;
  final String? notes;

  const MeasurementResult({
    required this.target,
    required this.durationSeconds,
    this.pulseRateBpm,
    this.breathingRateBpm,
    this.hrvRmssdMs,
    this.qualityScore,
    this.stabilityStatus,
    required this.timestamp,
    required this.isSimulated,
    required this.isSuccessful,
    this.failureReason,
    this.notes,
  });

  String get summaryLabel {
    if (!isSuccessful) {
      return failureReason ?? 'Measurement incomplete (confidence window not reached)';
    }
    final List<String> parts = [];
    if (pulseRateBpm != null) {
      parts.add('${pulseRateBpm!.toStringAsFixed(0)} bpm pulse');
    }
    if (breathingRateBpm != null) {
      parts.add('${breathingRateBpm!.toStringAsFixed(0)} br/min breathing');
    }
    if (hrvRmssdMs != null) {
      parts.add('${hrvRmssdMs!.toStringAsFixed(0)} ms HRV (RMSSD)');
    }
    if (parts.isEmpty) return 'No metrics met confidence window';
    return parts.join(' • ');
  }
}
