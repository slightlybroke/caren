import '../../../services/vitals/vitals_models.dart';

enum WellnessFeeling {
  feelingWell,
  doingFine,
  aBitTired,
  restingToday,
}

enum SleepQuality {
  restful,
  interrupted,
  restless,
}

class DailyCheckIn {
  final String id;
  final String userId;
  final String userName;
  final DateTime timestamp;
  final WellnessFeeling feeling;
  final SleepQuality sleep;
  final bool tookPrescribedMedications;
  final String? personalNote;
  final MeasurementResult? optionalMeasurement;
  final bool isSharedWithFamily;

  const DailyCheckIn({
    required this.id,
    required this.userId,
    required this.userName,
    required this.timestamp,
    required this.feeling,
    required this.sleep,
    required this.tookPrescribedMedications,
    this.personalNote,
    this.optionalMeasurement,
    this.isSharedWithFamily = true,
  });

  String get feelingDisplay {
    switch (feeling) {
      case WellnessFeeling.feelingWell:
        return 'Feeling well & energized';
      case WellnessFeeling.doingFine:
        return 'Doing fine';
      case WellnessFeeling.aBitTired:
        return 'A bit tired today';
      case WellnessFeeling.restingToday:
        return 'Taking it slow / resting';
    }
  }

  String get sleepDisplay {
    switch (sleep) {
      case SleepQuality.restful:
        return 'Rested well';
      case SleepQuality.interrupted:
        return 'Some awakenings';
      case SleepQuality.restless:
        return 'Restless night';
    }
  }
}

