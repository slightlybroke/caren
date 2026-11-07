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
import '../domain/family_member.dart';

class FamilyMemberListScreen extends ConsumerWidget {
  const FamilyMemberListScreen({super.key});

  void _showInviteDialog(BuildContext context) {
    final nameController = TextEditingController();
    final relationController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invite a Family Member'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: relationController,
                decoration: const InputDecoration(labelText: 'Relationship (e.g. Parent, Child)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email address'),
              ),
              const SizedBox(height: 16),
              const Text(
                'An invitation will be sent. Family participation is completely voluntary and check-in sharing permissions can be changed at any time.',
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invitation sent successfully.')),
              );
            },
            child: const Text('Send Invitation'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyAsync = ref.watch(familyMembersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Circle'),
        actions: [
          IconButton(
            tooltip: 'Invite Member',
            icon: const Icon(Icons.person_add_alt_1_outlined),
            onPressed: () => _showInviteDialog(context),
          ),
        ],
      ),
      body: familyAsync.when(
        data: (members) {
          return ListView.separated(
            padding: AppSpacing.screenPadding,
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
                    onPressed: () => _showInviteDialog(context),
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
                        member.name.split(' ').map((n) => n[0]).take(2).join(),
                        style: AppTypography.titleMedium.copyWith(color: AppColors.primary),
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
                          : BadgeType.warning,
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
    );
  }
}

