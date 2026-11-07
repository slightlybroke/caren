import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/caren_app_bar.dart';
import '../../../core/widgets/caren_button.dart';
import '../../../core/widgets/caren_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../family/data/family_repository.dart';
import '../../family/domain/family_member.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyAsync = ref.watch(familyMembersProvider);

    return Scaffold(
      appBar: const CarenAppBar(
        title: 'caren',
        showProfileButton: true,
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Greeting
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Good morning, Julian',
                        style: AppTypography.titleLarge.copyWith(color: Colors.white),
                      ),
                      const StatusBadge(
                        label: 'Care, closer',
                        type: BadgeType.neutral,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Your morning check-in is ready whenever you feel like completing it.',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.secondaryContainer),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CarenButton(
                    label: 'Start Today’s Check-In',
                    icon: Icons.check_circle_outline,
                    variant: CarenButtonVariant.secondary,
                    onPressed: () => context.push('/family/check-in'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Family Section Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Family Circle',
                  style: AppTypography.titleMedium.copyWith(color: AppColors.primaryDark),
                ),
                TextButton(
                  onPressed: () => context.go('/family'),
                  child: const Text('View Circle'),
                ),
              ],
            ),
            familyAsync.when(
              data: (members) {
                final completedCount =
                    members.where((m) => m.checkInStatus == CheckInStatus.completedToday).length;
                return CarenCard(
                  onTap: () => context.go('/family'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: AppColors.secondaryContainer,
                                child: Icon(Icons.favorite_rounded, color: AppColors.secondary, size: 20),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                '$completedCount of ${members.length} checked in today',
                                style: AppTypography.titleMedium,
                              ),
                            ],
                          ),
                          const Icon(Icons.chevron_right, color: AppColors.textMuted),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Eleanor shared her morning update. Arthur has not checked in yet.',
                        style: AppTypography.bodyMedium,
                      ),
                    ],
                  ),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const Text('Could not load family updates.'),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Me Experience Quick Card
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Me • Personal Wellness',
                  style: AppTypography.titleMedium.copyWith(color: AppColors.primaryDark),
                ),
                TextButton(
                  onPressed: () => context.go('/me'),
                  child: const Text('Open Me'),
                ),
              ],
            ),
            CarenCard(
              onTap: () => context.push('/me/breathing'),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.air_rounded, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Take a 3-Minute Breath', style: AppTypography.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          'Guided relaxation session. Private to you.',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textMuted),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Safety Assist Summary Card
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Safety Assist',
                  style: AppTypography.titleMedium.copyWith(color: AppColors.primaryDark),
                ),
                TextButton(
                  onPressed: () => context.go('/assist'),
                  child: const Text('Open Assist'),
                ),
              ],
            ),
            CarenCard(
              backgroundColor: AppColors.surfaceVariant,
              onTap: () => context.go('/assist'),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_outlined, color: AppColors.warning, size: 26),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Assistance Documentation', style: AppTypography.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          'Structured, timestamped record for emergency handoffs.',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textMuted),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

