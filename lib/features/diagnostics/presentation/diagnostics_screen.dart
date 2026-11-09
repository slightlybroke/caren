import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/caren_button.dart';
import '../../../core/widgets/caren_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../services/vitals/session_repository.dart';
import '../../../services/vitals/vitals_models.dart';
import '../../../services/vitals/vitals_provider.dart';
import '../../profile/data/profile_repository.dart';

/// Developer Diagnostics & Live SmartSpectra SDK Console.
/// Enforces single-owner measurement lifecycle, navigation cleanup, and session continuity.
class DiagnosticsScreen extends ConsumerStatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  ConsumerState<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends ConsumerState<DiagnosticsScreen> with WidgetsBindingObserver {
  Map<String, dynamic> _diagnosticsData = {};

  // Live measurement session state
  MeasurementTarget _selectedTarget = MeasurementTarget.pulseOnly;
  bool _isMeasuring = false;
  bool _isStarting = false;
  VitalsStreamData? _latestStreamData;
  MeasurementResult? _lastResult;
  MeasurementSessionRecord? _interruptedSession;
  StreamSubscription<VitalsStreamData>? _streamSub;
  String? _measurementError;

  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshDiagnostics();
    _checkPreviousSession();

    // Poll diagnostics state every 2 seconds when idle
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted && !_isMeasuring) {
        _refreshDiagnostics(silent: true);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_isMeasuring) {
        _interruptLiveMeasurement('App moved to background during measurement');
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    _streamSub?.cancel();

    // Clean up active session on screen pop / disposal to release camera hardware
    if (_isMeasuring) {
      try {
        final provider = ref.read(vitalsProvider);
        provider.stopMeasurement(
          markInterrupted: true,
          interruptionReason: 'Navigated away from Developer Diagnostics',
        );
      } catch (_) {}
    }

    super.dispose();
  }

  Future<void> _checkPreviousSession() async {
    try {
      final repo = ref.read(sessionRepositoryProvider);
      final latest = await repo.getLatestSession();
      if (latest != null && mounted) {
        setState(() {
          if (latest.status == MeasurementSessionStatus.interrupted) {
            _interruptedSession = latest;
            _selectedTarget = latest.target;
          } else if (latest.status == MeasurementSessionStatus.completed) {
            _lastResult = latest.result;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _refreshDiagnostics({bool silent = false}) async {
    try {
      final provider = ref.read(vitalsProvider);
      final data = await provider.getDiagnosticsState();
      if (mounted) {
        setState(() {
          _diagnosticsData = data;
        });
      }
    } catch (_) {}
  }

  Future<void> _initializeNativeSdk() async {
    try {
      final provider = ref.read(vitalsProvider);
      await provider.initialize();
      await _refreshDiagnostics();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Native SmartSpectra SDK initialized successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('Initialization failed: $e'),
          ),
        );
      }
      await _refreshDiagnostics();
    }
  }

  Future<void> _requestCameraPermission() async {
    final provider = ref.read(vitalsProvider);
    final result = await provider.requestCameraPermission();
    await _refreshDiagnostics();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.granted
              ? 'Camera permission granted.'
              : result.permanentlyDenied
                  ? 'Camera permission permanently denied. Open settings.'
                  : 'Camera permission denied.'),
        ),
      );
    }
  }

  void _startLiveMeasurement({String? existingSessionId, int attemptNumber = 1}) async {
    if (_isStarting || _isMeasuring) return;

    final provider = ref.read(vitalsProvider);
    setState(() {
      _isStarting = true;
      _measurementError = null;
      _lastResult = null;
      _latestStreamData = null;
      if (existingSessionId == null) {
        _interruptedSession = null;
      }
    });

    final perm = await provider.requestCameraPermission();
    if (!perm.granted) {
      if (mounted) {
        setState(() {
          _isStarting = false;
          _isMeasuring = false;
          _measurementError = perm.permanentlyDenied
              ? 'Camera permission is permanently denied. Please enable it in Android Settings.'
              : 'Camera permission denied. Measurement requires camera access.';
        });
      }
      return;
    }

    try {
      final stream = provider.startMeasurement(
        config: MeasurementConfig(
          target: _selectedTarget,
          durationSeconds: _selectedTarget.defaultDurationSeconds,
          sessionId: existingSessionId,
          enableSdkTelemetry: false,
        ),
      );

      _streamSub?.cancel();
      _streamSub = stream.listen(
        (data) {
          if (mounted) {
            setState(() {
              _latestStreamData = data;
              _isMeasuring = true;
              _isStarting = false;
            });
            if (data.progress >= 1.0) {
              _stopLiveMeasurement();
            }
          }
        },
        onError: (err) {
          if (mounted) {
            setState(() {
              _isMeasuring = false;
              _isStarting = false;
              _measurementError = 'Measurement stream error: $err';
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isStarting = false;
          _isMeasuring = false;
          _measurementError = 'Failed to start measurement: $e';
        });
      }
    }
  }

  void _stopLiveMeasurement() async {
    _streamSub?.cancel();
    final provider = ref.read(vitalsProvider);
    final result = await provider.stopMeasurement();
    if (mounted) {
      setState(() {
        _isMeasuring = false;
        _isStarting = false;
        _lastResult = result;
      });
      await _refreshDiagnostics();
      await _checkPreviousSession();
    }
  }

  void _interruptLiveMeasurement(String reason) async {
    _streamSub?.cancel();
    final provider = ref.read(vitalsProvider);
    await provider.stopMeasurement(markInterrupted: true, interruptionReason: reason);
    if (mounted) {
      setState(() {
        _isMeasuring = false;
        _isStarting = false;
      });
      await _refreshDiagnostics();
      await _checkPreviousSession();
    }
  }

  void _cancelLiveMeasurement() async {
    _streamSub?.cancel();
    final provider = ref.read(vitalsProvider);
    await provider.cancelMeasurement(reason: 'User cancelled');
    if (mounted) {
      setState(() {
        _isMeasuring = false;
        _isStarting = false;
        _latestStreamData = null;
        _interruptedSession = null;
      });
      await _refreshDiagnostics();
      await _checkPreviousSession();
    }
  }

  void _continueInterruptedSession() {
    if (_interruptedSession == null) return;
    final sessionId = _interruptedSession!.id;
    final target = _interruptedSession!.target;
    final attempt = _interruptedSession!.attemptNumber + 1;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Resuming workflow. Note: Camera measurement starts fresh to observe valid signals.'),
      ),
    );

    setState(() {
      _selectedTarget = target;
    });

    _startLiveMeasurement(existingSessionId: sessionId, attemptNumber: attempt);
  }

  void _restartSession() async {
    if (_interruptedSession != null) {
      try {
        final repo = ref.read(sessionRepositoryProvider);
        await repo.saveSession(
          _interruptedSession!.copyWith(
            status: MeasurementSessionStatus.cancelled,
            userCancelled: true,
          ),
        );
      } catch (_) {}
    }

    setState(() {
      _interruptedSession = null;
      _lastResult = null;
      _measurementError = null;
      _latestStreamData = null;
    });

    _startLiveMeasurement();
  }

  void _copyDiagnosticsToClipboard() {
    final buffer = StringBuffer();
    buffer.writeln('=== caren SMART SPECTRA DIAGNOSTICS LOG ===');
    buffer.writeln('Timestamp: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Platform: $defaultTargetPlatform');
    buffer.writeln('Active Provider: ${ref.read(vitalsProvider).providerName}');
    _diagnosticsData.forEach((key, value) {
      buffer.writeln('$key: $value');
    });
    if (_interruptedSession != null) {
      buffer.writeln('\n--- INTERRUPTED SESSION METADATA ---');
      buffer.writeln('id: ${_interruptedSession!.id}');
      buffer.writeln('target: ${_interruptedSession!.target.name}');
      buffer.writeln('status: ${_interruptedSession!.status.name}');
      buffer.writeln('interruptionReason: ${_interruptedSession!.interruptionReason}');
      buffer.writeln('attemptNumber: ${_interruptedSession!.attemptNumber}');
    }
    if (_latestStreamData != null) {
      buffer.writeln('\n--- LATEST STREAM PACKET ---');
      buffer.writeln('sessionId: ${_latestStreamData!.sessionId}');
      buffer.writeln('sessionStatus: ${_latestStreamData!.sessionStatus?.name}');
      buffer.writeln('elapsedSeconds: ${_latestStreamData!.elapsedSeconds}');
      buffer.writeln('status: ${_latestStreamData!.status.name}');
      buffer.writeln('validationCode: ${_latestStreamData!.validationCode}');
      buffer.writeln('validationHint: ${_latestStreamData!.validationHint}');
      buffer.writeln('processingStatus: ${_latestStreamData!.processingStatus}');
      buffer.writeln('instantaneousPulse: ${_latestStreamData!.instantaneousPulse}');
      buffer.writeln('instantaneousBreathing: ${_latestStreamData!.instantaneousBreathing}');
      buffer.writeln('waveformValue: ${_latestStreamData!.waveformValue}');
      buffer.writeln('confidenceScore: ${_latestStreamData!.confidenceScore}');
      buffer.writeln('stabilityScore: ${_latestStreamData!.stabilityScore}');
      buffer.writeln('sdkErrorCode: ${_latestStreamData!.sdkErrorCode}');
      buffer.writeln('sdkErrorMessage: ${_latestStreamData!.sdkErrorMessage}');
    }
    if (_lastResult != null) {
      buffer.writeln('\n--- LAST MEASUREMENT RESULT ---');
      buffer.writeln('isSuccessful: ${_lastResult!.isSuccessful}');
      buffer.writeln('pulseRateBpm: ${_lastResult!.pulseRateBpm}');
      buffer.writeln('breathingRateBpm: ${_lastResult!.breathingRateBpm}');
      buffer.writeln('hrvRmssdMs: ${_lastResult!.hrvRmssdMs}');
      buffer.writeln('qualityScore: ${_lastResult!.qualityScore}');
      buffer.writeln('stabilityStatus: ${_lastResult!.stabilityStatus}');
      buffer.writeln('failureReason: ${_lastResult!.failureReason}');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Diagnostics log copied to clipboard (credentials omitted).')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final privacyAsync = ref.watch(privacySettingsProvider);
    final isMockMode = privacyAsync.asData?.value.enableSmartSpectraSimulatedMock ?? true;
    final activeProvider = ref.watch(vitalsProvider);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (_isMeasuring) {
          _interruptLiveMeasurement('Navigated back from Developer Diagnostics');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Developer Diagnostics'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Diagnostics',
              onPressed: () => _refreshDiagnostics(),
            ),
            IconButton(
              icon: const Icon(Icons.copy_rounded),
              tooltip: 'Copy Diagnostic Log',
              onPressed: _copyDiagnosticsToClipboard,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mode Banner & Mode Switch
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isMockMode ? AppColors.warningContainer : AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: isMockMode ? AppColors.warning : AppColors.secondary,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isMockMode ? Icons.science_outlined : Icons.camera_alt_outlined,
                              color: isMockMode ? AppColors.warning : AppColors.primaryDark,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isMockMode ? 'SIMULATED MOCK MODE' : 'NATIVE SMARTSPECTRA SDK',
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isMockMode ? AppColors.warning : AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                        StatusBadge(
                          label: isMockMode ? 'TEST MOCK' : 'NATIVE',
                          type: isMockMode ? BadgeType.warning : BadgeType.success,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isMockMode
                          ? 'Simulated provider active. Generates synthetic sine data for UI development.'
                          : 'Real Presage SmartSpectra SDK 3.4.0 active. Captures real camera frames and infers vital signs.',
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    privacyAsync.when(
                      data: (privacy) => Material(
                        color: Colors.transparent,
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Use Mock Simulation', style: AppTypography.labelMedium),
                          subtitle: const Text('Toggle OFF to activate native Android CameraX and SmartSpectra SDK.',
                              style: AppTypography.caption),
                          value: privacy.enableSmartSpectraSimulatedMock,
                          activeThumbColor: AppColors.primary,
                          onChanged: (val) async {
                            if (_isMeasuring) {
                              _interruptLiveMeasurement('Provider mode changed');
                            }
                            await ref.read(privacySettingsProvider.notifier).updateSettings(
                                  privacy.copyWith(enableSmartSpectraSimulatedMock: val),
                                );
                            ref.invalidate(vitalsProvider);
                            await _refreshDiagnostics();
                          },
                        ),
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Settings error: $e', style: AppTypography.caption),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Interrupted Session Recovery Banner (Part 5)
              if (_interruptedSession != null && !_isMeasuring) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.warningContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.warning),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.history_toggle_off, color: AppColors.warning),
                          const SizedBox(width: 8),
                          Text(
                            'Interrupted Session Detected',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Session ${_interruptedSession!.id} (${_interruptedSession!.target.displayName}) was interrupted: '
                        '${_interruptedSession!.interruptionReason ?? "Navigation away from screen"}.',
                        style: AppTypography.caption,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: CarenButton(
                              label: 'Continue (Attempt ${_interruptedSession!.attemptNumber + 1})',
                              icon: Icons.play_arrow_outlined,
                              variant: CarenButtonVariant.primary,
                              onPressed: _continueInterruptedSession,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: CarenButton(
                              label: 'Restart Fresh',
                              icon: Icons.restart_alt,
                              variant: CarenButtonVariant.secondary,
                              onPressed: _restartSession,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // Live Camera Viewfinder & Feedback
              Text('Hardware Camera Preview & SDK Guidance', style: AppTypography.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Container(
                height: 240,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // CameraX preview feed on Android (when in Native mode)
                      if (!isMockMode && defaultTargetPlatform == TargetPlatform.android)
                        const AndroidView(
                          viewType: 'com.caren.app/smartspectra_camera_view',
                        )
                      else
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isMockMode ? Icons.science_outlined : Icons.videocam_off_outlined,
                                size: 40,
                                color: Colors.white.withAlpha(120),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isMockMode
                                    ? 'Mock simulation mode\n(Camera sensor detached)'
                                    : 'Camera viewfinder standby\n(Start measurement to open camera)',
                                textAlign: TextAlign.center,
                                style: AppTypography.caption.copyWith(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),

                      // Face Positioning Oval Guide
                      Container(
                        width: 140,
                        height: 180,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(70),
                          border: Border.all(
                            color: (_latestStreamData?.isFaceDetected ?? false)
                                ? AppColors.secondary
                                : Colors.white.withAlpha(120),
                            width: 2.5,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            (_latestStreamData?.isFaceDetected ?? false)
                                ? Icons.face_rounded
                                : Icons.face_retouching_natural,
                            size: 44,
                            color: (_latestStreamData?.isFaceDetected ?? false)
                                ? AppColors.secondary.withAlpha(180)
                                : Colors.white.withAlpha(90),
                          ),
                        ),
                      ),

                      // Top Status Overlay (SDK Validation Code & Processing Status)
                      Positioned(
                        top: 10,
                        left: 10,
                        right: 10,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(180),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'SDK: ${_latestStreamData?.processingStatus ?? _diagnosticsData['processingStatus'] ?? "IDLE"}',
                                style: AppTypography.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(180),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'VAL: ${_latestStreamData?.validationCode ?? _diagnosticsData['validationCode'] ?? "Not exposed by SDK"}',
                                style: AppTypography.caption.copyWith(
                                  color: (_latestStreamData?.validationCode == 'OK' ||
                                          _diagnosticsData['validationCode'] == 'OK')
                                      ? AppColors.secondary
                                      : Colors.amber,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bottom Guidance Text Overlay
                      Positioned(
                        bottom: 10,
                        left: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(190),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _latestStreamData?.validationHint ??
                                _diagnosticsData['validationHint'] ??
                                'Position face squarely inside the frame in steady lighting.',
                            textAlign: TextAlign.center,
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Measurement Controls Card
              CarenCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Live Measurement Console', style: AppTypography.titleMedium),
                        StatusBadge(
                          label: _isMeasuring
                              ? 'ACTIVE MEASURING'
                              : _isStarting
                                  ? 'STARTING...'
                                  : 'IDLE',
                          type: _isMeasuring ? BadgeType.warning : BadgeType.neutral,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Select a metric target to observe documented confidence windows (12s Pulse, 30s Breathing, 60s HRV):',
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: 8,
                      children: MeasurementTarget.values.map((target) {
                        final selected = _selectedTarget == target;
                        return ChoiceChip(
                          label: Text(target.displayName),
                          selected: selected,
                          onSelected: (_isMeasuring || _isStarting)
                              ? null
                              : (_) => setState(() => _selectedTarget = target),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    if (_measurementError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.dangerContainer,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _measurementError!,
                                style: AppTypography.caption.copyWith(color: AppColors.danger, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: CarenButton(
                            label: _isMeasuring
                                ? 'Stop Measurement'
                                : _isStarting
                                    ? 'Starting Session...'
                                    : 'Start Live Measurement',
                            icon: _isMeasuring ? Icons.stop_rounded : Icons.play_arrow_rounded,
                            variant: _isMeasuring ? CarenButtonVariant.danger : CarenButtonVariant.primary,
                            onPressed: _isStarting
                                ? null
                                : _isMeasuring
                                    ? _stopLiveMeasurement
                                    : () => _startLiveMeasurement(),
                          ),
                        ),
                        if (_isMeasuring) ...[
                          const SizedBox(width: AppSpacing.sm),
                          IconButton(
                            icon: const Icon(Icons.cancel_outlined),
                            tooltip: 'Cancel Measurement',
                            onPressed: _cancelLiveMeasurement,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Live Stream Telemetry Readout
              if (_isMeasuring && _latestStreamData != null) ...[
                CarenCard(
                  backgroundColor: AppColors.surfaceVariant,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Active Stream Telemetry', style: AppTypography.labelLarge),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricItem(
                              label: 'Elapsed Time',
                              value: '${_latestStreamData!.elapsedSeconds}s / ${_selectedTarget.defaultDurationSeconds}s',
                            ),
                          ),
                          Expanded(
                            child: _MetricItem(
                              label: 'Pulse (12s)',
                              value: _latestStreamData!.instantaneousPulse != null
                                  ? '${_latestStreamData!.instantaneousPulse!.toInt()} bpm'
                                  : 'Acquiring...',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricItem(
                              label: 'Breathing (30s)',
                              value: _latestStreamData!.instantaneousBreathing != null
                                  ? '${_latestStreamData!.instantaneousBreathing!.toInt()} br/min'
                                  : 'Acquiring...',
                            ),
                          ),
                          Expanded(
                            child: _MetricItem(
                              label: 'Face Detected',
                              value: _latestStreamData!.isFaceDetected ? 'YES' : 'NO',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      LinearProgressIndicator(
                        value: _latestStreamData!.progress,
                        color: AppColors.primary,
                        backgroundColor: AppColors.border,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // Last Measurement Result Card
              if (_lastResult != null) ...[
                CarenCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Completed Measurement Result', style: AppTypography.titleMedium),
                          StatusBadge(
                            label: _lastResult!.isSuccessful ? 'SUCCESSFUL' : 'INCOMPLETE',
                            type: _lastResult!.isSuccessful ? BadgeType.success : BadgeType.warning,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(_lastResult!.summaryLabel, style: AppTypography.bodyMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Target: ${_lastResult!.target.displayName} • Duration: ${_lastResult!.durationSeconds}s',
                        style: AppTypography.caption,
                      ),
                      if (_lastResult!.failureReason != null) ...[
                        const SizedBox(height: 4),
                        Text('Reason: ${_lastResult!.failureReason}',
                            style: AppTypography.caption.copyWith(color: AppColors.warning)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // Comprehensive Runtime Diagnostics Grid (Part 6)
              Text('SDK Runtime Lifecycle & Architecture', style: AppTypography.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              CarenCard(
                child: Column(
                  children: [
                    _DiagRow(
                      label: 'Provider Mode',
                      value: activeProvider.providerName,
                      isPositive: !isMockMode,
                    ),
                    const Divider(height: 1),
                    _DiagRow(
                      label: 'SDK Initialized',
                      value: (_diagnosticsData['isInitialized'] == true) ? 'Yes (Initialized)' : 'No',
                      isPositive: _diagnosticsData['isInitialized'] == true,
                    ),
                    const Divider(height: 1),
                    _DiagRow(
                      label: 'Camera Preview State',
                      value: isMockMode
                          ? 'Standby (Mock Mode)'
                          : (_diagnosticsData['cameraPreviewAttached'] == true
                              ? 'Active (PlatformView Bound)'
                              : 'Detached'),
                      isPositive: !isMockMode && (_diagnosticsData['cameraPreviewAttached'] == true),
                    ),
                    const Divider(height: 1),
                    _DiagRow(
                      label: 'Session State Machine',
                      value: _diagnosticsData['sessionState'] ?? 'UNINITIALIZED',
                      isPositive: _diagnosticsData['sessionState'] == 'ACTIVE' ||
                          _diagnosticsData['sessionState'] == 'IDLE',
                    ),
                    const Divider(height: 1),
                    _DiagRow(
                      label: 'Current Session ID',
                      value: _latestStreamData?.sessionId ??
                          _diagnosticsData['currentSessionId'] ??
                          _interruptedSession?.id ??
                          'None',
                      isPositive: true,
                    ),
                    const Divider(height: 1),
                    _DiagRow(
                      label: 'API Key (BuildConfig)',
                      value: _diagnosticsData['hasApiKey'] == true ? 'Present (Configured)' : 'Missing',
                      isPositive: _diagnosticsData['hasApiKey'] == true,
                    ),
                    const Divider(height: 1),
                    _DiagRow(
                      label: 'Camera Permission',
                      value: _diagnosticsData['hasCameraPermission'] == true ? 'Granted' : 'Not Granted',
                      isPositive: _diagnosticsData['hasCameraPermission'] == true,
                    ),
                    const Divider(height: 1),
                    _DiagRow(
                      label: 'SmartSpectra Version',
                      value: _diagnosticsData['sdkVersion'] ?? '3.4.0',
                      isPositive: true,
                    ),
                    const Divider(height: 1),
                    _DiagRow(
                      label: 'Processing Status',
                      value: _latestStreamData?.processingStatus ?? _diagnosticsData['processingStatus'] ?? 'IDLE',
                      isPositive: _latestStreamData?.processingStatus != 'ERROR',
                    ),
                    const Divider(height: 1),
                    _DiagRow(
                      label: 'Start Requests Total',
                      value: '${_diagnosticsData['startRequestsCount'] ?? 0}',
                      isPositive: true,
                    ),
                    const Divider(height: 1),
                    _DiagRow(
                      label: 'Rejected Duplicate Starts',
                      value: '${_diagnosticsData['rejectedDuplicateStartsCount'] ?? 0}',
                      isPositive: true,
                    ),
                    const Divider(height: 1),
                    _DiagRow(
                      label: 'Last Interruption Reason',
                      value: _diagnosticsData['lastInterruptionReason'] ?? _interruptedSession?.interruptionReason ?? 'None',
                      isPositive: true,
                    ),
                    const Divider(height: 1),
                    _DiagRow(
                      label: 'SDK Error Code',
                      value: _latestStreamData?.sdkErrorCode ?? _diagnosticsData['latestErrorCode'] ?? 'Not exposed by SDK',
                      isPositive: _latestStreamData?.sdkErrorCode == null &&
                          (_diagnosticsData['latestErrorCode'] == 'Not exposed by SDK' ||
                              _diagnosticsData['latestErrorCode'] == 'None'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Developer Actions Card
              CarenCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Direct Native Actions', style: AppTypography.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.security),
                          label: const Text('Request Camera Permission'),
                          onPressed: _requestCameraPermission,
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.settings),
                          label: const Text('Open App Settings'),
                          onPressed: () => ref.read(vitalsProvider).openAppSettings(),
                        ),
                        if (!isMockMode)
                          OutlinedButton.icon(
                            icon: const Icon(Icons.power_settings_new),
                            label: const Text('Initialize Native SDK'),
                            onPressed: _initializeNativeSdk,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;

  const _MetricItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _DiagRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isPositive;

  const _DiagRow({
    required this.label,
    required this.value,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: isPositive ? AppColors.secondary : AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
