import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/family_member.dart';
import '../domain/daily_check_in.dart';
import '../domain/sharing_permission.dart';
import '../../../services/vitals/vitals_models.dart';

abstract class FamilyRepository {
  Future<List<FamilyMember>> getFamilyMembers();
  Future<FamilyMember?> getMemberById(String id);
  Future<List<DailyCheckIn>> getCheckInHistoryForMember(String memberId);
  Future<void> submitCheckIn(DailyCheckIn checkIn);
  Future<void> updateSharingPermissions(String memberId, SharingPermission permission);
  Future<void> sendGentleReminder(String memberId);
}

class LocalFamilyRepository implements FamilyRepository {
  final List<FamilyMember> _members = [
    FamilyMember(
      id: 'mem_1',
      name: 'Eleanor Vance',
      relationship: 'Mother',
      city: 'Portland, OR',
      avatarUrl: '',
      checkInStatus: CheckInStatus.completedToday,
      lastCheckInTime: DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
      lastWellnessSummary: 'Feeling well & energized • Rested well',
      sharingPermission: SharingPermission(
        shareCheckInStatus: true,
        shareSelfReportedMood: true,
        shareVitalsMeasurements: true,
        shareNotes: true,
        lastUpdated: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ),
    FamilyMember(
      id: 'mem_2',
      name: 'Arthur Vance',
      relationship: 'Father',
      city: 'Portland, OR',
      avatarUrl: '',
      checkInStatus: CheckInStatus.pendingToday,
      lastCheckInTime: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      lastWellnessSummary: 'Yesterday: Doing fine',
      sharingPermission: SharingPermission(
        shareCheckInStatus: true,
        shareSelfReportedMood: true,
        shareVitalsMeasurements: false, // Respects privacy
        shareNotes: false,
        lastUpdated: DateTime.now().subtract(const Duration(days: 14)),
      ),
    ),
    FamilyMember(
      id: 'mem_3',
      name: 'Maya Lin',
      relationship: 'Sister',
      city: 'Seattle, WA',
      avatarUrl: '',
      checkInStatus: CheckInStatus.completedToday,
      lastCheckInTime: DateTime.now().subtract(const Duration(hours: 4)),
      lastWellnessSummary: 'Doing fine • Regular morning walk',
      sharingPermission: SharingPermission(
        shareCheckInStatus: true,
        shareSelfReportedMood: true,
        shareVitalsMeasurements: false,
        shareNotes: false,
        lastUpdated: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ),
  ];

  final List<DailyCheckIn> _checkIns = [
    DailyCheckIn(
      id: 'chk_101',
      userId: 'mem_1',
      userName: 'Eleanor Vance',
      timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
      feeling: WellnessFeeling.feelingWell,
      sleep: SleepQuality.restful,
      tookPrescribedMedications: true,
      personalNote: 'Had morning tea in the garden. Feeling refreshed.',
      optionalMeasurement: MeasurementResult(
        target: MeasurementTarget.breathingAndPulse,
        durationSeconds: 30,
        pulseRateBpm: 68,
        breathingRateBpm: 14,
        qualityScore: 0.95,
        stabilityStatus: 'Stable camera and steady lighting',
        timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 10)),
        isSimulated: true, // Marked simulated
        isSuccessful: true,
        notes: '[SIMULATED] Camera spot check completed in steady morning light.',
      ),
      isSharedWithFamily: true,
    ),
    DailyCheckIn(
      id: 'chk_100',
      userId: 'mem_1',
      userName: 'Eleanor Vance',
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      feeling: WellnessFeeling.doingFine,
      sleep: SleepQuality.interrupted,
      tookPrescribedMedications: true,
      personalNote: 'A bit windy outside so stayed indoors with crossword puzzles.',
      optionalMeasurement: null,
      isSharedWithFamily: true,
    ),
  ];

  @override
  Future<List<FamilyMember>> getFamilyMembers() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_members);
  }

  @override
  Future<FamilyMember?> getMemberById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _members.where((m) => m.id == id).firstOrNull;
  }

  @override
  Future<List<DailyCheckIn>> getCheckInHistoryForMember(String memberId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _checkIns.where((c) => c.userId == memberId).toList();
  }

  @override
  Future<void> submitCheckIn(DailyCheckIn checkIn) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _checkIns.insert(0, checkIn);
    final index = _members.indexWhere((m) => m.id == checkIn.userId);
    if (index != -1) {
      _members[index] = _members[index].copyWith(
        checkInStatus: CheckInStatus.completedToday,
        lastCheckInTime: checkIn.timestamp,
        lastWellnessSummary: '${checkIn.feelingDisplay} • ${checkIn.sleepDisplay}',
      );
    }
  }

  @override
  Future<void> updateSharingPermissions(String memberId, SharingPermission permission) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _members.indexWhere((m) => m.id == memberId);
    if (index != -1) {
      _members[index] = _members[index].copyWith(sharingPermission: permission);
    }
  }

  @override
  Future<void> sendGentleReminder(String memberId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    // Simulated friendly notification trigger
  }
}

final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  return LocalFamilyRepository();
});

final familyMembersProvider = FutureProvider<List<FamilyMember>>((ref) async {
  final repo = ref.watch(familyRepositoryProvider);
  return repo.getFamilyMembers();
});

final familyMemberDetailProvider = FutureProvider.family<FamilyMember?, String>((ref, id) async {
  final repo = ref.watch(familyRepositoryProvider);
  return repo.getMemberById(id);
});

final familyMemberHistoryProvider = FutureProvider.family<List<DailyCheckIn>, String>((ref, memberId) async {
  final repo = ref.watch(familyRepositoryProvider);
  return repo.getCheckInHistoryForMember(memberId);
});

