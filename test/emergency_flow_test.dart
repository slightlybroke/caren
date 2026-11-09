import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caren/features/emergency/presentation/emergency_landing_screen.dart';
import 'package:caren/features/emergency/presentation/emergency_session_screen.dart';
import 'package:caren/services/emergency/emergency_dialer_service.dart';
import 'package:caren/features/assist/data/assist_repository.dart';
import 'package:caren/features/profile/data/profile_repository.dart';
import 'package:caren/features/profile/domain/user_profile.dart';

void main() {
  group('Emergency Flow & Responsive UI Tests', () {
    late MockEmergencyDialerService mockDialer;
    late LocalAssistRepository assistRepo;

    setUp(() {
      mockDialer = MockEmergencyDialerService();
      assistRepo = LocalAssistRepository();
    });

    testWidgets('Emergency landing displays localized number (112) and opens dialer on confirm', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            emergencyDialerServiceProvider.overrideWithValue(mockDialer),
            userProfileProvider.overrideWith((ref) async => UserProfile.empty(id: 'u1', email: 'test@example.com')),
          ],
          child: const MaterialApp(
            home: EmergencyLandingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Call Emergency Services (112)'), findsOneWidget);

      // Tap call emergency
      await tester.tap(find.text('Call Emergency Services (112)'));
      await tester.pumpAndSettle();

      expect(find.text('Call Emergency (112)?'), findsOneWidget);
      expect(find.text('Open Dialer (112)'), findsOneWidget);

      // Confirm call
      await tester.tap(find.text('Open Dialer (112)'));
      await tester.pumpAndSettle();

      expect(mockDialer.launchedNumbers, contains('112'));
    });

    testWidgets('Emergency session renders on narrow screen (320px) with NO RenderFlex overflow', (tester) async {
      // Set narrow viewport to verify fix for "RenderFlex overflowed by 47px"
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            emergencyDialerServiceProvider.overrideWithValue(mockDialer),
            assistRepositoryProvider.overrideWithValue(assistRepo),
            userProfileProvider.overrideWith((ref) async => UserProfile.empty(id: 'u1', email: 'test@example.com')),
          ],
          child: const MaterialApp(
            home: EmergencySessionScreen(sessionId: 'ast_test'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No exception or overflow
      expect(tester.takeException(), isNull);
      expect(find.text('Call Emergency (112)'), findsOneWidget);
      expect(find.text('Quick Observation Logging'), findsOneWidget);
    });

    testWidgets('Emergency session logs quick observations into timeline', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            emergencyDialerServiceProvider.overrideWithValue(mockDialer),
            assistRepositoryProvider.overrideWithValue(assistRepo),
            userProfileProvider.overrideWith((ref) async => UserProfile.empty(id: 'u1', email: 'test@example.com')),
          ],
          child: const MaterialApp(
            home: EmergencySessionScreen(sessionId: 'ast_test'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Responsive & Alert'
      await tester.tap(find.text('Responsive & Alert'));
      await tester.pumpAndSettle();

      expect(find.text('Person is alert, oriented, and answering questions.'), findsOneWidget);

      // Tap 'Offered Water'
      await tester.tap(find.text('Offered Water'));
      await tester.pumpAndSettle();

      expect(find.text('Offered a small sip of water while seated.'), findsOneWidget);
    });

    testWidgets('Emergency handoff summary opens and shows timeline and copy option', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            emergencyDialerServiceProvider.overrideWithValue(mockDialer),
            assistRepositoryProvider.overrideWithValue(assistRepo),
            userProfileProvider.overrideWith((ref) async => UserProfile.empty(id: 'u1', email: 'test@example.com')),
          ],
          child: const MaterialApp(
            home: EmergencySessionScreen(sessionId: 'ast_test'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Summary / Handoff'));
      await tester.pumpAndSettle();

      expect(find.text('Incident Handoff Summary'), findsOneWidget);
      expect(find.text('Copy Notes'), findsOneWidget);
      expect(find.text('Conclude and Archive Session'), findsOneWidget);
    });
  });
}

