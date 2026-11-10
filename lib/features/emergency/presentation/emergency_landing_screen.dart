import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/caren_app_bar.dart';
import '../../../core/widgets/caren_button.dart';
import '../../../core/widgets/caren_card.dart';
import '../../../services/emergency/emergency_dialer_service.dart';
import '../../assist/data/assist_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/domain/user_profile.dart';

class EmergencyLandingScreen extends ConsumerWidget {
  const EmergencyLandingScreen({super.key});

  Future<void> _handleEmergencyCall(
    BuildContext context,
    WidgetRef ref,
    String emergencyNumber,
    String country,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.danger,
              size: 28,
            ),
            const SizedBox(width: 8),
            Flexible(child: Text('Call Emergency ($emergencyNumber)?')),
          ],
        ),
        content: Text(
          'This will open your phone\'s dialer for official emergency dispatchers ($emergencyNumber in $country).\n\ncaren never places calls automatically without your explicit action.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            icon: const Icon(Icons.phone, color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(ctx, true),
            label: Text(
              'Open Dialer ($emergencyNumber)',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final result = await ref
          .read(emergencyDialerServiceProvider)
          .launchDialer(emergencyNumber);
      if (!result.isSuccess && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text(
              result.errorMessage ??
                  'Could not launch dialer. Please dial $emergencyNumber directly.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final emergencyNumber =
        profileAsync.asData?.value.emergencyNumber ??
        EmergencyDirectory.fallbackNumber;
    final country = profileAsync.asData?.value.country ?? 'India';

    return Scaffold(
      appBar: const CarenAppBar(title: 'Emergency', showProfileButton: true),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Prominent Localized Emergency Banner
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.dangerContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.danger.withAlpha(80)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.emergency_rounded,
                        color: AppColors.danger,
                        size: 28,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Immediate Assistance Needed?',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.danger,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'If you or someone nearby is unresponsive, experiencing acute chest pain, or having severe trouble breathing, call $emergencyNumber ($country) immediately.',
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: CarenButton(
                      label: 'Call Emergency Services ($emergencyNumber)',
                      icon: Icons.phone_in_talk,
                      variant: CarenButtonVariant.danger,
                      onPressed: () => _handleEmergencyCall(
                        context,
                        ref,
                        emergencyNumber,
                        country,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Start Assistance Session Card
            Text('Incident Timeline & Log', style: AppTypography.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Document timestamped observations and actions when someone is unwell. Create an exportable summary for first responders or physicians.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
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
                        child: const Icon(
                          Icons.edit_calendar_outlined,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Assistance Session & Handoff',
                              style: AppTypography.titleMedium,
                            ),
                            Text(
                              'Time-tracked symptoms, vitals, & notes',
                              style: AppTypography.caption,
                            ),
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
                      final session = await ref
                          .read(assistRepositoryProvider)
                          .startNewSession();
                      if (context.mounted) {
                        context.push(
                          '/emergency/session?sessionId=${session.id}',
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // First Aid Quick References
            Text('First Aid References', style: AppTypography.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            _FirstAidCard(
              title: 'Recovery Position',
              subtitle: 'For unconscious persons who are breathing normally',
              icon: Icons.airline_seat_flat_rounded,
              details:
                  '1. Place person on their side.\n2. Tilt head backward gently to maintain open airway.\n3. Bend top knee at a right angle to prevent rolling.\n4. Call $emergencyNumber and stay with them continuously.',
            ),
            const SizedBox(height: AppSpacing.sm),
            _FirstAidCard(
              title: 'Severe Shortness of Breath',
              subtitle: 'Calm posture & support',
              icon: Icons.air_rounded,
              details:
                  '1. Help person sit upright and lean forward slightly.\n2. Loosen tight clothing around chest and neck.\n3. Encourage slow, steady breathing.\n4. If breathing deteriorates or lips turn bluish, call $emergencyNumber immediately.',
            ),
            const SizedBox(height: AppSpacing.lg),

            // Safety Notice
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
                      Icon(
                        Icons.shield_outlined,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: AppSpacing.xs),
                      Text(
                        'Important Medical Notice',
                        style: AppTypography.labelMedium,
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    'caren does not diagnose heart attacks, stroke, or critical medical events. Never delay calling official emergency dispatch or beginning CPR to record information in any app.',
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

class _FirstAidCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String details;

  const _FirstAidCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.details,
  });

  @override
  State<_FirstAidCard> createState() => _FirstAidCardState();
}

class _FirstAidCardState extends State<_FirstAidCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return CarenCard(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(widget.icon, color: AppColors.primary, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: AppTypography.titleSmall),
                    Text(widget.subtitle, style: AppTypography.caption),
                  ],
                ),
              ),
              Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                color: AppColors.textSecondary,
              ),
            ],
          ),
          if (_expanded) ...[
            const Divider(height: AppSpacing.lg),
            Text(widget.details, style: AppTypography.bodySmall),
          ],
        ],
      ),
    );
  }
}
