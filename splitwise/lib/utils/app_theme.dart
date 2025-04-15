import 'package:flutter/material.dart';
import 'package:splitwise/utils/app_color.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    primaryColor: AppColors.primaryMain,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryMain,
      secondary: AppColors.secondaryMain,
      surface: AppColors.surfaceLight,
      error: AppColors.error,
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
        backgroundColor: AppColors.primaryMain,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shadowColor: AppColors.primaryMain.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: AppColors.surfaceLight,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: AppColors.secondaryMain, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(color: AppColors.textLight),
      hintStyle: TextStyle(color: AppColors.textLight.withValues(alpha: 0.7)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.secondaryMain,
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
      color: AppColors.borderLight,
      thickness: 1,
      space: 1,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    primaryColor: AppColors.primaryMainDarkTheme,
    colorScheme: const ColorScheme.dark(
      // Primary colors - much brighter for better contrast
      primary: Color(0xFF64B5F6), // Bright blue for better visibility
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF42A5F5),
      onPrimaryContainer: Colors.white,

      // Secondary colors - brighter
      secondary: Color(0xFF81D4FA), // Light blue for better contrast
      onSecondary: Colors.black,
      secondaryContainer: Color(0xFF4FC3F7),
      onSecondaryContainer: Colors.black,

      // Tertiary/accent colors - brighter
      tertiary: Color(0xFF4FC3F7), // Bright blue for better contrast
      onTertiary: Colors.black,

      // Surface colors - more contrast
      surface: Color(0xFF1E1E1E), // Slightly lighter than background
      onSurface: Colors.white, // Card background
      surfaceContainerHighest: Color(0xFF2C2C2C), // Card background
      onSurfaceVariant: Color(0xFFE0E0E0), // Very light gray for secondary text
      surfaceTint: Color(0xFF64B5F6),

      // Error colors - brighter
      error: Color(0xFFFF8A80), // Bright red for better visibility
      onError: Colors.white,

      // Border colors
      outline: Color(0xFF757575), // Medium gray for borders
      outlineVariant: Color(0xFF424242), // Darker gray for subtle borders

      // Other colors
      shadow: Color(0x40000000), // Shadow with 25% opacity
      scrim: Color(0x4D000000), // Black with 30% opacity
      inverseSurface: Colors.white,
      onInverseSurface: Colors.black,
      inversePrimary: Color(0xFF42A5F5),
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
        foregroundColor: Colors.white,
        backgroundColor:
            const Color(0xFF2196F3), // Bright blue for better visibility
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
        side: const BorderSide(color: Color(0xFF424242), width: 1),
      ),
      color: const Color(0xFF2C2C2C),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF424242)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF424242)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF64B5F6), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF8A80)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(color: Color(0xFFE0E0E0)),
      hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor:
          const Color(0xFF2196F3), // Bright blue for better visibility
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF2C2C2C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Color(0xFF424242), width: 1),
      ),
      elevation: 8,
      shadowColor: Color(0x66000000),
    ),
    tabBarTheme: const TabBarTheme(
      labelColor: Colors.white,
      unselectedLabelColor: Color(0xFFBDBDBD),
      indicatorSize: TabBarIndicatorSize.label,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(width: 2.0, color: Color(0xFF64B5F6)),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF424242),
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
