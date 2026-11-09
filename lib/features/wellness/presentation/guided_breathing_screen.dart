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

class GuidedBreathingScreen extends ConsumerStatefulWidget {
  static const int minSessionDurationMinutes = 2;
  static const int maxSessionDurationMinutes = 60;

  final int initialDurationMinutes;

  const GuidedBreathingScreen({super.key, this.initialDurationMinutes = 2});

  @override
  ConsumerState<GuidedBreathingScreen> createState() =>
      _GuidedBreathingScreenState();
}

class _GuidedBreathingScreenState extends ConsumerState<GuidedBreathingScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late int _durationMinutes;
  bool _isCustomDuration = false;
  BreathingCadence _cadence = BreathingCadence.gentlePaced;

  // Session phase: 'setup' -> 'breathing' -> 'summary'
  String _phase = 'setup';
  Timer? _sessionTimer;
  int _secondsRemaining = 0;
  bool _isPaused = false;
  bool _isMuted = false;

  // Accurate wall-clock timing across app lifecycle
  DateTime? _sessionStartWallClock;
  int _secondsAlreadyElapsed = 0;

  // Breathing animation & cues
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  String _breathPrompt = 'Prepare to breathe...';
  String _lastSpokenPhase = '';

  late SpokenGuidanceService _speechService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _speechService = ref.read(spokenGuidanceServiceProvider);
    _durationMinutes = widget.initialDurationMinutes.clamp(
      GuidedBreathingScreen.minSessionDurationMinutes,
      GuidedBreathingScreen.maxSessionDurationMinutes,
    );
    if (![2, 5, 15].contains(_durationMinutes)) {
      _isCustomDuration = true;
    }
    _secondsRemaining = _durationMinutes * 60;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // 4s inhale + 6s exhale
    );

    _scaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween(begin: 0.8, end: 1.25),
            weight: 40,
          ), // Inhale
          TweenSequenceItem(
            tween: Tween(begin: 1.25, end: 0.8),
            weight: 60,
          ), // Exhale
        ]).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
        );

    _animController.addListener(_onAnimationTick);
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed &&
          _phase == 'breathing' &&
          !_isPaused) {
        _animController.forward(from: 0.0);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _phase == 'breathing' &&
        !_isPaused) {
      _syncRemainingTime();
    }
  }

  void _syncRemainingTime() {
    if (_sessionStartWallClock == null) return;
    final elapsedNow = DateTime.now()
        .difference(_sessionStartWallClock!)
        .inSeconds;
    final totalElapsed = _secondsAlreadyElapsed + elapsedNow;
    final totalTargetSeconds = _durationMinutes * 60;
    final remaining = (totalTargetSeconds - totalElapsed).clamp(
      0,
      totalTargetSeconds,
    );

    if (mounted) {
      setState(() {
        _secondsRemaining = remaining;
      });
      if (_secondsRemaining <= 0) {
        _finishSession();
      }
    }
  }

  void _onAnimationTick() {
    if (!mounted || _phase != 'breathing' || _isPaused) return;

    final progress = _animController.value;

    if (progress < 0.40) {
      // Inhale phase
      if (_breathPrompt != 'Breathe in slowly') {
        setState(() => _breathPrompt = 'Breathe in slowly');
        if (_lastSpokenPhase != 'inhale') {
          _lastSpokenPhase = 'inhale';
          _speechService.speak('Breathe in slowly');
        }
      }
    } else if (progress >= 0.40 && progress < 0.45) {
      // Gentle transition hold
      if (_breathPrompt != 'Hold gently') {
        setState(() => _breathPrompt = 'Hold gently');
        if (_lastSpokenPhase != 'hold') {
          _lastSpokenPhase = 'hold';
          _speechService.speak('Hold gently');
        }
      }
    } else if (progress >= 0.45 && progress < 0.90) {
      // Exhale phase
      if (_breathPrompt != 'Now breathe out slowly') {
        setState(() => _breathPrompt = 'Now breathe out slowly');
        if (_lastSpokenPhase != 'exhale') {
          _lastSpokenPhase = 'exhale';
          _speechService.speak('Now breathe out slowly');
        }
      }
    } else {
      // Relax / rest phase
      if (_breathPrompt != 'Let your body relax') {
        setState(() => _breathPrompt = 'Let your body relax');
        if (_lastSpokenPhase != 'relax') {
          _lastSpokenPhase = 'relax';
          _speechService.speak('Let your body relax');
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionTimer?.cancel();
    _animController.dispose();
    // Immediate voice cancellation on exit using cached service reference
    _speechService.stop();
    super.dispose();
  }

  void _toggleMute() {
    final newMuted = !_isMuted;
    _speechService.setMuted(newMuted);
    setState(() {
      _isMuted = newMuted;
    });
  }

  Future<void> _startBreathing() async {
    _speechService.setMuted(_isMuted);

    setState(() {
      _phase = 'breathing';
      _isPaused = false;
      _secondsAlreadyElapsed = 0;
      _sessionStartWallClock = DateTime.now();
      _secondsRemaining = _durationMinutes * 60;
      _breathPrompt = 'Find a comfortable position...';
      _lastSpokenPhase = 'intro';
    });

    // Opening spoken guidance
    await _speechService.speak(
      "Let's begin. Find a comfortable position and relax your shoulders.",
    );

    if (!mounted || _phase != 'breathing') return;

    _animController.forward(from: 0.0);

    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) return;
      if (!_isPaused) {
        _syncRemainingTime();
      }
    });
  }

  void _togglePause() {
    final speechService = ref.read(spokenGuidanceServiceProvider);
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _animController.stop();
        speechService.stop();
        if (_sessionStartWallClock != null) {
          _secondsAlreadyElapsed += DateTime.now()
              .difference(_sessionStartWallClock!)
              .inSeconds;
          _sessionStartWallClock = null;
        }
      } else {
        _sessionStartWallClock = DateTime.now();
        _animController.forward();
      }
    });
  }

  Future<void> _finishSession() async {
    _sessionTimer?.cancel();
    _animController.stop();

    _speechService.speak(
      'Your session is complete. Take a moment before returning to your day.',
    );

    final session = BreathingSession(
      id: 'sess_${DateTime.now().millisecondsSinceEpoch}',
      startTime: DateTime.now().subtract(Duration(minutes: _durationMinutes)),
      durationMinutes: _durationMinutes,
      cadence: _cadence,
      personalReflection: 'Completed relaxation session.',
      isCompleted: true,
    );

    await ref.read(wellnessRepositoryProvider).saveBreathingSession(session);
    if (mounted) {
      setState(() => _phase = 'summary');
    }
  }

  Future<void> _showCustomDurationDialog() async {
    final textController = TextEditingController(text: '$_durationMinutes');
    String? validationMessage;

    final selectedMinutes = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Custom Session Duration'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter desired duration between ${GuidedBreathingScreen.minSessionDurationMinutes} and ${GuidedBreathingScreen.maxSessionDurationMinutes} minutes:',
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: textController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(
                    suffixText: 'mins',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                ),
                if (validationMessage != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    validationMessage!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final text = textController.text.trim();
                  final val = int.tryParse(text);
                  if (val == null) {
                    setDialogState(() {
                      validationMessage =
                          'Please enter a valid whole number of minutes.';
                    });
                    return;
                  }
                  if (val < GuidedBreathingScreen.minSessionDurationMinutes) {
                    setDialogState(() {
                      validationMessage =
                          'Your session must be at least ${GuidedBreathingScreen.minSessionDurationMinutes} minutes long.';
                    });
                    return;
                  }
                  if (val > GuidedBreathingScreen.maxSessionDurationMinutes) {
                    textController.text =
                        '${GuidedBreathingScreen.maxSessionDurationMinutes}';
                    setDialogState(() {
                      validationMessage =
                          "${GuidedBreathingScreen.maxSessionDurationMinutes} minutes is the longest session you can choose. We've set it to the maximum.";
                    });
                    return;
                  }
                  Navigator.pop(ctx, val);
                },
                child: const Text('Set Duration'),
              ),
            ],
          );
        },
      ),
    );

    if (selectedMinutes != null && mounted) {
      final clamped = selectedMinutes.clamp(
        GuidedBreathingScreen.minSessionDurationMinutes,
        GuidedBreathingScreen.maxSessionDurationMinutes,
      );
      setState(() {
        _durationMinutes = clamped;
        _isCustomDuration = true;
        _secondsRemaining = clamped * 60;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guided Breathing'),
        actions: [
          IconButton(
            tooltip: _isMuted ? 'Unmute voice guidance' : 'Mute voice guidance',
            icon: Icon(
              _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            ),
            onPressed: _toggleMute,
          ),
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
      case 'setup':
        return _buildSetupView();
      case 'breathing':
        return _buildBreathingView();
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
            'Gentle breathing calms the autonomic nervous system. Works standalone without requiring camera access.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Duration Selector: 2m, 5m, 15m, and Custom
          Row(
            children: [
              _buildDurationChip(2, '2m'),
              const SizedBox(width: 8),
              _buildDurationChip(5, '5m'),
              const SizedBox(width: 8),
              _buildDurationChip(15, '15m'),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: Text(
                    _isCustomDuration
                        ? '${_durationMinutes}m (Custom)'
                        : 'Custom',
                  ),
                  selected: _isCustomDuration,
                  selectedColor: AppColors.primaryContainer,
                  labelStyle: TextStyle(
                    color: _isCustomDuration
                        ? AppColors.primary
                        : AppColors.textPrimary,
                    fontWeight: _isCustomDuration
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                  onSelected: (val) {
                    _showCustomDurationDialog();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Cadence Selector
          Text('Breathing Rhythm', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          CarenCard(
            onTap: () =>
                setState(() => _cadence = BreathingCadence.gentlePaced),
            borderColor: _cadence == BreathingCadence.gentlePaced
                ? AppColors.primary
                : AppColors.border,
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
                      Text(
                        'Gentle Paced (4s Inhale, 6s Exhale)',
                        style: AppTypography.labelLarge,
                      ),
                      Text(
                        'Extended exhalations encourage parasympathetic relaxation.',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          CarenCard(
            onTap: () =>
                setState(() => _cadence = BreathingCadence.coherentRelaxation),
            borderColor: _cadence == BreathingCadence.coherentRelaxation
                ? AppColors.primary
                : AppColors.border,
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
                      Text(
                        'Coherent Flow (5s Inhale, 5s Exhale)',
                        style: AppTypography.labelLarge,
                      ),
                      Text(
                        'Balanced cadence for heart-rate variability and calm focus.',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Spoken Guidance Info Box
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                Icon(
                  _isMuted
                      ? Icons.volume_off_rounded
                      : Icons.record_voice_over_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _isMuted
                        ? 'Spoken guidance is currently muted. You can unmute anytime.'
                        : 'Spoken guidance will lead each breath. You can mute at any time using the speaker icon.',
                    style: AppTypography.caption,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Standalone Start Action
          CarenButton(
            label: 'Start Breathing Session (${_durationMinutes}m)',
            icon: Icons.spa_rounded,
            onPressed: _startBreathing,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildDurationChip(int mins, String label) {
    final isSelected = !_isCustomDuration && _durationMinutes == mins;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      onSelected: (val) {
        if (val) {
          setState(() {
            _isCustomDuration = false;
            _durationMinutes = mins;
            _secondsRemaining = mins * 60;
          });
        }
      },
    );
  }

  Widget _buildBreathingView() {
    return Column(
      children: [
        // Top Timer & Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppFormatters.formatTimer(_secondsRemaining),
              style: AppTypography.displaySmall.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                IconButton(
                  tooltip: _isMuted ? 'Unmute' : 'Mute',
                  icon: Icon(
                    _isMuted
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
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
                  tooltip: 'End Session Early',
                  icon: const Icon(Icons.stop_rounded),
                  onPressed: _finishSession,
                ),
              ],
            ),
          ],
        ),
        const Spacer(),

        // Animated Breathing Orb
        AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return Transform.scale(
              scale: _isPaused ? 1.0 : _scaleAnimation.value,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withAlpha(180),
                      AppColors.primaryLight.withAlpha(100),
                      AppColors.surfaceVariant.withAlpha(20),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(60),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      _breathPrompt,
                      textAlign: TextAlign.center,
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const Spacer(),

        // Status Card
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Text(
            _isPaused
                ? 'Session paused. Tap play to resume.'
                : 'Follow the circle rhythm • Breathe naturally without strain',
            style: AppTypography.caption,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buildSummaryView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: AppColors.primary,
          size: 64,
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Session Complete', style: AppTypography.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'You completed $_durationMinutes minutes of mindful breathing.',
          style: AppTypography.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        CarenButton(label: 'Back to Wellness', onPressed: () => context.pop()),
      ],
    );
  }
}
