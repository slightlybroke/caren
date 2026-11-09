import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caren/features/wellness/domain/wellness_activity.dart';
import 'package:caren/features/wellness/presentation/guided_activity_screen.dart';
import 'package:caren/features/wellness/presentation/me_dashboard_screen.dart';
import 'package:caren/services/speech/spoken_guidance_service.dart';
import 'package:caren/features/wellness/data/wellness_repository.dart';

void main() {
  group('Wellness Catalog & Relaxation Activities Tests', () {
    test('Catalog contains 5 distinct activities covering all categories', () {
      final all = WellnessCatalog.allActivities;
      expect(all.length, 5);

      final categories = all.map((a) => a.category).toSet();
      expect(categories, contains(WellnessCategory.mindfulness));
      expect(categories, contains(WellnessCategory.bodyRelaxation));
      expect(categories, contains(WellnessCategory.quietMoments));

      final fiveSenses = WellnessCatalog.findById('mindfulness_5_senses');
      expect(fiveSenses, isNotNull);
      expect(fiveSenses!.steps.length, greaterThanOrEqualTo(5));

      final pmr = WellnessCatalog.findById('body_pmr');
      expect(pmr, isNotNull);
      expect(pmr!.steps.length, greaterThanOrEqualTo(4));

      final quiet = WellnessCatalog.findById('quiet_timed_moment');
      expect(quiet, isNotNull);
      expect(quiet!.steps.isNotEmpty, isTrue);
    });

    testWidgets('MeDashboard renders all 4 wellness categories and Camera Check card', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            wellnessRepositoryProvider.overrideWithValue(LocalWellnessRepository()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MeDashboardScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check for category titles
      expect(find.text('Guided Breathing'), findsOneWidget);
      expect(find.text('Mindfulness & Grounding'), findsOneWidget);
      expect(find.text('Body Relaxation'), findsOneWidget);
      expect(find.text('Quiet Moments'), findsOneWidget);

      // Check for Camera Wellness Check card
      expect(find.text('Camera Wellness Check'), findsOneWidget);
      expect(find.text('Open Camera Wellness Check'), findsOneWidget);
    });

    testWidgets('GuidedActivityScreen runs through steps and speaks step guidance without requiring camera', (tester) async {
      final mockSpeech = MockSpokenGuidanceService();
      final mockRepo = LocalWellnessRepository();

      const testActivity = WellnessActivity(
        id: 'test_activity',
        title: 'Test Relaxation',
        subtitle: 'A simple test relaxation',
        category: WellnessCategory.mindfulness,
        defaultDurationMinutes: 1,
        description: 'Testing the relaxation screen workflow.',
        icon: Icons.spa,
        steps: [
          WellnessActivityStep(
            title: 'Step 1: Relax',
            instruction: 'Sit comfortably and close your eyes.',
            spokenCue: 'Sit comfortably and close your eyes.',
            durationSeconds: 2,
          ),
          WellnessActivityStep(
            title: 'Step 2: Breathe',
            instruction: 'Feel the breath entering your lungs.',
            spokenCue: 'Feel the breath entering your lungs.',
            durationSeconds: 2,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            spokenGuidanceServiceProvider.overrideWithValue(mockSpeech),
            wellnessRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: GuidedActivityScreen(activity: testActivity),
          ),
        ),
      );
      await tester.pump();

      // Opening instruction should be queued
      expect(mockSpeech.spokenUtterances, contains('Sit comfortably and close your eyes.'));

      // Check that step title is displayed
      expect(find.text('Step 1: Relax'), findsOneWidget);

      // Pause activity
      final pauseBtn = find.byTooltip('Pause');
      await tester.tap(pauseBtn);
      await tester.pump();
      expect(find.byTooltip('Resume'), findsOneWidget);

      // Resume activity
      await tester.tap(find.byTooltip('Resume'));
      await tester.pump();
      expect(find.byTooltip('Pause'), findsOneWidget);

      // Step transition forward
      final nextBtn = find.text('Next Step');
      await tester.tap(nextBtn);
      await tester.pump();

      expect(find.text('Step 2: Breathe'), findsOneWidget);
      expect(mockSpeech.spokenUtterances, contains('Feel the breath entering your lungs.'));

      // Complete activity by tapping Complete
      final completeBtn = find.text('Complete');
      await tester.tap(completeBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Session Complete'), findsOneWidget);
      expect(find.text('Back to Wellness'), findsOneWidget);

      // Verify session was recorded in repository by pumping fake async clock
      final historyFuture = mockRepo.getRecentSessions();
      await tester.pump(const Duration(milliseconds: 200));
      final history = await historyFuture;
      expect(history.first.customTitle, 'Test Relaxation');

      // Unmount screen to stop animation controller and ticker cleanly
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            spokenGuidanceServiceProvider.overrideWithValue(mockSpeech),
            wellnessRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: SizedBox(),
          ),
        ),
      );
    });
  });
}
