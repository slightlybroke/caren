import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/profile/data/profile_repository.dart';
import 'mock_vitals_provider.dart';
import 'native_vitals_provider.dart';
import 'session_repository.dart';
import 'vitals_models.dart';

/// Abstract contract for camera-based wellness vitals measurement.
/// Decouples Flutter UI from native SDK implementations (Android SmartSpectra via Kotlin,
/// iOS via Swift, or Mock provider for development and testing).
abstract class VitalsProvider {
  /// Whether the native SDK or mock environment is available on this device.
  bool get isAvailable;

  /// Human-readable provider name (e.g. 'Presage SmartSpectra Android SDK' or 'Simulated Mock Vitals').
  String get providerName;

  /// The active measurement session record, if one is currently in progress.
  MeasurementSessionRecord? get activeSession;

  /// Initializes the provider with required credentials or configs.
  Future<bool> initialize({String? apiKey});

  /// Explicitly requests camera permission before starting video stream.
  Future<CameraPermissionResult> requestCameraPermission();

  /// Opens application settings when camera permission has been permanently denied.
  Future<void> openAppSettings();

  /// Starts a measurement session, streaming real-time frame telemetry.
  /// Guarantees that at most one measurement session is active at any time.
  Stream<VitalsStreamData> startMeasurement({MeasurementConfig config = const MeasurementConfig()});

  /// Completes the ongoing measurement and returns the summarized result.
  Future<MeasurementResult> stopMeasurement({
    bool markInterrupted = false,
    String? interruptionReason,
  });

  /// Cancels an active measurement session without recording.
  Future<void> cancelMeasurement({String? reason});

  /// Releases hardware camera and SDK resources.
  Future<void> dispose();

  /// Queries runtime diagnostics and native SDK connection state.
  Future<Map<String, dynamic>> getDiagnosticsState();
}

final mockVitalsProvider = Provider<VitalsProvider>((ref) {
  final sessionRepo = ref.watch(sessionRepositoryProvider);
  final provider = MockVitalsProvider(sessionRepository: sessionRepo);
  ref.onDispose(() => provider.dispose());
  return provider;
});

final nativeVitalsProvider = Provider<VitalsProvider>((ref) {
  final sessionRepo = ref.watch(sessionRepositoryProvider);
  final provider = NativeVitalsProvider(sessionRepository: sessionRepo);
  ref.onDispose(() => provider.dispose());
  return provider;
});

/// Riverpod provider for the vitals service.
/// Resolves explicitly to MockVitalsProvider when simulated mock mode is selected,
/// or NativeVitalsProvider when physical SDK integration is selected.
/// NEVER silently falls back.
final vitalsProvider = Provider<VitalsProvider>((ref) {
  final privacyAsync = ref.watch(privacySettingsProvider);
  final useMock = privacyAsync.asData?.value.enableSmartSpectraSimulatedMock ?? false;

  if (useMock) {
    return ref.watch(mockVitalsProvider);
  } else {
    return ref.watch(nativeVitalsProvider);
  }
});
