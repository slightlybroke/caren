import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/caren_button.dart';
import '../../../core/widgets/caren_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../services/vitals/vitals_provider.dart';
import '../data/profile_repository.dart';
import '../../authentication/presentation/controllers/auth_controller.dart';
import '../domain/user_profile.dart';

class ProfileSettingsScreen extends ConsumerWidget {
  const ProfileSettingsScreen({super.key});

  void _showCountrySelectionDialog(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Country for Emergency Dispatch'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: EmergencyDirectory.countryNumbers.entries.map((entry) {
              final isSelected = profile.country == entry.key;
              return ListTile(
                title: Text(entry.key, style: AppTypography.bodyLarge),
                subtitle: Text('Dispatch: ${entry.value}', style: AppTypography.caption),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () {
                  ref.read(profileRepositoryProvider).updateProfile(
                        profile.copyWith(country: entry.key),
                      );
                  ref.invalidate(userProfileProvider);
                  Navigator.pop(ctx);
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final privacyAsync = ref.watch(privacySettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
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
      ),
      body: profileAsync.when(
        data: (profile) {
          return SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Identity Card
                CarenCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primaryContainer,
                        child: Text(
                          profile.fullName.split(' ').map((n) => n[0]).take(2).join(),
                          style: AppTypography.displayMedium.copyWith(color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(profile.fullName, style: AppTypography.titleLarge),
                            Text(profile.email, style: AppTypography.bodyMedium),
                            Text('${profile.city} • Preferred Check-In: ${profile.preferredTimeForCheckIn}',
                                style: AppTypography.caption),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Privacy & Sharing Navigation Tile
                Text('Privacy & Sharing Controls', style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                CarenCard(
                  onTap: () => context.push('/profile/privacy'),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: const BoxDecoration(
                          color: AppColors.secondaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shield_outlined, color: AppColors.primary),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Family Sharing Permissions', style: AppTypography.labelLarge),
                            Text('Control and revoke what family members can see', style: AppTypography.caption),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.textMuted),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Preferences & Reminders
                Text('Preferences', style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                CarenCard(
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Gentle Daily Reminders', style: AppTypography.labelLarge),
                        subtitle: const Text('Receive a friendly notification at your preferred check-in time',
                            style: AppTypography.caption),
                        value: profile.enableGentleReminders,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) {
                          ref.read(profileRepositoryProvider).updateProfile(
                                profile.copyWith(enableGentleReminders: val),
                              );
                        },
                      ),
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Country & Emergency Dispatch', style: AppTypography.labelLarge),
                        subtitle: Text(
                          '${profile.country} • Emergency Number: ${profile.emergencyNumber}',
                          style: AppTypography.caption,
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                        onTap: () => _showCountrySelectionDialog(context, ref, profile),
                      ),
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Preferred Check-In Time', style: AppTypography.labelLarge),
                        subtitle: Text(profile.preferredTimeForCheckIn, style: AppTypography.caption),
                        trailing: const Icon(Icons.access_time, color: AppColors.textMuted),
                        onTap: () {
                          // Change check-in time
                        },
                      ),
                    ],
                  ),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: AppSpacing.lg),

                  // Developer & SDK Status
                  Text('Presage SmartSpectra SDK Status', style: AppTypography.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  CarenCard(
                    backgroundColor: AppColors.surfaceVariant,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        privacyAsync.when(
                          data: (privacy) => Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Provider Mode', style: AppTypography.labelLarge),
                              StatusBadge(
                                label: privacy.enableSmartSpectraSimulatedMock ? 'SIMULATED MOCK' : 'NATIVE SMARTSPECTRA',
                                type: privacy.enableSmartSpectraSimulatedMock ? BadgeType.warning : BadgeType.success,
                              ),
                            ],
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        privacyAsync.when(
                          data: (privacy) => Text(
                            privacy.enableSmartSpectraSimulatedMock
                                ? 'Running MockVitalsProvider with clearly marked simulated data for UI and automated testing.'
                                : 'Running NativeVitalsProvider with real Presage SmartSpectra SDK 3.4.0 and CameraX PlatformView.',
                            style: AppTypography.caption,
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        privacyAsync.when(
                          data: (privacy) => SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Simulated Mock Mode', style: AppTypography.labelMedium),
                            subtitle: const Text('Toggle OFF to activate native Android CameraX and SmartSpectra SDK.',
                                style: AppTypography.caption),
                            value: privacy.enableSmartSpectraSimulatedMock,
                            activeThumbColor: AppColors.primary,
                            onChanged: (val) async {
                              await ref.read(privacySettingsProvider.notifier).updateSettings(
                                    privacy.copyWith(enableSmartSpectraSimulatedMock: val),
                                  );
                              ref.invalidate(vitalsProvider);
                            },
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        CarenButton(
                          label: 'Developer Diagnostics & SDK Console',
                          icon: Icons.bug_report_outlined,
                          variant: CarenButtonVariant.outline,
                          onPressed: () => context.push('/diagnostics'),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),

                // Sign Out
                CarenButton(
                  label: 'Sign Out',
                  variant: CarenButtonVariant.outline,
                  onPressed: () async {
                    await ref.read(authNotifierProvider.notifier).signOut();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
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

