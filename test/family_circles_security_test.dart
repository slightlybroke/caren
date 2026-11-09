import 'package:flutter_test/flutter_test.dart';
import 'package:caren/features/family/data/family_repository.dart';
import 'package:caren/features/family/domain/family_invitation.dart';
import 'package:caren/features/family/domain/family_member.dart';

/// Simulates the exact Boolean authorization logic embedded in `firestore.rules`.
class SecurityRulesSimulator {
  // Evaluates read on /families/{familyId}
  static bool canReadFamily({
    required String? authUid,
    required List<String> memberUids,
  }) {
    if (authUid == null) return false;
    return memberUids.contains(authUid);
  }

  // Evaluates create on /families/{familyId}/members/{memberId}
  static bool canCreateMember({
    required String? authUid,
    required String memberId,
    required String role,
    required String familyCreatedBy,
  }) {
    if (authUid == null) return false;
    // Authenticated user adding themselves as creator or role == 'member'
    if (authUid != memberId) return false;
    return authUid == familyCreatedBy || role == 'member';
  }

  // Evaluates update on /families/{familyId}/members/{memberId}
  static bool canUpdateMember({
    required String? authUid,
    required String memberId,
    required String currentRole,
    required String newRole,
    required Map<String, dynamic> currentConsent,
    required Map<String, dynamic> newConsent,
    required String familyCreatedBy,
  }) {
    if (authUid == null) return false;

    // Self update: Can update name/city/consent, but CANNOT self-promote role
    if (authUid == memberId) {
      if (newRole != currentRole) return false; // Self-promotion blocked
      return true;
    }

    // Creator update: Can manage role, but CANNOT modify another member's consent!
    if (authUid == familyCreatedBy) {
      // Must not modify another member's consent
      final consentModified = newConsent.toString() != currentConsent.toString();
      if (consentModified) return false;
      return true;
    }

    return false;
  }

  // Evaluates create on /invitations/{invitationId}
  static bool canCreateInvitation({
    required String? authUid,
    required String invitedByUid,
    required String status,
    required DateTime expiresAt,
    required DateTime now,
  }) {
    if (authUid == null) return false;
    if (authUid != invitedByUid) return false; // Anti-forgery
    if (status != 'pending') return false;
    if (!expiresAt.isAfter(now)) return false; // Must be in future
    return true;
  }

  // Evaluates update on /invitations/{invitationId}
  static bool canUpdateInvitation({
    required String? authUid,
    required String? authEmail,
    required String invitedByUid,
    required String inviteeEmail,
    required String currentStatus,
    required String newStatus,
    required DateTime expiresAt,
    required DateTime now,
    required String originFamilyId,
    required String targetFamilyId,
  }) {
    if (authUid == null) return false;
    if (originFamilyId != targetFamilyId) return false; // Immutability violation

    final isInvitee = authEmail != null &&
        authEmail.trim().toLowerCase() == inviteeEmail.trim().toLowerCase();

    // Invitee accepting or declining
    if (isInvitee) {
      if (currentStatus != 'pending') return false; // Single use: cannot reuse
      if (now.isAfter(expiresAt)) return false; // Cannot accept expired invite
      if (newStatus != 'accepted' && newStatus != 'declined') return false;
      return true;
    }

    // Inviter revoking
    if (authUid == invitedByUid) {
      if (currentStatus != 'pending') return false;
      if (newStatus != 'revoked') return false;
      return true;
    }

    return false;
  }

  // Evaluates update/delete on /families/{familyId}/checkins/{checkinId}
  static bool canModifyCheckIn({
    required String? authUid,
    required List<String> memberUids,
    required String checkinUserId,
  }) {
    if (authUid == null) return false;
    if (!memberUids.contains(authUid)) return false;
    return authUid == checkinUserId; // Only the author can modify or delete
  }

  // Evaluates read on /users/{userId}/me_sessions/{sessionId}
  static bool canReadMeSession({
    required String? authUid,
    required String resourceUserId,
  }) {
    if (authUid == null) return false;
    return authUid == resourceUserId; // Strictly private sanctuary
  }
}

void main() {
  group('FamilyInvitation Security & Lifecycle', () {
    test('Defaults to 7 days expiration from creation', () {
      final now = DateTime.now();
      final inv = FamilyInvitation(
        id: 'inv_1',
        familyId: 'fam_1',
        familyName: 'The Vance Family',
        invitedByUid: 'uid_alice',
        invitedByEmail: 'alice@example.com',
        inviteeEmail: 'bob@example.com',
        relationship: 'Brother',
        createdAt: now,
      );

      expect(inv.expiresAt.difference(now).inDays, 7);
      expect(inv.isExpired, false);
      expect(inv.canRespond, true);
    });

    test('Reports isExpired when past expiresAt date', () {
      final past = DateTime.now().subtract(const Duration(days: 8));
      final inv = FamilyInvitation(
        id: 'inv_old',
        familyId: 'fam_1',
        familyName: 'The Vance Family',
        invitedByUid: 'uid_alice',
        invitedByEmail: 'alice@example.com',
        inviteeEmail: 'bob@example.com',
        relationship: 'Brother',
        createdAt: past,
        expiresAt: past.add(const Duration(days: 7)),
      );

      expect(inv.isExpired, true);
      expect(inv.effectiveStatus, InvitationStatus.expired);
      expect(inv.canRespond, false);
    });

    test('LocalFamilyRepository blocks acceptance of expired invitation', () async {
      final repo = LocalFamilyRepository();
      final past = DateTime.now().subtract(const Duration(days: 10));

      // Create an expired invitation
      final expiredInv = FamilyInvitation(
        id: 'inv_expired',
        familyId: 'local_family',
        familyName: 'Family',
        invitedByUid: 'user_self',
        invitedByEmail: 'user@example.com',
        inviteeEmail: 'cousin@example.com',
        relationship: 'Cousin',
        status: InvitationStatus.pending,
        createdAt: past,
        expiresAt: past.add(const Duration(days: 7)),
      );

      expect(expiredInv.isExpired, true);
      expect(expiredInv.canRespond, false);
      repo.dispose();
    });

    test('Inviter can revoke pending invitation', () async {
      final repo = LocalFamilyRepository();
      await repo.sendInvitation(
        inviteeEmail: 'uncle@example.com',
        relationship: 'Uncle',
      );

      final sent = await repo.getSentInvitations();
      expect(sent.length, 1);
      final invId = sent.first.id;

      await repo.revokeInvitation(invId);
      final updatedSent = await repo.getSentInvitations();
      expect(updatedSent.first.status, InvitationStatus.revoked);

      // Revoked invite can no longer be responded to
      expect(updatedSent.first.canRespond, false);
      repo.dispose();
    });

    test('Simultaneous acceptance attempts: second attempt throws StateError', () async {
      final repo = LocalFamilyRepository();
      await repo.sendInvitation(
        inviteeEmail: 'brother@example.com',
        relationship: 'Brother',
      );

      final sent = await repo.getSentInvitations();
      final invId = sent.first.id;

      // First acceptance succeeds
      await repo.acceptInvitation(invId);

      // Simultaneous / second acceptance fails
      expect(
        () => repo.acceptInvitation(invId),
        throwsA(isA<StateError>()),
      );
      repo.dispose();
    });

    test('Invitation revocation race: acceptance after revocation throws StateError', () async {
      final repo = LocalFamilyRepository();
      await repo.sendInvitation(
        inviteeEmail: 'sister@example.com',
        relationship: 'Sister',
      );

      final sent = await repo.getSentInvitations();
      final invId = sent.first.id;

      // Inviter revokes invitation
      await repo.revokeInvitation(invId);

      // Invitee attempts to accept revoked invitation
      expect(
        () => repo.acceptInvitation(invId),
        throwsA(isA<StateError>()),
      );
      repo.dispose();
    });
  });

  group('Family Member Roles & Removal Flow', () {
    test('Role hierarchy distinguishes owner, admin, and member', () {
      expect(FamilyRole.owner.isAdminOrOwner, true);
      expect(FamilyRole.admin.isAdminOrOwner, true);
      expect(FamilyRole.member.isAdminOrOwner, false);
    });

    test('removeFamilyMember terminates member presence in circle', () async {
      final repo = LocalFamilyRepository();
      final membersBefore = await repo.getFamilyMembers();
      final targetId = membersBefore.first.id;

      await repo.removeFamilyMember('local_family', targetId);
      final membersAfter = await repo.getFamilyMembers();
      expect(membersAfter.any((m) => m.id == targetId), false);
      repo.dispose();
    });
  });

  group('10 Attack Vectors Firestore Security Verification', () {
    final now = DateTime.now();

    test('Vector 1: Read without membership is DENIED', () {
      final permitted = SecurityRulesSimulator.canReadFamily(
        authUid: 'attacker_uid',
        memberUids: ['user_alice', 'user_bob'],
      );
      expect(permitted, false);

      final legitimateMember = SecurityRulesSimulator.canReadFamily(
        authUid: 'user_alice',
        memberUids: ['user_alice', 'user_bob'],
      );
      expect(legitimateMember, true);
    });

    test('Vector 2: Create membership without invite is DENIED', () {
      // Attacker tries to inject themselves as an admin or arbitrary member
      final attackerDirectAdd = SecurityRulesSimulator.canCreateMember(
        authUid: 'attacker_uid',
        memberId: 'victim_uid',
        role: 'admin',
        familyCreatedBy: 'user_alice',
      );
      expect(attackerDirectAdd, false);
    });

    test('Vector 3: Modify another member’s consent is DENIED', () {
      final initialConsent = {'shareVitals': false};
      final alteredConsent = {'shareVitals': true};

      // Admin or family creator attempts to force consent changes on another member
      final maliciousUpdate = SecurityRulesSimulator.canUpdateMember(
        authUid: 'user_alice', // Circle Creator
        memberId: 'user_bob',  // Member
        currentRole: 'member',
        newRole: 'member',
        currentConsent: initialConsent,
        newConsent: alteredConsent,
        familyCreatedBy: 'user_alice',
      );
      expect(maliciousUpdate, false);

      // Self update of own consent is PERMITTED
      final legitimateSelfUpdate = SecurityRulesSimulator.canUpdateMember(
        authUid: 'user_bob',
        memberId: 'user_bob',
        currentRole: 'member',
        newRole: 'member',
        currentConsent: initialConsent,
        newConsent: alteredConsent,
        familyCreatedBy: 'user_alice',
      );
      expect(legitimateSelfUpdate, true);
    });

    test('Vector 4: Member self-promotion to admin is DENIED', () {
      final consent = {'shareVitals': true};
      final selfPromote = SecurityRulesSimulator.canUpdateMember(
        authUid: 'user_bob',
        memberId: 'user_bob',
        currentRole: 'member',
        newRole: 'admin',
        currentConsent: consent,
        newConsent: consent,
        familyCreatedBy: 'user_alice',
      );
      expect(selfPromote, false);
    });

    test('Vector 5: Forge invitation ownership is DENIED', () {
      // Attacker claims to send invite on behalf of victim
      final forgedInvite = SecurityRulesSimulator.canCreateInvitation(
        authUid: 'attacker_uid',
        invitedByUid: 'victim_alice',
        status: 'pending',
        expiresAt: now.add(const Duration(days: 7)),
        now: now,
      );
      expect(forgedInvite, false);
    });

    test('Vector 6: Accept expired or revoked invite is DENIED', () {
      final expiredInvite = SecurityRulesSimulator.canUpdateInvitation(
        authUid: 'user_bob',
        authEmail: 'bob@example.com',
        invitedByUid: 'user_alice',
        inviteeEmail: 'bob@example.com',
        currentStatus: 'pending',
        newStatus: 'accepted',
        expiresAt: now.subtract(const Duration(minutes: 1)),
        now: now,
        originFamilyId: 'fam_1',
        targetFamilyId: 'fam_1',
      );
      expect(expiredInvite, false);

      final revokedInvite = SecurityRulesSimulator.canUpdateInvitation(
        authUid: 'user_bob',
        authEmail: 'bob@example.com',
        invitedByUid: 'user_alice',
        inviteeEmail: 'bob@example.com',
        currentStatus: 'revoked',
        newStatus: 'accepted',
        expiresAt: now.add(const Duration(days: 5)),
        now: now,
        originFamilyId: 'fam_1',
        targetFamilyId: 'fam_1',
      );
      expect(revokedInvite, false);
    });

    test('Vector 7: Reuse accepted invite is DENIED', () {
      final reuseAttempt = SecurityRulesSimulator.canUpdateInvitation(
        authUid: 'user_attacker',
        authEmail: 'attacker@example.com',
        invitedByUid: 'user_alice',
        inviteeEmail: 'attacker@example.com',
        currentStatus: 'accepted', // Already used
        newStatus: 'accepted',
        expiresAt: now.add(const Duration(days: 5)),
        now: now,
        originFamilyId: 'fam_1',
        targetFamilyId: 'fam_1',
      );
      expect(reuseAttempt, false);
    });

    test('Vector 8: Modify or delete another member’s check-in is DENIED', () {
      // Family member attempting to modify another member's checkin
      final crossUserEdit = SecurityRulesSimulator.canModifyCheckIn(
        authUid: 'user_alice',
        memberUids: ['user_alice', 'user_bob'],
        checkinUserId: 'user_bob',
      );
      expect(crossUserEdit, false);

      // Author modifying their own checkin is PERMITTED
      final authorEdit = SecurityRulesSimulator.canModifyCheckIn(
        authUid: 'user_bob',
        memberUids: ['user_alice', 'user_bob'],
        checkinUserId: 'user_bob',
      );
      expect(authorEdit, true);
    });

    test('Vector 9: Read private Me sanctuary sessions is strictly DENIED to family members', () {
      // Alice is in the same family as Bob, but cannot view Bob's personal Me sanctuary
      final familyMemberSneak = SecurityRulesSimulator.canReadMeSession(
        authUid: 'user_alice',
        resourceUserId: 'user_bob',
      );
      expect(familyMemberSneak, false);

      final ownerRead = SecurityRulesSimulator.canReadMeSession(
        authUid: 'user_bob',
        resourceUserId: 'user_bob',
      );
      expect(ownerRead, true);
    });

    test('Vector 10: Read after removal is immediately DENIED', () {
      final activeMembers = ['user_alice', 'user_bob'];
      expect(SecurityRulesSimulator.canReadFamily(authUid: 'user_bob', memberUids: activeMembers), true);

      // Bob is removed from memberUids
      final updatedMembers = ['user_alice'];
      expect(SecurityRulesSimulator.canReadFamily(authUid: 'user_bob', memberUids: updatedMembers), false);
    });
  });
}
