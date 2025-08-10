import 'package:flutter/material.dart';

// Extension for Color manipulation (consistent implementation)
extension ColorExtension on Color {
  Color withValues({double? alpha}) {
    return Color.fromRGBO(r.toInt(), g.toInt(), b.toInt(), alpha ?? a);
  }
}

class AppColors {
  // Instagram-Inspired Light Theme Colors
  // Based on the financial app design with blue and white scheme
  
  // Primary Colors - Vibrant Blue
  static const Color primaryLight = Color(0xFF6EC3FF);  // Light sky blue
  static const Color primaryMain = Color(0xFF0070C0);   // Medium vibrant blue
  static const Color primaryDark = Color(0xFF004E86);   // Dark rich blue

  // Secondary/Accent Colors - Complementary
  static const Color secondaryLight = Color(0xFFE8F4FD); // Very light blue
  static const Color secondaryMain = Color(0xFFB8D9F2);  // Light blue
  static const Color secondaryDark = Color(0xFF7FB3D9);  // Medium blue

  // Dark Theme Primary Colors - Adjusted for dark mode
  static const Color primaryLightDarkTheme = Color(0xFF4A9EFF);  // Brighter blue for dark theme
  static const Color primaryMainDarkTheme = Color(0xFF0070C0);   // Same main blue
  static const Color primaryDarkDarkTheme = Color(0xFF0056A3);   // Slightly lighter dark blue

  // Accent Colors - For highlights and important elements
  static const Color accentLight = Color(0xFFFFE066);  // Light yellow
  static const Color accentMain = Color(0xFFFFD60A);   // Yellow
  static const Color accentDark = Color(0xFFCCA300);   // Dark yellow

  // Background Colors - Soft Off-White/Blue-Gray
  static const Color backgroundLight = Color(0xFFF7F9FB);  // Very light off-white
  static const Color backgroundMain = Color(0xFFE9ECEF);   // Light gray-blue
  static const Color backgroundDark = Color(0xFFDEE2E6);   // Medium gray-blue

  // Dark Theme Background Colors - Deep Navy Blue
  static const Color backgroundDarkTheme = Color(0xFF0D1B2A);    // Deep navy
  static const Color surfaceDarkTheme = Color(0xFF1B263B);       // Dark navy
  static const Color cardDarkTheme = Color(0xFF25324B);          // Medium navy

  // Text Colors
  static const Color textLight = Color(0xFF22313C);  // Dark gray-blue
  static const Color textMain = Color(0xFF1C1C1E);  // Very dark gray
  static const Color textDark = Color(0xFF000000);   // Black

  // Dark Theme Text Colors
  static const Color textLightDarkTheme = Color(0xFFF2F2F7);     // Very light gray
  static const Color textMainDarkTheme = Color(0xFFE5E5EA);      // Light gray
  static const Color textSecondaryDarkTheme = Color(0xFF8E8E93); // Medium gray

  // Status Colors - System-like
  static const Color error = Color(0xFFFF3B30);      // Red
  static const Color success = Color(0xFF34C759);    // Green
  static const Color warning = Color(0xFFFF9500);    // Orange
  static const Color info = Color(0xFF007AFF);       // Blue

  // Gradient Colors
  static const List<Color> primaryGradient = [primaryDark, primaryMain];
  static const List<Color> secondaryGradient = [secondaryDark, secondaryMain];
  static const List<Color> accentGradient = [accentDark, accentMain];

  // Surface Colors - Clean Whites/Grays
  static const Color surfaceLight = Color(0xFFFFFFFF);  // Pure white
  static const Color surfaceMedium = Color(0xFFF2F2F7); // Very light gray
  static const Color surfaceDark = Color(0xFFE5E5EA);   // Light gray

  // Border Colors
  static const Color borderLight = Color(0xFFD1D1D6);  // Light gray
  static const Color borderMain = Color(0xFFC7C7CC);   // Medium gray
  static const Color borderDark = Color(0xFF8E8E93);   // Dark gray

  // Dark Theme Border Colors
  static const Color borderLightDarkTheme = Color(0xFF48484A);   // Medium gray
  static const Color borderMainDarkTheme = Color(0xFF636366);    // Light gray

  // Card Colors
  static const Color cardLight = Color(0xFFFFFFFF);              // Pure white
  static const Color cardShadow = Color(0x1A000000);            // Black with 10% opacity
  static const Color cardShadowDarkTheme = Color(0x40000000);   // Black with 25% opacity

  // Balance Colors
  static const Color positiveBalance = Color(0xFF34C759);        // Green
  static const Color negativeBalance = Color(0xFFFF3B30);       // Red

  // Interactive Elements
  static const Color buttonPrimary = Color(0xFF0070C0);          // Main blue
  static const Color buttonSecondary = Color(0xFF34C759);       // Green
  static const Color rippleEffect = Color(0x1A0070C0);          // Blue with 10% opacity
}
