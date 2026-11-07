class UserProfile {
  final String id;
  final String fullName;
  final String email;
  final String city;
  final String preferredTimeForCheckIn; // e.g. "09:00 AM"
  final bool enableGentleReminders;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.city,
    this.preferredTimeForCheckIn = '09:00 AM',
    this.enableGentleReminders = true,
  });

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? email,
    String? city,
    String? preferredTimeForCheckIn,
    bool? enableGentleReminders,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      city: city ?? this.city,
      preferredTimeForCheckIn: preferredTimeForCheckIn ?? this.preferredTimeForCheckIn,
      enableGentleReminders: enableGentleReminders ?? this.enableGentleReminders,
    );
  }
}

