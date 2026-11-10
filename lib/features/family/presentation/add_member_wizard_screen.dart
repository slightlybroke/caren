import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_branding.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/caren_button.dart';
import '../../../core/widgets/caren_card.dart';
import '../../../core/widgets/caren_text_field.dart';
import '../data/family_repository.dart';

/// Full-screen 3-step wizard for inviting a new family member to the circle.
/// Visual source of truth: Google Stitch "Serene Hearth" screens:
/// - Step 1: Role & Relationship (`16e66b749e504f7e8914822a5edfc024`)
/// - Step 2: Privacy Boundaries (`7a49b3e4f70f4b6f8eca7f966281ad14`)
/// - Step 3: Invite & Activation (`00b3f4b1e8e64f66bb65e8c3a1df641b`)
class AddMemberWizardScreen extends ConsumerStatefulWidget {
  const AddMemberWizardScreen({super.key});

  @override
  ConsumerState<AddMemberWizardScreen> createState() => _AddMemberWizardScreenState();
}

class _AddMemberWizardScreenState extends ConsumerState<AddMemberWizardScreen> {
  int _currentStep = 1;

  // Step 1 State: Role & Relationship
  final _nameController = TextEditingController();
  String _selectedRelationship = 'Parent / Elder';
  final _customRelationController = TextEditingController();
  bool _livesIndependently = true;
  String _selectedArchetype = 'elder'; // elder, companion, physician
  bool _assistedSetup = true;

  // Step 2 State: Privacy Boundaries (All default to OFF per sovereign consent policy)
  bool _shareCheckInStatus = false;
  bool _shareSelfReportedMood = false;
  bool _shareVitalsMeasurements = false;
  bool _shareNotes = false;

  // Step 3 State: Invite & Activation
  final _emailController = TextEditingController();
  bool _isSending = false;
  String? _errorMessage;
  bool _isSubmittedSuccess = false;
  late final String _generatedPasscode;

  final List<String> _relationshipOptions = const [
    'Parent / Elder',
    'Spouse / Partner',
    'Sibling',
    'Child',
    'Close Friend',
    'Caregiver / Physician',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    // Cryptographically secure 6-digit passcode for activation
    final secureRandom = Random.secure();
    _generatedPasscode = (100000 + secureRandom.nextInt(900000)).toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _customRelationController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String get _effectiveRelationship {
    if (_selectedRelationship == 'Other') {
      final custom = _customRelationController.text.trim();
      return custom.isNotEmpty ? custom : 'Other';
    }
    return _selectedRelationship;
  }

  void _handleBack() {
    if (_isSubmittedSuccess) {
      context.pop();
      return;
    }
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
        _errorMessage = null;
      });
    } else {
      _promptExit();
    }
  }

  void _promptExit() {
    final hasInput = _nameController.text.trim().isNotEmpty ||
        _emailController.text.trim().isNotEmpty;
    if (!hasInput) {
      context.pop();
      return;
    }

    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Discard Invitation?', style: AppTypography.titleLarge),
        content: const Text(
          'You have unsubmitted invitation details. Are you sure you want to close without sending?',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Editing'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx, true);
              context.pop();
            },
            child: Text(
              'Discard',
              style: AppTypography.labelLarge.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitInvitation() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter an email address for the invitee.');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      await ref.read(familyRepositoryProvider).sendInvitation(
            inviteeEmail: email,
            relationship: _effectiveRelationship,
            sharingPermissions: {
              'shareCheckInStatus': _shareCheckInStatus,
              'shareSelfReportedMood': _shareSelfReportedMood,
              'shareVitalsMeasurements': _shareVitalsMeasurements,
              'shareNotes': _shareNotes,
            },
            passcode: _generatedPasscode,
          );

      if (mounted) {
        setState(() {
          _isSending = false;
          _isSubmittedSuccess = true;
        });
        ref.invalidate(familyMembersProvider);
        ref.invalidate(sentInvitationsProvider);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            tooltip: 'Go back',
            icon: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, size: 20, color: AppColors.textSecondary),
            ),
            onPressed: _handleBack,
          ),
          title: Image.asset(
            AppBranding.wordmark,
            height: 24,
            fit: BoxFit.contain,
            semanticLabel: 'caren',
          ),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'Close wizard',
              icon: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
              ),
              onPressed: _promptExit,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Step Progress Header Pill
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                child: _buildStepIndicator(),
              ),
              const Divider(height: 1, color: AppColors.surfaceVariant),

              // Step Content Area
              Expanded(
                child: SingleChildScrollView(
                  padding: AppSpacing.screenPadding,
                  child: _isSubmittedSuccess ? _buildSuccessView() : _buildActiveStepView(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    String stepLabel;
    switch (_currentStep) {
      case 1:
        stepLabel = 'Step 1 of 3: Role & Relationship';
        break;
      case 2:
        stepLabel = 'Step 2 of 3: Privacy Boundaries';
        break;
      case 3:
      default:
        stepLabel = 'Step 3 of 3: Pair & Welcome';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              stepLabel,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveStepView() {
    switch (_currentStep) {
      case 1:
        return _buildStep1RoleAndRelationship();
      case 2:
        return _buildStep2PrivacyBoundaries();
      case 3:
      default:
        return _buildStep3InviteAndActivation();
    }
  }

  // ==========================================
  // STEP 1: ROLE & RELATIONSHIP
  // ==========================================
  Widget _buildStep1RoleAndRelationship() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Who are you inviting?',
          style: AppTypography.displayMedium.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'caren tailors touchpoints based on how your loved one interacts with technology.',
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),

        // Member Basic Profile Card
        CarenCard(
          backgroundColor: AppColors.surfaceContainerLow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CarenTextField(
                label: "Loved One's Name",
                hint: 'e.g. Papa / Ramesh Sharma',
                controller: _nameController,
                prefixIcon: const Icon(Icons.favorite_outline, color: AppColors.secondary),
              ),
              const SizedBox(height: AppSpacing.md),

              const Text('Relationship', style: AppTypography.labelLarge),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _relationshipOptions.map((rel) {
                  final isSelected = _selectedRelationship == rel;
                  return ChoiceChip(
                    label: Text(rel),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedRelationship = rel);
                    },
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surfaceContainer,
                    labelStyle: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9999),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                      ),
                    ),
                  );
                }).toList(),
              ),

              if (_selectedRelationship == 'Other') ...[
                const SizedBox(height: AppSpacing.sm),
                CarenTextField(
                  label: 'Custom Relationship',
                  hint: 'e.g. Aunt, Mentor, Neighbor',
                  controller: _customRelationController,
                ),
              ],

              const SizedBox(height: AppSpacing.md),
              const Text('Living Arrangement', style: AppTypography.labelLarge),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: _buildArrangementOption(
                      icon: Icons.location_on_outlined,
                      label: 'Lives independently',
                      sublabel: 'Different home or city',
                      isSelected: _livesIndependently,
                      onTap: () => setState(() => _livesIndependently = true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildArrangementOption(
                      icon: Icons.cottage_outlined,
                      label: 'Same household',
                      sublabel: 'Living together',
                      isSelected: !_livesIndependently,
                      onTap: () => setState(() => _livesIndependently = false),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),
        const Text('Care Role Profile', style: AppTypography.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Choose how caren presents routines, notifications, and permissions for this member.',
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),

        // Role Archetype Cards
        _buildArchetypeCard(
          id: 'elder',
          title: 'Elder / Primary Loved One',
          badge: 'Recommended for Parents & Grandparents',
          description:
              'High-contrast large touch targets, warm audio check-ins, automated morning reminders, and 1-tap SOS.',
          icon: Icons.elderly_rounded,
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildArchetypeCard(
          id: 'companion',
          title: 'Family Companion',
          badge: 'Equal Co-Member',
          description:
              'Full standard interface. Celebrates milestones, sends gentle check-ins, and coordinates family care.',
          icon: Icons.groups_rounded,
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildArchetypeCard(
          id: 'physician',
          title: 'Physician or Dedicated Care Aide',
          badge: 'Clinical View',
          description:
              'Read-only access to doctor-ready wellness exports, medical notes, and vital trendlines.',
          icon: Icons.medical_services_outlined,
        ),

        const SizedBox(height: AppSpacing.md),
        // Assisted Setup Checkbox
        CarenCard(
          backgroundColor: AppColors.secondaryContainer.withAlpha(120),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'I will guide them through setup',
                          style: AppTypography.titleSmall,
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Generates a single-use voice activation passcode and step-by-step setup guidance.',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch.adaptive(
                    activeTrackColor: AppColors.primary,
                    value: _assistedSetup,
                    onChanged: (val) => setState(() => _assistedSetup = val),
                  ),
                ],
              ),
              if (_assistedSetup) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const Icon(Icons.record_voice_over_outlined, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Audio onboarding guidance available during first sign-in.',
                        style: AppTypography.caption.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xl),
        CarenButton(
          label: 'Continue to Privacy Boundaries',
          icon: Icons.arrow_forward,
          onPressed: () {
            if (_nameController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please enter the loved one's name.")),
              );
              return;
            }
            setState(() => _currentStep = 2);
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: TextButton(
            onPressed: _promptExit,
            child: Text(
              'Cancel & return to Family',
              style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildArrangementOption({
    required IconData icon,
    required String label,
    required String sublabel,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primary.withAlpha(20), blurRadius: 6, offset: const Offset(0, 2))]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: isSelected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(sublabel, style: AppTypography.caption),
          ],
        ),
      ),
    );
  }

  Widget _buildArchetypeCard({
    required String id,
    required String title,
    required String badge,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _selectedArchetype == id;
    return InkWell(
      onTap: () => setState(() => _selectedArchetype = id),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cardBackground : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primary.withAlpha(20), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isSelected ? AppColors.secondaryContainer : AppColors.surfaceContainer,
                  child: Icon(icon, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.titleSmall.copyWith(
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.tertiaryContainer.withAlpha(140),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          badge,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.onTertiaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.outline,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(description, style: AppTypography.bodySmall),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // STEP 2: PRIVACY BOUNDARIES
  // ==========================================
  Widget _buildStep2PrivacyBoundaries() {
    final name = _nameController.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configure Sovereign Boundaries',
          style: AppTypography.displayMedium.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Choose what $name will share with the Circle by default. $name retains complete sovereignty and can adjust these anytime.',
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),

        // Autonomous Dignity Banner
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.secondaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: Icon(Icons.verified_user, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Autonomous Dignity First',
                      style: AppTypography.titleSmall.copyWith(color: AppColors.primaryDark),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Family care never means quiet surveillance. All sharing permissions default to OFF and must be voluntarily configured.',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),
        const Text('Consent & Sharing Permissions', style: AppTypography.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'All permissions default to OFF until explicitly turned on.',
          style: AppTypography.caption,
        ),
        const SizedBox(height: AppSpacing.md),

        // 1. Morning Check-in Status
        _buildPermissionTile(
          icon: Icons.wb_twilight_rounded,
          title: 'Daily Check-in Completion',
          description: 'Allows circle members to see whether a daily check-in was finished.',
          value: _shareCheckInStatus,
          onChanged: (val) => setState(() => _shareCheckInStatus = val),
        ),
        const SizedBox(height: AppSpacing.sm),

        // 2. Self-reported Mood
        _buildPermissionTile(
          icon: Icons.sentiment_satisfied_rounded,
          title: 'Self-Reported Feeling & Mood',
          description: 'Shares overall energy and morning mood answer with the family.',
          value: _shareSelfReportedMood,
          onChanged: (val) => setState(() => _shareSelfReportedMood = val),
        ),
        const SizedBox(height: AppSpacing.sm),

        // 3. Contactless Camera Scans (rPPG)
        _buildPermissionTile(
          icon: Icons.videocam_outlined,
          title: 'Optional Camera Spot-Check Vitals',
          description:
              'Shares voluntary pulse rate readings only when user completes a camera check.',
          value: _shareVitalsMeasurements,
          onChanged: (val) => setState(() => _shareVitalsMeasurements = val),
        ),
        const SizedBox(height: AppSpacing.sm),

        // 4. Check-in Notes
        _buildPermissionTile(
          icon: Icons.note_outlined,
          title: 'Personal Check-in Notes',
          description: 'Shares written reflection messages attached to daily check-ins.',
          value: _shareNotes,
          onChanged: (val) => setState(() => _shareNotes = val),
        ),
        const SizedBox(height: AppSpacing.sm),

        // 5. Personal Diary & Me Sanctuary (LOCKED 100% PRIVATE)
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh.withAlpha(160),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.surfaceContainer,
                child: Icon(Icons.lock, size: 18, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Private Me Sanctuary', style: AppTypography.labelLarge),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: const Text('100% Private (Locked)', style: AppTypography.caption),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Guided breathwork, relaxation sessions, and private HRV are strictly confidential and never accessible to family members.',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // 6. Emergency SOS Escalation (PROTECTED ACTIVE)
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.dangerContainer.withAlpha(140),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.danger,
                child: Icon(Icons.health_and_safety, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Emergency SOS Action', style: AppTypography.labelLarge),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            'Essential Safety',
                            style: AppTypography.caption.copyWith(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Emergency assistance number (112) and manual responder notification remain readily accessible.',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: CarenButton(
                label: 'Back',
                variant: CarenButtonVariant.outline,
                onPressed: () => setState(() => _currentStep = 1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: CarenButton(
                label: 'Continue to Invite Link',
                icon: Icons.arrow_forward,
                onPressed: () => setState(() => _currentStep = 3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: value ? AppColors.secondaryContainer.withAlpha(120) : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? AppColors.secondary : Colors.transparent,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: value ? AppColors.secondaryContainer : AppColors.surfaceContainer,
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.labelLarge),
                const SizedBox(height: 2),
                Text(description, style: AppTypography.bodySmall),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 3: INVITE & ACTIVATION
  // ==========================================
  Widget _buildStep3InviteAndActivation() {
    final name = _nameController.text.trim();
    final relation = _effectiveRelationship;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome $name to the Hearth',
          style: AppTypography.displayMedium.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Send a secure invitation. Your loved one will be guided step-by-step with accessible buttons and clear privacy options.',
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),

        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.dangerContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.danger),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.danger),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Invitee Email Field (Required for Authenticated Firestore Invitation)
        CarenCard(
          backgroundColor: AppColors.surfaceContainerLow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Invitee Account Email', style: AppTypography.titleSmall),
              const SizedBox(height: 4),
              const Text(
                'Invitations require matching email authentication for circle security.',
                style: AppTypography.caption,
              ),
              const SizedBox(height: AppSpacing.sm),
              CarenTextField(
                label: 'Email address of invitee',
                hint: 'lovedone@example.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.secondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Member Summary Card
        CarenCard(
          backgroundColor: AppColors.secondaryContainer.withAlpha(100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'M',
                      style: AppTypography.titleLarge.copyWith(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: AppTypography.titleMedium),
                        Text(
                          '$relation • ${_livesIndependently ? 'Lives independently' : 'Same household'}',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      'Ready to Pair',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              const Text('Configured Permissions:', style: AppTypography.labelLarge),
              const SizedBox(height: 6),
              _buildPermissionSummaryItem('Daily Check-in Status', _shareCheckInStatus),
              _buildPermissionSummaryItem('Self-Reported Feeling', _shareSelfReportedMood),
              _buildPermissionSummaryItem('Camera Spot-Check Vitals', _shareVitalsMeasurements),
              _buildPermissionSummaryItem('Check-in Notes', _shareNotes),
              _buildPermissionSummaryItem('Me Sanctuary Sessions', false, isAlwaysPrivate: true),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Single-Use Passcode Card (Serene Hearth Step 3)
        CarenCard(
          backgroundColor: AppColors.surfaceContainerLow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.key, size: 18, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text('Voice & Text Passcode', style: AppTypography.labelLarge),
                    ],
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy code'),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _generatedPasscode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Passcode copied to clipboard.')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Digit blocks
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDigitBlock(_generatedPasscode.substring(0, 1)),
                  _buildDigitBlock(_generatedPasscode.substring(1, 2)),
                  _buildDigitBlock(_generatedPasscode.substring(2, 3)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text('–', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  _buildDigitBlock(_generatedPasscode.substring(3, 4)),
                  _buildDigitBlock(_generatedPasscode.substring(4, 5)),
                  _buildDigitBlock(_generatedPasscode.substring(5, 6)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.verified_user_outlined, size: 14, color: AppColors.secondary),
                      SizedBox(width: 4),
                      Text('Valid for 7 days • Single-use', style: AppTypography.caption),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      'Spoken aloud on call',
                      style: AppTypography.caption.copyWith(color: AppColors.onPrimaryContainer),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xl),
        // Primary Submit Action
        CarenButton(
          label: _isSending ? 'Sending Invitation...' : 'Send Invitation via Email',
          icon: _isSending ? null : Icons.send_rounded,
          onPressed: _isSending ? null : _submitInvitation,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: CarenButton(
                label: 'Back',
                variant: CarenButtonVariant.outline,
                onPressed: _isSending ? null : () => setState(() => _currentStep = 2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDigitBlock(String digit) {
    return Container(
      width: 38,
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      alignment: Alignment.center,
      child: Text(
        digit,
        style: AppTypography.titleLarge.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildPermissionSummaryItem(String label, bool isEnabled, {bool isAlwaysPrivate = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isAlwaysPrivate
                ? Icons.lock
                : (isEnabled ? Icons.check_circle : Icons.radio_button_unchecked),
            size: 16,
            color: isAlwaysPrivate
                ? AppColors.textMuted
                : (isEnabled ? AppColors.primary : AppColors.textMuted),
          ),
          const SizedBox(width: 8),
          Text(label, style: AppTypography.bodySmall),
          const Spacer(),
          Text(
            isAlwaysPrivate ? '100% Private' : (isEnabled ? 'Shared' : 'Off'),
            style: AppTypography.caption.copyWith(
              color: isEnabled ? AppColors.primary : AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 32),
        const CircleAvatar(
          radius: 40,
          backgroundColor: AppColors.primaryContainer,
          child: Icon(Icons.check, size: 48, color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Invitation Dispatched!',
          style: AppTypography.displayMedium.copyWith(color: AppColors.primary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'A secure family invitation has been sent to $email for $name.',
          style: AppTypography.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        CarenCard(
          backgroundColor: AppColors.surfaceContainerLow,
          child: Column(
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.timer_outlined, color: AppColors.secondary),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Valid for 7 days', style: AppTypography.titleSmall),
                          SizedBox(height: 2),
                          Text(
                            'Your loved one can accept anytime with their verified email account.',
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 16),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.shield_outlined, color: AppColors.secondary),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Zero-surveillance guarantee', style: AppTypography.titleSmall),
                          SizedBox(height: 2),
                          Text(
                            'They choose what to share independently upon joining.',
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        CarenButton(
          label: 'Return to Family Dashboard',
          onPressed: () => context.go('/family'),
        ),
      ],
    );
  }
}
