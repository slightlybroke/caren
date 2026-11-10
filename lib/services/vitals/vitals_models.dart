/// Target metrics for a SmartSpectra camera spot-check session.
/// Enforces documented confidence windows:
/// - Pulse rate: 12 seconds
/// - Breathing rate: 30 seconds
/// - HRV: 60 seconds
enum MeasurementTarget { pulseOnly, breathingAndPulse, fullVitalsAndHrv }

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

/// Session-level lifecycle statuses.
enum MeasurementSessionStatus {
  planned,
  starting,
  active,
  stopping,
  interrupted,
  completed,
  cancelled,
  failed,
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

  /// Optional specific session ID if continuing an existing session.
  final String? sessionId;

  /// Built-in SDK diagnostic telemetry setting (defaults to false in caren for privacy)
  final bool enableSdkTelemetry;

  const MeasurementConfig({
    this.target = MeasurementTarget.pulseOnly,
    this.durationSeconds = 15,
    this.sessionId,
    this.enableSdkTelemetry = false,
  });
}

/// Instantaneous streaming telemetry emitted while a measurement is active.
class VitalsStreamData {
  final MeasurementStatus status;
  final int elapsedSeconds;
  final double?
  instantaneousPulse; // Null if elapsed < 12s or signal unreliable
  final double?
  instantaneousBreathing; // Null if elapsed < 30s or signal unreliable
  final double? waveformValue;
  final bool isFaceDetected;
  final double progress; // 0.0 to 1.0
  final String statusText;
  final bool isSimulated;
  final double? confidenceScore; // Only if SDK reports it
  final double? stabilityScore; // Only if SDK reports it
  final String? validationCode; // Genuine SDK ValidationCode (e.g. OK, FACE_NOT_CENTERED, TOO_DARK)
  final String? validationHint; // Genuine SDK human guidance hint
  final String? processingStatus; // Genuine SDK ProcessingStatus (IDLE, STARTING, RUNNING, ERROR)
  final String? sdkErrorCode; // Genuine SDK SmartSpectraError code (e.g. AUTHENTICATION_FAILED)
  final String? sdkErrorMessage; // Genuine SDK error message
  final String? sessionId; // Associated session ID
  final MeasurementSessionStatus? sessionStatus; // Current session state
  final Map<String, dynamic>?
  rawTelemetry; // Raw EventChannel packet for developer inspection

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
    this.validationCode,
    this.validationHint,
    this.processingStatus,
    this.sdkErrorCode,
    this.sdkErrorMessage,
    this.sessionId,
    this.sessionStatus,
    this.rawTelemetry,
  });

  factory VitalsStreamData.initial({String? sessionId}) => VitalsStreamData(
    status: MeasurementStatus.preparingCamera,
    elapsedSeconds: 0,
    instantaneousPulse: null,
    instantaneousBreathing: null,
    waveformValue: 0.0,
    isFaceDetected: false,
    progress: 0.0,
    statusText: 'Preparing camera feed...',
    isSimulated: false,
    validationCode: null,
    validationHint: null,
    processingStatus: 'IDLE',
    sessionId: sessionId,
    sessionStatus: MeasurementSessionStatus.planned,
  );
}

/// Persistent record representing a discrete user measurement session.
class MeasurementSessionRecord {
  final String id;
  final MeasurementTarget target;
  final DateTime createdAt;
  final DateTime lastActivityAt;
  final MeasurementSessionStatus status;
  final MeasurementResult? result;
  final DateTime? completedAt;
  final bool isInterrupted;
  final String? interruptionReason;
  final bool userCancelled;
  final String? errorCode;
  final String? errorMessage;
  final int attemptNumber;

  const MeasurementSessionRecord({
    required this.id,
    required this.target,
    required this.createdAt,
    required this.lastActivityAt,
    required this.status,
    this.result,
    this.completedAt,
    this.isInterrupted = false,
    this.interruptionReason,
    this.userCancelled = false,
    this.errorCode,
    this.errorMessage,
    this.attemptNumber = 1,
  });

  MeasurementSessionRecord copyWith({
    String? id,
    MeasurementTarget? target,
    DateTime? createdAt,
    DateTime? lastActivityAt,
    MeasurementSessionStatus? status,
    MeasurementResult? result,
    DateTime? completedAt,
    bool? isInterrupted,
    String? interruptionReason,
    bool? userCancelled,
    String? errorCode,
    String? errorMessage,
    int? attemptNumber,
  }) {
    return MeasurementSessionRecord(
      id: id ?? this.id,
      target: target ?? this.target,
      createdAt: createdAt ?? this.createdAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      status: status ?? this.status,
      result: result ?? this.result,
      completedAt: completedAt ?? this.completedAt,
      isInterrupted: isInterrupted ?? this.isInterrupted,
      interruptionReason: interruptionReason ?? this.interruptionReason,
      userCancelled: userCancelled ?? this.userCancelled,
      errorCode: errorCode ?? this.errorCode,
      errorMessage: errorMessage ?? this.errorMessage,
      attemptNumber: attemptNumber ?? this.attemptNumber,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'target': target.name,
      'createdAt': createdAt.toIso8601String(),
      'lastActivityAt': lastActivityAt.toIso8601String(),
      'status': status.name,
      'result': result != null
          ? {
              'target': result!.target.name,
              'durationSeconds': result!.durationSeconds,
              'pulseRateBpm': result!.pulseRateBpm,
              'breathingRateBpm': result!.breathingRateBpm,
              'hrvRmssdMs': result!.hrvRmssdMs,
              'qualityScore': result!.qualityScore,
              'stabilityStatus': result!.stabilityStatus,
              'timestamp': result!.timestamp.toIso8601String(),
              'isSimulated': result!.isSimulated,
              'isSuccessful': result!.isSuccessful,
              'failureReason': result!.failureReason,
              'notes': result!.notes,
            }
          : null,
      'completedAt': completedAt?.toIso8601String(),
      'isInterrupted': isInterrupted,
      'interruptionReason': interruptionReason,
      'userCancelled': userCancelled,
      'errorCode': errorCode,
      'errorMessage': errorMessage,
      'attemptNumber': attemptNumber,
    };
  }

  factory MeasurementSessionRecord.fromJson(Map<String, dynamic> json) {
    MeasurementResult? parseResult(Map<dynamic, dynamic>? resMap) {
      if (resMap == null) return null;
      final targetStr = resMap['target'] as String? ?? 'pulseOnly';
      final target = MeasurementTarget.values.firstWhere(
        (t) => t.name == targetStr,
        orElse: () => MeasurementTarget.pulseOnly,
      );
      return MeasurementResult(
        target: target,
        durationSeconds: (resMap['durationSeconds'] as num?)?.toInt() ?? 0,
        pulseRateBpm: (resMap['pulseRateBpm'] as num?)?.toDouble(),
        breathingRateBpm: (resMap['breathingRateBpm'] as num?)?.toDouble(),
        hrvRmssdMs: (resMap['hrvRmssdMs'] as num?)?.toDouble(),
        qualityScore: (resMap['qualityScore'] as num?)?.toDouble(),
        stabilityStatus: resMap['stabilityStatus'] as String?,
        timestamp: resMap['timestamp'] != null
            ? DateTime.parse(resMap['timestamp'] as String)
            : DateTime.now(),
        isSimulated: resMap['isSimulated'] as bool? ?? false,
        isSuccessful: resMap['isSuccessful'] as bool? ?? false,
        failureReason: resMap['failureReason'] as String?,
        notes: resMap['notes'] as String?,
      );
    }

    final targetStr = json['target'] as String? ?? 'pulseOnly';
    final target = MeasurementTarget.values.firstWhere(
      (t) => t.name == targetStr,
      orElse: () => MeasurementTarget.pulseOnly,
    );

    final statusStr = json['status'] as String? ?? 'planned';
    final status = MeasurementSessionStatus.values.firstWhere(
      (s) => s.name == statusStr,
      orElse: () => MeasurementSessionStatus.planned,
    );

    return MeasurementSessionRecord(
      id: json['id'] as String,
      target: target,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastActivityAt: DateTime.parse(json['lastActivityAt'] as String),
      status: status,
      result: parseResult(json['result'] as Map<dynamic, dynamic>?),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      isInterrupted: json['isInterrupted'] as bool? ?? false,
      interruptionReason: json['interruptionReason'] as String?,
      userCancelled: json['userCancelled'] as bool? ?? false,
      errorCode: json['errorCode'] as String?,
      errorMessage: json['errorMessage'] as String?,
      attemptNumber: (json['attemptNumber'] as num?)?.toInt() ?? 1,
    );
  }
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
  final String?
  stabilityStatus; // Reported ONLY if native SDK provided stability
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
      return failureReason ??
          'Measurement incomplete (confidence window not reached)';
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
