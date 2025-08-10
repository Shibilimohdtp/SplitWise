import 'package:flutter/material.dart';
import 'package:splitwise/constants/app_color.dart';

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
      onSecondary: AppColors.textDark,
      secondaryContainer: AppColors.secondaryLight,
      onSecondaryContainer: AppColors.primaryDark,

      // Tertiary/accent colors
      tertiary: AppColors.accentMain,
      onTertiary: Colors.black, // For better contrast on yellow
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
      surfaceContainerLow: AppColors.backgroundMain,
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
        borderSide: const BorderSide(color: AppColors.primaryMain, width: 2.0),
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
    // Additional theme customizations for the new color scheme
    chipTheme: const ChipThemeData(
      backgroundColor: AppColors.secondaryLight,
      selectedColor: AppColors.primaryLight,
      labelStyle: TextStyle(color: AppColors.textMain),
      side: BorderSide(color: AppColors.borderLight),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primaryMain;
        }
        return AppColors.borderMain;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primaryLight;
        }
        return AppColors.borderLight;
      }),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    primaryColor: AppColors.primaryMainDarkTheme,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      // Primary colors
      primary: AppColors.primaryMainDarkTheme,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryLightDarkTheme,
      onPrimaryContainer: Colors.white,

      // Secondary colors
      secondary: AppColors.secondaryLight,
      onSecondary: AppColors.textDark,
      secondaryContainer: AppColors.secondaryMain,
      onSecondaryContainer: AppColors.primaryDark,

      // Tertiary/accent colors
      tertiary: AppColors.accentLight,
      onTertiary: Colors.black,
      tertiaryContainer: AppColors.accentMain,
      onTertiaryContainer: Colors.black,

      // Surface colors
      surface: AppColors.surfaceDarkTheme,
      onSurface: AppColors.textLightDarkTheme,
      onSurfaceVariant: AppColors.textMainDarkTheme,
      surfaceContainerHighest: AppColors.cardDarkTheme,
      surfaceTint: AppColors.primaryLightDarkTheme,

      // Error colors
      error: AppColors.error,
      onError: Colors.white,

      // Border colors
      outline: AppColors.borderMainDarkTheme,
      outlineVariant: AppColors.borderLightDarkTheme,
      surfaceContainerLow:
          Color(0x4D636366), // borderMainDarkTheme with opacity

      // Other colors
      shadow: Color(0x40000000),
      scrim: Color(0x4D000000),
      inverseSurface: Colors.white,
      onInverseSurface: Colors.black,
      inversePrimary: AppColors.primaryMain,
    ),
    scaffoldBackgroundColor: AppColors.backgroundDarkTheme,
    textTheme: _buildTextTheme(isDark: true),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.textLightDarkTheme,
      iconTheme: IconThemeData(color: AppColors.textLightDarkTheme),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textLightDarkTheme,
        letterSpacing: 0.15,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: AppColors.buttonPrimary,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    cardTheme: CardTheme(
      elevation: 4,
      shadowColor: AppColors.cardShadowDarkTheme,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderMainDarkTheme, width: 1),
      ),
      color: AppColors.cardDarkTheme,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardDarkTheme,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: AppColors.borderMainDarkTheme, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: AppColors.borderMainDarkTheme, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: AppColors.primaryMainDarkTheme, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(color: AppColors.textLightDarkTheme),
      hintStyle: const TextStyle(color: AppColors.textSecondaryDarkTheme),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.buttonPrimary,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.cardDarkTheme,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppColors.borderMainDarkTheme, width: 1.2),
      ),
      elevation: 8,
      shadowColor: AppColors.cardShadowDarkTheme,
    ),
    tabBarTheme: const TabBarTheme(
      labelColor: AppColors.textLightDarkTheme,
      unselectedLabelColor: AppColors.textSecondaryDarkTheme,
      indicatorSize: TabBarIndicatorSize.label,
      indicator: UnderlineTabIndicator(
        borderSide:
            BorderSide(width: 2.0, color: AppColors.primaryMainDarkTheme),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.borderMainDarkTheme,
      thickness: 1,
      space: 1,
    ),
    // Additional theme customizations for dark theme
    chipTheme: const ChipThemeData(
      backgroundColor: AppColors.surfaceDarkTheme,
      selectedColor: AppColors.primaryLightDarkTheme,
      labelStyle: TextStyle(color: AppColors.textLightDarkTheme),
      side: BorderSide(color: AppColors.borderMainDarkTheme),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primaryMainDarkTheme;
        }
        return AppColors.borderMainDarkTheme;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primaryLightDarkTheme;
        }
        return AppColors.borderLightDarkTheme;
      }),
    ),
  );

  static TextTheme _buildTextTheme({required bool isDark}) {
    final mainColor =
        isDark ? AppColors.textLightDarkTheme : AppColors.textMain;
    final secondaryColor =
        isDark ? AppColors.textMainDarkTheme : AppColors.textLight;
    final darkColor =
        isDark ? AppColors.textLightDarkTheme : AppColors.textDark;

    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: darkColor,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: darkColor,
        letterSpacing: -0.25,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: darkColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: darkColor,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: darkColor,
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: mainColor,
        letterSpacing: 0.15,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: mainColor,
        letterSpacing: 0.15,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: mainColor,
        letterSpacing: 0.1,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: mainColor,
        letterSpacing: 0.15,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: mainColor,
        letterSpacing: 0.25,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: secondaryColor,
        letterSpacing: 0.4,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: mainColor,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: mainColor,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
        letterSpacing: 0.5,
      ),
    );
  }
}
