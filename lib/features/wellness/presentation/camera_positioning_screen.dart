import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/caren_app_bar.dart';
import '../../../core/widgets/caren_button.dart';
import '../../../core/widgets/caren_card.dart';
import '../../../core/widgets/simulated_banner.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/vitals_measurement_widget.dart';
import '../../../services/vitals/vitals_models.dart';
import '../../../services/vitals/vitals_provider.dart';

/// Preflight phases for camera-based wellness measurement.
enum CameraPreflightPhase { preparation, positioning, measuring, completed }

/// Reusable full-screen camera positioning and measurement experience.
/// Used by both Me Camera Wellness Check and Family Daily Check-in.
///
/// Guarantees:
/// 1. Camera prepares first, measures second.
/// 2. Measurement window is NOT consumed while user is positioning.
/// 3. Actual SDK validation feedback drives readiness.
/// 4. Cancelling cleanly releases camera and SDK resources.
class CameraPositioningScreen extends ConsumerStatefulWidget {
  final MeasurementTarget target;
  final String title;
  final String? subtitle;

  const CameraPositioningScreen({
    super.key,
    this.target = MeasurementTarget.pulseOnly,
    this.title = 'Camera Wellness Check',
    this.subtitle,
  });

  @override
  ConsumerState<CameraPositioningScreen> createState() =>
      _CameraPositioningScreenState();
}

class _CameraPositioningScreenState
    extends ConsumerState<CameraPositioningScreen> {
  CameraPreflightPhase _phase = CameraPreflightPhase.preparation;

  bool _permissionDenied = false;
  bool _isPermanentlyDenied = false;
  String? _errorMessage;

  VitalsStreamData? _latestStreamData;
  StreamSubscription<VitalsStreamData>? _streamSub;
  MeasurementResult? _completedResult;
  String? _currentSessionId;

  // Readiness state
  bool _isSdkReady = false;
  String _validationHint = 'Position your face within the oval guide.';

  // Measurement countdown
  Timer? _measurementTimer;
  int _secondsRemaining = 0;
  int _totalMeasurementSeconds = 15;

  @override
  void initState() {
    super.initState();
    _totalMeasurementSeconds = widget.target.defaultDurationSeconds;
    _secondsRemaining = _totalMeasurementSeconds;
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _measurementTimer?.cancel();
    _cleanupCamera();
    super.dispose();
  }

  void _cleanupCamera() {
    try {
      ref
          .read(vitalsProvider)
          .cancelMeasurement(reason: 'Exited Camera Positioning Screen');
    } catch (_) {}
  }

  Future<void> _startPositioningStage() async {
    final provider = ref.read(vitalsProvider);

    setState(() {
      _errorMessage = null;
      _permissionDenied = false;
    });

    final permResult = await provider.requestCameraPermission();
    if (!permResult.granted) {
      if (mounted) {
        setState(() {
          _permissionDenied = true;
          _isPermanentlyDenied = permResult.permanentlyDenied;
        });
      }
      return;
    }

    try {
      await provider.initialize();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize camera pipeline: $e';
        });
      }
      return;
    }

    if (!mounted) return;

    final newSessionId = 'preflight_${DateTime.now().millisecondsSinceEpoch}';
    _currentSessionId = newSessionId;

    setState(() {
      _phase = CameraPreflightPhase.positioning;
      _isSdkReady = false;
      _latestStreamData = null; // Stale session protection: clear prior telemetry immediately
      _validationHint = 'Positioning camera feed...';
    });

    // Start stream in preflight mode with explicit unique sessionId
    final stream = provider.startMeasurement(
      config: MeasurementConfig(
        target: widget.target,
        durationSeconds: widget.target.defaultDurationSeconds,
        sessionId: newSessionId,
      ),
    );

    _streamSub?.cancel();
    _streamSub = stream.listen(
      (data) {
        if (!mounted) return;

        // Stale event protection: Drop events from earlier cancelled or completed sessions
        if (data.sessionId != null &&
            _currentSessionId != null &&
            data.sessionId != _currentSessionId) {
          return;
        }

        setState(() {
          _latestStreamData = data;

          // Determine genuine SDK validation feedback
          if (data.validationHint != null && data.validationHint!.isNotEmpty) {
            _validationHint = data.validationHint!;
          } else if (data.statusText.isNotEmpty) {
            _validationHint = data.statusText;
          }

          // Evaluate readiness strictly using explicit semantic sets (no broad negative heuristics)
          _isSdkReady = SdkValidationSemantics.isMeasurementReady(
            code: data.validationCode,
            isFaceDetected: data.isFaceDetected,
            errorCode: data.sdkErrorCode,
            processingStatus: data.processingStatus,
          );
        });
      },
      onError: (err) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Camera error: $err';
        });
      },
    );
  }

  void _beginActualMeasurement() {
    if (!_isSdkReady) return;

    setState(() {
      _phase = CameraPreflightPhase.measuring;
      _secondsRemaining = _totalMeasurementSeconds;
    });

    _measurementTimer?.cancel();
    _measurementTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 1) {
          _secondsRemaining--;
        } else {
          _secondsRemaining = 0;
          timer.cancel();
          _finalizeMeasurement();
        }
      });
    });
  }

  Future<void> _finalizeMeasurement() async {
    _streamSub?.cancel();
    final provider = ref.read(vitalsProvider);
    final result = await provider.stopMeasurement();

    if (mounted) {
      setState(() {
        _phase = CameraPreflightPhase.completed;
        _completedResult = result;
      });
    }
  }

  void _handleCancel() {
    _streamSub?.cancel();
    _measurementTimer?.cancel();
    _cleanupCamera();
    _currentSessionId = null;
    _latestStreamData = null;
    _isSdkReady = false;
    try {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CarenAppBar(
        title: widget.title,
        actions: [
          TextButton(onPressed: _handleCancel, child: const Text('Cancel')),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: _buildPhaseContent(),
        ),
      ),
    );
  }

  Widget _buildPhaseContent() {
    switch (_phase) {
      case CameraPreflightPhase.preparation:
        return _buildPreparationView();
      case CameraPreflightPhase.positioning:
        return _buildPositioningView();
      case CameraPreflightPhase.measuring:
        return _buildMeasuringView();
      case CameraPreflightPhase.completed:
        return _buildCompletedView();
    }
  }

  Widget _buildPreparationView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: AppColors.primary,
                  size: 28,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Private Real-Time Analysis',
                        style: AppTypography.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Video is analyzed live on your device. Video frames are never stored, transmitted, or uploaded.',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (widget.subtitle != null) ...[
            Text(widget.subtitle!, style: AppTypography.bodyMedium),
            const SizedBox(height: AppSpacing.md),
          ],
          Text('Measurement Guidelines', style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'For accurate personal wellness observations, please follow these steps before starting:',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          _GuidelineItem(
            icon: Icons.lightbulb_outline_rounded,
            title: 'Even Lighting',
            description: 'Sit facing a soft window or lamp. Avoid bright backlights or dark shadows.',
          ),
          const SizedBox(height: AppSpacing.sm),
          _GuidelineItem(
            icon: Icons.face_rounded,
            title: 'Position Face in Center',
            description: 'Hold the phone at eye level. Position your face in the center of the guide.',
          ),
          const SizedBox(height: AppSpacing.sm),
          _GuidelineItem(
            icon: Icons.accessibility_new_rounded,
            title: 'Stay Still & Breathe Naturally',
            description: 'Rest your elbows on a table or steady surface. Minimize talking or moving.',
          ),
          const SizedBox(height: AppSpacing.lg),

          // Non-clinical & Non-stress Disclaimer
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const Text(
              'Notice: Camera observations are for personal wellness tracking only. They do not constitute a medical diagnosis and are not an indicator of psychological stress.',
              style: AppTypography.caption,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          if (_permissionDenied) ...[
            CarenPermissionDeniedView(
              isPermanentlyDenied: _isPermanentlyDenied,
              onGrantPermission: _startPositioningStage,
              onOpenSettings: () => ref.read(vitalsProvider).openAppSettings(),
              onContinueWithout: _handleCancel,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          if (_errorMessage != null) ...[
            CarenErrorView(
              message: _errorMessage!,
              onRetry: _startPositioningStage,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          CarenButton(
            label: 'Continue to Camera Positioning',
            icon: Icons.camera_alt_outlined,
            onPressed: _startPositioningStage,
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: TextButton(
              onPressed: _handleCancel,
              child: const Text('Cancel & Use Without Camera'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositioningView() {
    final isSimulated = _latestStreamData?.isSimulated ?? false;
    final valCode = _latestStreamData?.validationCode;
    final isFaceDetected = _latestStreamData?.isFaceDetected ?? false;

    // Explicit semantic evaluation per SmartSpectra 3.4.0 specification
    final faceStatus = SdkValidationSemantics.evaluateFaceCentered(valCode, isFaceDetected);
    final lightStatus = SdkValidationSemantics.evaluateGoodLight(valCode);
    final motionStatus = SdkValidationSemantics.evaluateHoldingStill(valCode);

    return Column(
      children: [
        if (isSimulated) ...[
          const SimulatedBanner(),
          const SizedBox(height: AppSpacing.sm),
        ],

        // Live Front Camera Viewport with Positioning Guide Overlay
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Real Android Camera Preview or Mock Simulation
                  if (!isSimulated &&
                      defaultTargetPlatform == TargetPlatform.android)
                    const AndroidView(
                      viewType: 'com.caren.app/smartspectra_camera_view',
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.85,
                          colors: [
                            _isSdkReady
                                ? AppColors.primaryLight.withValues(alpha: 0.35)
                                : const Color(0xFF1E2822),
                            const Color(0xFF0F1512),
                            Colors.black,
                          ],
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Viewfinder grid lines
                          Opacity(
                            opacity: 0.12,
                            child: GridPaper(
                              color: AppColors.primaryLight,
                              divisions: 2,
                              subdivisions: 1,
                            ),
                          ),
                          // Center face & sensor icon
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isFaceDetected
                                    ? Icons.face_rounded
                                    : Icons.face_retouching_natural_rounded,
                                size: 84,
                                color: _isSdkReady
                                    ? AppColors.primaryContainer
                                    : Colors.white38,
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white24,
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: _isSdkReady
                                            ? const Color(0xFF4CAF50)
                                            : Colors.amber,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      kIsWeb
                                          ? 'Web Camera Simulation Active'
                                          : 'Optical Sensor Active',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  // Positioning Oval Overlay
                  Container(
                    width: 220,
                    height: 290,
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(110),
                      border: Border.all(
                        color: _isSdkReady
                            ? AppColors.success
                            : Colors.white.withAlpha(180),
                        width: _isSdkReady ? 4 : 2,
                      ),
                    ),
                  ),

                  // Dynamic Position Status Pill
                  Positioned(
                    top: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _isSdkReady
                            ? AppColors.success.withAlpha(220)
                            : Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isSdkReady
                                ? Icons.check_circle_rounded
                                : Icons.center_focus_strong_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isSdkReady
                                ? 'Positioning Good • Ready'
                                : 'Adjust Face Position',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Live SDK Readiness Badges (driven strictly by SDK ValidationCode semantics)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ConditionBadge(
              label: 'Face Centered',
              status: faceStatus,
            ),
            _ConditionBadge(
              label: 'Good Light',
              status: lightStatus,
            ),
            _ConditionBadge(
              label: 'Holding Still',
              status: motionStatus,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Live SDK Validation Hint Card
        CarenCard(
          backgroundColor: AppColors.surfaceVariant,
          child: Row(
            children: [
              Icon(
                _isSdkReady ? Icons.check_rounded : Icons.info_outline_rounded,
                color: _isSdkReady ? AppColors.success : AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _validationHint,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Explicit Measurement Start Action (Only enabled when SDK reports readiness)
        CarenButton(
          label: _isSdkReady
              ? 'Start ${widget.target.displayName}'
              : 'Waiting for Positioning...',
          icon: Icons.play_arrow_rounded,
          variant: _isSdkReady
              ? CarenButtonVariant.primary
              : CarenButtonVariant.secondary,
          onPressed: _isSdkReady ? _beginActualMeasurement : null,
        ),
        const SizedBox(height: AppSpacing.xs),
      ],
    );
  }

  Widget _buildMeasuringView() {
    final progress =
        (_totalMeasurementSeconds - _secondsRemaining) /
        _totalMeasurementSeconds;

    return Column(
      children: [
        // Measurement Progress Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Observing Vitals...',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_secondsRemaining}s remaining',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: AppColors.surfaceVariant,
          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: AppSpacing.md),

        // Live Measurement Widget
        Expanded(
          child: VitalsMeasurementWidget(
            streamData: _latestStreamData,
            onCancel: _handleCancel,
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedView() {
    final pulse = _completedResult?.pulseRateBpm?.toInt();
    final breathing = _completedResult?.breathingRateBpm?.toInt();
    final isSuccess = _completedResult?.isSuccessful ?? false;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSuccess
                ? Icons.check_circle_rounded
                : Icons.warning_amber_rounded,
            size: 64,
            color: isSuccess ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            isSuccess ? 'Observation Complete' : 'Observation Incomplete',
            style: AppTypography.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isSuccess
                ? 'Camera observation completed successfully.'
                : (_completedResult?.failureReason ??
                      'Could not acquire stable signal. Please retry with even lighting.'),
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),

          if (isSuccess) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (pulse != null)
                  _MetricCard(
                    title: 'Pulse',
                    value: '$pulse',
                    unit: 'bpm',
                    icon: Icons.favorite_rounded,
                  ),
                if (breathing != null) ...[
                  const SizedBox(width: AppSpacing.md),
                  _MetricCard(
                    title: 'Breathing',
                    value: '$breathing',
                    unit: 'br/min',
                    icon: Icons.air_rounded,
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          const Text(
            'Personal wellness observation only. Not a medical diagnosis.',
            style: AppTypography.caption,
          ),
          const SizedBox(height: AppSpacing.xl),

          CarenButton(
            label: 'Use This Observation',
            icon: Icons.check,
            onPressed: () => context.pop(_completedResult),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () {
              setState(() {
                _phase = CameraPreflightPhase.preparation;
                _completedResult = null;
              });
            },
            child: const Text('Take Another Observation'),
          ),
        ],
      ),
    );
  }
}

class _GuidelineItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _GuidelineItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return CarenCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleSmall),
                const SizedBox(height: 2),
                Text(description, style: AppTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(title, style: AppTypography.caption),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 2),
              Text(unit, style: AppTypography.caption),
            ],
          ),
        ],
      ),
    );
  }
}

enum ValidationIndicatorStatus {
  pass,
  fail,
  pending,
}

/// Authoritative mapping of Presage SmartSpectra SDK 3.4.0 ValidationCode values
/// into semantically strict readiness indicators.
class SdkValidationSemantics {
  static const Set<String> faceCenteringFailures = {
    'NO_FACE_FOUND',
    'MULTIPLE_FACES_FOUND',
    'FACE_NOT_CENTERED',
    'FACE_SIZE_OUT_OF_RANGE',
    'FACE_TOO_CLOSE',
    'FACE_TOO_FAR',
    'FACE_TOO_HIGH',
    'FACE_TOO_LOW',
    'FACE_NOT_FORWARD',
  };

  static const Set<String> lightingFailures = {
    'TOO_DARK',
    'TOO_BRIGHT',
  };

  static const Set<String> motionFailures = {
    'EXCESSIVE_MOTION',
  };

  static ValidationIndicatorStatus evaluateFaceCentered(
      String? code, bool isFaceDetected) {
    if (code == null || code == 'CAMERA_TUNING' || code == 'FRAME_RATE_TOO_LOW') {
      return ValidationIndicatorStatus.pending;
    }
    if (code == 'OK') {
      return isFaceDetected
          ? ValidationIndicatorStatus.pass
          : ValidationIndicatorStatus.pending;
    }
    if (faceCenteringFailures.contains(code)) {
      return ValidationIndicatorStatus.fail;
    }
    // When code is for an unrelated issue (e.g. TOO_DARK), face centering cannot be confirmed
    return ValidationIndicatorStatus.pending;
  }

  static ValidationIndicatorStatus evaluateGoodLight(String? code) {
    if (code == null || code == 'CAMERA_TUNING' || code == 'FRAME_RATE_TOO_LOW') {
      return ValidationIndicatorStatus.pending;
    }
    if (code == 'OK') {
      return ValidationIndicatorStatus.pass;
    }
    if (lightingFailures.contains(code)) {
      return ValidationIndicatorStatus.fail;
    }
    // Unrelated issue (e.g. NO_FACE_FOUND, EXCESSIVE_MOTION): lighting is pending
    return ValidationIndicatorStatus.pending;
  }

  static ValidationIndicatorStatus evaluateHoldingStill(String? code) {
    if (code == null || code == 'CAMERA_TUNING' || code == 'FRAME_RATE_TOO_LOW') {
      return ValidationIndicatorStatus.pending;
    }
    if (code == 'OK') {
      return ValidationIndicatorStatus.pass;
    }
    if (motionFailures.contains(code)) {
      return ValidationIndicatorStatus.fail;
    }
    // Unrelated issue: motion stability is pending
    return ValidationIndicatorStatus.pending;
  }

  static bool isMeasurementReady({
    required String? code,
    required bool isFaceDetected,
    required String? errorCode,
    required String? processingStatus,
  }) {
    if (errorCode != null && errorCode.isNotEmpty) return false;
    if (processingStatus == 'ERROR') return false;
    if (!isFaceDetected) return false;
    return code == 'OK';
  }
}

class _ConditionBadge extends StatelessWidget {
  final String label;
  final ValidationIndicatorStatus status;

  const _ConditionBadge({
    required this.label,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;

    switch (status) {
      case ValidationIndicatorStatus.pass:
        color = AppColors.success;
        icon = Icons.check_circle_rounded;
        break;
      case ValidationIndicatorStatus.fail:
        color = AppColors.warning;
        icon = Icons.cancel_rounded;
        break;
      case ValidationIndicatorStatus.pending:
        color = AppColors.textSecondary;
        icon = Icons.radio_button_unchecked_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

