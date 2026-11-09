import 'package:cloud_firestore/cloud_firestore.dart';

enum InvitationStatus {
  pending,
  accepted,
  declined,
  expired,
  revoked,
}

/// An invitation sent to an email address to join a Family Circle.
class FamilyInvitation {
  final String id;
  final String familyId;
  final String familyName;
  final String invitedByUid;
  final String invitedByEmail;
  final String inviteeEmail;
  final String relationship;
  final InvitationStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? acceptedAt;
  final DateTime? declinedAt;
  final DateTime? revokedAt;

  FamilyInvitation({
    required this.id,
    required this.familyId,
    required this.familyName,
    required this.invitedByUid,
    required this.invitedByEmail,
    required this.inviteeEmail,
    required this.relationship,
    this.status = InvitationStatus.pending,
    required this.createdAt,
    DateTime? expiresAt,
    this.acceptedAt,
    this.declinedAt,
    this.revokedAt,
  }) : expiresAt = expiresAt ?? createdAt.add(const Duration(days: 7));

  /// Checks if this invitation is expired (past 7 days or marked expired).
  bool get isExpired {
    if (status == InvitationStatus.expired) return true;
    if (status == InvitationStatus.pending && DateTime.now().isAfter(expiresAt)) {
      return true;
    }
    return false;
  }

  /// Returns the effective status accounting for time-based expiration.
  InvitationStatus get effectiveStatus {
    if (isExpired) return InvitationStatus.expired;
    return status;
  }

  /// Whether the invitation can still be accepted or declined.
  bool get canRespond => effectiveStatus == InvitationStatus.pending;

  Map<String, dynamic> toFirestore() {
    return {
      'familyId': familyId,
      'familyName': familyName,
      'invitedByUid': invitedByUid,
      'invitedByEmail': invitedByEmail.trim().toLowerCase(),
      'inviteeEmail': inviteeEmail.trim().toLowerCase(),
      'relationship': relationship,
      'status': effectiveStatus.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      if (acceptedAt != null) 'acceptedAt': Timestamp.fromDate(acceptedAt!),
      if (declinedAt != null) 'declinedAt': Timestamp.fromDate(declinedAt!),
      if (revokedAt != null) 'revokedAt': Timestamp.fromDate(revokedAt!),
    };
  }

  factory FamilyInvitation.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final createdTimestamp = data['createdAt'] as Timestamp?;
    final expiresTimestamp = data['expiresAt'] as Timestamp?;
    final acceptedTimestamp = data['acceptedAt'] as Timestamp?;
    final declinedTimestamp = data['declinedAt'] as Timestamp?;
    final revokedTimestamp = data['revokedAt'] as Timestamp?;
    final statusStr = data['status'] as String? ?? 'pending';

    final created = createdTimestamp?.toDate() ?? DateTime.now();
    final expires = expiresTimestamp?.toDate() ?? created.add(const Duration(days: 7));

    return FamilyInvitation(
      id: doc.id,
      familyId: data['familyId'] as String? ?? '',
      familyName: data['familyName'] as String? ?? 'Family',
      invitedByUid: data['invitedByUid'] as String? ?? '',
      invitedByEmail: data['invitedByEmail'] as String? ?? '',
      inviteeEmail: data['inviteeEmail'] as String? ?? '',
      relationship: data['relationship'] as String? ?? 'Family Member',
      status: InvitationStatus.values.firstWhere(
        (e) => e.name == statusStr,
        orElse: () => InvitationStatus.pending,
      ),
      createdAt: created,
      expiresAt: expires,
      acceptedAt: acceptedTimestamp?.toDate(),
      declinedAt: declinedTimestamp?.toDate(),
      revokedAt: revokedTimestamp?.toDate(),
    );
  }
}
