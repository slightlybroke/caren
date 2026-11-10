import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_branding.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/caren_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      category: 'FAMILY CIRCLES',
      categoryIcon: Icons.favorite_outline_rounded,
      icon: Icons.people_outline_rounded,
      title: 'Care without surveillance',
      description:
          'Stay connected through voluntary daily check-ins for parents and loved ones living anywhere. Transparent, private, and always revocable.',
      accentContainer: AppColors.primaryContainer,
      accentColor: AppColors.primary,
    ),
    _OnboardingPageData(
      category: 'ME SANCTUARY',
      categoryIcon: Icons.spa_outlined,
      icon: Icons.self_improvement_rounded,
      title: 'A private space for Me',
      description:
          'Make room for gentle guided breathing, mindfulness, and personal reflection. Your sessions are strictly confidential and never shared.',
      accentContainer: AppColors.secondaryContainer,
      accentColor: AppColors.secondary,
    ),
    _OnboardingPageData(
      category: 'EMERGENCY ACCESS',
      categoryIcon: Icons.shield_outlined,
      icon: Icons.phone_in_talk_outlined,
      title: 'Reach help when it matters',
      description:
          'Direct, one-tap connection to local emergency services. Instant dialer assistance that never requires login, camera, or sensor setup.',
      accentContainer: AppColors.warningContainer,
      accentColor: AppColors.warning,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handlePrimaryAction() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    } else {
      context.go('/register');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            children: [
              // Editorial Top Brand Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (kDebugMode)
                    IconButton(
                      icon: const Icon(
                        Icons.bug_report_outlined,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      tooltip: 'Developer Diagnostics',
                      onPressed: () => context.push('/diagnostics'),
                    )
                  else
                    const SizedBox(width: 48, height: 48),

                  // Prominent brand wordmark
                  Hero(
                    tag: 'caren_brand_wordmark',
                    child: Image.asset(
                      AppBranding.wordmark,
                      height: 38,
                      fit: BoxFit.contain,
                      semanticLabel: 'caren',
                    ),
                  ),

                  TextButton(
                    onPressed: () => context.go('/family'),
                    child: Text(
                      'Skip',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Main Editorial Carousel Card
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, index) {
                    final item = _pages[index];
                    return _OnboardingSlideCard(data: item);
                  },
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Polished Page Indicator (Pill for active, subtle dots for inactive)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (index) {
                  final isActive = _currentPage == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primary
                          : AppColors.border.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Primary Action
              CarenButton(
                label: _currentPage == _pages.length - 1
                    ? 'Get Started'
                    : 'Continue',
                onPressed: _handlePrimaryAction,
              ),

              const SizedBox(height: AppSpacing.xs),

              // Secondary Action
              CarenButton(
                label: 'I already have an account',
                variant: CarenButtonVariant.text,
                onPressed: () => context.go('/login'),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlideCard extends StatelessWidget {
  final _OnboardingPageData data;

  const _OnboardingSlideCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.4),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Watermark Motif: Subtle emblem background
            Positioned(
              right: -14,
              bottom: -14,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.04,
                  child: Image.asset(
                    AppBranding.icon,
                    width: 140,
                    height: 140,
                    fit: BoxFit.contain,
                    color: AppColors.primary,
                    colorBlendMode: BlendMode.srcIn,
                  ),
                ),
              ),
            ),

            // Content
            Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Top Category Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: data.accentContainer.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            data.categoryIcon,
                            size: 14,
                            color: data.accentColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            data.category,
                            style: AppTypography.labelSmall.copyWith(
                              color: data.accentColor,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Hero Emblem-Styled Icon Container
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: data.accentContainer.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: data.accentColor.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          data.icon,
                          size: 46,
                          color: data.accentColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Title
                    Text(
                      data.title,
                      textAlign: TextAlign.center,
                      style: AppTypography.displayMedium.copyWith(
                        color: AppColors.primaryDark,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Description
                    Text(
                      data.description,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final String category;
  final IconData categoryIcon;
  final IconData icon;
  final String title;
  final String description;
  final Color accentContainer;
  final Color accentColor;

  const _OnboardingPageData({
    required this.category,
    required this.categoryIcon,
    required this.icon,
    required this.title,
    required this.description,
    required this.accentContainer,
    required this.accentColor,
  });
}
