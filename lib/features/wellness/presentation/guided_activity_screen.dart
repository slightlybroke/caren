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
import '../../../services/speech/spoken_guidance_service.dart';
import '../data/wellness_repository.dart';
import '../domain/breathing_session.dart';
import '../domain/wellness_activity.dart';

class GuidedActivityScreen extends ConsumerStatefulWidget {
  final WellnessActivity activity;

  const GuidedActivityScreen({
    super.key,
    required this.activity,
  });

  @override
  ConsumerState<GuidedActivityScreen> createState() =>
      _GuidedActivityScreenState();
}

class _GuidedActivityScreenState extends ConsumerState<GuidedActivityScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late SpokenGuidanceService _speechService;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  int _currentStepIndex = 0;
  int _stepSecondsRemaining = 0;
  bool _isPaused = false;
  bool _isMuted = false;
  bool _isCompleted = false;

  Timer? _ticker;
  DateTime? _stepStartWallClock;
  int _stepAlreadyElapsed = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _speechService = ref.read(spokenGuidanceServiceProvider);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _setupStep(0);
  }

  void _setupStep(int index) {
    if (index >= widget.activity.steps.length) {
      _finishActivity();
      return;
    }

    final step = widget.activity.steps[index];
    void updateState() {
      _currentStepIndex = index;
      _stepSecondsRemaining = step.durationSeconds;
      _stepStartWallClock = DateTime.now();
      _stepAlreadyElapsed = 0;
    }

    if (mounted) {
      setState(updateState);
    } else {
      updateState();
    }

    // Spoken guidance with queue clearing for step transition
    _speechService.speak(step.spokenCue, clearQueue: true);

    _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted || _isPaused || _isCompleted) return;

      if (_stepStartWallClock == null) return;
      final elapsedNow =
          DateTime.now().difference(_stepStartWallClock!).inSeconds;
      final currentTotalElapsed = _stepAlreadyElapsed + elapsedNow;
      final stepDuration =
          widget.activity.steps[_currentStepIndex].durationSeconds;

      final remaining =
          (stepDuration - currentTotalElapsed).clamp(0, stepDuration);

      setState(() {
        _stepSecondsRemaining = remaining;
      });

      if (_stepSecondsRemaining <= 0) {
        if (_currentStepIndex < widget.activity.steps.length - 1) {
          _setupStep(_currentStepIndex + 1);
        } else {
          _finishActivity();
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isPaused && !_isCompleted) {
      // Re-sync on app foregrounding
      if (_stepStartWallClock != null) {
        final elapsed =
            DateTime.now().difference(_stepStartWallClock!).inSeconds;
        final total = _stepAlreadyElapsed + elapsed;
        final stepDuration =
            widget.activity.steps[_currentStepIndex].durationSeconds;
        setState(() {
          _stepSecondsRemaining =
              (stepDuration - total).clamp(0, stepDuration);
        });
      }
    }
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _pulseController.stop();
        _speechService.pause();
        if (_stepStartWallClock != null) {
          _stepAlreadyElapsed +=
              DateTime.now().difference(_stepStartWallClock!).inSeconds;
          _stepStartWallClock = null;
        }
      } else {
        _stepStartWallClock = DateTime.now();
        _pulseController.repeat(reverse: true);
        _speechService.resume();
      }
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _speechService.setMuted(_isMuted);
    });
  }

  void _nextStep() {
    if (_currentStepIndex < widget.activity.steps.length - 1) {
      _setupStep(_currentStepIndex + 1);
    } else {
      _finishActivity();
    }
  }

  void _previousStep() {
    if (_currentStepIndex > 0) {
      _setupStep(_currentStepIndex - 1);
    }
  }

  Future<void> _finishActivity() async {
    _ticker?.cancel();
    _pulseController.stop();
    setState(() {
      _isCompleted = true;
    });

    await _speechService.speak(
      'Your session is complete. Take a moment before returning to your day.',
      clearQueue: true,
    );

    final session = BreathingSession(
      id: 'sess_${DateTime.now().millisecondsSinceEpoch}',
      startTime: DateTime.now().subtract(
        Duration(minutes: widget.activity.defaultDurationMinutes),
      ),
      durationMinutes: widget.activity.defaultDurationMinutes,
      cadence: BreathingCadence.gentlePaced,
      customTitle: widget.activity.title,
      personalReflection: 'Completed ${widget.activity.title} exercise.',
      isCompleted: true,
    );

    await ref.read(wellnessRepositoryProvider).saveBreathingSession(session);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _pulseController.dispose();
    _speechService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompleted) {
      return _buildCompletionView();
    }

    final currentStep = widget.activity.steps[_currentStepIndex];
    final progress = (_currentStepIndex + 1) / widget.activity.steps.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activity.title),
        actions: [
          IconButton(
            tooltip: _isMuted ? 'Unmute voice guidance' : 'Mute voice guidance',
            icon: Icon(
              _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            ),
            onPressed: _toggleMute,
          ),
          IconButton(
            tooltip: _isPaused ? 'Resume' : 'Pause',
            icon: Icon(
              _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            ),
            onPressed: _togglePause,
          ),
          IconButton(
            tooltip: 'End Exercise',
            icon: const Icon(Icons.stop_rounded),
            onPressed: _finishActivity,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            children: [
              // Overall Progress Bar
              LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.surfaceVariant,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Step ${_currentStepIndex + 1} of ${widget.activity.steps.length}',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    AppFormatters.formatTimer(_stepSecondsRemaining),
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // Gentle Pulsing Visual Focus
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primaryContainer,
                        AppColors.primaryLight.withAlpha(40),
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(30),
                        blurRadius: 24,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      widget.activity.icon,
                      size: 54,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const Spacer(),

              // Step Guidance Card
              CarenCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentStep.title,
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      currentStep.instruction,
                      style: AppTypography.bodyLarge.copyWith(
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Step Navigation Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Previous'),
                    onPressed: _currentStepIndex > 0 ? _previousStep : null,
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    icon: Icon(
                      _currentStepIndex < widget.activity.steps.length - 1
                          ? Icons.arrow_forward
                          : Icons.check,
                      size: 18,
                    ),
                    label: Text(
                      _currentStepIndex < widget.activity.steps.length - 1
                          ? 'Next Step'
                          : 'Complete',
                    ),
                    onPressed: _nextStep,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionView() {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activity.title),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 68,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Session Complete',
                style: AppTypography.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'You completed ${widget.activity.title}. Private to you and saved to your wellness log.',
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              CarenButton(
                label: 'Back to Wellness',
                icon: Icons.spa_rounded,
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

