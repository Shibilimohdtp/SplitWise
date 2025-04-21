import 'package:flutter/material.dart';
import 'package:splitwise/utils/app_color.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    primaryColor: AppColors.primaryMain,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      // Primary colors
      primary: AppColors.primaryMain,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryLight,
      onPrimaryContainer: AppColors.primaryDark,

      // Secondary colors
      secondary: AppColors.secondaryMain,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.secondaryLight,
      onSecondaryContainer: AppColors.secondaryDark,

      // Tertiary/accent colors
      tertiary: AppColors.accentMain,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.accentLight,
      onTertiaryContainer: AppColors.accentDark,

      // Surface colors
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textMain,
      surfaceContainerHighest: AppColors.surfaceMedium,
      onSurfaceVariant: AppColors.textLight,
      surfaceTint: AppColors.primaryLight,

      // Error colors
      error: AppColors.error,
      onError: Colors.white,

      // Border colors
      outline: AppColors.borderMain,
      outlineVariant: AppColors.borderLight,
      surfaceContainerLow:
          Color(0xFFD5CFC0), // Lighter version of borderLight with opacity
    ),
    scaffoldBackgroundColor: AppColors.backgroundLight,
    textTheme: _buildTextTheme(isDark: false),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.primaryMain,
      iconTheme: IconThemeData(color: AppColors.primaryMain),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryMain,
        letterSpacing: 0.15,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: AppColors.buttonPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shadowColor: AppColors.cardShadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderLight, width: 0.5),
      ),
      color: AppColors.cardLight,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderMain, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderMain, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: AppColors.secondaryMain, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(color: AppColors.textLight),
      hintStyle: TextStyle(color: AppColors.textLight.withValues(alpha: 0.7)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.buttonPrimary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    tabBarTheme: const TabBarTheme(
      labelColor: AppColors.primaryMain,
      unselectedLabelColor: AppColors.textLight,
      indicatorSize: TabBarIndicatorSize.label,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(width: 2.0, color: AppColors.primaryMain),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.borderMain,
      thickness: 1,
      space: 1,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    primaryColor: AppColors.primaryMainDarkTheme,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      // Primary colors - adjusted for dark theme
      primary: Color(0xFFFF9A9B), // Lighter version of primary-200
      onPrimary: Colors.black,
      primaryContainer: Color(0xFFF1B78D), // Lighter version of primary-100
      onPrimaryContainer: Colors.black,

      // Secondary colors - adjusted for dark theme
      secondary: Color(0xFF8FBF9F), // accent-100 for better visibility
      onSecondary: Colors.black,
      secondaryContainer: Color(0xFF346145), // accent-200
      onSecondaryContainer: Colors.white,

      // Tertiary/accent colors - adjusted for dark theme
      tertiary: Color(0xFF8FBF9F), // accent-100 for better visibility
      onTertiary: Colors.black,
      tertiaryContainer: Color(0xFF346145), // accent-200
      onTertiaryContainer: Colors.white,

      // Surface colors - warm dark tones
      surface: Color(0xFF2A2723), // Dark version of bg-200
      onSurface: Color(0xFFE0E0E0), // Dark version of bg-300
      onSurfaceVariant: Color(0xFFCCCCCC), // Main text for dark theme
      surfaceContainerHighest: Color(0xFF35322C), // Card background
      surfaceTint: Color(0xFFF1B78D), // Light text for dark theme

      // Error colors - brighter for visibility
      error: Color(0xFFFF8A80), // Bright red for better visibility
      onError: Colors.black,

      // Border colors
      outline: AppColors.borderMainDarkTheme, // Medium border for dark theme
      outlineVariant:
          AppColors.borderLightDarkTheme, // Light border for dark theme
      surfaceContainerLow:
          Color(0x4DADA598), // borderMainDarkTheme with opacity

      // Other colors
      shadow: Color(0x40000000), // Shadow with 25% opacity
      scrim: Color(0x4D000000), // Black with 30% opacity
      inverseSurface: Colors.white,
      onInverseSurface: Colors.black,
      inversePrimary: Color(0xFFFF8789), // primary-200
    ),
    scaffoldBackgroundColor: AppColors.backgroundDarkTheme,
    textTheme: _buildTextTheme(isDark: true).copyWith(
      bodyLarge: const TextStyle(
        fontSize: 16,
        color: Colors.white,
        letterSpacing: 0.15,
      ),
      bodyMedium: const TextStyle(
        fontSize: 14,
        color: Colors.white,
        letterSpacing: 0.25,
      ),
      bodySmall: const TextStyle(
        fontSize: 12,
        color: Color(0xFFE0E0E0),
        letterSpacing: 0.4,
      ),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: 0.15,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor:
            const Color(0xFFFF9A9B), // Lighter version of primary-200
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    cardTheme: CardTheme(
      elevation: 4,
      shadowColor: const Color(0x66000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderMainDarkTheme, width: 1),
      ),
      color: const Color(0xFF35322C), // Dark version of bg-300
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF35322C), // Dark version of bg-300
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
            color: AppColors.borderMainDarkTheme,
            width: 1.2), // Enhanced contrast border
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
            color: AppColors.borderMainDarkTheme,
            width: 1.2), // Enhanced contrast border
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
            color: Color(0xFFFF9A9B),
            width: 2.0), // Lighter version of primary-200 with increased width
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF8A80), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(color: Color(0xFFE0E0E0)),
      hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor:
          const Color(0xFFFF9A9B), // Lighter version of primary-200
      foregroundColor: Colors.black,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF35322C), // Dark version of bg-300
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(
            color: AppColors.borderMainDarkTheme,
            width: 1.2), // Enhanced contrast border
      ),
      elevation: 8,
      shadowColor: Color(0x66000000),
    ),
    tabBarTheme: const TabBarTheme(
      labelColor: Colors.white,
      unselectedLabelColor: Color(0xFFBDBDBD),
      indicatorSize: TabBarIndicatorSize.label,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(
            width: 2.0,
            color: Color(0xFFFF9A9B)), // Lighter version of primary-200
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.borderMainDarkTheme, // Enhanced contrast border
      thickness: 1,
      space: 1,
    ),
  );

  static TextTheme _buildTextTheme({required bool isDark}) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : AppColors.textDark,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : AppColors.textDark,
        letterSpacing: -0.25,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : AppColors.textDark,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : AppColors.textDark,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : AppColors.textDark,
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : AppColors.textMain,
        letterSpacing: 0.15,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white : AppColors.textMain,
        letterSpacing: 0.15,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white : AppColors.textMain,
        letterSpacing: 0.1,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: isDark ? Colors.white : AppColors.textMain,
        letterSpacing: 0.15,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: isDark ? Colors.white : AppColors.textMain,
        letterSpacing: 0.25,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: isDark ? const Color(0xFFE0E0E0) : AppColors.textMain,
        letterSpacing: 0.4,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white : AppColors.textMain,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: isDark ? const Color(0xFFE0E0E0) : AppColors.textMain,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: isDark ? const Color(0xFFBDBDBD) : AppColors.textLight,
        letterSpacing: 0.5,
      ),
    );
  }
}
