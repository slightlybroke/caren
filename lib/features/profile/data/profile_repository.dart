import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user_profile.dart';
import '../domain/privacy_settings.dart';

abstract class ProfileRepository {
  Future<UserProfile> getUserProfile();
  Future<PrivacySettings> getPrivacySettings();
  Future<void> updateProfile(UserProfile profile);
  Future<void> updatePrivacySettings(PrivacySettings settings);
}

class LocalProfileRepository implements ProfileRepository {
  UserProfile _profile = const UserProfile(
    id: 'user_self',
    fullName: 'Julian Vance',
    email: 'julian.vance@example.com',
    city: 'Seattle, WA',
    preferredTimeForCheckIn: '09:00 AM',
    enableGentleReminders: true,
  );

  PrivacySettings _privacy = PrivacySettings(
    shareCheckInStatusWithFamily: true,
    shareSelfReportedWellness: true,
    shareCameraMeasurementsWithFamily: false, // Explicit privacy
    storeMeasurementsLocallyOnly: true,
    enableSmartSpectraSimulatedMock: true,
    lastUpdated: DateTime.now().subtract(const Duration(days: 3)),
  );

  @override
  Future<UserProfile> getUserProfile() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _profile;
  }

  @override
  Future<PrivacySettings> getPrivacySettings() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _privacy;
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _profile = profile;
  }

  @override
  Future<void> updatePrivacySettings(PrivacySettings settings) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _privacy = settings;
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return LocalProfileRepository();
});

final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getUserProfile();
});

final privacySettingsProvider = FutureProvider<PrivacySettings>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getPrivacySettings();
});

