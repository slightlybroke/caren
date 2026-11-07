/// Directory of localized emergency numbers with fallback.
class EmergencyDirectory {
  EmergencyDirectory._();

  static const String fallbackNumber = '112';

  static const Map<String, String> countryNumbers = {
    'India': '112',
    'United States': '911',
    'United Kingdom': '999',
    'European Union': '112',
    'Australia': '000',
    'Canada': '911',
    'New Zealand': '111',
    'Japan': '119',
    'Singapore': '995',
  };

  static String getNumber(String? country) {
    if (country == null) return fallbackNumber;
    return countryNumbers[country] ?? fallbackNumber;
  }
}

class UserProfile {
  final String id;
  final String fullName;
  final String email;
  final String city;
  final String country;
  final String emergencyNumber;
  final String preferredTimeForCheckIn; // e.g. "09:00 AM"
  final bool enableGentleReminders;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.city,
    this.country = 'India',
    this.emergencyNumber = '112',
    this.preferredTimeForCheckIn = '09:00 AM',
    this.enableGentleReminders = true,
  });

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? email,
    String? city,
    String? country,
    String? emergencyNumber,
    String? preferredTimeForCheckIn,
    bool? enableGentleReminders,
  }) {
    final newCountry = country ?? this.country;
    final newEmergency = emergencyNumber ?? (country != null ? EmergencyDirectory.getNumber(country) : this.emergencyNumber);

    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      city: city ?? this.city,
      country: newCountry,
      emergencyNumber: newEmergency,
      preferredTimeForCheckIn: preferredTimeForCheckIn ?? this.preferredTimeForCheckIn,
      enableGentleReminders: enableGentleReminders ?? this.enableGentleReminders,
    );
  }
}
