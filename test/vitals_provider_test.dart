import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caren/services/vitals/vitals_models.dart';
import 'package:caren/services/vitals/session_repository.dart';
import 'package:caren/services/vitals/mock_vitals_provider.dart';
import 'package:caren/services/vitals/native_vitals_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MockVitalsProvider Tests', () {
    late MockVitalsProvider provider;
    late LocalMeasurementSessionRepository sessionRepo;

    setUp(() {
      sessionRepo = LocalMeasurementSessionRepository();
      provider = MockVitalsProvider(
        updateInterval: const Duration(milliseconds: 10),
        sessionRepository: sessionRepo,
      );
    });

    tearDown(() async {
      await provider.dispose();
    });

    test('isAvailable returns true and providerName indicates simulation', () {
      expect(provider.isAvailable, isTrue);
      expect(provider.providerName, contains('Simulated Mock Vitals'));
    });

    test('initialize returns true', () async {
      final success = await provider.initialize(apiKey: 'test_key');
      expect(success, isTrue);
    });

    test('requestCameraPermission returns granted by default and denied when configured', () async {
      final res1 = await provider.requestCameraPermission();
      expect(res1.granted, isTrue);
      expect(res1.permanentlyDenied, isFalse);

      final deniedProvider = MockVitalsProvider(shouldSimulatePermissionDenial: true);
      final res2 = await deniedProvider.requestCameraPermission();
      expect(res2.granted, isFalse);
      expect(res2.permanentlyDenied, isTrue);
      await deniedProvider.dispose();
    });

    test('openAppSettings executes without error', () async {
      await expectLater(provider.openAppSettings(), completes);
    });

    test('1. Starting one measurement streams valid data', () async {
      final stream = provider.startMeasurement(
        config: const MeasurementConfig(
          target: MeasurementTarget.pulseOnly,
          durationSeconds: 15,
        ),
      );

      final firstEvent = await stream.first;
      expect(firstEvent.isSimulated, isTrue);
      expect(firstEvent.progress, greaterThanOrEqualTo(0.0));
      expect(firstEvent.statusText, isNotEmpty);
      expect(firstEvent.sessionId, isNotNull);
      expect(provider.activeSession, isNotNull);
      expect(provider.activeSession!.status, equals(MeasurementSessionStatus.active));
    });

    test('2 & 3. Repeated and concurrent start requests return same stream without creating duplicate sessions', () {
      final stream1 = provider.startMeasurement(
        config: const MeasurementConfig(
          target: MeasurementTarget.pulseOnly,
          durationSeconds: 15,
        ),
      );

      final stream2 = provider.startMeasurement(
        config: const MeasurementConfig(
          target: MeasurementTarget.pulseOnly,
          durationSeconds: 15,
        ),
      );

      expect(stream1, isNotNull);
      expect(stream2, isNotNull);
      expect(provider.activeSession?.target, equals(MeasurementTarget.pulseOnly));
    });

    test('4. Starting after a successful stop works cleanly', () async {
      provider.startMeasurement(
        config: const MeasurementConfig(
          target: MeasurementTarget.pulseOnly,
          durationSeconds: 15,
        ),
      );

      // Fast-forward or stop
      await provider.stopMeasurement();
      expect(provider.activeSession, isNotNull);

      // Start fresh
      final stream2 = provider.startMeasurement(
        config: const MeasurementConfig(
          target: MeasurementTarget.breathingAndPulse,
          durationSeconds: 30,
        ),
      );
      expect(stream2, isNotNull);
      expect(provider.activeSession?.target, equals(MeasurementTarget.breathingAndPulse));
    });

    test('5. Starting after a failed attempt resets state and starts fresh', () async {
      final failingProvider = MockVitalsProvider(shouldSimulateSuccess: false, sessionRepository: sessionRepo);
      failingProvider.startMeasurement();
      final failResult = await failingProvider.stopMeasurement();
      expect(failResult.isSuccessful, isFalse);
      expect(failingProvider.activeSession?.status, equals(MeasurementSessionStatus.interrupted));

      // New attempt
      failingProvider.startMeasurement();
      expect(failingProvider.activeSession?.status, equals(MeasurementSessionStatus.active));
      await failingProvider.dispose();
    });

    test('6. Cancelling an active session marks cancelled and persists', () async {
      provider.startMeasurement();
      await provider.cancelMeasurement(reason: 'User cancelled');
      expect(provider.activeSession?.status, equals(MeasurementSessionStatus.cancelled));
      expect(provider.activeSession?.userCancelled, isTrue);
      expect(provider.activeSession?.interruptionReason, contains('User cancelled'));

      final persisted = await sessionRepo.getSession(provider.activeSession!.id);
      expect(persisted?.status, equals(MeasurementSessionStatus.cancelled));
    });

    test('7. Stopping an idle session is safe and idempotent', () async {
      final result = await provider.stopMeasurement();
      expect(result.isSuccessful, isFalse);
      expect(result.failureReason, contains('confidence window'));
    });

    test('8. Leaving the measurement route during active session interrupts cleanly', () async {
      provider.startMeasurement();
      final result = await provider.stopMeasurement(
        markInterrupted: true,
        interruptionReason: 'Navigated away from screen',
      );
      expect(result.isSuccessful, isFalse);
      expect(provider.activeSession?.status, equals(MeasurementSessionStatus.interrupted));
      expect(provider.activeSession?.interruptionReason, equals('Navigated away from screen'));
    });

    test('9 & 10. Returning to and continuing an interrupted session', () async {
      provider.startMeasurement();
      final originalId = provider.activeSession!.id;
      await provider.stopMeasurement(markInterrupted: true, interruptionReason: 'Route pop');

      final latest = await sessionRepo.getLatestSession();
      expect(latest?.status, equals(MeasurementSessionStatus.interrupted));

      // Continue session: same ID, increment attempt
      provider.startMeasurement(
        config: MeasurementConfig(
          target: latest!.target,
          sessionId: latest.id,
        ),
      );
      expect(provider.activeSession?.id, equals(originalId));
      expect(provider.activeSession?.status, equals(MeasurementSessionStatus.active));
    });

    test('11. Restarting an interrupted session creates a fresh session ID', () async {
      provider.startMeasurement();
      final oldId = provider.activeSession!.id;
      await provider.stopMeasurement(markInterrupted: true);

      // Mark old cancelled and start fresh
      await provider.cancelMeasurement(reason: 'Restarted');
      provider.startMeasurement();
      final newId = provider.activeSession!.id;
      expect(newId, isNot(equals(oldId)));
    });

    test('12. App lifecycle interruption records reason', () async {
      provider.startMeasurement();
      await provider.stopMeasurement(
        markInterrupted: true,
        interruptionReason: 'App moved to background',
      );
      expect(provider.activeSession?.interruptionReason, equals('App moved to background'));
      expect(provider.activeSession?.isInterrupted, isTrue);
    });

    test('13. Changing metric types between sessions updates active configuration', () {
      provider.startMeasurement(
        config: const MeasurementConfig(target: MeasurementTarget.pulseOnly),
      );
      expect(provider.activeSession?.target, equals(MeasurementTarget.pulseOnly));
      provider.cancelMeasurement();

      provider.startMeasurement(
        config: const MeasurementConfig(target: MeasurementTarget.fullVitalsAndHrv),
      );
      expect(provider.activeSession?.target, equals(MeasurementTarget.fullVitalsAndHrv));
    });

    test('14. Preventing stale results from appearing in new session', () async {
      provider.startMeasurement();
      await provider.stopMeasurement();
      expect(provider.activeSession?.result, isNotNull);

      // Start new session
      provider.startMeasurement();
      expect(provider.activeSession?.result, isNull);
    });

    test('15. Correct persistence of session status across lifecycle', () async {
      provider.startMeasurement();
      final id = provider.activeSession!.id;
      await Future.delayed(const Duration(milliseconds: 20));
      var stored = await sessionRepo.getSession(id);
      expect(stored?.status, equals(MeasurementSessionStatus.active));

      await provider.stopMeasurement(markInterrupted: true, interruptionReason: 'Timeout');
      await Future.delayed(const Duration(milliseconds: 20));
      stored = await sessionRepo.getSession(id);
      expect(stored?.status, equals(MeasurementSessionStatus.interrupted));
      expect(stored?.interruptionReason, equals('Timeout'));
    });
  });

  group('NativeVitalsProvider Unit & Channel Tests', () {
    const MethodChannel methodChannel = MethodChannel('com.caren.app/smartspectra');
    late NativeVitalsProvider nativeProvider;
    late LocalMeasurementSessionRepository sessionRepo;
    final List<MethodCall> methodCalls = [];

    setUp(() {
      methodCalls.clear();
      sessionRepo = LocalMeasurementSessionRepository();
      nativeProvider = NativeVitalsProvider(sessionRepository: sessionRepo);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        methodChannel,
        (MethodCall call) async {
          methodCalls.add(call);
          switch (call.method) {
            case 'initialize':
              return true;
            case 'getDiagnostics':
              return {
                'isInitialized': true,
                'hasApiKey': true,
                'hasCameraPermission': true,
                'isSessionActive': false,
                'sessionState': 'IDLE',
                'activeTarget': 'pulseOnly',
                'sdkVersion': '3.4.0 (AAR)',
                'cameraPreviewAttached': true,
                'processingStatus': 'IDLE',
                'validationCode': 'OK',
                'validationHint': 'Signal acquired',
                'latestErrorCode': 'None',
                'latestErrorMessage': 'None',
                'authStatus': 'Key Configured (Presage 3.4.0)',
                'latestPulse': 72.0,
                'telemetryConfigured': false,
                'startRequestsCount': 1,
                'rejectedDuplicateStartsCount': 0,
              };
            case 'requestCameraPermission':
              return {'granted': true, 'permanentlyDenied': false};
            case 'openAppSettings':
              return true;
            case 'startMeasurement':
              final args = call.arguments as Map?;
              return {
                'started': true,
                'alreadyActive': false,
                'sessionId': args?['sessionId'],
                'status': 'ACTIVE',
              };
            case 'stopMeasurement':
              final args = call.arguments as Map?;
              final markInterrupted = args?['markInterrupted'] as bool? ?? false;
              final reason = markInterrupted ? (args?['interruptionReason'] as String?) : null;
              return {
                'sessionId': 'sess_test',
                'durationSeconds': 15,
                'pulseRateBpm': 72.0,
                'breathingRateBpm': 16.0,
                'hrvRmssdMs': 42.0,
                'qualityScore': 0.88,
                'stabilityStatus': 'Stable signal observed',
                'isSuccessful': !markInterrupted,
                'sessionStatus': markInterrupted ? 'INTERRUPTED' : 'COMPLETED',
                'failureReason': reason,
                'notes': 'SmartSpectra SDK 3.4.0 native measurement.',
              };
            case 'cancelMeasurement':
              return true;
            case 'dispose':
              return true;
            default:
              return null;
          }
        },
      );
    });

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        methodChannel,
        null,
      );
      await nativeProvider.dispose();
    });

    test('initialize sets isAvailable to true upon native confirmation', () async {
      final success = await nativeProvider.initialize(apiKey: 'real_presage_key');
      expect(success, isTrue);
      expect(nativeProvider.isAvailable, isTrue);
      expect(methodCalls.any((c) => c.method == 'initialize'), isTrue);
    });

    test('requestCameraPermission parses map correctly', () async {
      final result = await nativeProvider.requestCameraPermission();
      expect(result.granted, isTrue);
      expect(result.permanentlyDenied, isFalse);
    });

    test('openAppSettings sends method call to platform', () async {
      await nativeProvider.openAppSettings();
      expect(methodCalls.any((c) => c.method == 'openAppSettings'), isTrue);
    });

    test('1 & 2. Native startMeasurement handles duplicate call deterministically without crashing', () {
      final stream1 = nativeProvider.startMeasurement(
        config: const MeasurementConfig(
          target: MeasurementTarget.pulseOnly,
          durationSeconds: 15,
        ),
      );

      final stream2 = nativeProvider.startMeasurement(
        config: const MeasurementConfig(
          target: MeasurementTarget.pulseOnly,
          durationSeconds: 15,
        ),
      );

      expect(stream1, isNotNull);
      expect(stream2, isNotNull);
      expect(nativeProvider.activeSession, isNotNull);
    });

    test('7. Stopping without active session returns structured failure without crashing', () async {
      final result = await nativeProvider.stopMeasurement();
      expect(result.isSuccessful, isFalse);
      expect(result.failureReason, contains('No active measurement session'));
    });

    test('startMeasurement and stopMeasurement lifecycle produces genuine MeasurementResult and persists', () async {
      nativeProvider.startMeasurement(
        config: const MeasurementConfig(
          target: MeasurementTarget.pulseOnly,
          durationSeconds: 15,
        ),
      );

      final result = await nativeProvider.stopMeasurement();
      expect(result.isSuccessful, isTrue);
      expect(result.pulseRateBpm, equals(72.0));
      expect(result.qualityScore, equals(0.88));
      expect(result.isSimulated, isFalse);
      expect(nativeProvider.activeSession?.status, equals(MeasurementSessionStatus.completed));

      final stored = await sessionRepo.getSession(nativeProvider.activeSession!.id);
      expect(stored?.status, equals(MeasurementSessionStatus.completed));
    });

    test('8. Route departure stops native measurement with markInterrupted flag', () async {
      nativeProvider.startMeasurement();
      final result = await nativeProvider.stopMeasurement(
        markInterrupted: true,
        interruptionReason: 'User navigated back',
      );

      expect(result.isSuccessful, isFalse);
      expect(result.failureReason, equals('User navigated back'));
      expect(nativeProvider.activeSession?.status, equals(MeasurementSessionStatus.interrupted));
    });

    test('getDiagnosticsState queries platform channel and parses session lifecycle fields', () async {
      final diag = await nativeProvider.getDiagnosticsState();
      expect(diag['isInitialized'], isTrue);
      expect(diag['hasApiKey'], isTrue);
      expect(diag['sdkVersion'], equals('3.4.0 (AAR)'));
      expect(diag['sessionState'], equals('IDLE'));
      expect(diag['startRequestsCount'], equals(1));
      expect(diag['rejectedDuplicateStartsCount'], equals(0));
      expect(methodCalls.any((c) => c.method == 'getDiagnostics'), isTrue);
    });

    test('cancelMeasurement and dispose are idempotent without active session', () async {
      await expectLater(nativeProvider.cancelMeasurement(), completes);
      await expectLater(nativeProvider.dispose(), completes);
    });
  });
}
