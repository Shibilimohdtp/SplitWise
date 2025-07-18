import 'package:flutter/material.dart';

// Extension for Color manipulation (consistent implementation)
extension ColorExtension on Color {
  Color withValues({double? alpha}) {
    return Color.fromRGBO(r.toInt(), g.toInt(), b.toInt(), alpha ?? a);
  }
}

class AppColors {
  // Primary Colors - Cool Indigo/Blue
  static const Color primaryLight = Color(0xFFA8A7F5);
  static const Color primaryMain = Color(0xFF5E5CE6);
  static const Color primaryDark = Color(0xFF3A38B5);

  // Secondary/Accent Colors - Vibrant Green
  static const Color secondaryLight = Color(0xFF9EE8AF);
  static const Color secondaryMain = Color(0xFF34C759);
  static const Color secondaryDark = Color(0xFF1E7A36);

  // Dark Theme Primary Colors
  static const Color primaryLightDarkTheme = Color(0xFF7D7BF7);
  static const Color primaryMainDarkTheme = Color(0xFF5E5CE6);
  static const Color primaryDarkDarkTheme = Color(0xFFC7C6FA);

  // Accent Colors - For highlights and important elements
  static const Color accentLight = Color(0xFFFFE066);
  static const Color accentMain = Color(0xFFFFD60A);
  static const Color accentDark = Color(0xFFCCA300);

  // Background Colors - Soft Off-White/Blue-Gray
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color backgroundMain = Color(0xFFE9ECEF);
  static const Color backgroundDark = Color(0xFFDEE2E6);

  // Dark Theme Background Colors - Deep Navy Blue
  static const Color backgroundDarkTheme = Color(0xFF0D1B2A);
  static const Color surfaceDarkTheme = Color(0xFF1B263B);
  static const Color cardDarkTheme = Color(0xFF25324B);

  // Text Colors
  static const Color textLight = Color(0xFF3A3A3C);
  static const Color textMain = Color(0xFF1C1C1E);
  static const Color textDark = Color(0xFF000000);

  // Dark Theme Text Colors
  static const Color textLightDarkTheme = Color(0xFFF2F2F7);
  static const Color textMainDarkTheme = Color(0xFFE5E5EA);
  static const Color textSecondaryDarkTheme = Color(0xFF8E8E93);

  // Status Colors - System-like
  static const Color error = Color(0xFFFF3B30);
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color info = Color(0xFF007AFF);

  // Gradient Colors
  static const List<Color> primaryGradient = [primaryDark, primaryMain];
  static const List<Color> secondaryGradient = [secondaryDark, secondaryMain];
  static const List<Color> accentGradient = [accentDark, accentMain];

  // Surface Colors - Clean Whites/Grays
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceMedium = Color(0xFFF2F2F7);
  static const Color surfaceDark = Color(0xFFE5E5EA);

  // Border Colors
  static const Color borderLight = Color(0xFFD1D1D6);
  static const Color borderMain = Color(0xFFC7C7CC);
  static const Color borderDark = Color(0xFF8E8E93);

  // Dark Theme Border Colors
  static const Color borderLightDarkTheme = Color(0xFF48484A);
  static const Color borderMainDarkTheme = Color(0xFF636366);

  // Card Colors
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardShadow = Color(0x1A000000);
  static const Color cardShadowDarkTheme = Color(0x40000000);

  // Balance Colors
  static const Color positiveBalance = Color(0xFF34C759);
  static const Color negativeBalance = Color(0xFFFF3B30);

  // Interactive Elements
  static const Color buttonPrimary = Color(0xFF5E5CE6);
  static const Color buttonSecondary = Color(0xFF34C759);
  static const Color rippleEffect = Color(0x1A5E5CE6);
}
