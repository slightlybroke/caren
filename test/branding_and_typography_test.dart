import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caren/app/app.dart';
import 'package:caren/app/theme/app_theme.dart';
import 'package:caren/core/constants/app_branding.dart';
import 'package:caren/core/constants/app_colors.dart';
import 'package:caren/core/constants/app_typography.dart';
import 'package:caren/core/widgets/caren_app_bar.dart';

void main() {
  group('CAREN Brand Assets and Theme Foundation', () {
    test('AppBranding constants resolve to approved local asset paths and exist on disk', () {
      expect(AppBranding.icon, equals('assets/branding/icon.png'));
      expect(AppBranding.wordmark, equals('assets/branding/wordmark_icon.png'));

      final iconFile = File(AppBranding.icon);
      final wordmarkFile = File(AppBranding.wordmark);
      expect(iconFile.existsSync(), isTrue);
      expect(wordmarkFile.existsSync(), isTrue);
      expect(iconFile.lengthSync(), isPositive);
      expect(wordmarkFile.lengthSync(), isPositive);
    });

    test('Bundled Manrope font files exist on disk for all 4 weights', () {
      final weights = ['Regular', 'Medium', 'SemiBold', 'Bold'];
      for (final weight in weights) {
        final fontFile = File('assets/fonts/Manrope/Manrope-$weight.ttf');
        expect(fontFile.existsSync(), isTrue, reason: 'Manrope-$weight.ttf must exist');
        expect(fontFile.lengthSync(), isPositive);
      }
    });

    test('AppTypography specifies locally bundled Manrope font family', () {
      expect(AppTypography.fontFamily, equals('Manrope'));
      expect(AppTypography.displayLarge.fontFamily, equals('Manrope'));
      expect(AppTypography.displayMedium.fontFamily, equals('Manrope'));
      expect(AppTypography.titleLarge.fontFamily, equals('Manrope'));
      expect(AppTypography.titleMedium.fontFamily, equals('Manrope'));
      expect(AppTypography.bodyLarge.fontFamily, equals('Manrope'));
      expect(AppTypography.bodyMedium.fontFamily, equals('Manrope'));
      expect(AppTypography.bodySmall.fontFamily, equals('Manrope'));
      expect(AppTypography.caption.fontFamily, equals('Manrope'));
      expect(AppTypography.labelLarge.fontFamily, equals('Manrope'));
    });

    test('AppColors matches approved Serene Hearth palette tokens', () {
      expect(AppColors.primary, equals(const Color(0xFF174F47)));
      expect(AppColors.secondaryContainer, equals(const Color(0xFFE8F2ED)));
      expect(AppColors.background, equals(const Color(0xFFFAF9F4)));
      expect(AppColors.surface, equals(const Color(0xFFFAF9F4)));
      expect(AppColors.accent, equals(const Color(0xFFF3D7C3)));
      expect(AppColors.tertiary, equals(const Color(0xFF3E2D20)));
      expect(AppColors.error, equals(const Color(0xFFC94A4A)));
    });

    test('AppTheme configures light theme with Manrope and Serene Hearth tokens', () {
      final theme = AppTheme.lightTheme;
      expect(theme.textTheme.bodyMedium?.fontFamily, equals('Manrope'));
      expect(theme.scaffoldBackgroundColor, equals(AppColors.background));
      expect(theme.colorScheme.primary, equals(AppColors.primary));
      expect(theme.colorScheme.surface, equals(AppColors.surface));
      expect(theme.colorScheme.error, equals(AppColors.error));
    });

    testWidgets('CarenAppBar with wordmark renders on narrow screen (320px) without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            appBar: CarenAppBar(
              title: 'Family',
              useBrandWordmark: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CarenAppBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SplashScreen renders brand icon and wordmark on narrow screen (320px) without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: CarenApp(),
        ),
      );

      expect(find.bySemanticsLabel('caren'), findsOneWidget);
      expect(find.bySemanticsLabel('caren emblem'), findsOneWidget);
      expect(find.text('Care, closer.'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Settle navigation timer
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();
    });
  });
}
