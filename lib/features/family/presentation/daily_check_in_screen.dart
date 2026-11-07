import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/caren_button.dart';
import '../../../core/widgets/caren_card.dart';
import '../../../core/widgets/simulated_banner.dart';
import '../../../core/widgets/vitals_measurement_widget.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../services/vitals/vitals_models.dart';
import '../../../services/vitals/vitals_provider.dart';
import '../data/family_repository.dart';
import '../domain/daily_check_in.dart';

class DailyCheckInScreen extends ConsumerStatefulWidget {
  const DailyCheckInScreen({super.key});

  @override
  ConsumerState<DailyCheckInScreen> createState() => _DailyCheckInScreenState();
}

class _DailyCheckInScreenState extends ConsumerState<DailyCheckInScreen> {
  WellnessFeeling _feeling = WellnessFeeling.feelingWell;
  SleepQuality _sleep = SleepQuality.restful;
  bool _tookMeds = true;
  final TextEditingController _noteController = TextEditingController();
  bool _shareWithFamily = true;

  // Camera Spot Check State (Metric-Aware)
  MeasurementTarget _selectedTarget = MeasurementTarget.pulseOnly;
  bool _showCameraMeasurement = false;
  bool _isMeasuring = false;
  bool _permissionDenied = false;
  VitalsStreamData? _latestStreamData;
  StreamSubscription<VitalsStreamData>? _streamSub;
  MeasurementResult? _completedMeasurement;
  String? _measurementError;

  @override
  void dispose() {
    _streamSub?.cancel();
    _noteController.dispose();
    super.dispose();
  }

  void _startCameraSpotCheck() async {
    final provider = ref.read(vitalsProvider);
    setState(() {
      _showCameraMeasurement = true;
      _permissionDenied = false;
      _measurementError = null;
    });

    final hasPermission = await provider.requestCameraPermission();
    if (!hasPermission) {
      if (mounted) {
        setState(() {
          _permissionDenied = true;
          _isMeasuring = false;
        });
      }
      return;
    }

    setState(() {
      _isMeasuring = true;
      _completedMeasurement = null;
    });

    final stream = provider.startMeasurement(
      config: MeasurementConfig(
        target: _selectedTarget,
        durationSeconds: _selectedTarget.defaultDurationSeconds,
      ),
    );

    _streamSub = stream.listen(
      (data) {
        if (mounted) {
          setState(() {
            _latestStreamData = data;
          });
          if (data.progress >= 1.0) {
            _finishMeasurement();
          }
        }
      },
      onError: (err) {
        if (mounted) {
          setState(() {
            _isMeasuring = false;
            _measurementError = 'Spot check could not be completed clearly. You may try again or submit self-reported data.';
          });
        }
      },
    );
  }

  void _finishMeasurement() async {
    _streamSub?.cancel();
    final provider = ref.read(vitalsProvider);
    final result = await provider.stopMeasurement();
    if (mounted) {
      setState(() {
        _isMeasuring = false;
        _completedMeasurement = result;
      });
    }
  }

  void _cancelCameraMeasurement() async {
    _streamSub?.cancel();
    final provider = ref.read(vitalsProvider);
    await provider.cancelMeasurement();
    if (mounted) {
      setState(() {
        _isMeasuring = false;
        _showCameraMeasurement = false;
      });
    }
  }

  void _submitCheckIn() async {
    final newCheckIn = DailyCheckIn(
      id: 'chk_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'user_self',
      userName: 'Julian Vance',
      timestamp: DateTime.now(),
      feeling: _feeling,
      sleep: _sleep,
      tookPrescribedMedications: _tookMeds,
      personalNote: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      optionalMeasurement: _completedMeasurement,
      isSharedWithFamily: _shareWithFamily,
    );

    await ref.read(familyRepositoryProvider).submitCheckIn(newCheckIn);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Daily check-in saved.')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Check-In'),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How are you feeling today?',
              style: AppTypography.titleLarge.copyWith(color: AppColors.primaryDark),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'A brief self-reflection to stay connected with loved ones.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Step 1: Self-Reported Feeling
            Text('Overall Energy & Well-being', style: AppTypography.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: WellnessFeeling.values.map((f) {
                final isSelected = _feeling == f;
                return ChoiceChip(
                  label: Text(_getFeelingLabel(f)),
                  selected: isSelected,
                  selectedColor: AppColors.primaryContainer,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _feeling = f);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Step 2: Sleep Quality
            Text('Last Night’s Sleep', style: AppTypography.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SleepQuality.values.map((s) {
                final isSelected = _sleep == s;
                return ChoiceChip(
                  label: Text(_getSleepLabel(s)),
                  selected: isSelected,
                  selectedColor: AppColors.primaryContainer,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _sleep = s);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Step 3: Prescribed Medications
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Prescribed routines or vitamins taken', style: AppTypography.labelLarge),
              subtitle: const Text('Keeps a gentle log for your own peace of mind', style: AppTypography.caption),
              value: _tookMeds,
              activeThumbColor: AppColors.primary,
              onChanged: (val) => setState(() => _tookMeds = val),
            ),
            const SizedBox(height: AppSpacing.md),

            // Optional Personal Note
            Text('Personal Note (Optional)', style: AppTypography.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g. Took a sunny stroll this morning...',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Step 4: Optional Camera Wellness Spot-Check (Clear distinction)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.videocam_outlined, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Optional Camera Spot-Check',
                        style: AppTypography.titleMedium.copyWith(color: AppColors.primaryDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'Optional spot check for pulse and breathing rhythm via camera. Video is processed locally in real time and is NEVER saved or uploaded.',
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  if (!_showCameraMeasurement && _completedMeasurement == null) ...[
                    Text('Select Measurement Window:', style: AppTypography.labelMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Pulse Only (15s • 12s window)'),
                          selected: _selectedTarget == MeasurementTarget.pulseOnly,
                          selectedColor: AppColors.primaryContainer,
                          onSelected: (val) {
                            if (val) setState(() => _selectedTarget = MeasurementTarget.pulseOnly);
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Pulse & Breathing (30s window)'),
                          selected: _selectedTarget == MeasurementTarget.breathingAndPulse,
                          selectedColor: AppColors.primaryContainer,
                          onSelected: (val) {
                            if (val) setState(() => _selectedTarget = MeasurementTarget.breathingAndPulse);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _selectedTarget.description,
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    CarenButton(
                      label: 'Begin ${_selectedTarget.displayName}',
                      icon: Icons.camera_alt_outlined,
                      variant: CarenButtonVariant.outline,
                      onPressed: _startCameraSpotCheck,
                    ),
                  ],

                  if (_permissionDenied) ...[
                    const SizedBox(height: AppSpacing.sm),
                    CarenPermissionDeniedView(
                      onGrantPermission: _startCameraSpotCheck,
                      onContinueWithout: () => setState(() => _showCameraMeasurement = false),
                    ),
                  ],

                  if (_measurementError != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    CarenErrorView(
                      message: _measurementError!,
                      onRetry: _startCameraSpotCheck,
                    ),
                  ],

                  if (_isMeasuring) ...[
                    const SizedBox(height: AppSpacing.sm),
                    VitalsMeasurementWidget(
                      streamData: _latestStreamData,
                      onCancel: _cancelCameraMeasurement,
                    ),
                  ],

                  if (_completedMeasurement != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    if (_completedMeasurement!.isSimulated) const SimulatedBanner(),
                    const SizedBox(height: AppSpacing.sm),
                    CarenCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const StatusBadge(
                            label: 'Spot Check Completed',
                            type: BadgeType.success,
                            icon: Icons.check_circle_outline,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            _completedMeasurement!.summaryLabel,
                            style: AppTypography.titleMedium,
                          ),
                          if (_completedMeasurement!.qualityScore != null)
                            Text(
                              'Signal quality: ${(_completedMeasurement!.qualityScore! * 100).toInt()}%',
                              style: AppTypography.caption,
                            ),
                          const SizedBox(height: 4),
                          const Text(
                            'Notice: Camera observations are for personal wellness tracking only and not a clinical diagnosis.',
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Explicit Sharing Consent
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Share this check-in with your Family Circle', style: AppTypography.labelLarge),
              subtitle: const Text('You can revoke sharing at any time in privacy settings', style: AppTypography.caption),
              value: _shareWithFamily,
              activeColor: AppColors.primary,
              onChanged: (val) => setState(() => _shareWithFamily = val ?? true),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Submit Button
            CarenButton(
              label: 'Save & Share Check-In',
              onPressed: _submitCheckIn,
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  String _getFeelingLabel(WellnessFeeling f) {
    switch (f) {
      case WellnessFeeling.feelingWell:
        return 'Feeling Well';
      case WellnessFeeling.doingFine:
        return 'Doing Fine';
      case WellnessFeeling.aBitTired:
        return 'A Bit Tired';
      case WellnessFeeling.restingToday:
        return 'Resting Today';
    }
  }

  String _getSleepLabel(SleepQuality s) {
    switch (s) {
      case SleepQuality.restful:
        return 'Rested Well';
      case SleepQuality.interrupted:
        return 'Some Awakenings';
      case SleepQuality.restless:
        return 'Restless';
    }
  }
}

