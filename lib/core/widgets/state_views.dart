import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';
import 'caren_button.dart';

class CarenLoadingView extends StatelessWidget {
  final String message;

  const CarenLoadingView({
    super.key,
    this.message = 'Loading wellness information...',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              strokeWidth: 3,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class CarenEmptyView extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const CarenEmptyView({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.spa_outlined,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: const BoxDecoration(
                color: AppColors.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              CarenButton(
                label: actionLabel!,
                onPressed: onAction,
                isFullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CarenPermissionDeniedView extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onGrantPermission;
  final VoidCallback? onContinueWithout;

  const CarenPermissionDeniedView({
    super.key,
    this.title = 'Camera Access Needed for Measurement',
    this.description =
        'CAREN uses your front camera to observe pulse and breathing signals during voluntary spot-checks. We never record, upload, or store video. You can also complete your check-in with self-reported answers.',
    required this.onGrantPermission,
    this.onContinueWithout,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: const BoxDecoration(
                color: AppColors.warningContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.videocam_off_outlined, size: 44, color: AppColors.warning),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              description,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            CarenButton(
              label: 'Grant Camera Access',
              onPressed: onGrantPermission,
              icon: Icons.camera_alt_outlined,
            ),
            if (onContinueWithout != null) ...[
              const SizedBox(height: AppSpacing.sm),
              CarenButton(
                label: 'Continue without camera',
                onPressed: onContinueWithout,
                variant: CarenButtonVariant.text,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CarenErrorView extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const CarenErrorView({
    super.key,
    this.title = 'Something didn’t work quite right',
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: const BoxDecoration(
                color: AppColors.dangerContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.refresh_rounded, size: 40, color: AppColors.danger),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.xl),
              CarenButton(
                label: 'Try Again',
                onPressed: onRetry,
                isFullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

