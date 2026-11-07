import 'sharing_permission.dart';

enum CheckInStatus {
  completedToday,
  pendingToday,
  missedYesterday,
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
    );
  }
}

