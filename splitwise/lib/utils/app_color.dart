import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Rich Navy
  static const Color primaryLight = Color(0xFF526D82);
  static const Color primaryMain = Color(0xFF27374D); // Rich Navy
  static const Color primaryDark = Color(0xFF1B2430);

  // Secondary Colors - Sage/Green tones
  static const Color secondaryLight = Color(0xFF9DB2BF);
  static const Color secondaryMain = Color(0xFF526D82); // Muted Blue
  static const Color secondaryDark = Color(0xFF27374D);

  // Accent Colors - For highlights and important elements
  static const Color accentLight = Color(0xFFDDE6ED);
  static const Color accentMain = Color(0xFF9DB2BF); // Soft Blue
  static const Color accentDark = Color(0xFF526D82);

  // Background Colors - Warm but bright
  static const Color backgroundLight = Color(0xFFF5F7F8); // Bright off-white
  static const Color backgroundMain = Color(0xFFEEF2F5); // Soft grey-white
  static const Color backgroundDark = Color(0xFFE4E9EC); // Light grey

  // Text Colors
  static const Color textLight = Color(0xFF526D82); // Softer text
  static const Color textMain = Color(0xFF27374D); // Main text
  static const Color textDark = Color(0xFF1B2430); // Bold text

  // Status Colors - More vibrant
  static const Color error = Color(0xFFE74C3C); // Vibrant red
  static const Color success = Color(0xFF2ECC71); // Fresh green
  static const Color warning = Color(0xFFF1C40F); // Bright yellow
  static const Color info = Color(0xFF3498DB); // Sky blue

  // Gradient Colors
  static const List<Color> primaryGradient = [
    Color(0xFF27374D),
    Color(0xFF526D82)
  ];
  static const List<Color> secondaryGradient = [
    Color(0xFF526D82),
    Color(0xFF9DB2BF)
  ];
  static const List<Color> accentGradient = [
    Color(0xFF9DB2BF),
    Color(0xFFDDE6ED)
  ];

  // Surface Colors - Clean and bright
  static const Color surfaceLight = Color(0xFFFFFFFF); // Pure white
  static const Color surfaceMedium = Color(0xFFF8FAFC); // Slight off-white
  static const Color surfaceDark = Color(0xFFF1F4F6); // Light grey

  // Border Colors - Subtle but visible
  static const Color borderLight = Color(0xFFE2E8F0); // Light border
  static const Color borderMain = Color(0xFFCBD5E1); // Medium border
  static const Color borderDark = Color(0xFF94A3B8); // Dark border

  // Card Colors - For elevated surfaces
  static const Color cardLight = Color(0xFFFFFFFF); // White cards
  static const Color cardShadow = Color(0x1A27374D); // Subtle shadow

  // Balance Colors - For financial information
  static const Color positiveBalance = Color(0xFF2ECC71); // Money owed to user
  static const Color negativeBalance = Color(0xFFE74C3C); // Money user owes

  // Interactive Elements
  static const Color buttonPrimary = Color(0xFF27374D); // Primary buttons
  static const Color buttonSecondary = Color(0xFF526D82); // Secondary buttons
  static const Color rippleEffect = Color(0x1A27374D); // Touch feedback
}
