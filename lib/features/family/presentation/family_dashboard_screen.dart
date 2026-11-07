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
import '../data/family_repository.dart';
import '../domain/family_member.dart';

class FamilyDashboardScreen extends ConsumerWidget {
  const FamilyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyAsync = ref.watch(familyMembersProvider);

    return Scaffold(
      appBar: CarenAppBar(
        title: 'Family',
        actions: [
          IconButton(
            tooltip: 'All Family Members',
            icon: const Icon(Icons.people_outline_rounded),
            onPressed: () => context.push('/family/members'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(familyMembersProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Daily Check-In Prompt Banner
              CarenCard(
                backgroundColor: AppColors.secondaryContainer,
                borderColor: AppColors.secondaryLight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.wb_sunny_outlined, color: AppColors.secondary, size: 24),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Your Daily Check-In',
                          style: AppTypography.titleMedium.copyWith(color: AppColors.onSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Let your loved ones know how you are feeling today with a 30-second voluntary update.',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.onSecondary),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    CarenButton(
                      label: 'Complete Check-In',
                      onPressed: () => context.push('/family/check-in'),
                      icon: Icons.check_circle_outline,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Transparent Privacy Assurance
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'All check-ins are voluntary. You control exactly what is shared with each member.',
                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Family Circle Members
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Family Circle',
                    style: AppTypography.titleLarge.copyWith(color: AppColors.primaryDark),
                  ),
                  TextButton(
                    onPressed: () => context.push('/family/members'),
                    child: const Text('Manage'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),

              familyAsync.when(
                data: (members) {
                  if (members.isEmpty) {
                    return const Center(child: Text('No family members invited yet.'));
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: members.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final member = members[index];
                      return _FamilyMemberCard(member: member);
                    },
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Center(
                  child: Text('Error loading family members: $err'),
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

class _FamilyMemberCard extends StatelessWidget {
  final FamilyMember member;

  const _FamilyMemberCard({required this.member});

  @override
  Widget build(BuildContext context) {
    final isCompleted = member.checkInStatus == CheckInStatus.completedToday;

    return CarenCard(
      onTap: () => context.push('/family/member/${member.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: isCompleted ? AppColors.secondaryContainer : AppColors.surfaceVariant,
                child: Text(
                  member.name.split(' ').map((n) => n[0]).take(2).join(),
                  style: AppTypography.titleMedium.copyWith(
                    color: isCompleted ? AppColors.secondary : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.name, style: AppTypography.titleMedium),
                    Text(
                      '${member.relationship} • ${member.city}',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: isCompleted ? 'Checked in' : 'Pending today',
                type: isCompleted ? BadgeType.success : BadgeType.warning,
                icon: isCompleted ? Icons.check_circle : Icons.schedule,
              ),
            ],
          ),
          if (member.lastWellnessSummary != null) ...[
            const SizedBox(height: AppSpacing.sm),
            const Divider(),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppColors.textMuted),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    member.lastWellnessSummary!,
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

