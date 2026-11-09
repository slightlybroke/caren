import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caren/features/wellness/presentation/camera_positioning_screen.dart';
import 'package:caren/services/vitals/vitals_provider.dart';
import 'package:caren/services/vitals/mock_vitals_provider.dart';
import 'package:caren/services/vitals/session_repository.dart';
import 'package:caren/services/vitals/vitals_models.dart';

void main() {
  group('Camera Positioning & Preflight Screen Tests', () {
    late MockVitalsProvider mockVitals;
    late LocalMeasurementSessionRepository sessionRepo;

    setUp(() {
      sessionRepo = LocalMeasurementSessionRepository();
      mockVitals = MockVitalsProvider(
        updateInterval: const Duration(milliseconds: 10),
        sessionRepository: sessionRepo,
      );
    });

    tearDown(() async {
      await mockVitals.dispose();
    });

    testWidgets('Stage A: Preparation screen displays guidance and non-diagnostic disclaimer', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vitalsProvider.overrideWithValue(mockVitals),
          ],
          child: const MaterialApp(
            home: CameraPositioningScreen(
              target: MeasurementTarget.pulseOnly,
              title: 'Camera Wellness Check',
              subtitle: 'Check in with yourself before continuing',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Camera Wellness Check'), findsOneWidget);
      expect(find.text('Check in with yourself before continuing'), findsOneWidget);

      // Preparation steps
      expect(find.text('Measurement Guidelines'), findsOneWidget);
      expect(find.text('Even Lighting'), findsOneWidget);
      expect(find.text('Position Face in Center'), findsOneWidget);
      expect(find.text('Stay Still & Breathe Naturally'), findsOneWidget);

      // Disclaimer
      expect(find.textContaining('Notice: Camera observations are for personal wellness tracking only.'), findsOneWidget);

      // Action button
      expect(find.text('Continue to Camera Positioning'), findsOneWidget);
    });

    testWidgets('Stage B: Tapping Continue transitions to positioning stage without starting countdown', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vitalsProvider.overrideWithValue(mockVitals),
          ],
          child: const MaterialApp(
            home: CameraPositioningScreen(
              target: MeasurementTarget.pulseOnly,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Continue to Camera Positioning
      final continueBtn = find.text('Continue to Camera Positioning');
      await tester.ensureVisible(continueBtn);
      await tester.tap(continueBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Should be in positioning phase showing oval guide instructions
      expect(find.byType(CameraPositioningScreen), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Condition badges driven by SDK validation
      expect(find.text('Face Centered'), findsOneWidget);
      expect(find.text('Good Light'), findsOneWidget);
      expect(find.text('Holding Still'), findsOneWidget);

      // When positioning, button indicates positioning status or ready status
      final hasReadyOrWaiting = find.text('Start Pulse Rate Check').evaluate().isNotEmpty ||
          find.text('Waiting for Positioning...').evaluate().isNotEmpty;
      expect(hasReadyOrWaiting, isTrue);

      // Clean up active session
      await mockVitals.cancelMeasurement();
    });

    testWidgets('Cancellation triggers provider cancel and releases session cleanly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vitalsProvider.overrideWithValue(mockVitals),
          ],
          child: const MaterialApp(
            home: CameraPositioningScreen(
              target: MeasurementTarget.pulseOnly,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter positioning
      final continueBtn = find.text('Continue to Camera Positioning');
      await tester.ensureVisible(continueBtn);
      await tester.tap(continueBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Active session exists in provider
      expect(mockVitals.activeSession, isNotNull);

      // Tap Cancel button
      final cancelBtn = find.text('Cancel');
      expect(cancelBtn, findsOneWidget);
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      // Session should be cancelled
      expect(mockVitals.activeSession?.status, equals(MeasurementSessionStatus.cancelled));
      expect(mockVitals.activeSession?.userCancelled, isTrue);
    });

    test('SdkValidationSemantics strictly evaluates Pass, Fail, and Pending without negative heuristics', () {
      // 1. OK code with face detected -> all Pass, ready
      expect(SdkValidationSemantics.evaluateFaceCentered('OK', true), equals(ValidationIndicatorStatus.pass));
      expect(SdkValidationSemantics.evaluateGoodLight('OK'), equals(ValidationIndicatorStatus.pass));
      expect(SdkValidationSemantics.evaluateHoldingStill('OK'), equals(ValidationIndicatorStatus.pass));
      expect(SdkValidationSemantics.isMeasurementReady(code: 'OK', isFaceDetected: true, errorCode: null, processingStatus: 'RUNNING'), isTrue);

      // 2. TOO_DARK -> Good Light fails; Face & Motion are Pending (cannot assess in darkness)
      expect(SdkValidationSemantics.evaluateGoodLight('TOO_DARK'), equals(ValidationIndicatorStatus.fail));
      expect(SdkValidationSemantics.evaluateFaceCentered('TOO_DARK', true), equals(ValidationIndicatorStatus.pending));
      expect(SdkValidationSemantics.evaluateHoldingStill('TOO_DARK'), equals(ValidationIndicatorStatus.pending));
      expect(SdkValidationSemantics.isMeasurementReady(code: 'TOO_DARK', isFaceDetected: true, errorCode: null, processingStatus: 'RUNNING'), isFalse);

      // 3. TOO_BRIGHT -> Good Light fails; others Pending
      expect(SdkValidationSemantics.evaluateGoodLight('TOO_BRIGHT'), equals(ValidationIndicatorStatus.fail));
      expect(SdkValidationSemantics.isMeasurementReady(code: 'TOO_BRIGHT', isFaceDetected: true, errorCode: null, processingStatus: 'RUNNING'), isFalse);

      // 4. EXCESSIVE_MOTION -> Holding Still fails; others Pending
      expect(SdkValidationSemantics.evaluateHoldingStill('EXCESSIVE_MOTION'), equals(ValidationIndicatorStatus.fail));
      expect(SdkValidationSemantics.evaluateFaceCentered('EXCESSIVE_MOTION', true), equals(ValidationIndicatorStatus.pending));
      expect(SdkValidationSemantics.isMeasurementReady(code: 'EXCESSIVE_MOTION', isFaceDetected: true, errorCode: null, processingStatus: 'RUNNING'), isFalse);

      // 5. Positioning failures -> Face Centered fails; others Pending
      expect(SdkValidationSemantics.evaluateFaceCentered('FACE_NOT_CENTERED', true), equals(ValidationIndicatorStatus.fail));
      expect(SdkValidationSemantics.evaluateFaceCentered('FACE_TOO_FAR', true), equals(ValidationIndicatorStatus.fail));
      expect(SdkValidationSemantics.evaluateFaceCentered('NO_FACE_FOUND', false), equals(ValidationIndicatorStatus.fail));
      expect(SdkValidationSemantics.evaluateGoodLight('NO_FACE_FOUND'), equals(ValidationIndicatorStatus.pending));
      expect(SdkValidationSemantics.isMeasurementReady(code: 'FACE_NOT_CENTERED', isFaceDetected: true, errorCode: null, processingStatus: 'RUNNING'), isFalse);

      // 6. CAMERA_TUNING / null / low fps -> all Pending; NEVER green pass
      expect(SdkValidationSemantics.evaluateFaceCentered('CAMERA_TUNING', false), equals(ValidationIndicatorStatus.pending));
      expect(SdkValidationSemantics.evaluateGoodLight('CAMERA_TUNING'), equals(ValidationIndicatorStatus.pending));
      expect(SdkValidationSemantics.evaluateHoldingStill('CAMERA_TUNING'), equals(ValidationIndicatorStatus.pending));
      expect(SdkValidationSemantics.evaluateFaceCentered(null, false), equals(ValidationIndicatorStatus.pending));
      expect(SdkValidationSemantics.isMeasurementReady(code: 'CAMERA_TUNING', isFaceDetected: false, errorCode: null, processingStatus: 'RUNNING'), isFalse);
      expect(SdkValidationSemantics.isMeasurementReady(code: null, isFaceDetected: false, errorCode: null, processingStatus: 'RUNNING'), isFalse);
    });

    testWidgets('Rapid cancel and restart lifecycle is clean and idempotent without session collisions', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vitalsProvider.overrideWithValue(mockVitals),
          ],
          child: const MaterialApp(
            home: CameraPositioningScreen(
              target: MeasurementTarget.pulseOnly,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Start positioning
      final continueBtn = find.text('Continue to Camera Positioning');
      await tester.ensureVisible(continueBtn);
      await tester.tap(continueBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final firstSessionId = mockVitals.activeSession?.id;
      expect(firstSessionId, isNotNull);

      // 2. Rapid Cancel
      final cancelBtn = find.text('Cancel');
      await tester.tap(cancelBtn);
      await tester.pump();

      // 3. Restart immediately
      await mockVitals.cancelMeasurement();
      final stream = mockVitals.startMeasurement();
      expect(stream, isNotNull);
      expect(mockVitals.activeSession?.status, equals(MeasurementSessionStatus.active));
      expect(mockVitals.activeSession?.id, isNot(equals(firstSessionId)));

      await mockVitals.cancelMeasurement();
    });
  });
}
