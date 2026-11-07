/// Application failures and error models with human-readable, non-alarmist descriptions.
abstract class Failure {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  String toString() => message;
}

class CameraPermissionDeniedFailure extends Failure {
  const CameraPermissionDeniedFailure({
    super.message = 'Camera access is required for wellness measurements. You can grant access anytime in your device settings.',
    super.code = 'PERMISSION_DENIED',
  });
}

class MeasurementQualityFailure extends Failure {
  const MeasurementQualityFailure({
    super.message = 'Measurement could not be completed clearly. Please ensure good lighting and steady posture before trying again.',
    super.code = 'POOR_LIGHTING_OR_MOTION',
  });
}

class VitalsSdkUnavailableFailure extends Failure {
  const VitalsSdkUnavailableFailure({
    super.message = 'Camera-based measurement service is currently unavailable. You may continue with your self-reported wellness check-in.',
    super.code = 'SDK_UNAVAILABLE',
  });
}

class GenericFailure extends Failure {
  const GenericFailure({
    required super.message,
    super.code,
  });
}

