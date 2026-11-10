import 'package:flutter/material.dart';

/// Design tokens for caren (Serene Hearth design system).
/// Organic Warm Minimalism: Deep Forest, Soft Mint, Warm Ivory, Soft Sage, Peach Accent, and Emergency Crimson.
class AppColors {
  AppColors._();

  // Primary Palette - Deep Forest
  static const Color primary = Color(0xFF174F47);
  static const Color primaryLight = Color(0xFF32675F);
  static const Color primaryDark = Color(0xFF003731);
  static const Color primaryContainer = Color(0xFFCAEAD7);
  static const Color onPrimary = Colors.white;
  static const Color onPrimaryContainer = Color(0xFF00201C);

  // Secondary Palette - Soft Sage & Botanical Greens
  static const Color secondary = Color(0xFF486456);
  static const Color secondaryLight = Color(0xFFA9C8B6);
  static const Color secondaryContainer = Color(0xFFE8F2ED);
  static const Color onSecondary = Colors.white;
  static const Color onSecondaryContainer = Color(0xFF042015);

  // Tertiary / Peach Accent - Warmth & Celebration
  static const Color tertiary = Color(0xFF3E2D20);
  static const Color tertiaryLight = Color(0xFFF3D7C3);
  static const Color tertiaryContainer = Color(0xFFFADDC9);
  static const Color onTertiary = Colors.white;
  static const Color onTertiaryContainer = Color(0xFF27180C);
  static const Color peach = Color(0xFFF3D7C3);

  // Background & Surfaces - Warm Ivory & Soft Mint
  static const Color background = Color(0xFFFAF9F4);
  static const Color surface = Color(0xFFFAF9F4);
  static const Color surfaceVariant = Color(0xFFE3E3DE);
  static const Color surfaceContainerLow = Color(0xFFF5F4EF);
  static const Color surfaceContainer = Color(0xFFEFEEE9);
  static const Color surfaceContainerHigh = Color(0xFFE9E8E3);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF1B1C19);
  static const Color textSecondary = Color(0xFF404946);
  static const Color textMuted = Color(0xFF707976);

  // Borders & Dividers
  static const Color border = Color(0xFFBFC8C5);
  static const Color divider = Color(0xFFE3E3DE);
  static const Color outline = Color(0xFF707976);

  // Feedback Colors (Calm, Non-Alarmist)
  static const Color success = Color(0xFF486456);
  static const Color successContainer = Color(0xFFCAEAD7);
  static const Color warning = Color(0xFFC78430);
  static const Color warningContainer = Color(0xFFFDF4E7);
  static const Color info = Color(0xFF32675F);
  static const Color infoContainer = Color(0xFFE8F2ED);
  static const Color danger = Color(0xFFC94A4A);
  static const Color dangerContainer = Color(0xFFFFDAD6);
  static const Color error = danger;
  static const Color accent = peach;
  static const Color accentDark = primaryDark;
  static const Color accentLight = secondaryLight;

  // Simulation & Mock Marker (distinct amber badge)
  static const Color simulatedBannerBg = Color(0xFFFFF3CD);
  static const Color simulatedBannerText = Color(0xFF856404);
  static const Color simulatedBannerBorder = Color(0xFFFFEEBA);
}
