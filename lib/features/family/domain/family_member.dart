import 'package:cloud_firestore/cloud_firestore.dart';
import 'sharing_permission.dart';

enum CheckInStatus {
  completedToday,
  pendingToday,
  missedYesterday,
}

enum FamilyRole {
  owner,
  admin,
  member;

  static FamilyRole fromString(String? role) {
    switch (role?.toLowerCase()) {
      case 'owner':
        return FamilyRole.owner;
      case 'admin':
        return FamilyRole.admin;
      default:
        return FamilyRole.member;
    }
  }

  String get displayName {
    switch (this) {
      case FamilyRole.owner:
        return 'Circle Owner';
      case FamilyRole.admin:
        return 'Admin';
      case FamilyRole.member:
        return 'Member';
    }
  }

  bool get isAdminOrOwner => this == FamilyRole.owner || this == FamilyRole.admin;
}

class FamilyMember {
  final String id;
  final String name;
  final String relationship; // e.g., 'Mother', 'Father', 'Daughter', 'Partner'
  final String city;
  final String avatarUrl;
  final CheckInStatus checkInStatus;
  final DateTime? lastCheckInTime;
  final SharingPermission sharingPermission;
  final String? lastWellnessSummary;
  final FamilyRole role;
  final String? email;
  final String? phoneNumber;
  final DateTime? joinedAt;

  const FamilyMember({
    required this.id,
    required this.name,
    required this.relationship,
    required this.city,
    required this.avatarUrl,
    required this.checkInStatus,
    this.lastCheckInTime,
    required this.sharingPermission,
    this.lastWellnessSummary,
    this.role = FamilyRole.member,
    this.email,
    this.phoneNumber,
    this.joinedAt,
  });

  FamilyMember copyWith({
    String? id,
    String? name,
    String? relationship,
    String? city,
    String? avatarUrl,
    CheckInStatus? checkInStatus,
    DateTime? lastCheckInTime,
    SharingPermission? sharingPermission,
    String? lastWellnessSummary,
    FamilyRole? role,
    String? email,
    String? phoneNumber,
    DateTime? joinedAt,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      city: city ?? this.city,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      checkInStatus: checkInStatus ?? this.checkInStatus,
      lastCheckInTime: lastCheckInTime ?? this.lastCheckInTime,
      sharingPermission: sharingPermission ?? this.sharingPermission,
      lastWellnessSummary: lastWellnessSummary ?? this.lastWellnessSummary,
      role: role ?? this.role,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'relationship': relationship,
      'city': city,
      'avatarUrl': avatarUrl,
      'role': role.name,
      if (email != null) 'email': email!.trim().toLowerCase(),
      if (phoneNumber != null) 'phoneNumber': phoneNumber!.trim(),
      'joinedAt': joinedAt != null ? Timestamp.fromDate(joinedAt!) : FieldValue.serverTimestamp(),
      'sharingPermission': sharingPermission.toMap(),
    };
  }

  factory FamilyMember.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final joinedTimestamp = data['joinedAt'] as Timestamp?;
    final pData = data['sharingPermission'] as Map<String, dynamic>?;

    return FamilyMember(
      id: doc.id,
      name: data['name'] as String? ?? 'Family Member',
      relationship: data['relationship'] as String? ?? 'Member',
      city: data['city'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String? ?? '',
      role: FamilyRole.fromString(data['role'] as String?),
      email: data['email'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      joinedAt: joinedTimestamp?.toDate(),
      checkInStatus: CheckInStatus.pendingToday,
      sharingPermission: pData != null
          ? SharingPermission.fromMap(pData)
          : SharingPermission(lastUpdated: DateTime.now()),
    );
  }
}
