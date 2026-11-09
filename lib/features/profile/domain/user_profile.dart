import 'package:cloud_firestore/cloud_firestore.dart';

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
  final bool onboardingCompleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.city,
    this.country = 'India',
    this.emergencyNumber = '112',
    this.preferredTimeForCheckIn = '09:00 AM',
    this.enableGentleReminders = true,
    this.onboardingCompleted = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Convenient alias for fullName matching Firebase / Auth displayName
  String get displayName => fullName;

  /// Creates a default new user profile
  factory UserProfile.empty({required String id, required String email, String? displayName}) {
    final name = displayName != null && displayName.isNotEmpty
        ? displayName
        : (email.isNotEmpty ? email.split('@').first : 'User');
    return UserProfile(
      id: id,
      fullName: name,
      email: email,
      city: '',
      country: 'India',
      emergencyNumber: '112',
      preferredTimeForCheckIn: '09:00 AM',
      enableGentleReminders: true,
      onboardingCompleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? displayName,
    String? email,
    String? city,
    String? country,
    String? emergencyNumber,
    String? preferredTimeForCheckIn,
    bool? enableGentleReminders,
    bool? onboardingCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final newCountry = country ?? this.country;
    final newEmergency = emergencyNumber ??
        (country != null ? EmergencyDirectory.getNumber(country) : this.emergencyNumber);

    return UserProfile(
      id: id ?? this.id,
      fullName: displayName ?? fullName ?? this.fullName,
      email: email ?? this.email,
      city: city ?? this.city,
      country: newCountry,
      emergencyNumber: newEmergency,
      preferredTimeForCheckIn: preferredTimeForCheckIn ?? this.preferredTimeForCheckIn,
      enableGentleReminders: enableGentleReminders ?? this.enableGentleReminders,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': fullName,
      'fullName': fullName,
      'email': email,
      'city': city,
      'country': country,
      'emergencyNumber': emergencyNumber,
      'preferredTimeForCheckIn': preferredTimeForCheckIn,
      'enableGentleReminders': enableGentleReminders,
      'onboardingCompleted': onboardingCompleted,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': fullName,
      'email': email,
      'city': city,
      'country': country,
      'emergencyNumber': emergencyNumber,
      'preferredTimeForCheckIn': preferredTimeForCheckIn,
      'enableGentleReminders': enableGentleReminders,
      'onboardingCompleted': onboardingCompleted,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, {String? id}) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final country = map['country'] as String? ?? 'United States';
    final emergency = map['emergencyNumber'] as String? ?? EmergencyDirectory.getNumber(country);

    return UserProfile(
      id: id ?? map['id'] as String? ?? '',
      fullName: map['displayName'] as String? ?? map['fullName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      city: map['city'] as String? ?? '',
      country: country,
      emergencyNumber: emergency,
      preferredTimeForCheckIn: map['preferredTimeForCheckIn'] as String? ?? '09:00 AM',
      enableGentleReminders: map['enableGentleReminders'] as bool? ?? true,
      onboardingCompleted: map['onboardingCompleted'] as bool? ?? true,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  factory UserProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserProfile.fromMap(data, id: doc.id);
  }
}
