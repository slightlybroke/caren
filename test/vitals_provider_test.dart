import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caren/services/vitals/vitals_models.dart';
import 'package:caren/services/vitals/mock_vitals_provider.dart';
import 'package:caren/services/vitals/native_vitals_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MockVitalsProvider Tests', () {
    late MockVitalsProvider provider;

    setUp(() {
      provider = MockVitalsProvider(
        updateInterval: const Duration(milliseconds: 10), // Fast ticks for test
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

    test('startMeasurement streams telemetry explicitly marked as isSimulated', () async {
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
      expect(firstEvent.status, equals(MeasurementStatus.preparingCamera));
    });

    test('stopping before 12s confidence window fails with explicit window reason', () async {
      provider.startMeasurement(
        config: const MeasurementConfig(
          target: MeasurementTarget.pulseOnly,
          durationSeconds: 15,
        ),
      );

      // Stop immediately before 12s has elapsed
      final result = await provider.stopMeasurement();
      expect(result.isSimulated, isTrue);
      expect(result.isSuccessful, isFalse);
      expect(result.failureReason, contains('confidence window'));
    });

    test('stopMeasurement with failure simulation returns unsuccessful result', () async {
      final failingProvider = MockVitalsProvider(shouldSimulateSuccess: false);
      final result = await failingProvider.stopMeasurement();
      expect(result.isSuccessful, isFalse);
      expect(result.isSimulated, isTrue);
      await failingProvider.dispose();
    });

    test('cancelMeasurement and dispose are idempotent', () async {
      await expectLater(provider.cancelMeasurement(), completes);
      await expectLater(provider.cancelMeasurement(), completes);
      await expectLater(provider.dispose(), completes);
    });
  });

  group('NativeVitalsProvider Unit & Channel Tests', () {
    const MethodChannel methodChannel = MethodChannel('com.caren.app/smartspectra');
    late NativeVitalsProvider nativeProvider;
    final List<MethodCall> methodCalls = [];

    setUp(() {
      methodCalls.clear();
      nativeProvider = NativeVitalsProvider();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        methodChannel,
        (MethodCall call) async {
          methodCalls.add(call);
          switch (call.method) {
            case 'initialize':
              return true;
            case 'requestCameraPermission':
              return {'granted': true, 'permanentlyDenied': false};
            case 'openAppSettings':
              return true;
            case 'startMeasurement':
              return true;
            case 'stopMeasurement':
              return {
                'durationSeconds': 15,
                'pulseRateBpm': 72.0,
                'breathingRateBpm': 16.0,
                'hrvRmssdMs': 42.0,
                'qualityScore': 0.88,
                'stabilityStatus': 'Stable signal observed',
                'isSuccessful': true,
                'failureReason': null,
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

    test('duplicate startMeasurement throws StateError', () {
      nativeProvider.startMeasurement(
        config: const MeasurementConfig(
          target: MeasurementTarget.pulseOnly,
          durationSeconds: 15,
        ),
      );

      expect(
        () => nativeProvider.startMeasurement(
          config: const MeasurementConfig(
            target: MeasurementTarget.pulseOnly,
            durationSeconds: 15,
          ),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('stopping without active session returns structured failure without crashing', () async {
      final result = await nativeProvider.stopMeasurement();
      expect(result.isSuccessful, isFalse);
      expect(result.failureReason, contains('No active measurement session'));
    });

    test('startMeasurement and stopMeasurement lifecycle produces genuine MeasurementResult', () async {
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
      expect(result.notes, contains('SmartSpectra SDK 3.4.0'));
    });

    test('cancelMeasurement and dispose are idempotent without active session', () async {
      await expectLater(nativeProvider.cancelMeasurement(), completes);
      await expectLater(nativeProvider.dispose(), completes);
    });
  });
}
