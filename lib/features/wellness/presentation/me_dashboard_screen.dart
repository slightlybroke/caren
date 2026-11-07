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
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 20, color: AppColors.primary),
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

            // Guided Breathing Feature Card
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
                        child: const Icon(Icons.air_rounded, color: AppColors.primary, size: 28),
                      ),
                      const StatusBadge(label: 'Guided Relaxation', type: BadgeType.info),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Guided Breathing',
                    style: AppTypography.titleLarge.copyWith(color: AppColors.primaryDark),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Slow your breath, settle your thoughts, and optionally observe your pulse rhythm before and after.',
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Quick Start Duration:', style: AppTypography.labelMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [2, 3, 5, 10].map((mins) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              ),
                            ),
                            onPressed: () => context.push('/me/breathing?duration=$mins'),
                            child: Text(
                              '${mins}m',
                              style: AppTypography.labelLarge.copyWith(color: AppColors.primary),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CarenButton(
                    label: 'Start 3-Minute Breathing Session',
                    icon: Icons.play_arrow_rounded,
                    onPressed: () => context.push('/me/breathing?duration=3'),
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
                  'Recent Sessions',
                  style: AppTypography.titleMedium.copyWith(color: AppColors.primaryDark),
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
                    child: Text('No previous breathing sessions recorded.'),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sessions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    return CarenCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${session.durationMinutes} min • ${session.cadenceTitle}',
                                style: AppTypography.titleMedium,
                              ),
                              Text(
                                AppFormatters.formatDate(session.startTime),
                                style: AppTypography.caption,
                              ),
                            ],
                          ),
                          if (session.preSessionVitals != null && session.postSessionVitals != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Pulse: ${session.preSessionVitals!.pulseRateBpm?.toInt() ?? "--"} → ${session.postSessionVitals!.pulseRateBpm?.toInt() ?? "--"} bpm',
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.primary),
                            ),
                          ],
                          if (session.personalReflection != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '“${session.personalReflection!}”',
                              style: AppTypography.caption.copyWith(fontStyle: FontStyle.italic),
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
}

