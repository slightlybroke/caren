import 'package:flutter_test/flutter_test.dart';
import 'package:caren/services/vitals/vitals_models.dart';
import 'package:caren/services/vitals/mock_vitals_provider.dart';

void main() {
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

    test('requestCameraPermission returns true by default and false when configured', () async {
      expect(await provider.requestCameraPermission(), isTrue);

      final deniedProvider = MockVitalsProvider(shouldSimulatePermissionDenial: true);
      expect(await deniedProvider.requestCameraPermission(), isFalse);
      await deniedProvider.dispose();
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
  });
}
