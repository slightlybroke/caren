import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caren/app/router/app_router.dart';
import 'package:caren/features/authentication/data/auth_repository.dart';
import 'package:caren/features/authentication/domain/auth_user.dart';
import 'package:caren/features/dashboard/presentation/main_scaffold_screen.dart';

class FakeAuthRepository implements AuthRepository {
  AuthUser? _user;

  FakeAuthRepository([this._user]);

  @override
  Stream<AuthUser?> get authStateChanges => Stream.value(_user);

  @override
  AuthUser? get currentUser => _user;

  @override
  Future<AuthUser> signInWithEmailAndPassword(String email, String password) async {
    _user = AuthUser(uid: 'u1', email: email, displayName: 'Test User');
    return _user!;
  }

  @override
  Future<AuthUser> registerWithEmailAndPassword(String email, String password, {String? displayName}) async {
    _user = AuthUser(uid: 'u1', email: email, displayName: displayName);
    return _user!;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> signOut() async {
    _user = null;
  }

  @override
  Future<void> deleteAccount() async {
    _user = null;
  }
}

void main() {
  group('Primary Navigation & Stateful Shell Tests', () {
    testWidgets('MainScaffoldScreen displays Family, Me, and Emergency destinations', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: appRouter,
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Navigate to /family
      appRouter.go('/family');
      await tester.pumpAndSettle();

      expect(find.byType(MainScaffoldScreen), findsOneWidget);
      expect(find.text('Family'), findsWidgets);
      expect(find.text('Me'), findsOneWidget);
      expect(find.text('Emergency'), findsOneWidget);
      // 'Assist' tab label must no longer exist
      expect(find.widgetWithText(NavigationDestination, 'Assist'), findsNothing);
    });

    testWidgets('Tab switching between Family, Me, and Emergency functions smoothly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: appRouter,
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      appRouter.go('/family');
      await tester.pumpAndSettle();
      expect(find.text('Family Circle'), findsOneWidget);

      // Tap Me
      await tester.tap(find.text('Me'));
      await tester.pumpAndSettle();
      expect(find.text('Guided Breathing'), findsOneWidget);

      // Tap Emergency
      await tester.tap(find.text('Emergency'));
      await tester.pumpAndSettle();
      expect(find.text('Immediate Assistance Needed?'), findsOneWidget);
    });

    testWidgets('Redirect /dashboard -> /family and /assist -> /emergency', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: appRouter,
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      appRouter.go('/dashboard');
      await tester.pumpAndSettle();
      expect(find.text('Family Circle'), findsOneWidget);

      appRouter.go('/assist');
      await tester.pumpAndSettle();
      expect(find.text('Immediate Assistance Needed?'), findsOneWidget);
    });
  });
}
