import 'package:flutter/material.dart';
import '../../../../core/constants/app_branding.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';

/// Authoritative authentication brand header for caren.
///
/// Features:
/// - Prominently displays the approved horizontal wordmark (40dp height, ~120dp width).
/// - Incorporates the standalone emblem as an elegant, non-competing watermark motif.
/// - Replaces generic app-bar titles ("Sign In", "Create Account") with clean brand identity.
/// - Honors the Serene Hearth palette (Warm Ivory & Deep Forest).
/// - Accommodates leading back navigation when appropriate.
class AuthBrandHeader extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leading;
  final List<Widget>? actions;
  final bool showBackButton;

  const AuthBrandHeader({
    super.key,
    this.leading,
    this.actions,
    this.showBackButton = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(76.0);

  @override
  Widget build(BuildContext context) {
    final showLeading = leading != null || showBackButton;

    return Container(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: preferredSize.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Subtle background emblem watermark (non-competing motif)
              Positioned(
                right: -16,
                top: -12,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.05,
                    child: Image.asset(
                      AppBranding.icon,
                      width: 96,
                      height: 96,
                      fit: BoxFit.contain,
                      color: AppColors.primary,
                      colorBlendMode: BlendMode.srcIn,
                      semanticLabel: 'caren emblem watermark',
                    ),
                  ),
                ),
              ),

              // Foreground content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Row(
                  children: [
                    if (showLeading)
                      leading ??
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: AppColors.primary,
                            ),
                            tooltip: 'Back',
                            onPressed: () => Navigator.of(context).maybePop(),
                          )
                    else
                      const SizedBox(width: AppSpacing.md),

                    // Prominent Brand Wordmark
                    Hero(
                      tag: 'caren_brand_wordmark',
                      child: Image.asset(
                        AppBranding.wordmark,
                        height: 38,
                        fit: BoxFit.contain,
                        alignment: Alignment.centerLeft,
                        semanticLabel: 'caren',
                      ),
                    ),

                    const Spacer(),

                    ...?actions,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
