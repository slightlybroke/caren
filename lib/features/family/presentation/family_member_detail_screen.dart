import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/caren_button.dart';
import '../../../core/widgets/caren_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/family_repository.dart';
import '../domain/family_member.dart';

class FamilyMemberDetailScreen extends ConsumerWidget {
  final String memberId;

  const FamilyMemberDetailScreen({super.key, required this.memberId});

  Future<void> _launchCall(BuildContext context, String? phone, String name) async {
    if (phone != null && phone.isNotEmpty) {
      final uri = Uri(scheme: 'tel', path: phone);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No phone number saved for $name.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(familyMemberDetailProvider(memberId));
    final historyAsync = ref.watch(familyMemberHistoryProvider(memberId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Member'),
      ),
      body: memberAsync.when(
        data: (member) {
          if (member == null) {
            return const Center(child: Text('Member not found.'));
          }

          final isCompleted = member.checkInStatus == CheckInStatus.completedToday;

          return SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Profile Card
                CarenCard(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.primaryContainer,
                        child: Text(
                          member.name.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join(),
                          style: AppTypography.displayMedium.copyWith(color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(member.name, style: AppTypography.titleLarge),
                      Text(
                        '${member.relationship}${member.city.isNotEmpty ? " • Living in ${member.city}" : ""}',
                        style: AppTypography.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      StatusBadge(
                        label: member.role.displayName,
                        type: BadgeType.neutral,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      StatusBadge(
                        label: isCompleted ? 'Completed Today’s Check-in' : 'Check-in Pending Today',
                        type: isCompleted ? BadgeType.success : BadgeType.neutral,
                        icon: isCompleted ? Icons.check_circle : Icons.schedule,
                      ),
                      if (member.lastCheckInTime != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Last check-in: ${AppFormatters.formatDateTime(member.lastCheckInTime!)}',
                          style: AppTypography.caption,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Friendly Follow-Up Button if pending
                if (!isCompleted) ...[
                  CarenCard(
                    backgroundColor: AppColors.surfaceVariant,
                    borderColor: AppColors.primary.withAlpha(50),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'Gentle Human Follow-Up',
                              style: AppTypography.labelLarge.copyWith(color: AppColors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        const Text(
                          'A missed or delayed check-in is not proof that someone is unwell—people often get busy or misplace their phone. Send a warm reminder or reach out directly.',
                          style: AppTypography.caption,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: CarenButton(
                                label: 'Send Reminder',
                                variant: CarenButtonVariant.secondary,
                                icon: Icons.send_rounded,
                                onPressed: () {
                                  ref.read(familyRepositoryProvider).sendGentleReminder(member.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Warm reminder notification sent.')),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: CarenButton(
                                label: 'Call Member',
                                variant: CarenButtonVariant.outline,
                                icon: Icons.phone_outlined,
                                onPressed: () => _launchCall(context, member.phoneNumber, member.name),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Transparent Sharing Permissions (What this member shares with you)
                Text(
                  'Sharing Permissions with You',
                  style: AppTypography.titleMedium.copyWith(color: AppColors.primaryDark),
                ),
                const SizedBox(height: AppSpacing.xs),
                CarenCard(
                  child: Column(
                    children: [
                      _PermissionRow(
                        title: 'Daily check-in status',
                        subtitle: 'Can see if check-in was finished today',
                        isShared: member.sharingPermission.shareCheckInStatus,
                      ),
                      const Divider(),
                      _PermissionRow(
                        title: 'Self-reported wellness',
                        subtitle: 'Mood, energy, and sleep reflections',
                        isShared: member.sharingPermission.shareSelfReportedMood,
                      ),
                      const Divider(),
                      _PermissionRow(
                        title: 'Camera wellness spot-checks',
                        subtitle: 'Pulse & breathing spot readings (if taken)',
                        isShared: member.sharingPermission.shareVitalsMeasurements,
                      ),
                      const Divider(),
                      _PermissionRow(
                        title: 'Personal notes',
                        subtitle: 'Freeform daily thoughts and reflections',
                        isShared: member.sharingPermission.shareNotes,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Check-in History
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Shared Check-in History',
                      style: AppTypography.titleMedium.copyWith(color: AppColors.primaryDark),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),

                historyAsync.when(
                  data: (checkIns) {
                    if (checkIns.isEmpty) {
                      return const CarenCard(
                        child: Text('No historical check-ins shared yet.'),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: checkIns.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final checkIn = checkIns[index];
                        return CarenCard(
                          onTap: () => context.push('/family/report/${checkIn.id}'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppFormatters.formatDayHeader(checkIn.timestamp),
                                    style: AppTypography.titleMedium,
                                  ),
                                  const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${checkIn.feelingDisplay} • ${checkIn.sleepDisplay}',
                                style: AppTypography.bodyMedium,
                              ),
                              if (checkIn.optionalMeasurement != null &&
                                  member.sharingPermission.shareVitalsMeasurements) ...[
                                const SizedBox(height: AppSpacing.xs),
                                StatusBadge(
                                  label: checkIn.optionalMeasurement!.summaryLabel,
                                  type: BadgeType.info,
                                  icon: Icons.camera_alt_outlined,
                                ),
                              ],
                              if (checkIn.isSyncPending) ...[
                                const SizedBox(height: AppSpacing.xs),
                                const StatusBadge(
                                  label: 'Saved offline (Sync pending)',
                                  type: BadgeType.neutral,
                                  icon: Icons.cloud_queue_rounded,
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error loading history: $e'),
                ),
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

class _PermissionRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isShared;

  const _PermissionRow({
    required this.title,
    required this.subtitle,
    required this.isShared,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            isShared ? Icons.check_circle_outline : Icons.remove_circle_outline,
            color: isShared ? AppColors.secondary : AppColors.textMuted,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.labelLarge),
                Text(subtitle, style: AppTypography.caption),
              ],
            ),
          ),
          StatusBadge(
            label: isShared ? 'Shared' : 'Private',
            type: isShared ? BadgeType.success : BadgeType.neutral,
          ),
        ],
      ),
    );
  }
}

