import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/daily_check_in.dart';
import '../domain/family_circle.dart';
import '../domain/family_invitation.dart';
import '../domain/family_member.dart';
import '../domain/sharing_permission.dart';
import 'family_repository.dart';

/// Firestore implementation for real family circles, invitations, and check-ins.
/// Collections:
/// - families/{familyId}
/// - families/{familyId}/members/{uid}
/// - families/{familyId}/checkins/{checkinId}
/// - invitations/{invitationId}
class FirestoreFamilyRepository implements FamilyRepository {
  final FirebaseFirestore _firestore;
  final String currentUserId;
  final String currentUserEmail;
  final String currentUserName;

  FirestoreFamilyRepository({
    required this.currentUserId,
    required String currentUserEmail,
    String? currentUserName,
    FirebaseFirestore? firestore,
  })  : currentUserEmail = currentUserEmail.trim().toLowerCase(),
        currentUserName =
            currentUserName ?? (currentUserEmail.split('@').first),
        _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _familiesCol =>
      _firestore.collection('families');

  CollectionReference<Map<String, dynamic>> get _invitationsCol =>
      _firestore.collection('invitations');

  /// Helper to get or create the primary family circle for the current user.
  Future<FamilyCircle> getOrCreatePrimaryFamily() async {
    final query = await _familiesCol
        .where('memberUids', arrayContains: currentUserId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return FamilyCircle.fromFirestore(query.docs.first);
    }

    // Create a new family circle
    final docRef = _familiesCol.doc();
    final family = FamilyCircle(
      id: docRef.id,
      name: '$currentUserName\'s Family',
      createdBy: currentUserId,
      memberUids: [currentUserId],
      createdAt: DateTime.now(),
    );
    await docRef.set(family.toFirestore());

    // Add self as primary owner member
    await docRef.collection('members').doc(currentUserId).set({
      'name': currentUserName,
      'email': currentUserEmail,
      'relationship': 'Me',
      'city': '',
      'avatarUrl': '',
      'joinedAt': FieldValue.serverTimestamp(),
      'role': 'owner',
      'sharingPermission': SharingPermission(
        shareCheckInStatus: true,
        shareSelfReportedMood: true,
        shareVitalsMeasurements: true,
        shareNotes: true,
        lastUpdated: DateTime.now(),
      ).toMap(),
    });

    return family;
  }

  @override
  Future<List<FamilyMember>> getFamilyMembers() async {
    final family = await getOrCreatePrimaryFamily();
    final membersSnapshot =
        await _familiesCol.doc(family.id).collection('members').get();

    // Query recent check-ins for the family to establish live check-in statuses
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final checkInsSnapshot = await _familiesCol
        .doc(family.id)
        .collection('checkins')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
        .get();

    final checkedInUserIds = <String, DateTime>{};
    for (final doc in checkInsSnapshot.docs) {
      final uId = doc.data()['userId'] as String?;
      final ts = (doc.data()['timestamp'] as Timestamp?)?.toDate();
      if (uId != null && ts != null) {
        if (!checkedInUserIds.containsKey(uId) || checkedInUserIds[uId]!.isBefore(ts)) {
          checkedInUserIds[uId] = ts;
        }
      }
    }

    return membersSnapshot.docs.map((doc) {
      final member = FamilyMember.fromFirestore(doc);
      final hasCheckedInToday = checkedInUserIds.containsKey(member.id);
      final lastCheckIn = checkedInUserIds[member.id] ?? member.lastCheckInTime;

      return member.copyWith(
        checkInStatus: hasCheckedInToday
            ? CheckInStatus.completedToday
            : CheckInStatus.pendingToday,
        lastCheckInTime: lastCheckIn,
      );
    }).toList();
  }

  @override
  Stream<List<FamilyMember>> watchFamilyMembers() async* {
    final family = await getOrCreatePrimaryFamily();
    yield* _familiesCol
        .doc(family.id)
        .collection('members')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return FamilyMember.fromFirestore(doc);
      }).toList();
    });
  }

  @override
  Future<FamilyMember?> getMemberById(String id) async {
    final members = await getFamilyMembers();
    return members.where((m) => m.id == id).firstOrNull;
  }

  @override
  Future<List<DailyCheckIn>> getCheckInHistoryForMember(String memberId) async {
    final family = await getOrCreatePrimaryFamily();
    final snapshot = await _familiesCol
        .doc(family.id)
        .collection('checkins')
        .where('userId', isEqualTo: memberId)
        .orderBy('timestamp', descending: true)
        .limit(30)
        .get();

    return snapshot.docs.map((d) => DailyCheckIn.fromFirestore(d)).toList();
  }

  @override
  Stream<List<DailyCheckIn>> watchCheckInHistory() async* {
    final family = await getOrCreatePrimaryFamily();
    yield* _familiesCol
        .doc(family.id)
        .collection('checkins')
        .orderBy('timestamp', descending: true)
        .limit(30)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((d) => DailyCheckIn.fromFirestore(d)).toList());
  }

  @override
  Future<void> submitCheckIn(DailyCheckIn checkIn) async {
    final family = await getOrCreatePrimaryFamily();
    
    // Idempotent document ID preventing duplicate submissions during offline retries
    final dateKey =
        '${checkIn.timestamp.year}_${checkIn.timestamp.month.toString().padLeft(2, '0')}_${checkIn.timestamp.day.toString().padLeft(2, '0')}';
    final docId = checkIn.id.isNotEmpty && !checkIn.id.startsWith('chk_')
        ? checkIn.id
        : 'chk_${checkIn.userId}_$dateKey';

    await _familiesCol
        .doc(family.id)
        .collection('checkins')
        .doc(docId)
        .set(checkIn.toFirestore(), SetOptions(merge: true));

    // Update member's lastCheckInTime and wellness summary in members subcollection
    await _familiesCol
        .doc(family.id)
        .collection('members')
        .doc(currentUserId)
        .set({
      'lastCheckInTime': Timestamp.fromDate(checkIn.timestamp),
      'lastWellnessSummary': '${checkIn.feelingDisplay} • ${checkIn.sleepDisplay}',
    }, SetOptions(merge: true));
  }

  @override
  Future<void> addFamilyMember(FamilyMember member) async {
    final family = await getOrCreatePrimaryFamily();
    await _familiesCol.doc(family.id).collection('members').doc(member.id).set(
          member.toFirestore(),
        );
    await _familiesCol.doc(family.id).update({
      'memberUids': FieldValue.arrayUnion([member.id]),
    });
  }

  @override
  Future<void> removeFamilyMember(String familyId, String memberId) async {
    // 1. Remove member document
    await _familiesCol
        .doc(familyId)
        .collection('members')
        .doc(memberId)
        .delete();

    // 2. Remove member UID from family array so access is immediately terminated
    await _familiesCol.doc(familyId).update({
      'memberUids': FieldValue.arrayRemove([memberId]),
    });
  }

  @override
  Future<void> updateSharingPermissions(
      String memberId, SharingPermission permission) async {
    // Sharing permissions can only be modified for one's own account
    if (memberId != currentUserId) {
      throw StateError('Cannot modify another member\'s sharing permissions.');
    }

    final family = await getOrCreatePrimaryFamily();
    await _familiesCol
        .doc(family.id)
        .collection('members')
        .doc(memberId)
        .set({
      'sharingPermission': permission.toMap(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> sendGentleReminder(String memberId) async {
    final family = await getOrCreatePrimaryFamily();
    await _familiesCol
        .doc(family.id)
        .collection('reminders')
        .add({
      'fromUid': currentUserId,
      'toUid': memberId,
      'sentAt': FieldValue.serverTimestamp(),
      'type': 'gentle_check_in_reminder',
    });
  }

  @override
  Future<List<FamilyInvitation>> getPendingInvitations() async {
    final snapshot = await _invitationsCol
        .where('inviteeEmail', isEqualTo: currentUserEmail)
        .where('status', isEqualTo: 'pending')
        .get();

    final invitations = snapshot.docs
        .map((d) => FamilyInvitation.fromFirestore(d))
        .where((inv) => !inv.isExpired)
        .toList();

    return invitations;
  }

  @override
  Future<List<FamilyInvitation>> getSentInvitations() async {
    final snapshot = await _invitationsCol
        .where('invitedByUid', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((d) => FamilyInvitation.fromFirestore(d)).toList();
  }

  @override
  Future<void> sendInvitation({
    required String inviteeEmail,
    required String relationship,
    String? familyName,
  }) async {
    final family = await getOrCreatePrimaryFamily();
    final invitationDoc = _invitationsCol.doc();
    final now = DateTime.now();

    final invitation = FamilyInvitation(
      id: invitationDoc.id,
      familyId: family.id,
      familyName: familyName ?? family.name,
      invitedByUid: currentUserId,
      invitedByEmail: currentUserEmail,
      inviteeEmail: inviteeEmail.trim().toLowerCase(),
      relationship: relationship,
      status: InvitationStatus.pending,
      createdAt: now,
      expiresAt: now.add(const Duration(days: 7)),
    );

    await invitationDoc.set(invitation.toFirestore());
  }

  @override
  Future<void> acceptInvitation(String invitationId) async {
    final invDocRef = _invitationsCol.doc(invitationId);

    await _firestore.runTransaction((transaction) async {
      final invSnap = await transaction.get(invDocRef);
      if (!invSnap.exists) {
        throw StateError('Invitation does not exist.');
      }

      final inv = FamilyInvitation.fromFirestore(invSnap);

      // 1. Verify intended recipient email identity
      if (inv.inviteeEmail.trim().toLowerCase() != currentUserEmail) {
        throw StateError('This invitation was sent to a different email address.');
      }

      // 2. Verify pending status
      if (inv.status != InvitationStatus.pending) {
        throw StateError('Invitation is already ${inv.status.name}.');
      }

      // 3. Verify expiry
      if (inv.isExpired) {
        transaction.update(invDocRef, {
          'status': InvitationStatus.expired.name,
        });
        throw StateError('This invitation has expired.');
      }

      // 4. Verify family existence
      final familyDocRef = _familiesCol.doc(inv.familyId);
      final famSnap = await transaction.get(familyDocRef);
      if (!famSnap.exists) {
        throw StateError('The target family circle no longer exists.');
      }

      final memberUids = List<String>.from(famSnap.data()?['memberUids'] as List? ?? []);
      // 5. Verify existing membership status
      if (memberUids.contains(currentUserId)) {
        transaction.update(invDocRef, {
          'status': InvitationStatus.accepted.name,
          'acceptedAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      // 6. Atomically add member
      final memberDocRef = familyDocRef.collection('members').doc(currentUserId);
      transaction.set(memberDocRef, {
        'name': currentUserName,
        'email': currentUserEmail,
        'relationship': inv.relationship,
        'joinedAt': FieldValue.serverTimestamp(),
        'role': 'member',
        'city': '',
        'avatarUrl': '',
        'sharingPermission': SharingPermission(
          shareCheckInStatus: true,
          shareSelfReportedMood: true,
          shareVitalsMeasurements: true,
          shareNotes: true,
          lastUpdated: DateTime.now(),
        ).toMap(),
      });

      // 7. Update family memberUids
      transaction.update(familyDocRef, {
        'memberUids': FieldValue.arrayUnion([currentUserId]),
      });

      // 8. Transition invitation status to accepted
      transaction.update(invDocRef, {
        'status': InvitationStatus.accepted.name,
        'acceptedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> declineInvitation(String invitationId) async {
    final invDoc = await _invitationsCol.doc(invitationId).get();
    if (!invDoc.exists) return;

    final inv = FamilyInvitation.fromFirestore(invDoc);
    if (inv.inviteeEmail.trim().toLowerCase() != currentUserEmail) {
      throw StateError('Not authorized to decline this invitation.');
    }

    await _invitationsCol.doc(invitationId).update({
      'status': InvitationStatus.declined.name,
      'declinedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> revokeInvitation(String invitationId) async {
    final invDoc = await _invitationsCol.doc(invitationId).get();
    if (!invDoc.exists) return;

    final inv = FamilyInvitation.fromFirestore(invDoc);
    if (inv.invitedByUid != currentUserId) {
      throw StateError('Only the inviter can revoke this invitation.');
    }

    await _invitationsCol.doc(invitationId).update({
      'status': InvitationStatus.revoked.name,
      'revokedAt': FieldValue.serverTimestamp(),
    });
  }
}
