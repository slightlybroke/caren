import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/caren_app_bar.dart';
import '../../../core/widgets/caren_button.dart';
import '../../../core/widgets/caren_card.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/domain/user_profile.dart';
import '../data/assist_repository.dart';

class AssistLandingScreen extends ConsumerWidget {
  const AssistLandingScreen({super.key});

  void _showEmergencyDialog(BuildContext context, String emergencyNumber, String country) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 28),
            const SizedBox(width: 8),
            Text('Contact Emergency Services ($emergencyNumber)'),
          ],
        ),
        content: Text(
          'In a critical or acute situation, contact official emergency dispatchers ($emergencyNumber in $country). Do not delay CPR, AED use, or official first-responder guidance to use any app.\n\nNote: CAREN will never initiate a phone call automatically without your explicit action.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Dismiss'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            icon: const Icon(Icons.phone, color: Colors.white, size: 18),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Prepared dialer action for emergency number $emergencyNumber ($country). No call was initiated automatically.'),
                ),
              );
            },
            label: Text('Open Dialer for $emergencyNumber', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final emergencyNumber = profileAsync.asData?.value.emergencyNumber ?? EmergencyDirectory.fallbackNumber;
    final country = profileAsync.asData?.value.country ?? 'India';

    return Scaffold(
      appBar: const CarenAppBar(
        title: 'Safety Assist',
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Prominent Emergency Banner (Localized Emergency Number)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.dangerContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.danger.withAlpha(50)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.emergency_rounded, color: AppColors.danger, size: 24),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Is this an acute emergency?',
                        style: AppTypography.titleMedium.copyWith(color: AppColors.danger),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'If someone nearby is unresponsive, experiencing severe chest discomfort, or struggling to breathe, contact local emergency dispatch ($emergencyNumber in $country) immediately.',
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  CarenButton(
                    label: 'Emergency Services ($emergencyNumber)',
                    icon: Icons.phone_in_talk,
                    variant: CarenButtonVariant.danger,
                    onPressed: () => _showEmergencyDialog(context, emergencyNumber, country),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Start Assist Session Card
            Text('Temporary Assistance Session', style: AppTypography.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Document a timeline of observations and actions when someone nearby is resting or feeling unwell. Create a clear summary for first responders or family physicians.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            CarenCard(
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
                        child: const Icon(Icons.edit_calendar_outlined, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Situation Log & Handoff', style: AppTypography.titleMedium),
                            Text('Timestamped notes of observed signs', style: AppTypography.caption),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CarenButton(
                    label: 'Start Assistance Session',
                    icon: Icons.play_arrow_rounded,
                    onPressed: () async {
                      final session = await ref.read(assistRepositoryProvider).startNewSession();
                      if (context.mounted) {
                        context.push('/assist/session?sessionId=${session.id}');
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Safety & Non-Diagnostic Disclaimer
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 18, color: AppColors.textSecondary),
                      SizedBox(width: AppSpacing.xs),
                      Text('Important Safety Notice', style: AppTypography.labelMedium),
                    ],
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    'CAREN does not diagnose fainting, heart attacks, strokes, or any medical condition. Never delay emergency services, CPR, or medical care to record information.',
                    style: AppTypography.caption,
                  ),
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

