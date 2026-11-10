import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/firebase/firebase_service.dart';
import '../../authentication/data/auth_repository.dart';
import '../domain/family_member.dart';
import '../domain/daily_check_in.dart';
import '../domain/family_invitation.dart';
import '../domain/sharing_permission.dart';
import '../../../services/vitals/vitals_models.dart';
import 'firestore_family_repository.dart';

abstract class FamilyRepository {
  Future<List<FamilyMember>> getFamilyMembers();
  Stream<List<FamilyMember>> watchFamilyMembers();
  Future<FamilyMember?> getMemberById(String id);
  Future<List<DailyCheckIn>> getCheckInHistoryForMember(String memberId);
  Stream<List<DailyCheckIn>> watchCheckInHistory();
  Future<void> submitCheckIn(DailyCheckIn checkIn);
  Future<void> addFamilyMember(FamilyMember member);
  Future<void> removeFamilyMember(String familyId, String memberId);
  Future<void> updateSharingPermissions(String memberId, SharingPermission permission);
  Future<void> sendGentleReminder(String memberId);
  Future<List<FamilyInvitation>> getPendingInvitations();
  Future<List<FamilyInvitation>> getSentInvitations();
  Future<void> sendInvitation({
    required String inviteeEmail,
    required String relationship,
    String? familyName,
    Map<String, bool>? sharingPermissions,
    String? passcode,
  });
  Future<void> acceptInvitation(String invitationId);
  Future<void> declineInvitation(String invitationId);
  Future<void> revokeInvitation(String invitationId);
}

class LocalFamilyRepository implements FamilyRepository {
  final List<FamilyMember> _members;
  final List<DailyCheckIn> _checkIns;
  final List<FamilyInvitation> _invitations = [];
  final _membersController = StreamController<List<FamilyMember>>.broadcast();
  final _checkInsController = StreamController<List<DailyCheckIn>>.broadcast();

  LocalFamilyRepository({
    List<FamilyMember>? initialMembers,
    List<DailyCheckIn>? initialCheckIns,
  })  : _members = initialMembers ??
            [
              FamilyMember(
                id: 'mem_1',
                name: 'Eleanor Vance',
                relationship: 'Mother',
                city: 'Portland, OR',
                avatarUrl: '',
                role: FamilyRole.owner,
                checkInStatus: CheckInStatus.completedToday,
                lastCheckInTime:
                    DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
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
                role: FamilyRole.member,
                checkInStatus: CheckInStatus.pendingToday,
                lastCheckInTime:
                    DateTime.now().subtract(const Duration(days: 1, hours: 3)),
                lastWellnessSummary: 'Yesterday: Doing fine',
                sharingPermission: SharingPermission(
                  shareCheckInStatus: true,
                  shareSelfReportedMood: true,
                  shareVitalsMeasurements: false,
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
                role: FamilyRole.member,
                checkInStatus: CheckInStatus.completedToday,
                lastCheckInTime:
                    DateTime.now().subtract(const Duration(hours: 4)),
                lastWellnessSummary: 'Doing fine • Regular morning walk',
                sharingPermission: SharingPermission(
                  shareCheckInStatus: true,
                  shareSelfReportedMood: true,
                  shareVitalsMeasurements: false,
                  shareNotes: false,
                  lastUpdated: DateTime.now().subtract(const Duration(days: 5)),
                ),
              ),
            ],
        _checkIns = initialCheckIns ??
            [
              DailyCheckIn(
                id: 'chk_101',
                userId: 'mem_1',
                userName: 'Eleanor Vance',
                timestamp:
                    DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
                feeling: WellnessFeeling.feelingWell,
                sleep: SleepQuality.restful,
                tookPrescribedMedications: true,
                personalNote:
                    'Had morning tea in the garden. Feeling refreshed.',
                optionalMeasurement: MeasurementResult(
                  target: MeasurementTarget.breathingAndPulse,
                  durationSeconds: 30,
                  pulseRateBpm: 68,
                  breathingRateBpm: 14,
                  qualityScore: 0.95,
                  stabilityStatus: 'Stable camera and steady lighting',
                  timestamp: DateTime.now()
                      .subtract(const Duration(hours: 2, minutes: 10)),
                  isSimulated: true,
                  isSuccessful: true,
                  notes:
                      '[SIMULATED] Camera spot check completed in steady morning light.',
                ),
                isSharedWithFamily: true,
              ),
            ];

  @override
  Future<List<FamilyMember>> getFamilyMembers() async {
    return List.unmodifiable(_members);
  }

  @override
  Stream<List<FamilyMember>> watchFamilyMembers() {
    return _membersController.stream;
  }

  @override
  Future<FamilyMember?> getMemberById(String id) async {
    return _members.where((m) => m.id == id).firstOrNull;
  }

  @override
  Future<List<DailyCheckIn>> getCheckInHistoryForMember(String memberId) async {
    return _checkIns.where((c) => c.userId == memberId).toList();
  }

  @override
  Stream<List<DailyCheckIn>> watchCheckInHistory() {
    return _checkInsController.stream;
  }

  @override
  Future<void> submitCheckIn(DailyCheckIn checkIn) async {
    _checkIns.insert(0, checkIn);
    _checkInsController.add(List.unmodifiable(_checkIns));
    final index = _members.indexWhere((m) => m.id == checkIn.userId);
    if (index != -1) {
      _members[index] = _members[index].copyWith(
        checkInStatus: CheckInStatus.completedToday,
        lastCheckInTime: checkIn.timestamp,
        lastWellnessSummary:
            '${checkIn.feelingDisplay} • ${checkIn.sleepDisplay}',
      );
      _membersController.add(List.unmodifiable(_members));
    }
  }

  @override
  Future<void> addFamilyMember(FamilyMember member) async {
    _members.add(member);
    _membersController.add(List.unmodifiable(_members));
  }

  @override
  Future<void> removeFamilyMember(String familyId, String memberId) async {
    _members.removeWhere((m) => m.id == memberId);
    _membersController.add(List.unmodifiable(_members));
  }

  @override
  Future<void> updateSharingPermissions(
      String memberId, SharingPermission permission) async {
    final index = _members.indexWhere((m) => m.id == memberId);
    if (index != -1) {
      _members[index] = _members[index].copyWith(sharingPermission: permission);
      _membersController.add(List.unmodifiable(_members));
    }
  }

  @override
  Future<void> sendGentleReminder(String memberId) async {
    // Local simulation of gentle reminder
  }

  @override
  Future<List<FamilyInvitation>> getPendingInvitations() async {
    return _invitations.where((i) => i.canRespond).toList();
  }

  @override
  Future<List<FamilyInvitation>> getSentInvitations() async {
    return List.unmodifiable(_invitations);
  }

  @override
  Future<void> sendInvitation({
    required String inviteeEmail,
    required String relationship,
    String? familyName,
    Map<String, bool>? sharingPermissions,
    String? passcode,
  }) async {
    final now = DateTime.now();
    final inv = FamilyInvitation(
      id: 'inv_${now.millisecondsSinceEpoch}',
      familyId: 'local_family',
      familyName: familyName ?? 'Family',
      invitedByUid: 'user_self',
      invitedByEmail: 'user@example.com',
      inviteeEmail: inviteeEmail.trim().toLowerCase(),
      relationship: relationship,
      status: InvitationStatus.pending,
      createdAt: now,
      expiresAt: now.add(const Duration(days: 7)),
      sharingPermissions: sharingPermissions,
      passcode: passcode,
    );
    _invitations.add(inv);
  }

  @override
  Future<void> acceptInvitation(String invitationId) async {
    final index = _invitations.indexWhere((i) => i.id == invitationId);
    if (index != -1) {
      final inv = _invitations[index];
      if (inv.isExpired) {
        throw StateError('Cannot accept an expired invitation.');
      }
      if (inv.status != InvitationStatus.pending) {
        throw StateError('Cannot accept an invitation that is already ${inv.status.name}.');
      }

      _invitations[index] = FamilyInvitation(
        id: inv.id,
        familyId: inv.familyId,
        familyName: inv.familyName,
        invitedByUid: inv.invitedByUid,
        invitedByEmail: inv.invitedByEmail,
        inviteeEmail: inv.inviteeEmail,
        relationship: inv.relationship,
        status: InvitationStatus.accepted,
        createdAt: inv.createdAt,
        expiresAt: inv.expiresAt,
        acceptedAt: DateTime.now(),
        sharingPermissions: inv.sharingPermissions,
        passcode: inv.passcode,
      );

      final initialSharing = inv.sharingPermissions;
      // Add to local members with sovereign default-OFF or configured permissions
      _members.add(FamilyMember(
        id: 'member_${DateTime.now().millisecondsSinceEpoch}',
        name: inv.inviteeEmail.split('@').first,
        relationship: inv.relationship,
        city: 'Local',
        avatarUrl: '',
        role: FamilyRole.member,
        checkInStatus: CheckInStatus.pendingToday,
        sharingPermission: SharingPermission(
          shareCheckInStatus: initialSharing['shareCheckInStatus'] ?? false,
          shareSelfReportedMood: initialSharing['shareSelfReportedMood'] ?? false,
          shareVitalsMeasurements: initialSharing['shareVitalsMeasurements'] ?? false,
          shareNotes: initialSharing['shareNotes'] ?? false,
          lastUpdated: DateTime.now(),
        ),
      ));
      _membersController.add(List.unmodifiable(_members));
    }
  }

  @override
  Future<void> declineInvitation(String invitationId) async {
    final index = _invitations.indexWhere((i) => i.id == invitationId);
    if (index != -1) {
      final inv = _invitations[index];
      _invitations[index] = FamilyInvitation(
        id: inv.id,
        familyId: inv.familyId,
        familyName: inv.familyName,
        invitedByUid: inv.invitedByUid,
        invitedByEmail: inv.invitedByEmail,
        inviteeEmail: inv.inviteeEmail,
        relationship: inv.relationship,
        status: InvitationStatus.declined,
        createdAt: inv.createdAt,
        expiresAt: inv.expiresAt,
        declinedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> revokeInvitation(String invitationId) async {
    final index = _invitations.indexWhere((i) => i.id == invitationId);
    if (index != -1) {
      final inv = _invitations[index];
      _invitations[index] = FamilyInvitation(
        id: inv.id,
        familyId: inv.familyId,
        familyName: inv.familyName,
        invitedByUid: inv.invitedByUid,
        invitedByEmail: inv.invitedByEmail,
        inviteeEmail: inv.inviteeEmail,
        relationship: inv.relationship,
        status: InvitationStatus.revoked,
        createdAt: inv.createdAt,
        expiresAt: inv.expiresAt,
        revokedAt: DateTime.now(),
      );
    }
  }

  void dispose() {
    _membersController.close();
    _checkInsController.close();
  }
}

final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  final fbState = ref.watch(firebaseStateProvider);
  final currentUser = ref.watch(currentUserProvider);

  if (fbState.isInitialized && currentUser != null) {
    return FirestoreFamilyRepository(
      currentUserId: currentUser.uid,
      currentUserEmail: currentUser.email,
      currentUserName: currentUser.displayName,
    );
  }

  return LocalFamilyRepository();
});

final familyMembersProvider = FutureProvider<List<FamilyMember>>((ref) async {
  final repo = ref.watch(familyRepositoryProvider);
  return repo.getFamilyMembers();
});

final familyMemberDetailProvider =
    FutureProvider.family<FamilyMember?, String>((ref, id) async {
  final repo = ref.watch(familyRepositoryProvider);
  return repo.getMemberById(id);
});

final familyMemberHistoryProvider =
    FutureProvider.family<List<DailyCheckIn>, String>((ref, memberId) async {
  final repo = ref.watch(familyRepositoryProvider);
  return repo.getCheckInHistoryForMember(memberId);
});

final pendingInvitationsProvider =
    FutureProvider<List<FamilyInvitation>>((ref) async {
  final repo = ref.watch(familyRepositoryProvider);
  return repo.getPendingInvitations();
});

final sentInvitationsProvider =
    FutureProvider<List<FamilyInvitation>>((ref) async {
  final repo = ref.watch(familyRepositoryProvider);
  return repo.getSentInvitations();
});
