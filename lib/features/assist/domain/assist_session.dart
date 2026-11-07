import '../../../services/vitals/vitals_models.dart';
import 'assist_observation.dart';

class AssistSession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final List<AssistObservation> observations;
  final MeasurementResult? optionalConsentMeasurement;
  final bool calledEmergencyServices;
  final String? handoffSummary;

  const AssistSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.observations,
    this.optionalConsentMeasurement,
    this.calledEmergencyServices = false,
    this.handoffSummary,
  });

  bool get isActive => endTime == null;

  AssistSession copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    List<AssistObservation>? observations,
    MeasurementResult? optionalConsentMeasurement,
    bool? calledEmergencyServices,
    String? handoffSummary,
  }) {
    return AssistSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      observations: observations ?? this.observations,
      optionalConsentMeasurement:
          optionalConsentMeasurement ?? this.optionalConsentMeasurement,
      calledEmergencyServices:
          calledEmergencyServices ?? this.calledEmergencyServices,
      handoffSummary: handoffSummary ?? this.handoffSummary,
    );
  }
}

