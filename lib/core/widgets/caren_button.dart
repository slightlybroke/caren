import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';

enum CarenButtonVariant { primary, secondary, outline, text, danger }

class CarenButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final CarenButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double minHeight;

  const CarenButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = CarenButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.minHeight = AppSpacing.minTouchTarget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(
                variant == CarenButtonVariant.primary ? AppColors.onPrimary : AppColors.primary,
              ),
            ),
          )
        : Row(
            mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                label,
                style: AppTypography.labelLarge.copyWith(
                  color: _getTextColor(),
                ),
              ),
            ],
          );

    final style = _getButtonStyle(theme);

    Widget button;
    switch (variant) {
      case CarenButtonVariant.primary:
      case CarenButtonVariant.secondary:
      case CarenButtonVariant.danger:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: style,
          child: child,
        );
        break;
      case CarenButtonVariant.outline:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: style,
          child: child,
        );
        break;
      case CarenButtonVariant.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: style,
          child: child,
        );
        break;
    }

    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }
    return button;
  }

  Color _getTextColor() {
    switch (variant) {
      case CarenButtonVariant.primary:
        return AppColors.onPrimary;
      case CarenButtonVariant.secondary:
        return AppColors.onSecondary;
      case CarenButtonVariant.outline:
        return AppColors.primary;
      case CarenButtonVariant.text:
        return AppColors.primary;
      case CarenButtonVariant.danger:
        return Colors.white;
    }
  }

  ButtonStyle _getButtonStyle(ThemeData theme) {
    final baseShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
    );

    switch (variant) {
      case CarenButtonVariant.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          minimumSize: Size(minHeight, minHeight),
          shape: baseShape,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        );
      case CarenButtonVariant.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondaryContainer,
          foregroundColor: AppColors.onSecondary,
          elevation: 0,
          minimumSize: Size(minHeight, minHeight),
          shape: baseShape,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        );
      case CarenButtonVariant.outline:
        return OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          minimumSize: Size(minHeight, minHeight),
          shape: baseShape,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        );
      case CarenButtonVariant.text:
        return TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: Size(minHeight, minHeight),
          shape: baseShape,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        );
      case CarenButtonVariant.danger:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.danger,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: Size(minHeight, minHeight),
          shape: baseShape,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        );
    }
  }
}

