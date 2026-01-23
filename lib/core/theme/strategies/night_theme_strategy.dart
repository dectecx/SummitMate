import 'package:flutter/material.dart';
import '../i_theme_strategy.dart';

/// 月光夜 (Night Theme)
///
/// 設計理念：低光環境下的護眼模式，使用深藍、深灰為基調，搭配冷光藍或月光銀作為點綴。
class NightThemeStrategy implements AppThemeStrategy {
  @override
  String get name => '月光夜';

  // --- 核心配色 ---
  static const Color midnightBlue = Color(0xFF151922); // Deep Blue Black
  static const Color surfaceBlue = Color(0xFF1E2430); // Lighter Card Bg
  static const Color primaryNeon = Color(0xFF64B5F6); // Soft Blue Neon
  static const Color secondaryTeal = Color(0xFF4DB6AC); // Teal Accent
  static const Color textLight = Color(0xFFECEFF1); // Soft White

  @override
  ThemeData get themeData => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryNeon,
      brightness: Brightness.dark,
      primary: primaryNeon,
      onPrimary: Colors.black,
      secondary: secondaryTeal,
      onSecondary: Colors.black,
      surface: surfaceBlue,
      onSurface: textLight,
      surfaceContainerHighest: Color(0xFF2C3444),
    ),

    scaffoldBackgroundColor: midnightBlue,

    appBarTheme: const AppBarTheme(
      backgroundColor: midnightBlue,
      foregroundColor: textLight,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(color: textLight, fontWeight: FontWeight.normal, fontSize: 18, letterSpacing: 1),
      iconTheme: IconThemeData(color: textLight),
    ),

    cardTheme: CardThemeData(
      color: surfaceBlue,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primaryNeon,
        foregroundColor: Colors.black, // Dark text on bright button for contrast
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: secondaryTeal,
      foregroundColor: Colors.black,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF0F1218), // Darker than bg
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryNeon),
      ),
      labelStyle: TextStyle(color: Colors.grey[400]),
      hintStyle: TextStyle(color: Colors.grey[600]),
    ),

    // Customizing text for better reading in dark mode
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: textLight),
      bodyMedium: TextStyle(color: Color(0xFFB0BEC5)), // Blue Grey Lighter
    ),
  );

  @override
  LinearGradient? get appGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF263238), // Blue Grey 900 (Moonlight glow top)
      Color(0xFF151922), // Midnight base (Darker bottom)
    ],
  );

  @override
  LinearGradient? get appBarGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF37474F), // Blue Grey 800 (Stronger Moonlight)
      Color(0xFF151922),
    ],
  );

  @override
  LinearGradient? get bottomBarGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1E2430), // Surface Blue (Lighter than 151922 but dark)
      Color(0xFF151922),
    ],
  );

  @override
  LinearGradient? get drawerGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF37474F), // Blue Grey 800 (Distinct Moonlight source)
      Color(0xFF10131A), // Deep Black Blue bottom right
    ],
  );
}
