import 'package:flutter/material.dart';
import '../../features/profile/domain/user_profile.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';

/// Authoritative country selector matching [CarenTextField] styling identically.
///
/// Ensures:
/// - Same overall container height (52dp).
/// - Same border thickness (1.0dp unselected, 1.8dp focused), radius (radiusMd), and surface background.
/// - Same label typography and vertical spacing.
/// - Ellipsis overflow handling on narrow devices (320px width) with long country names.
/// - Native modal sheet for quick, ergonomic country selection with localized emergency numbers.
class CarenCountryPickerField extends StatefulWidget {
  final String label;
  final String selectedCountry;
  final ValueChanged<String> onCountrySelected;
  final String? errorText;
  final bool enabled;

  const CarenCountryPickerField({
    super.key,
    this.label = 'Country (for Emergency Localization)',
    required this.selectedCountry,
    required this.onCountrySelected,
    this.errorText,
    this.enabled = true,
  });

  @override
  State<CarenCountryPickerField> createState() => _CarenCountryPickerFieldState();
}

class _CarenCountryPickerFieldState extends State<CarenCountryPickerField> {
  bool _isFocused = false;

  void _openCountrySelectorSheet() async {
    if (!widget.enabled) return;

    setState(() => _isFocused = true);

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Country',
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.primaryDark,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Localizes your one-touch emergency dialer (112, 911, 999) without network dependency.',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.md),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: EmergencyDirectory.countryNumbers.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.divider),
                    itemBuilder: (context, index) {
                      final country = EmergencyDirectory.countryNumbers.keys.elementAt(index);
                      final number = EmergencyDirectory.countryNumbers[country]!;
                      final isCurrent = country == widget.selectedCountry;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        leading: Icon(
                          Icons.location_on_outlined,
                          color: isCurrent ? AppColors.primary : AppColors.textMuted,
                          size: 22,
                        ),
                        title: Text(
                          country,
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                            color: isCurrent ? AppColors.primary : AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCurrent ? AppColors.primaryContainer : AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Text(
                            number,
                            style: AppTypography.labelMedium.copyWith(
                              color: isCurrent ? AppColors.primaryDark : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        onTap: () => Navigator.of(sheetContext).pop(country),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (mounted) {
      setState(() => _isFocused = false);
      if (selected != null && selected != widget.selectedCountry) {
        widget.onCountrySelected(selected);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizedNumber = EmergencyDirectory.getNumber(widget.selectedCountry);
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTypography.labelLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          onTap: widget.enabled ? _openCountrySelectorSheet : null,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 52.0,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: hasError
                    ? AppColors.danger
                    : _isFocused
                        ? AppColors.primary
                        : AppColors.border,
                width: (_isFocused || hasError) ? 1.8 : 1.0,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.public_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    widget.selectedCountry,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    'SOS $localizedNumber',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            widget.errorText!,
            style: AppTypography.caption.copyWith(color: AppColors.danger),
          ),
        ] else ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Localized emergency number: $localizedNumber',
            style: AppTypography.caption.copyWith(color: AppColors.primaryDark),
          ),
        ],
      ],
    );
  }
}
