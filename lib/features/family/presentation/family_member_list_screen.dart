import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/caren_button.dart';
import '../../../core/widgets/caren_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/family_repository.dart';
import '../domain/family_invitation.dart';
import '../domain/family_member.dart';

class FamilyMemberListScreen extends ConsumerWidget {
  const FamilyMemberListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyAsync = ref.watch(familyMembersProvider);
    final pendingInvitesAsync = ref.watch(pendingInvitationsProvider);
    final sentInvitesAsync = ref.watch(sentInvitationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Circle'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/family');
            }
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Invite Member',
            icon: const Icon(Icons.person_add_alt_1_outlined),
            onPressed: () => context.push('/family/invite'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Received Pending Invitations for current user (if any)
            pendingInvitesAsync.when(
              data: (invitations) {
                if (invitations.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invitations Waiting for You',
                      style: AppTypography.titleMedium.copyWith(color: AppColors.primaryDark),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ...invitations.map((inv) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: CarenCard(
                            backgroundColor: AppColors.secondaryContainer.withValues(alpha: 0.4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Invitation to join "${inv.familyName}"',
                                  style: AppTypography.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Invited by ${inv.invitedByEmail} as ${inv.relationship}',
                                  style: AppTypography.bodySmall,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () async {
                                        await ref
                                            .read(familyRepositoryProvider)
                                            .declineInvitation(inv.id);
                                        ref.invalidate(pendingInvitationsProvider);
                                      },
                                      child: const Text('Decline'),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    ElevatedButton(
                                      onPressed: () async {
                                        try {
                                          await ref
                                              .read(familyRepositoryProvider)
                                              .acceptInvitation(inv.id);
                                          ref.invalidate(pendingInvitationsProvider);
                                          ref.invalidate(familyMembersProvider);
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Error: $e')),
                                            );
                                          }
                                        }
                                      },
                                      child: const Text('Accept'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )),
                    const SizedBox(height: AppSpacing.md),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),

            Text(
              'Circle Members',
              style: AppTypography.titleMedium.copyWith(color: AppColors.primaryDark),
            ),
            const SizedBox(height: AppSpacing.xs),

            familyAsync.when(
              data: (members) {
                if (members.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.group_outlined, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: AppSpacing.sm),
                          const Text('No other members in this circle yet.', style: AppTypography.bodyMedium),
                          const SizedBox(height: AppSpacing.md),
                          CarenButton(
                            label: 'Invite a Family Member',
                            icon: Icons.add,
                            variant: CarenButtonVariant.outline,
                            onPressed: () => context.push('/family/invite'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: members.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    if (index == members.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        child: CarenButton(
                          label: 'Invite Another Family Member',
                          icon: Icons.add,
                          variant: CarenButtonVariant.outline,
                          onPressed: () => context.push('/family/invite'),
                        ),
                      );
                    }

                    final member = members[index];
                    return CarenCard(
                      onTap: () => context.push('/family/member/${member.id}'),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.primaryContainer,
                            child: Text(
                              member.name.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join(),
                              style: AppTypography.titleMedium.copyWith(color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        member.name,
                                        style: AppTypography.titleMedium,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Text(
                                      '(${member.role.displayName})',
                                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${member.relationship}${member.city.isNotEmpty ? " • ${member.city}" : ""}',
                                  style: AppTypography.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          StatusBadge(
                            label: member.checkInStatus == CheckInStatus.completedToday
                                ? 'Checked in'
                                : 'Pending',
                            type: member.checkInStatus == CheckInStatus.completedToday
                                ? BadgeType.success
                                : BadgeType.neutral,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          const Icon(Icons.chevron_right, color: AppColors.textMuted),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Sent Invitations Section
            sentInvitesAsync.when(
              data: (sentList) {
                if (sentList.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sent Invitations',
                      style: AppTypography.titleMedium.copyWith(color: AppColors.primaryDark),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ...sentList.map((inv) {
                      final status = inv.effectiveStatus;
                      final isPending = status == InvitationStatus.pending;

                      BadgeType badgeType;
                      String badgeText;
                      switch (status) {
                        case InvitationStatus.accepted:
                          badgeType = BadgeType.success;
                          badgeText = 'Accepted';
                          break;
                        case InvitationStatus.declined:
                          badgeType = BadgeType.neutral;
                          badgeText = 'Declined';
                          break;
                        case InvitationStatus.revoked:
                          badgeType = BadgeType.neutral;
                          badgeText = 'Revoked';
                          break;
                        case InvitationStatus.expired:
                          badgeType = BadgeType.neutral;
                          badgeText = 'Expired';
                          break;
                        case InvitationStatus.pending:
                          badgeType = BadgeType.warning;
                          badgeText = 'Pending';
                          break;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: CarenCard(
                          child: Row(
                            children: [
                              const Icon(Icons.mail_outline, color: AppColors.textSecondary),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(inv.inviteeEmail, style: AppTypography.labelLarge),
                                    Text('As ${inv.relationship}', style: AppTypography.caption),
                                  ],
                                ),
                              ),
                              StatusBadge(label: badgeText, type: badgeType),
                              if (isPending) ...[
                                const SizedBox(width: AppSpacing.xs),
                                TextButton(
                                  onPressed: () async {
                                    await ref
                                        .read(familyRepositoryProvider)
                                        .revokeInvitation(inv.id);
                                    ref.invalidate(sentInvitationsProvider);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Invitation revoked.')),
                                      );
                                    }
                                  },
                                  child: const Text('Revoke'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
