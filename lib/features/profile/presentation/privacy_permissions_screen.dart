import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/caren_button.dart';
import '../../../core/widgets/caren_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/profile_repository.dart';
import '../domain/privacy_settings.dart';

class PrivacyPermissionsScreen extends ConsumerWidget {
  const PrivacyPermissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privacyAsync = ref.watch(privacySettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Sharing Permissions'),
      ),
      body: privacyAsync.when(
        data: (privacy) {
          return SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Privacy Charter Banner
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 26),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'The CAREN Privacy Promise',
                              style: AppTypography.titleMedium.copyWith(color: AppColors.primaryDark),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Your data belongs to you. Voluntary check-ins should bring loved ones closer, never create surveillance. All sharing is explicit and can be revoked at any moment.',
                              style: AppTypography.caption.copyWith(color: AppColors.primaryDark),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Family Sharing Controls
                Text('Family Sharing Granular Controls', style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                CarenCard(
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Share Check-In Completion Status', style: AppTypography.labelLarge),
                        subtitle: const Text(
                          'Allows family to see whether you finished today’s voluntary check-in.',
                          style: AppTypography.caption,
                        ),
                        value: privacy.shareCheckInStatusWithFamily,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) {
                          ref.read(profileRepositoryProvider).updatePrivacySettings(
                                privacy.copyWith(shareCheckInStatusWithFamily: val),
                              );
                        },
                      ),
                      const Divider(),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Share Self-Reported Wellness', style: AppTypography.labelLarge),
                        subtitle: const Text(
                          'Allows family to see your energy level, sleep reflection, and personal notes.',
                          style: AppTypography.caption,
                        ),
                        value: privacy.shareSelfReportedWellness,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) {
                          ref.read(profileRepositoryProvider).updatePrivacySettings(
                                privacy.copyWith(shareSelfReportedWellness: val),
                              );
                        },
                      ),
                      const Divider(),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Share Camera Spot-Check Readings', style: AppTypography.labelLarge),
                        subtitle: const Text(
                          'OFF by default. If enabled, shares pulse and breathing rhythm numbers from voluntary camera checks.',
                          style: AppTypography.caption,
                        ),
                        value: privacy.shareCameraMeasurementsWithFamily,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) {
                          ref.read(profileRepositoryProvider).updatePrivacySettings(
                                privacy.copyWith(shareCameraMeasurementsWithFamily: val),
                              );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Me Private Experience Privacy
                Text('Me Experience Isolation', style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                const CarenCard(
                  child: Row(
                    children: [
                      Icon(Icons.lock_rounded, color: AppColors.secondary, size: 24),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Always Strictly Private', style: AppTypography.labelLarge),
                            SizedBox(height: 2),
                            Text(
                              'Guided breathing sessions and personal trends in the Me section are strictly confidential. They cannot be viewed by or shared with family members.',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(label: 'Enforced', type: BadgeType.success),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Camera Access Transparency
                Text('Camera Sensor Safeguards', style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                CarenCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'How CAREN Uses Your Camera',
                        style: AppTypography.labelLarge,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        '• The camera is activated ONLY when you explicitly tap a spot-check button.\n'
                        '• Video streams are evaluated in real-time memory.\n'
                        '• NO raw video footage, photos, or facial images are ever recorded, stored to disk, or transmitted to any server.\n'
                        '• You may revoke camera permission at any time in your device Settings.',
                        style: AppTypography.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      CarenButton(
                        label: 'Revoke All Sharing Permissions',
                        variant: CarenButtonVariant.outline,
                        onPressed: () {
                          ref.read(profileRepositoryProvider).updatePrivacySettings(
                                PrivacySettings(
                                  shareCheckInStatusWithFamily: false,
                                  shareSelfReportedWellness: false,
                                  shareCameraMeasurementsWithFamily: false,
                                  storeMeasurementsLocallyOnly: true,
                                  enableSmartSpectraSimulatedMock: true,
                                  lastUpdated: DateTime.now(),
                                ),
                              );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('All family sharing permissions have been revoked.')),
                          );
                        },
                      ),
                    ],
                  ),
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

