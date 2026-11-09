import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

  final List<_OnboardingPageData> _pages = const [
    _OnboardingPageData(
      icon: Icons.people_outline_rounded,
      title: 'Care without surveillance',
      description:
          'Stay connected with voluntary daily check-ins for parents and loved ones living anywhere. Transparent, private, and always revocable.',
    ),
    _OnboardingPageData(
      icon: Icons.spa_outlined,
      title: 'A private space for Me',
      description:
          'Take a breath with guided relaxation sessions from 2 to 10 minutes. Your personal sessions are strictly private and never shared.',
    ),
    _OnboardingPageData(
      icon: Icons.shield_outlined,
      title: 'Safety-first Assist',
      description:
          'Clear, timestamped documentation when someone nearby needs assistance, with direct access to emergency services when every second counts.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.bug_report_outlined, size: 20, color: AppColors.textSecondary),
                    tooltip: 'Developer Diagnostics',
                    onPressed: () => context.push('/diagnostics'),
                  ),
                  TextButton(
                    onPressed: () => context.go('/family'),
                    child: Text('Skip', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
                  ),
                ],
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, index) {
                    final item = _pages[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(item.icon, size: 54, color: AppColors.primary),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Text(
                            item.title,
                            textAlign: TextAlign.center,
                            style: AppTypography.displayMedium.copyWith(color: AppColors.primaryDark),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            item.description,
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? AppColors.primary : AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.xl),
              CarenButton(
                label: _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                onPressed: () {
                  if (_currentPage < _pages.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    context.go('/register');
                  }
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              CarenButton(
                label: 'I already have an account',
                variant: CarenButtonVariant.text,
                onPressed: () => context.go('/login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
  });
}

