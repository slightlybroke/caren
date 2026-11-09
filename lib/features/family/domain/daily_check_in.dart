import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/vitals/vitals_models.dart';
import 'sharing_permission.dart';

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
  final SharingPermission? sharingPermission;
  final bool isSyncPending;

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
    this.sharingPermission,
    this.isSyncPending = false,
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

  Map<String, dynamic> toFirestore([SharingPermission? permission]) {
    final effectivePermission = permission ?? sharingPermission ?? SharingPermission(lastUpdated: DateTime.now());
    
    // Privacy and consent gating:
    final shouldShareNotes = effectivePermission.shareNotes;
    final shouldShareVitals = effectivePermission.shareVitalsMeasurements;
    final shouldShareMood = effectivePermission.shareSelfReportedMood;

    return {
      'userId': userId,
      'userName': userName,
      'timestamp': Timestamp.fromDate(timestamp),
      'feeling': shouldShareMood ? feeling.name : 'hidden_by_privacy',
      'sleep': shouldShareMood ? sleep.name : 'hidden_by_privacy',
      'tookPrescribedMedications': tookPrescribedMedications,
      'personalNote': shouldShareNotes ? personalNote : null,
      'hasOptionalMeasurement': optionalMeasurement != null && shouldShareVitals,
      'measurement': (optionalMeasurement != null && shouldShareVitals)
          ? {
              'pulseRateBpm': optionalMeasurement!.pulseRateBpm,
              'breathingRateBpm': optionalMeasurement!.breathingRateBpm,
              'durationSeconds': optionalMeasurement!.durationSeconds,
              'isSimulated': optionalMeasurement!.isSimulated,
              'isSuccessful': optionalMeasurement!.isSuccessful,
              'timestamp': Timestamp.fromDate(optionalMeasurement!.timestamp),
            }
          : null,
      'isSharedWithFamily': isSharedWithFamily,
      'permissions': {
        'shareCheckInStatus': effectivePermission.shareCheckInStatus,
        'shareSelfReportedMood': effectivePermission.shareSelfReportedMood,
        'shareVitalsMeasurements': effectivePermission.shareVitalsMeasurements,
        'shareNotes': effectivePermission.shareNotes,
      },
    };
  }

  factory DailyCheckIn.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final ts = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    final feelingStr = data['feeling'] as String? ?? 'doingFine';
    final sleepStr = data['sleep'] as String? ?? 'restful';
    final mData = data['measurement'] as Map<String, dynamic>?;

    MeasurementResult? measurement;
    if (mData != null) {
      measurement = MeasurementResult(
        target: MeasurementTarget.breathingAndPulse,
        durationSeconds: mData['durationSeconds'] as int? ?? 30,
        pulseRateBpm: (mData['pulseRateBpm'] as num?)?.toDouble(),
        breathingRateBpm: (mData['breathingRateBpm'] as num?)?.toDouble(),
        qualityScore: null,
        stabilityStatus: null,
        timestamp: (mData['timestamp'] as Timestamp?)?.toDate() ?? ts,
        isSimulated: mData['isSimulated'] as bool? ?? false,
        isSuccessful: mData['isSuccessful'] as bool? ?? true,
      );
    }

    final pData = data['permissions'] as Map<String, dynamic>?;
    final permission = pData != null
        ? SharingPermission(
            shareCheckInStatus: pData['shareCheckInStatus'] as bool? ?? true,
            shareSelfReportedMood: pData['shareSelfReportedMood'] as bool? ?? true,
            shareVitalsMeasurements: pData['shareVitalsMeasurements'] as bool? ?? false,
            shareNotes: pData['shareNotes'] as bool? ?? false,
            lastUpdated: ts,
          )
        : null;

    return DailyCheckIn(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      timestamp: ts,
      feeling: WellnessFeeling.values.firstWhere(
        (e) => e.name == feelingStr,
        orElse: () => WellnessFeeling.doingFine,
      ),
      sleep: SleepQuality.values.firstWhere(
        (e) => e.name == sleepStr,
        orElse: () => SleepQuality.restful,
      ),
      tookPrescribedMedications: data['tookPrescribedMedications'] as bool? ?? false,
      personalNote: data['personalNote'] as String?,
      optionalMeasurement: measurement,
      isSharedWithFamily: data['isSharedWithFamily'] as bool? ?? true,
      sharingPermission: permission,
      isSyncPending: doc.metadata.hasPendingWrites,
    );
  }
}
