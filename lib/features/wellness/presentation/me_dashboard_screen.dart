import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/caren_app_bar.dart';
import '../../../core/widgets/caren_button.dart';
import '../../../core/widgets/caren_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/wellness_repository.dart';
import '../domain/wellness_activity.dart';

class MeDashboardScreen extends ConsumerWidget {
  const MeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(recentBreathingSessionsProvider);

    return Scaffold(
      appBar: CarenAppBar(
        title: 'Me',
        actions: [
          IconButton(
            tooltip: 'Personal Trends & History',
            icon: const Icon(Icons.history_rounded),
            onPressed: () => context.push('/me/history'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Private by Default Shield
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined,
                      size: 20, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Strictly Private: Sessions and self-observations here are never shared with family members.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 1. Guided Breathing Section
            Text('Guided Breathing', style: AppTypography.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            CarenCard(
              backgroundColor: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: const BoxDecoration(
                          color: AppColors.secondaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.air_rounded,
                            color: AppColors.primary, size: 28),
                      ),
                      const StatusBadge(
                          label: 'Rhythmic Pacing', type: BadgeType.info),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Paced Inhale & Exhale',
                    style: AppTypography.titleMedium
                        .copyWith(color: AppColors.primaryDark),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'Slow your breath, activate parasympathetic relaxation, and settle your thoughts.',
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Quick Start Duration:',
                      style: AppTypography.labelMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [2, 5, 15].map((mins) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusMd),
                              ),
                            ),
                            onPressed: () => context
                                .push('/me/breathing?duration=$mins'),
                            child: Text(
                              '${mins}m',
                              style: AppTypography.labelLarge
                                  .copyWith(color: AppColors.primary),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CarenButton(
                    label: 'Start Breathing Session (2m)',
                    icon: Icons.play_arrow_rounded,
                    onPressed: () =>
                        context.push('/me/breathing?duration=2'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 2. Mindfulness & Grounding Section
            Text('Mindfulness & Grounding', style: AppTypography.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Step-by-step guided exercises to anchor your senses and cultivate presence.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            _ActivityTile(
              activity: WellnessCatalog.fiveSensesGrounding,
              onTap: () => _openActivity(context, WellnessCatalog.fiveSensesGrounding),
            ),
            const SizedBox(height: AppSpacing.xs),
            _ActivityTile(
              activity: WellnessCatalog.presentMomentMindfulness,
              onTap: () => _openActivity(context, WellnessCatalog.presentMomentMindfulness),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 3. Body Relaxation Section
            Text('Body Relaxation', style: AppTypography.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Systematic physical release for screen fatigue, shoulder tension, and posture.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            _ActivityTile(
              activity: WellnessCatalog.progressiveMuscleRelaxation,
              onTap: () => _openActivity(context, WellnessCatalog.progressiveMuscleRelaxation),
            ),
            const SizedBox(height: AppSpacing.xs),
            _ActivityTile(
              activity: WellnessCatalog.shoulderJawRelease,
              onTap: () => _openActivity(context, WellnessCatalog.shoulderJawRelease),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 4. Quiet Moments Section
            Text('Quiet Moments', style: AppTypography.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            _ActivityTile(
              activity: WellnessCatalog.quietReflection,
              onTap: () => _openActivity(context, WellnessCatalog.quietReflection),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 5. Optional Camera Wellness Check (Distinct Entry Point)
            Text('Camera Wellness Check', style: AppTypography.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            CarenCard(
              backgroundColor: AppColors.surfaceVariant,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.videocam_outlined,
                            color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Optional Pulse Observation',
                                style: AppTypography.titleMedium),
                            const Text(
                              'Analyzed live via camera • Never saved or uploaded',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Take an optional 15-second camera spot-check to observe your resting pulse rhythm. Position your face in the camera guide before measuring.',
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'Notice: Personal wellness observation only. Not a medical diagnosis or emotional stress measurement.',
                    style: AppTypography.caption,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CarenButton(
                    label: 'Open Camera Wellness Check',
                    icon: Icons.camera_alt_outlined,
                    variant: CarenButtonVariant.outline,
                    onPressed: () => context.push('/me/camera-check'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Recent Private Sessions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Private Sessions',
                  style: AppTypography.titleMedium
                      .copyWith(color: AppColors.primaryDark),
                ),
                TextButton(
                  onPressed: () => context.push('/me/history'),
                  child: const Text('View All'),
                ),
              ],
            ),
            sessionsAsync.when(
              data: (sessions) {
                if (sessions.isEmpty) {
                  return const CarenCard(
                    child: Text('No previous relaxation sessions recorded.'),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sessions.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    return CarenCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${session.durationMinutes} min • ${session.cadenceTitle}',
                                  style: AppTypography.titleMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                AppFormatters.formatDate(session.startTime),
                                style: AppTypography.caption,
                              ),
                            ],
                          ),
                          if (session.preSessionVitals != null &&
                              session.postSessionVitals != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Pulse: ${session.preSessionVitals!.pulseRateBpm?.toInt() ?? "--"} → ${session.postSessionVitals!.pulseRateBpm?.toInt() ?? "--"} bpm',
                              style: AppTypography.bodyMedium
                                  .copyWith(color: AppColors.primary),
                            ),
                          ],
                          if (session.personalReflection != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '“${session.personalReflection!}”',
                              style: AppTypography.caption.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error: $err'),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  void _openActivity(BuildContext context, WellnessActivity activity) {
    context.push('/me/activity/${activity.id}');
  }
}

class _ActivityTile extends StatelessWidget {
  final WellnessActivity activity;
  final VoidCallback onTap;

  const _ActivityTile({
    required this.activity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CarenCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withAlpha(80),
              shape: BoxShape.circle,
            ),
            child: Icon(activity.icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        activity.title,
                        style: AppTypography.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${activity.defaultDurationMinutes}m',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  activity.subtitle,
                  style: AppTypography.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
