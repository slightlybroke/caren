import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:caren/features/authentication/data/auth_repository.dart';
import 'package:caren/features/authentication/domain/auth_user.dart';
import 'package:caren/features/authentication/domain/auth_failure.dart';
import 'package:caren/features/authentication/presentation/controllers/auth_controller.dart';

void main() {
  group('AuthRepository and Authentication Flow', () {
    late MockAuthRepository mockAuth;

    setUp(() {
      mockAuth = MockAuthRepository();
    });

    tearDown(() {
      mockAuth.dispose();
    });

    test('Initial auth state is unauthenticated (null)', () {
      expect(mockAuth.currentUser, isNull);
    });

    test('registerWithEmailAndPassword registers and sets current user', () async {
      final user = await mockAuth.registerWithEmailAndPassword(
        'sarah.connor@example.com',
        'SecurePassword123!',
        displayName: 'Sarah Connor',
      );

      expect(user.email, 'sarah.connor@example.com');
      expect(user.displayName, 'Sarah Connor');
      expect(mockAuth.currentUser, equals(user));
    });

    test('signInWithEmailAndPassword successfully signs in registered user', () async {
      await mockAuth.registerWithEmailAndPassword(
        'john.doe@example.com',
        'Password123!',
        displayName: 'John Doe',
      );
      await mockAuth.signOut();
      expect(mockAuth.currentUser, isNull);

      final user = await mockAuth.signInWithEmailAndPassword(
        'john.doe@example.com',
        'Password123!',
      );

      expect(user.email, 'john.doe@example.com');
      expect(mockAuth.currentUser, isNotNull);
    });

    test('signInWithEmailAndPassword throws AuthFailure on invalid password', () async {
      await mockAuth.registerWithEmailAndPassword(
        'test@example.com',
        'CorrectPassword',
      );
      await mockAuth.signOut();

      expect(
        () => mockAuth.signInWithEmailAndPassword(
          'test@example.com',
          'WrongPassword',
        ),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('signOut clears current user and emits null', () async {
      await mockAuth.registerWithEmailAndPassword(
        'user@example.com',
        'Password123',
      );
      expect(mockAuth.currentUser, isNotNull);

      await mockAuth.signOut();
      expect(mockAuth.currentUser, isNull);
    });

    test('deleteAccount clears current user and emits null', () async {
      await mockAuth.registerWithEmailAndPassword(
        'delete_me@example.com',
        'Password123',
      );
      expect(mockAuth.currentUser, isNotNull);

      await mockAuth.deleteAccount();
      expect(mockAuth.currentUser, isNull);
    });

    test('authStateChanges stream emits user on login and null on logout', () async {
      final emitted = <AuthUser?>[];
      final sub = mockAuth.authStateChanges.listen((u) => emitted.add(u));

      await mockAuth.registerWithEmailAndPassword(
        'stream@example.com',
        'Password123',
        displayName: 'Stream User',
      );
      await mockAuth.signOut();

      await Future.delayed(const Duration(milliseconds: 100));
      await sub.cancel();

      expect(emitted.length, 2);
      expect(emitted[0]?.email, 'stream@example.com');
      expect(emitted[1], isNull);
    });
  });

  group('AuthNotifier and Riverpod Integration', () {
    test('AuthNotifier register creates profile and updates state', () async {
      final mockAuth = MockAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuth),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);
      final user = await notifier.register(
        email: 'riverpod@example.com',
        password: 'PassWord123',
        displayName: 'Riverpod User',
        country: 'United States',
        city: 'New York',
      );

      expect(user.email, 'riverpod@example.com');
      expect(container.read(authNotifierProvider).asData?.value?.email, 'riverpod@example.com');
      expect(mockAuth.currentUser?.email, 'riverpod@example.com');
    });
  });
}
