import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/caren_button.dart';
import '../../../core/widgets/caren_card.dart';
import '../../../core/widgets/simulated_banner.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../services/vitals/vitals_models.dart';
import '../../../services/vitals/vitals_provider.dart';
import '../data/wellness_repository.dart';
import '../domain/breathing_session.dart';

class GuidedBreathingScreen extends ConsumerStatefulWidget {
  final int initialDurationMinutes;

  const GuidedBreathingScreen({
    super.key,
    this.initialDurationMinutes = 3,
  });

  @override
  ConsumerState<GuidedBreathingScreen> createState() => _GuidedBreathingScreenState();
}

class _GuidedBreathingScreenState extends ConsumerState<GuidedBreathingScreen>
    with SingleTickerProviderStateMixin {
  late int _durationMinutes;
  BreathingCadence _cadence = BreathingCadence.gentlePaced;

  // Session phase: setup -> preCheck -> breathing -> postCheck -> summary
  String _phase = 'setup';
  Timer? _sessionTimer;
  int _secondsRemaining = 0;
  bool _isPaused = false;

  // Breathing animation (4s inhale, 6s exhale)
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  String _breathPrompt = 'Inhale gently...';

  // Optional measurements
  MeasurementResult? _preVitals;
  MeasurementResult? _postVitals;
  bool _isMeasuringVitals = false;
  VitalsStreamData? _vitalsData;
  StreamSubscription<VitalsStreamData>? _vitalsSub;

  @override
  void initState() {
    super.initState();
    _durationMinutes = widget.initialDurationMinutes;
    _secondsRemaining = _durationMinutes * 60;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // 4s inhale + 6s exhale
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.75, end: 1.2), weight: 40), // Inhale 40%
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.75), weight: 60), // Exhale 60%
    ]).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOut));

    _animController.addListener(() {
      if (!mounted) return;
      if (_animController.value < 0.4) {
        if (_breathPrompt != 'Inhale gently...') {
          setState(() => _breathPrompt = 'Inhale gently...');
        }
      } else {
        if (_breathPrompt != 'Exhale slowly...') {
          setState(() => _breathPrompt = 'Exhale slowly...');
        }
      }
    });

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animController.repeat();
      }
    });
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _vitalsSub?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _startBreathing() {
    setState(() {
      _phase = 'breathing';
      _isPaused = false;
      _secondsRemaining = _durationMinutes * 60;
    });

    _animController.forward(from: 0.0);
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (!_isPaused) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            timer.cancel();
            _animController.stop();
            _promptPostCheck();
          }
        });
      }
    });
  }

  void _promptPostCheck() {
    setState(() => _phase = 'postCheck');
  }

  void _runVitalsSpotCheck({required bool isPre}) async {
    final provider = ref.read(vitalsProvider);
    setState(() {
      _isMeasuringVitals = true;
      _vitalsData = null;
    });

    final hasPermission = await provider.requestCameraPermission();
    if (!hasPermission) {
      setState(() => _isMeasuringVitals = false);
      return;
    }

    final stream = provider.startMeasurement(
      config: const MeasurementConfig(
        target: MeasurementTarget.pulseOnly,
        durationSeconds: 15, // Meets 12s confidence window
      ),
    );

    _vitalsSub = stream.listen(
      (data) {
        if (mounted) {
          setState(() => _vitalsData = data);
          if (data.progress >= 1.0) {
            _finishVitalsCheck(isPre: isPre);
          }
        }
      },
      onError: (_) {
        if (mounted) setState(() => _isMeasuringVitals = false);
      },
    );
  }

  void _finishVitalsCheck({required bool isPre}) async {
    _vitalsSub?.cancel();
    final provider = ref.read(vitalsProvider);
    final result = await provider.stopMeasurement();
    if (mounted) {
      setState(() {
        _isMeasuringVitals = false;
        if (isPre) {
          _preVitals = result;
          _startBreathing();
        } else {
          _postVitals = result;
          _finishSession();
        }
      });
    }
  }

  void _finishSession() async {
    _sessionTimer?.cancel();
    _animController.stop();

    final session = BreathingSession(
      id: 'sess_${DateTime.now().millisecondsSinceEpoch}',
      startTime: DateTime.now().subtract(Duration(minutes: _durationMinutes)),
      durationMinutes: _durationMinutes,
      cadence: _cadence,
      preSessionVitals: _preVitals,
      postSessionVitals: _postVitals,
      personalReflection: 'Completed relaxation session.',
      isCompleted: true,
    );

    await ref.read(wellnessRepositoryProvider).saveBreathingSession(session);
    if (mounted) {
      setState(() => _phase = 'summary');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guided Breathing'),
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
      case 'setup':
        return _buildSetupView();
      case 'breathing':
        return _buildBreathingView();
      case 'postCheck':
        return _buildPostCheckView();
      case 'summary':
        return _buildSummaryView();
      default:
        return _buildSetupView();
    }
  }

  Widget _buildSetupView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choose Session Duration', style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Gentle breathing calms the nervous system. Take whatever time feels comfortable right now.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Duration Selector
          Row(
            children: [2, 3, 5, 10].map((mins) {
              final isSelected = _durationMinutes == mins;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text('${mins}m'),
                    selected: isSelected,
                    selectedColor: AppColors.primaryContainer,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _durationMinutes = mins;
                          _secondsRemaining = mins * 60;
                        });
                      }
                    },
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Cadence Selector
          Text('Breathing Rhythm', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          CarenCard(
            onTap: () => setState(() => _cadence = BreathingCadence.gentlePaced),
            borderColor: _cadence == BreathingCadence.gentlePaced ? AppColors.primary : AppColors.border,
            backgroundColor: _cadence == BreathingCadence.gentlePaced
                ? AppColors.primaryContainer.withAlpha(50)
                : AppColors.surface,
            child: Row(
              children: [
                Icon(
                  _cadence == BreathingCadence.gentlePaced
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Gentle Paced (4s Inhale, 6s Exhale)', style: AppTypography.labelLarge),
                      Text('Extended exhalations encourage relaxation response.', style: AppTypography.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          CarenCard(
            onTap: () => setState(() => _cadence = BreathingCadence.coherentRelaxation),
            borderColor: _cadence == BreathingCadence.coherentRelaxation ? AppColors.primary : AppColors.border,
            backgroundColor: _cadence == BreathingCadence.coherentRelaxation
                ? AppColors.primaryContainer.withAlpha(50)
                : AppColors.surface,
            child: Row(
              children: [
                Icon(
                  _cadence == BreathingCadence.coherentRelaxation
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Coherent Flow (5s Inhale, 5s Exhale)', style: AppTypography.labelLarge),
                      Text('Balanced rhythm for sustained focus and calm.', style: AppTypography.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Optional Pre-check
          CarenCard(
            backgroundColor: AppColors.surfaceVariant,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.videocam_outlined, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.xs),
                    Text('Optional Pre-Session Spot Check', style: AppTypography.titleMedium),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Record pulse before starting to observe how gentle breathing affects your body.',
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                if (_isMeasuringVitals) ...[
                  const SimulatedBanner(),
                  const SizedBox(height: AppSpacing.sm),
                  LinearProgressIndicator(value: _vitalsData?.progress ?? 0.0),
                ] else ...[
                  CarenButton(
                    label: 'Check Pulse First (15s • 12s window)',
                    variant: CarenButtonVariant.outline,
                    onPressed: () => _runVitalsSpotCheck(isPre: true),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          CarenButton(
            label: 'Begin Breathing Session',
            icon: Icons.play_arrow_rounded,
            onPressed: _startBreathing,
          ),
        ],
      ),
    );
  }

  Widget _buildBreathingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$_durationMinutes min Session',
              style: AppTypography.titleMedium.copyWith(color: AppColors.textMuted),
            ),
            Text(
              AppFormatters.formatDurationMinutes(_secondsRemaining),
              style: AppTypography.displayMedium.copyWith(color: AppColors.primary),
            ),
          ],
        ),
        Center(
          child: Column(
            children: [
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.secondaryLight.withAlpha(90),
                            AppColors.primary.withAlpha(40),
                          ],
                        ),
                        border: Border.all(
                          color: AppColors.primary,
                          width: 3.0,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _breathPrompt,
                          textAlign: TextAlign.center,
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              const Text(
                'Focus gently on your breath flowing in and out.',
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: CarenButton(
                label: _isPaused ? 'Resume' : 'Pause',
                variant: CarenButtonVariant.outline,
                onPressed: () {
                  setState(() {
                    _isPaused = !_isPaused;
                    if (_isPaused) {
                      _animController.stop();
                    } else {
                      _animController.repeat();
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: CarenButton(
                label: 'Finish Early',
                variant: CarenButtonVariant.text,
                onPressed: _promptPostCheck,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPostCheckView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle_outline_rounded, color: AppColors.secondary, size: 56),
        const SizedBox(height: AppSpacing.md),
        Text('Session Complete', style: AppTypography.displayMedium),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Take a moment to notice how you feel. Would you like to record a quick post-session spot check?',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xl),
        if (_isMeasuringVitals) ...[
          const SimulatedBanner(),
          const SizedBox(height: AppSpacing.md),
          LinearProgressIndicator(value: _vitalsData?.progress ?? 0.0),
          const SizedBox(height: AppSpacing.sm),
          Text(_vitalsData?.statusText ?? 'Measuring...', style: AppTypography.caption),
        ] else ...[
          CarenButton(
            label: 'Take 15s Post-Session Check (12s window)',
            icon: Icons.camera_alt_outlined,
            onPressed: () => _runVitalsSpotCheck(isPre: false),
          ),
          const SizedBox(height: AppSpacing.sm),
          CarenButton(
            label: 'Skip and View Summary',
            variant: CarenButtonVariant.text,
            onPressed: _finishSession,
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Session Summary', style: AppTypography.displayMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Your breathing session has been saved to your private personal history.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_postVitals?.isSimulated == true || _preVitals?.isSimulated == true) ...[
            const SimulatedBanner(),
            const SizedBox(height: AppSpacing.md),
          ],
          CarenCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Completed Duration', style: AppTypography.titleMedium),
                    StatusBadge(label: '$_durationMinutes minutes', type: BadgeType.success),
                  ],
                ),
                if (_preVitals != null || _postVitals != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  const Divider(),
                  const SizedBox(height: AppSpacing.sm),
                  const Text('Observed Spot Comparison', style: AppTypography.labelLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Before Session', style: AppTypography.caption),
                          Text(
                            _preVitals?.pulseRateBpm != null ? '${_preVitals!.pulseRateBpm!.toInt()} bpm' : '--',
                            style: AppTypography.titleLarge,
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_forward_rounded, color: AppColors.textMuted),
                      Column(
                        children: [
                          const Text('After Session', style: AppTypography.caption),
                          Text(
                            _postVitals?.pulseRateBpm != null ? '${_postVitals!.pulseRateBpm!.toInt()} bpm' : '--',
                            style: AppTypography.titleLarge.copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          CarenButton(
            label: 'Return to Me Dashboard',
            onPressed: () => context.go('/me'),
          ),
        ],
      ),
    );
  }
}

