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
import '../../authentication/data/auth_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../data/family_repository.dart';
import '../domain/family_member.dart';

class FamilyDashboardScreen extends ConsumerWidget {
  const FamilyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyAsync = ref.watch(familyMembersProvider);
    final authUser = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final userProfile = profileAsync.asData?.value;

    String name = '';
    if (userProfile != null && userProfile.fullName.trim().isNotEmpty) {
      name = userProfile.fullName.trim();
    } else if (authUser != null) {
      final dn = authUser.displayName;
      if (dn != null && dn.trim().isNotEmpty) {
        name = dn.trim();
      } else if (authUser.email.isNotEmpty) {
        name = authUser.email.split('@').first;
      }
    }

    final hour = DateTime.now().hour;
    final timeGreeting = hour < 12 ? 'Good morning' : (hour < 17 ? 'Good afternoon' : 'Good evening');
    final greetingText = name.isNotEmpty ? '$timeGreeting, $name' : timeGreeting;

    return Scaffold(
      appBar: CarenAppBar(
        title: 'Family',
        showProfileButton: true,
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
              // Dynamic Welcome Header
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
                        Flexible(
                          child: Text(
                            greetingText,
                            style: AppTypography.titleLarge.copyWith(color: Colors.white),
                          ),
                        ),
                        const StatusBadge(
                          label: 'Care, closer',
                          type: BadgeType.neutral,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Your daily wellness check-in keeps your family circle connected with peace of mind.',
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

              // Family Circle Members Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Family Circle',
                    style: AppTypography.titleLarge.copyWith(color: AppColors.primaryDark),
                  ),
                  TextButton(
                    onPressed: () => context.push('/family/members'),
                    child: const Text('Manage Circle'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),

              // Family Circle Members List / Empty State
              familyAsync.when(
                data: (members) {
                  if (members.isEmpty) {
                    return CarenCard(
                      child: Column(
                        children: [
                          const Icon(Icons.group_add_outlined, size: 48, color: AppColors.primary),
                          const SizedBox(height: AppSpacing.sm),
                          Text('Your Family Circle is Empty', style: AppTypography.titleMedium),
                          const SizedBox(height: AppSpacing.xs),
                          const Text(
                            'Invite parents, children, or loved ones to share voluntary daily wellness updates.',
                            style: AppTypography.caption,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          CarenButton(
                            label: 'Invite Family Member',
                            icon: Icons.person_add_alt_1,
                            variant: CarenButtonVariant.outline,
                            onPressed: () => context.push('/family/members'),
                          ),
                        ],
                      ),
                    );
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
    return CarenCard(
      onTap: () => context.push('/family/member/${member.id}'),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryLight.withAlpha(50),
            foregroundColor: AppColors.primary,
            child: Text(
              member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(member.name, style: AppTypography.titleSmall),
                    _buildStatusBadge(member.checkInStatus),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${member.relationship} • ${member.city}',
                  style: AppTypography.caption,
                ),
                if (member.lastCheckInTime != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Last check-in: ${_formatTimeAgo(member.lastCheckInTime!)}',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(CheckInStatus status) {
    switch (status) {
      case CheckInStatus.completedToday:
        return const StatusBadge(label: 'Checked In', type: BadgeType.success);
      case CheckInStatus.pendingToday:
        return const StatusBadge(label: 'Pending', type: BadgeType.warning);
      case CheckInStatus.missedYesterday:
        return const StatusBadge(label: 'Not checked in', type: BadgeType.neutral);
    }
  }

  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
