import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/data/profile_repository.dart';
import '../../../profile/domain/user_profile.dart';
import '../../data/auth_repository.dart';
import '../../domain/auth_user.dart';

/// Notifier managing auth actions and their loading/error states.
class AuthNotifier extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async {
    // Initial state is current user
    return ref.watch(currentUserProvider);
  }

  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.signInWithEmailAndPassword(email, password);
      state = AsyncValue.data(user);
      return user;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<AuthUser> register({
    required String email,
    required String password,
    String? displayName,
    String? country,
    String? city,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.registerWithEmailAndPassword(
        email,
        password,
        displayName: displayName,
      );

      // Create initial profile for the new user
      final profileRepo = ref.read(profileRepositoryProvider);
      final newProfile = UserProfile(
        id: user.uid,
        email: user.email,
        fullName: displayName ?? (user.email.split('@').first),
        country: country ?? 'United States',
        city: city ?? '',
        emergencyNumber: country == 'India'
            ? '112'
            : country == 'United Kingdom'
                ? '999'
                : '911',
        onboardingCompleted: true,
      );
      await profileRepo.saveProfile(newProfile);

      state = AsyncValue.data(user);
      return user;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.sendPasswordResetEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signOut();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.deleteAccount();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthUser?>(() => AuthNotifier());
