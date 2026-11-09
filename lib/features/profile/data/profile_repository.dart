import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/firebase/firebase_service.dart';
import '../../authentication/data/auth_repository.dart';
import '../domain/user_profile.dart';
import '../domain/privacy_settings.dart';
import 'firestore_profile_repository.dart';

abstract class ProfileRepository {
  Future<UserProfile> getUserProfile();
  Stream<UserProfile> watchUserProfile();
  Future<PrivacySettings> getPrivacySettings();
  Future<void> updateProfile(UserProfile profile);
  Future<void> saveProfile(UserProfile profile);
  Future<void> updatePrivacySettings(PrivacySettings settings);
}

class LocalProfileRepository implements ProfileRepository {
  UserProfile _profile;
  PrivacySettings _privacy;
  final _profileController = StreamController<UserProfile>.broadcast();

  LocalProfileRepository({UserProfile? initialProfile, PrivacySettings? initialPrivacy})
      : _profile = initialProfile ??
            UserProfile.empty(
              id: 'local_user',
              email: 'user@example.com',
              displayName: 'User',
            ),
        _privacy = initialPrivacy ?? PrivacySettings.defaultSettings();

  @override
  Future<UserProfile> getUserProfile() async {
    return _profile;
  }

  @override
  Stream<UserProfile> watchUserProfile() {
    return _profileController.stream;
  }

  @override
  Future<PrivacySettings> getPrivacySettings() async {
    return _privacy;
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    _profile = profile;
    _profileController.add(_profile);
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    await updateProfile(profile);
  }

  @override
  Future<void> updatePrivacySettings(PrivacySettings settings) async {
    _privacy = settings;
  }

  void dispose() {
    _profileController.close();
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final fbState = ref.watch(firebaseStateProvider);
  final currentUser = ref.watch(currentUserProvider);

  if (fbState.isInitialized && currentUser != null) {
    return FirestoreProfileRepository(userId: currentUser.uid);
  }

  return LocalProfileRepository(
    initialProfile: currentUser != null
        ? UserProfile.empty(
            id: currentUser.uid,
            email: currentUser.email,
            displayName: currentUser.displayName,
          )
        : null,
  );
});

final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getUserProfile();
});

class PrivacySettingsNotifier extends AsyncNotifier<PrivacySettings> {
  @override
  Future<PrivacySettings> build() async {
    final repo = ref.watch(profileRepositoryProvider);
    return repo.getPrivacySettings();
  }

  Future<void> updateSettings(PrivacySettings settings) async {
    final repo = ref.read(profileRepositoryProvider);
    await repo.updatePrivacySettings(settings);
    state = AsyncData(settings);
  }
}

final privacySettingsProvider =
    AsyncNotifierProvider<PrivacySettingsNotifier, PrivacySettings>(() => PrivacySettingsNotifier());
