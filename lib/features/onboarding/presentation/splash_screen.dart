import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_branding.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../authentication/data/auth_repository.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        final user = ref.read(currentUserProvider);
        if (user != null) {
          context.go('/family');
        } else {
          context.go('/onboarding');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              AppBranding.icon,
              width: 84,
              height: 84,
              fit: BoxFit.contain,
              semanticLabel: 'caren emblem',
            ),
            const SizedBox(height: AppSpacing.md),
            Hero(
              tag: 'caren_brand_wordmark',
              child: Image.asset(
                AppBranding.wordmark,
                height: 40,
                fit: BoxFit.contain,
                semanticLabel: 'caren',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Care, closer.',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
