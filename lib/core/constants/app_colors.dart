import 'package:flutter/material.dart';

/// Design tokens for CAREN.
/// Deep teal, soft mint/gentle sage, warm off-white, and calm accents.
class AppColors {
  AppColors._();

  // Primary Palette - Deep Teal
  static const Color primary = Color(0xFF1D4E56);
  static const Color primaryLight = Color(0xFF28626C);
  static const Color primaryDark = Color(0xFF13363C);
  static const Color primaryContainer = Color(0xFFE2F0F2);
  static const Color onPrimary = Colors.white;

  // Secondary Palette - Soft Mint & Gentle Sage
  static const Color secondary = Color(0xFF6F9985);
  static const Color secondaryLight = Color(0xFFA3C9A8);
  static const Color secondaryContainer = Color(0xFFEAF4ED);
  static const Color onSecondary = Color(0xFF152A20);

  // Background & Surfaces - Warm Off-White
  static const Color background = Color(0xFFF9F9F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F2EE);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF222B27);
  static const Color textSecondary = Color(0xFF5A6660);
  static const Color textMuted = Color(0xFF8B9892);

  // Borders & Dividers
  static const Color border = Color(0xFFE0E5E1);
  static const Color divider = Color(0xFFECEFEA);

  // Feedback Colors (Calm, Non-Alarmist)
  static const Color success = Color(0xFF4A8468);
  static const Color successContainer = Color(0xFFEBF5EE);
  static const Color warning = Color(0xFFC78430);
  static const Color warningContainer = Color(0xFFFDF4E7);
  static const Color info = Color(0xFF3B728C);
  static const Color infoContainer = Color(0xFFE9F3F8);
  static const Color danger = Color(0xFFB54C47);
  static const Color dangerContainer = Color(0xFFFBF0EF);
  static const Color error = danger;
  static const Color accent = secondary;
  static const Color accentDark = primaryDark;
  static const Color accentLight = secondaryLight;

  // Simulation & Mock Marker (distinct amber badge)
  static const Color simulatedBannerBg = Color(0xFFFFF3CD);
  static const Color simulatedBannerText = Color(0xFF856404);
  static const Color simulatedBannerBorder = Color(0xFFFFEEBA);
}

