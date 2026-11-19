import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router/app_router.dart';
import '../../features/authentication/data/auth_repository.dart';
import '../../features/authentication/domain/auth_user.dart';
import '../../features/authentication/presentation/controllers/auth_controller.dart';
import '../config/demo_config.dart';
import '../constants/app_branding.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

/// Responsive desktop presentation shell for caren.
///
/// On desktop and wide viewports (width >= 960px):
/// - Displays a serene two-panel layout matching the Serene Hearth design system.
/// - Left panel: Editorial introduction, feature carousel, and one-click demo access.
/// - Right panel: Centered, realistic smartphone frame containing the live, interactive app.
///
/// On mobile viewports (width < 960px):
/// - Displays a mobile welcome card for unauthenticated web visitors or passes through
///   the app full-screen natively when authenticated or running on native mobile.
class WebResponsiveShell extends ConsumerStatefulWidget {
  final Widget child;

  const WebResponsiveShell({super.key, required this.child});

  @override
  ConsumerState<WebResponsiveShell> createState() => _WebResponsiveShellState();
}

class _WebResponsiveShellState extends ConsumerState<WebResponsiveShell> {
  int _activeFeatureIndex = 0;
  Timer? _carouselTimer;
  Timer? _clockTimer;
  bool _isAutoAdvancePaused = false;
  bool _isDemoLoggingIn = false;
  String? _demoError;

  final List<Map<String, dynamic>> _features = const [
    {
      'title': 'Family Circle',
      'subtitle': 'Voluntary Family Check-Ins',
      'description':
          'Stay connected across distances with voluntary, reassuring check-ins. See who has checked in today with gentle reminders and zero surveillance pressure.',
      'icon': Icons.diversity_1_outlined,
      'badge': 'COMMUNITY',
      'tint': Color(0xFFEBF2EC),
      'accent': Color(0xFF174F47),
    },
    {
      'title': 'Me Sanctuary',
      'subtitle': 'Mindful Routines & Breathwork',
      'description':
          'Approach personal wellbeing with guided breathing, sensory grounding, and mindful body relaxation — with a personal session history.',
      'icon': Icons.spa_outlined,
      'badge': 'MINDFUL',
      'tint': Color(0xFFF6F2EB),
      'accent': Color(0xFF5C4D35),
    },
    {
      'title': 'Contactless Vitals',
      'subtitle': 'Presage SmartSpectra Spot-Checks',
      'description':
          'On Android, SmartSpectra estimates pulse and breathing pace with live camera positioning feedback. The browser demo does not capture live vitals.',
      'icon': Icons.favorite_outline,
      'badge': 'CAMERA SENSORS',
      'tint': Color(0xFFEFEBF6),
      'accent': Color(0xFF4A396B),
    },
    {
      'title': 'Emergency Assist',
      'subtitle': 'Immediate Help & Handover',
      'description':
          'Instant one-tap emergency calling with localized dispatch resolution (112 / 911 / 999) and structured medical handover cards for first responders.',
      'icon': Icons.emergency_outlined,
      'badge': 'SAFETY FIRST',
      'tint': Color(0xFFFBEBEB),
      'accent': Color(0xFF8B2C2C),
    },
  ];

  @override
  void initState() {
    super.initState();
    _startCarouselTimer();
    _clockTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  void _startCarouselTimer() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(milliseconds: 4500), (_) {
      if (!_isAutoAdvancePaused && mounted) {
        setState(() {
          _activeFeatureIndex = (_activeFeatureIndex + 1) % _features.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  String get _currentLocalTime {
    final now = DateTime.now();
    final hour = now.hour == 0 ? 12 : (now.hour > 12 ? now.hour - 12 : now.hour);
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _handleDemoLogin() async {
    setState(() {
      _isDemoLoggingIn = true;
      _demoError = null;
    });

    try {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      try {
        await authNotifier.signIn(
          email: DemoConfig.demoEmail,
          password: DemoConfig.demoPassword,
        );
      } catch (signInErr) {
        // If demo user does not exist yet in auth repository, register automatically
        try {
          await authNotifier.register(
            email: DemoConfig.demoEmail,
            password: DemoConfig.demoPassword,
            displayName: DemoConfig.demoDisplayName,
            country: 'United States',
            city: 'Portland',
          );
        } catch (_) {
          // If register also fails because user already exists or similar, rethrow original error
          rethrow;
        }
      }

      if (mounted) {
        // Trigger navigation to family dashboard inside the embedded router
        final router = ref.read(appRouterProvider);
        router.go('/family');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _demoError =
              'Demo sign-in: ${e.toString().replaceFirst("Exception: ", "")}';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isDemoLoggingIn = false);
      }
    }
  }

  Future<void> _handleDemoSignOut() async {
    try {
      await ref.read(authNotifierProvider.notifier).signOut();
      if (mounted) {
        final router = ref.read(appRouterProvider);
        router.go('/login');
      }
    } catch (_) {}
  }

  Widget _buildMobileWelcomeScreen(BuildContext context, AuthUser? authUser) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 40,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Wordmark logo
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Image.asset(
                            AppBranding.wordmark,
                            width: (screenWidth * 0.55).clamp(180.0, 260.0),
                            fit: BoxFit.contain,
                            alignment: Alignment.centerLeft,
                            errorBuilder: (context, error, stackTrace) =>
                                const Text(
                              'caren',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        Text(
                          'CARE, CLOSER.',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Text(
                          'Make everyday wellbeing\nmore human and connected.',
                          style: AppTypography.displayMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 14),

                        Text(
                          'caren is your personal and family wellbeing companion. '
                          'Build healthy everyday routines, check in voluntarily with family, '
                          'and know where to turn when help is needed.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Carousel card
                        _buildFeatureCard(_features[_activeFeatureIndex]),
                        const SizedBox(height: 24),

                        // Demo CTA button
                        if (authUser == null) ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isDemoLoggingIn
                                  ? null
                                  : _handleDemoLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 3,
                                shadowColor:
                                    AppColors.primary.withValues(alpha: 0.3),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 18,
                                ),
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isDemoLoggingIn
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.auto_awesome,
                                          color: AppColors.peach,
                                          size: 19,
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          'Explore the Live Demo',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_forward, size: 17),
                                      ],
                                    ),
                            ),
                          ),
                          if (_demoError != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _demoError!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return widget.child;
    }

    final screenSize = MediaQuery.sizeOf(context);
    final isDesktop = screenSize.width >= 960;
    final authUser = ref.watch(currentUserProvider);

    // Mobile / Narrow viewports: Render real app full-screen natively when authenticated
    if (!isDesktop) {
      if (authUser != null) {
        return widget.child;
      }
      return _buildMobileWelcomeScreen(context, authUser);
    }

    // Wide Viewports: Two-Panel Responsive Desktop Presentation Shell
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Subtle ambient decorative gradients
          Positioned(
            left: -100,
            top: -80,
            width: 520,
            height: 520,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryContainer.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: -80,
            bottom: -60,
            width: 560,
            height: 560,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.tertiaryContainer.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Live Preview Status Pill in the top-right corner
          Positioned(
            top: 20,
            right: 24,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.6),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7.5,
                      height: 7.5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2E7D32),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Live Preview',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Main Balanced Two-Panel Composition
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left Panel: Editorial Branding & Feature Showcase
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(
                            left: 24,
                            right: 40,
                            top: 24,
                            bottom: 24,
                          ),
                          child: _buildIntroPanel(context, authUser),
                        ),
                      ),
                    ),
                  ),

                  // Thin Vertical Divider
                  Container(
                    width: 1,
                    height: math.min(780.0, screenSize.height - 64.0),
                    color: AppColors.border.withValues(alpha: 0.5),
                  ),

                  // Right Panel: Interactive Phone Frame
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 40,
                          right: 24,
                          top: 20,
                          bottom: 20,
                        ),
                        child: _buildPhoneFrame(context, screenSize),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroPanel(BuildContext context, AuthUser? authUser) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Brand Wordmark
        Align(
          alignment: Alignment.centerLeft,
          child: Image.asset(
            AppBranding.wordmark,
            width: 220,
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
            errorBuilder: (context, error, stackTrace) => const Text(
              'caren',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Editorial Heading
        Text(
          'Care, closer.',
          style: AppTypography.displayLarge.copyWith(
            color: AppColors.primaryDark,
            fontSize: 36,
            fontWeight: FontWeight.w700,
            height: 1.15,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 12),

        // Brand Introduction
        Text(
          'caren is your personal and family wellbeing companion. Build healthy everyday routines, stay connected with loved ones through voluntary check-ins, and know where to turn when help is needed.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            fontSize: 14.5,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 28),

        // Auto-Advancing Feature Card Carousel
        MouseRegion(
          onEnter: (_) => setState(() => _isAutoAdvancePaused = true),
          onExit: (_) => setState(() => _isAutoAdvancePaused = false),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: _buildFeatureCard(
              _features[_activeFeatureIndex],
              key: ValueKey<int>(_activeFeatureIndex),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Carousel Indicators & Counter
        Row(
          children: [
            ...List.generate(_features.length, (index) {
              final isSelected = index == _activeFeatureIndex;
              return GestureDetector(
                onTap: () => setState(() => _activeFeatureIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.only(right: 6),
                  width: isSelected ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.border.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
            const Spacer(),
            Text(
              '${(_activeFeatureIndex + 1).toString().padLeft(2, '0')} / ${_features.length.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: _features[_activeFeatureIndex]['accent'] as Color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Demo Actions Section
        if (authUser != null) ...[
          // State: Already authenticated
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.secondaryContainer,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Demo Session Active',
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Signed in as ${authUser.displayName ?? authUser.email}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _handleDemoSignOut,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                  ),
                  child: const Text(
                    'Sign Out',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // State: Unauthenticated - Prominent "Explore Demo" CTA Button
          ElevatedButton(
            onPressed: _isDemoLoggingIn ? null : _handleDemoLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: AppColors.primary.withValues(alpha: 0.3),
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              minimumSize: const Size(double.infinity, 54),
            ),
            child: _isDemoLoggingIn
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: AppColors.peach,
                        size: 19,
                      ),
                      SizedBox(width: 9),
                      Text(
                        'Explore the Live Demo',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
          ),

          if (_demoError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _demoError!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.error,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Or interact with login & signup directly inside the phone screen →',
              style: TextStyle(
                fontSize: 11.5,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFeatureCard(Map<String, dynamic> feature, {Key? key}) {
    final accent = feature['accent'] as Color;
    final tint = feature['tint'] as Color;

    return Container(
      key: key,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  feature['badge'] as String,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: accent,
                  ),
                ),
              ),
              Icon(
                feature['icon'] as IconData,
                size: 24,
                color: accent,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            feature['title'] as String,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            feature['description'] as String,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: accent.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneFrame(BuildContext context, Size screenSize) {
    final targetHeight = math.min(840.0, screenSize.height - 64.0);
    final targetWidth = (targetHeight * (9.0 / 19.5)).clamp(360.0, 410.0);

    return Container(
      width: targetWidth,
      height: targetHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF181C19),
        borderRadius: BorderRadius.circular(46),
        border: Border.all(color: const Color(0xFF2E3530), width: 8),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 40,
            spreadRadius: 4,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(38),
        child: Container(
          color: AppColors.background,
          child: Stack(
            children: [
              // Inner Phone Screen Canvas containing the live Flutter application
              Positioned.fill(
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    size: Size(targetWidth - 16, targetHeight - 16),
                    padding: const EdgeInsets.only(top: 44, bottom: 20),
                  ),
                  child: widget.child,
                ),
              ),

              // Realistic Phone Status Bar Simulation
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 44,
                child: IgnorePointer(child: _buildPhoneStatusBar(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneStatusBar(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background.withValues(alpha: 0.95),
            AppColors.background.withValues(alpha: 0.80),
            AppColors.background.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.75, 1.0],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Local Time
          SizedBox(
            width: 68,
            child: Text(
              _currentLocalTime,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ),

          // Center: Dynamic Island camera cutout
          Expanded(
            child: Center(
              child: Container(
                width: 82,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 10),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF151916),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 3.5,
                          height: 3.5,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0B1420),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Right: Cellular + Wi-Fi + Battery indicators
          SizedBox(
            width: 68,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildCellularSignal(),
                const SizedBox(width: 5),
                const Icon(Icons.wifi, size: 13, color: AppColors.primary),
                const SizedBox(width: 5),
                _buildBatteryIndicator(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCellularSignal() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSignalBar(height: 3.5),
        const SizedBox(width: 1.5),
        _buildSignalBar(height: 5.5),
        const SizedBox(width: 1.5),
        _buildSignalBar(height: 7.5),
        const SizedBox(width: 1.5),
        _buildSignalBar(height: 9.5),
      ],
    );
  }

  Widget _buildSignalBar({required double height}) {
    return Container(
      width: 2.2,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(0.8),
      ),
    );
  }

  Widget _buildBatteryIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 19,
          height: 10,
          padding: const EdgeInsets.all(1.2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2.8),
            border: Border.all(color: AppColors.primary, width: 1.1),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 13,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(1.2),
              ),
            ),
          ),
        ),
        Container(
          width: 1.4,
          height: 3.5,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(0.8),
              bottomRight: Radius.circular(0.8),
            ),
          ),
        ),
      ],
    );
  }
}
