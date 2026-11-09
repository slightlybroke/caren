import 'package:flutter_test/flutter_test.dart';
import 'package:caren/features/family/data/family_repository.dart';
import 'package:caren/features/family/domain/daily_check_in.dart';
import 'package:caren/features/family/domain/family_invitation.dart';
import 'package:caren/features/family/domain/family_member.dart';
import 'package:caren/features/family/domain/sharing_permission.dart';
import 'package:caren/features/profile/domain/user_profile.dart';
import 'package:caren/services/vitals/vitals_models.dart';

void main() {
  group('EmergencyDirectory and UserProfile Localization', () {
    test('Correctly maps country to emergency dispatch numbers', () {
      expect(EmergencyDirectory.getNumber('United States'), '911');
      expect(EmergencyDirectory.getNumber('India'), '112');
      expect(EmergencyDirectory.getNumber('United Kingdom'), '999');
      expect(EmergencyDirectory.getNumber('Australia'), '000');
      expect(EmergencyDirectory.getNumber('Japan'), '119');
      expect(EmergencyDirectory.getNumber('Unknown Country'), '112');
    });

    test('UserProfile copyWith updates emergency number when country changes', () {
      final profile = UserProfile.empty(id: 'usr_1', email: 'test@example.com');
      expect(profile.emergencyNumber, '112');

      final updated = profile.copyWith(country: 'United States');
      expect(updated.country, 'United States');
      expect(updated.emergencyNumber, '911');
    });
  });

  group('DailyCheckIn Privacy & Consent Serialization', () {
    test('DailyCheckIn strips vitals and notes when permissions disallow them', () {
      final measurement = MeasurementResult(
        target: MeasurementTarget.pulseOnly,
        durationSeconds: 15,
        pulseRateBpm: 72,
        timestamp: DateTime.now(),
        isSimulated: true,
        isSuccessful: true,
      );

      final checkIn = DailyCheckIn(
        id: 'chk_1',
        userId: 'u1',
        userName: 'Alice',
        timestamp: DateTime.now(),
        feeling: WellnessFeeling.feelingWell,
        sleep: SleepQuality.restful,
        tookPrescribedMedications: true,
        personalNote: 'Private journal reflection',
        optionalMeasurement: measurement,
      );

      // Disallow vitals and notes
      final privatePermission = SharingPermission(
        shareCheckInStatus: true,
        shareSelfReportedMood: true,
        shareVitalsMeasurements: false,
        shareNotes: false,
        lastUpdated: DateTime.now(),
      );

      final firestoreData = checkIn.toFirestore(privatePermission);

      expect(firestoreData['hasOptionalMeasurement'], false);
      expect(firestoreData['measurement'], isNull);
      expect(firestoreData['personalNote'], isNull);
      expect(firestoreData['feeling'], 'feelingWell');
    });

    test('DailyCheckIn includes vitals and notes when permissions explicitly allow them', () {
      final measurement = MeasurementResult(
        target: MeasurementTarget.breathingAndPulse,
        durationSeconds: 30,
        pulseRateBpm: 75,
        breathingRateBpm: 15,
        timestamp: DateTime.now(),
        isSimulated: false,
        isSuccessful: true,
      );

      final checkIn = DailyCheckIn(
        id: 'chk_2',
        userId: 'u1',
        userName: 'Alice',
        timestamp: DateTime.now(),
        feeling: WellnessFeeling.doingFine,
        sleep: SleepQuality.restful,
        tookPrescribedMedications: true,
        personalNote: 'Had tea in the sun.',
        optionalMeasurement: measurement,
      );

      final openPermission = SharingPermission(
        shareCheckInStatus: true,
        shareSelfReportedMood: true,
        shareVitalsMeasurements: true,
        shareNotes: true,
        lastUpdated: DateTime.now(),
      );

      final firestoreData = checkIn.toFirestore(openPermission);

      expect(firestoreData['hasOptionalMeasurement'], true);
      expect(firestoreData['measurement'], isNotNull);
      expect((firestoreData['measurement'] as Map)['pulseRateBpm'], 75);
      expect((firestoreData['measurement'] as Map)['breathingRateBpm'], 15);
      expect(firestoreData['personalNote'], 'Had tea in the sun.');
    });
  });

  group('FamilyRepository Invitations and Members Flow', () {
    late LocalFamilyRepository repo;

    setUp(() {
      repo = LocalFamilyRepository();
    });

    tearDown(() {
      repo.dispose();
    });

    test('sendInvitation adds pending invitation', () async {
      await repo.sendInvitation(
        inviteeEmail: 'dad@example.com',
        relationship: 'Father',
      );

      final pending = await repo.getPendingInvitations();
      expect(pending.length, 1);
      expect(pending.first.inviteeEmail, 'dad@example.com');
      expect(pending.first.relationship, 'Father');
      expect(pending.first.status, InvitationStatus.pending);
    });

    test('acceptInvitation changes status to accepted', () async {
      await repo.sendInvitation(
        inviteeEmail: 'sister@example.com',
        relationship: 'Sister',
      );

      final pending = await repo.getPendingInvitations();
      final id = pending.first.id;

      await repo.acceptInvitation(id);
      final remaining = await repo.getPendingInvitations();
      expect(remaining.isEmpty, true);
    });

    test('submitCheckIn updates member checkInStatus to completedToday', () async {
      final initialMembers = await repo.getFamilyMembers();
      final memberId = initialMembers.first.id;

      final checkIn = DailyCheckIn(
        id: 'chk_new',
        userId: memberId,
        userName: initialMembers.first.name,
        timestamp: DateTime.now(),
        feeling: WellnessFeeling.feelingWell,
        sleep: SleepQuality.restful,
        tookPrescribedMedications: true,
      );

      await repo.submitCheckIn(checkIn);

      final updated = await repo.getMemberById(memberId);
      expect(updated?.checkInStatus, CheckInStatus.completedToday);
    });
  });
}

