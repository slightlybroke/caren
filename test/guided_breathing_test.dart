import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caren/features/wellness/presentation/guided_breathing_screen.dart';
import 'package:caren/services/speech/spoken_guidance_service.dart';

void main() {
  group('Guided Breathing & Spoken Guidance Tests', () {
    late MockSpokenGuidanceService mockSpeechService;

    setUp(() {
      mockSpeechService = MockSpokenGuidanceService();
    });

    testWidgets('Offers 2m, 5m, 15m, and Custom duration options', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            spokenGuidanceServiceProvider.overrideWithValue(mockSpeechService),
          ],
          child: const MaterialApp(
            home: GuidedBreathingScreen(initialDurationMinutes: 2),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2m'), findsOneWidget);
      expect(find.text('5m'), findsOneWidget);
      expect(find.text('15m'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);

      // Select 5m
      await tester.tap(find.text('5m'));
      await tester.pumpAndSettle();
      expect(find.text('Start Breathing Session (5m)'), findsOneWidget);

      // Select 15m
      await tester.tap(find.text('15m'));
      await tester.pumpAndSettle();
      expect(find.text('Start Breathing Session (15m)'), findsOneWidget);
    });

    testWidgets('Custom duration dialog allows setting custom minutes', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            spokenGuidanceServiceProvider.overrideWithValue(mockSpeechService),
          ],
          child: const MaterialApp(
            home: GuidedBreathingScreen(initialDurationMinutes: 2),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();

      expect(find.text('Custom Session Duration'), findsOneWidget);

      final textField = find.byType(TextField);
      await tester.enterText(textField, '7');
      await tester.tap(find.text('Set Duration'));
      await tester.pumpAndSettle();

      expect(find.text('Start Breathing Session (7m)'), findsOneWidget);
    });

    testWidgets('Custom duration rejects values less than 2 minutes with exact message', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            spokenGuidanceServiceProvider.overrideWithValue(mockSpeechService),
          ],
          child: const MaterialApp(
            home: GuidedBreathingScreen(initialDurationMinutes: 2),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      await tester.enterText(textField, '1');
      await tester.tap(find.text('Set Duration'));
      await tester.pumpAndSettle();

      expect(find.text('Your session must be at least 2 minutes long.'), findsOneWidget);
      // Dialog remains open
      expect(find.text('Custom Session Duration'), findsOneWidget);

      // Cancel dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Start Breathing Session (2m)'), findsOneWidget);
    });

    testWidgets('Custom duration rejects values greater than 60 minutes with exact message', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            spokenGuidanceServiceProvider.overrideWithValue(mockSpeechService),
          ],
          child: const MaterialApp(
            home: GuidedBreathingScreen(initialDurationMinutes: 2),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      await tester.enterText(textField, '75');
      await tester.tap(find.text('Set Duration'));
      await tester.pumpAndSettle();

      expect(find.text("60 minutes is the longest session you can choose. We've set it to the maximum."), findsOneWidget);
      // Dialog remains open
      expect(find.text('Custom Session Duration'), findsOneWidget);
    });

    testWidgets('Spoken guidance queue handles multiple utterances sequentially', (tester) async {
      mockSpeechService.speak('First instruction');
      mockSpeechService.speak('Second instruction');
      mockSpeechService.speak('Third instruction');

      expect(mockSpeechService.spokenUtterances.length, 3);
      expect(mockSpeechService.spokenUtterances[0], 'First instruction');
      expect(mockSpeechService.spokenUtterances[1], 'Second instruction');
      expect(mockSpeechService.spokenUtterances[2], 'Third instruction');

      mockSpeechService.stop();
      expect(mockSpeechService.isStopped, isTrue);
    });

    test('Speech queue interruption with clearQueue resolves all futures without hanging', () async {
      final future1 = mockSpeechService.speak('Old session phrase 1');
      final future2 = mockSpeechService.speak('Old session phrase 2');

      // Interrupt with clearQueue: true (new session)
      final future3 = mockSpeechService.speak('New session priority phrase', clearQueue: true);

      // Verify all futures resolve cleanly
      await expectLater(future1, completes);
      await expectLater(future2, completes);
      await expectLater(future3, completes);

      expect(mockSpeechService.spokenUtterances, contains('New session priority phrase'));
    });

    test('Stopping speech service resolves pending futures and clears queue', () async {
      final future = mockSpeechService.speak('In-flight instruction');
      await mockSpeechService.stop();

      await expectLater(future, completes);
      expect(mockSpeechService.isStopped, isTrue);
    });

    testWidgets('Spoken guidance triggers opening cue and phase cues during session', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            spokenGuidanceServiceProvider.overrideWithValue(mockSpeechService),
          ],
          child: const MaterialApp(
            home: GuidedBreathingScreen(initialDurationMinutes: 2),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Start session
      final startBtn = find.text('Start Breathing Session (2m)');
      await tester.ensureVisible(startBtn);
      await tester.tap(startBtn);
      await tester.pump();

      expect(mockSpeechService.spokenUtterances, contains("Let's begin. Find a comfortable position and relax your shoulders."));

      // Advance animation slightly into inhale phase
      await tester.pump(const Duration(milliseconds: 500));
      expect(mockSpeechService.spokenUtterances, contains('Breathe in slowly'));

      // Advance into exhale phase
      await tester.pump(const Duration(seconds: 5));
      expect(mockSpeechService.spokenUtterances, contains('Now breathe out slowly'));
    });

    testWidgets('Muting voice guidance prevents speech playback', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            spokenGuidanceServiceProvider.overrideWithValue(mockSpeechService),
          ],
          child: const MaterialApp(
            home: GuidedBreathingScreen(initialDurationMinutes: 2),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Toggle mute button
      final muteBtn = find.byTooltip('Mute voice guidance');
      expect(muteBtn, findsOneWidget);
      await tester.tap(muteBtn);
      await tester.pumpAndSettle();

      expect(mockSpeechService.isMuted, isTrue);

      // Start session while muted
      final startBtn = find.text('Start Breathing Session (2m)');
      await tester.ensureVisible(startBtn);
      await tester.tap(startBtn);
      await tester.pump();

      // Utterance list should remain empty while muted
      expect(mockSpeechService.spokenUtterances, isEmpty);
    });

    testWidgets('Disposing GuidedBreathingScreen stops spoken guidance immediately', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            spokenGuidanceServiceProvider.overrideWithValue(mockSpeechService),
          ],
          child: const MaterialApp(
            home: GuidedBreathingScreen(initialDurationMinutes: 2),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final startBtn = find.text('Start Breathing Session (2m)');
      await tester.ensureVisible(startBtn);
      await tester.tap(startBtn);
      await tester.pump();

      // Replace screen to trigger dispose
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            spokenGuidanceServiceProvider.overrideWithValue(mockSpeechService),
          ],
          child: const MaterialApp(
            home: SizedBox(),
          ),
        ),
      );

      expect(mockSpeechService.isStopped, isTrue);
    });
  });
}
