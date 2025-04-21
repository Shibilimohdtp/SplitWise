import 'package:flutter/material.dart';

// Extension for Color manipulation (consistent implementation)
extension ColorExtension on Color {
  Color withValues({double? alpha}) {
    return Color.fromRGBO(r.toInt(), g.toInt(), b.toInt(), alpha ?? a);
  }
}

class AppColors {
  // Primary Colors - Warm Orange/Coral
  static const Color primaryLight = Color(0xFFEB9C64); // primary-100
  static const Color primaryMain = Color(0xFFFF8789); // primary-200
  static const Color primaryDark = Color(0xFF554E4F); // primary-300

  // Secondary/Accent Colors - Green tones
  static const Color secondaryLight = Color(0xFF8FBF9F); // accent-100
  static const Color secondaryMain = Color(0xFF346145); // accent-200
  static const Color secondaryDark =
      Color(0xFF254733); // Darker shade of accent-200

  // Dark Theme Primary Colors - Adjusted for better contrast in dark mode
  static const Color primaryLightDarkTheme =
      Color(0xFFF1B78D); // Lighter version of primary-100 for dark theme
  static const Color primaryMainDarkTheme =
      Color(0xFFFF9A9B); // Lighter version of primary-200 for dark theme
  static const Color primaryDarkDarkTheme =
      Color(0xFF7A7273); // Lighter version of primary-300 for dark theme

  // Accent Colors - For highlights and important elements
  static const Color accentLight = Color(0xFF8FBF9F); // accent-100
  static const Color accentMain = Color(0xFF346145); // accent-200
  static const Color accentDark =
      Color(0xFF254733); // Darker shade of accent-200

  // Background Colors - Warm beige tones
  static const Color backgroundLight = Color(0xFFF5ECD7); // bg-100
  static const Color backgroundMain = Color(0xFFEBE2CD); // bg-200
  static const Color backgroundDark = Color(0xFFC2BAA6); // bg-300

  // Dark Theme Background Colors
  static const Color backgroundDarkTheme =
      Color(0xFF1E1C19); // Dark version of bg-100
  static const Color surfaceDarkTheme =
      Color(0xFF2A2723); // Dark version of bg-200
  static const Color cardDarkTheme =
      Color(0xFF35322C); // Dark version of bg-300

  // Text Colors
  static const Color textLight =
      Color(0xFF555555); // Lighter version of text-100
  static const Color textMain = Color(0xFF353535); // text-100
  static const Color textDark = Color(0xFF000000); // text-200

  // Dark Theme Text Colors
  static const Color textLightDarkTheme =
      Color(0xFFE0E0E0); // Light text for dark theme
  static const Color textMainDarkTheme =
      Color(0xFFCCCCCC); // Main text for dark theme
  static const Color textSecondaryDarkTheme =
      Color(0xFFAAAAAA); // Secondary text for dark theme

  // Status Colors - More vibrant
  static const Color error = Color(0xFFE74C3C); // Vibrant red
  static const Color success = Color(0xFF2ECC71); // Fresh green
  static const Color warning = Color(0xFFF1C40F); // Bright yellow
  static const Color info = Color(0xFF3498DB); // Sky blue

  // Gradient Colors
  static const List<Color> primaryGradient = [
    Color(0xFF554E4F),
    Color(0xFFFF8789)
  ];
  static const List<Color> secondaryGradient = [
    Color(0xFF346145),
    Color(0xFF8FBF9F)
  ];
  static const List<Color> accentGradient = [
    Color(0xFF8FBF9F),
    Color(0xFFEBE2CD)
  ];

  // Surface Colors - Warm beige tones
  static const Color surfaceLight = Color(0xFFFFFBF0); // Lightest beige
  static const Color surfaceMedium = Color(0xFFF5ECD7); // bg-100
  static const Color surfaceDark = Color(0xFFEBE2CD); // bg-200

  // Border Colors - Enhanced contrast for better visibility
  static const Color borderLight =
      Color(0xFF9E9784); // Light border (darker for better contrast)
  static const Color borderMain =
      Color(0xFF7D7666); // Medium border (darker than bg-300)
  static const Color borderDark =
      Color(0xFF554E4F); // Dark border (using primary-300 for consistency)

  // Dark Theme Border Colors
  static const Color borderLightDarkTheme =
      Color(0xFF8A847A); // Light border for dark theme (higher contrast)
  static const Color borderMainDarkTheme =
      Color(0xFFADA598); // Medium border for dark theme (higher contrast)

  // Card Colors - For elevated surfaces
  static const Color cardLight = Color(0xFFFFFBF0); // Light beige cards
  static const Color cardShadow =
      Color(0x1A554E4F); // Subtle shadow using primary-300
  static const Color cardShadowDarkTheme =
      Color(0x40000000); // Shadow for dark theme

  // Balance Colors - For financial information
  static const Color positiveBalance = Color(0xFF2ECC71); // Money owed to user
  static const Color negativeBalance = Color(0xFFE74C3C); // Money user owes

  // Interactive Elements
  static const Color buttonPrimary =
      Color(0xFFFF8789); // Primary buttons (primary-200)
  static const Color buttonSecondary =
      Color(0xFF346145); // Secondary buttons (accent-200)
  static const Color rippleEffect = Color(0x1AFF8789); // Touch feedback
}
