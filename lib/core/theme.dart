import 'package:flutter/material.dart';
import 'constants.dart';

/// SummitMate 深色主題配置
/// 遵循 UI/UX 規範：強制深色模式以適應夜間攀登
class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // 色彩配置
      colorScheme: const ColorScheme.dark(
        surface: Color(AppColors.backgroundValue),
        primary: Color(AppColors.accentValue),
        secondary: Color(AppColors.accentValue),
        onSurface: Color(AppColors.textPrimaryValue),
        error: Color(AppColors.errorValue),
      ),

      // Scaffold 背景
      scaffoldBackgroundColor: const Color(AppColors.backgroundValue),

      // AppBar 主題
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(AppColors.surfaceValue),
        foregroundColor: Color(AppColors.textPrimaryValue),
        elevation: 0,
        centerTitle: true,
      ),

      // Card 主題
      cardTheme: CardThemeData(
        color: const Color(AppColors.surfaceValue),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Bottom Navigation 主題
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(AppColors.surfaceValue),
        selectedItemColor: Color(AppColors.accentValue),
        unselectedItemColor: Color(AppColors.textSecondaryValue),
        type: BottomNavigationBarType.fixed,
      ),

      // Text 主題
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: Color(AppColors.textPrimaryValue),
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: Color(AppColors.textPrimaryValue),
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: Color(AppColors.textPrimaryValue),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: Color(AppColors.textPrimaryValue),
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: Color(AppColors.textPrimaryValue),
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: Color(AppColors.textSecondaryValue),
          fontSize: 14,
        ),
        // 關鍵數值 (海拔、時間) - 規範要求大於 18sp
        labelLarge: TextStyle(
          color: Color(AppColors.accentValue),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Input 主題
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(AppColors.surfaceValue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Color(AppColors.accentValue),
            width: 2,
          ),
        ),
        labelStyle: const TextStyle(
          color: Color(AppColors.textSecondaryValue),
        ),
        hintStyle: const TextStyle(
          color: Color(AppColors.textSecondaryValue),
        ),
      ),

      // Elevated Button 主題
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(AppColors.accentValue),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // FAB 主題
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(AppColors.accentValue),
        foregroundColor: Colors.black,
      ),

      // Tab Bar 主題
      tabBarTheme: const TabBarThemeData(
        labelColor: Color(AppColors.accentValue),
        unselectedLabelColor: Color(AppColors.textSecondaryValue),
        indicatorColor: Color(AppColors.accentValue),
      ),

      // Divider 主題
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2C2C2C),
        thickness: 1,
      ),
    );
  }

  // ======== 大自然主題配色 ========
  
  // 主色調：森林綠
  static const Color primaryColor = Color(0xFF2E7D32);
  // 次要色：山脈藍
  static const Color secondaryColor = Color(0xFF1565C0);
  // 背景色：淺米色
  static const Color lightBackground = Color(0xFFF5F5F0);
  // 表面色：白色
  static const Color lightSurface = Color(0xFFFFFFFF);

  /// 淺色主題 (大自然配色)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: lightSurface,
        error: const Color(AppColors.errorValue),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: lightSurface,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        backgroundColor: lightSurface,
      ),
      expansionTileTheme: const ExpansionTileThemeData(
        iconColor: primaryColor,
        collapsedIconColor: Colors.grey,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
