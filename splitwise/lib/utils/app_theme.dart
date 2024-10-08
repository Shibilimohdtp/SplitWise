import 'package:flutter/material.dart';
import 'package:splitwise/utils/app_color.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    primaryColor: AppColors.primaryMain,
    colorScheme: ColorScheme.light(
      primary: AppColors.primaryMain,
      secondary: AppColors.secondaryMain,
      surface: AppColors.backgroundLight,
    ),
    scaffoldBackgroundColor: AppColors.backgroundLight,
    textTheme: _buildTextTheme(isDark: false),
    appBarTheme: AppBarTheme(
      color: AppColors.primaryMain,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: AppColors.primaryMain,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.primaryMain),
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    primaryColor: AppColors.primaryDark,
    colorScheme: ColorScheme.dark(
      primary: AppColors.primaryDark,
      secondary: AppColors.secondaryDark,
      surface: AppColors.backgroundDark,
    ),
    scaffoldBackgroundColor: AppColors.backgroundDark,
    textTheme: _buildTextTheme(isDark: true),
    appBarTheme: AppBarTheme(
      color: AppColors.primaryDark,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: AppColors.primaryDark,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.primaryDark),
      ),
    ),
  );

  static TextTheme _buildTextTheme({required bool isDark}) {
    return TextTheme(
      headlineMedium: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.textLight : AppColors.textDark,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.textLight : AppColors.textDark,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: isDark ? AppColors.textLight : AppColors.textMain,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: isDark ? AppColors.textLight : AppColors.textMain,
      ),
    );
  }
}
