import '../../../services/vitals/vitals_models.dart';

enum BreathingCadence {
  boxBreathing, // 4s inhale, 4s hold, 4s exhale, 4s hold
  gentlePaced, // 4s inhale, 6s exhale
  coherentRelaxation, // 5s inhale, 5s exhale
}

class BreathingSession {
  final String id;
  final DateTime startTime;
  final int durationMinutes; // 2, 3, 5, or 10
  final BreathingCadence cadence;
  final String? customTitle;
  final MeasurementResult? preSessionVitals;
  final MeasurementResult? postSessionVitals;
  final String? personalReflection;
  final bool isCompleted;

  const BreathingSession({
    required this.id,
    required this.startTime,
    required this.durationMinutes,
    required this.cadence,
    this.customTitle,
    this.preSessionVitals,
    this.postSessionVitals,
    this.personalReflection,
    this.isCompleted = true,
  });

  String get cadenceTitle {
    if (customTitle != null && customTitle!.isNotEmpty) {
      return customTitle!;
    }
    switch (cadence) {
      case BreathingCadence.boxBreathing:
        return 'Box Breathing (4-4-4-4)';
      case BreathingCadence.gentlePaced:
        return 'Gentle Paced (4s Inhale, 6s Exhale)';
      case BreathingCadence.coherentRelaxation:
        return 'Coherent Flow (5s Inhale, 5s Exhale)';
    }
  }
}

