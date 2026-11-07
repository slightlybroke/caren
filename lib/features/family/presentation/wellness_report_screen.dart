import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/caren_card.dart';
import '../../../core/widgets/simulated_banner.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/family_repository.dart';
import '../domain/daily_check_in.dart';

class WellnessReportScreen extends ConsumerWidget {
  final String reportId;

  const WellnessReportScreen({super.key, required this.reportId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Look up in history
    final historyAsync = ref.watch(familyMemberHistoryProvider('mem_1'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wellness Report'),
      ),
      body: historyAsync.when(
        data: (checkIns) {
          final checkIn = checkIns.where((c) => c.id == reportId).firstOrNull ??
              DailyCheckIn(
                id: reportId,
                userId: 'mem_1',
                userName: 'Eleanor Vance',
                timestamp: DateTime.now().subtract(const Duration(hours: 3)),
                feeling: WellnessFeeling.feelingWell,
                sleep: SleepQuality.restful,
                tookPrescribedMedications: true,
                personalNote: 'Enjoyed an early walk and fresh tea.',
              );

          return SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                CarenCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            checkIn.userName,
                            style: AppTypography.titleLarge,
                          ),
                          StatusBadge(
                            label: checkIn.isSharedWithFamily ? 'Shared with Family' : 'Private',
                            type: checkIn.isSharedWithFamily ? BadgeType.success : BadgeType.neutral,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        AppFormatters.formatDateTime(checkIn.timestamp),
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Self-Reported Wellness Section
                Text(
                  'Self-Reported Wellness',
                  style: AppTypography.titleMedium.copyWith(color: AppColors.primaryDark),
                ),
                const SizedBox(height: AppSpacing.xs),
                CarenCard(
                  child: Column(
                    children: [
                      _DetailRow(
                        icon: Icons.sentiment_satisfied_alt_outlined,
                        label: 'Overall energy & feeling',
                        value: checkIn.feelingDisplay,
                      ),
                      const Divider(),
                      _DetailRow(
                        icon: Icons.bedtime_outlined,
                        label: 'Night sleep',
                        value: checkIn.sleepDisplay,
                      ),
                      const Divider(),
                      _DetailRow(
                        icon: Icons.medication_outlined,
                        label: 'Routines / vitamins',
                        value: checkIn.tookPrescribedMedications ? 'Completed as planned' : 'Not recorded',
                      ),
                      if (checkIn.personalNote != null) ...[
                        const Divider(),
                        _DetailRow(
                          icon: Icons.note_outlined,
                          label: 'Personal reflection',
                          value: '“${checkIn.personalNote!}”',
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Camera-Derived Spot-Check Section (Distinct from self-reported)
                Text(
                  'Camera-Based Spot Check (Optional)',
                  style: AppTypography.titleMedium.copyWith(color: AppColors.primaryDark),
                ),
                const SizedBox(height: AppSpacing.xs),

                if (checkIn.optionalMeasurement == null)
                  const CarenCard(
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.textMuted),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'No camera measurement was taken for this check-in. Camera spot-checks are always optional.',
                            style: AppTypography.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  if (checkIn.optionalMeasurement!.isSimulated) ...[
                    const SimulatedBanner(),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  CarenCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Observed Spot Signals', style: AppTypography.titleMedium),
                            if (checkIn.optionalMeasurement!.isSimulated)
                              const StatusBadge(label: 'MOCK DATA', type: BadgeType.warning),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: _MetricTile(
                                label: 'Pulse Rate',
                                value: checkIn.optionalMeasurement!.pulseRateBpm != null
                                    ? '${checkIn.optionalMeasurement!.pulseRateBpm!.toInt()} bpm'
                                    : '--',
                                icon: Icons.favorite_border_rounded,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _MetricTile(
                                label: 'Breathing Rhythm',
                                value: checkIn.optionalMeasurement!.breathingRateBpm != null
                                    ? '${checkIn.optionalMeasurement!.breathingRateBpm!.toInt()} br/min'
                                    : '--',
                                icon: Icons.air_rounded,
                              ),
                            ),
                          ],
                        ),
                        if (checkIn.optionalMeasurement!.qualityScore != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Native SDK signal confidence: ${(checkIn.optionalMeasurement!.qualityScore! * 100).toInt()}%',
                            style: AppTypography.caption,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.sm),
                        const Text(
                          'Important: Spot checks provide personal observation indicators and are never intended to diagnose, treat, or replace medical consultation.',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.caption),
                const SizedBox(height: 2),
                Text(value, style: AppTypography.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(label, style: AppTypography.caption),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.displayMedium.copyWith(color: AppColors.primaryDark),
          ),
        ],
      ),
    );
  }
}

