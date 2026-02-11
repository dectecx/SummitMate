import 'package:flutter/material.dart';
import '../i_theme_strategy.dart';

/// 2. 活力橙主題 (Creative Theme)
///
/// 設計理念：鮮豔、充滿活力，適合年輕化或需要高強度的場景。
class CreativeThemeStrategy implements AppThemeStrategy {
  @override
  String get name => '活力橙';

  // --- 核心配色 ---
  static const Color vibrantOrange = Color(0xFFFF6E40); // Deep Orange Accent
  static const Color freshBlue = Color(0xFF448AFF); // Blue Accent
  static const Color sunnyYellow = Color(0xFFFFAB00); // Amber Accent
  static const Color energeticRed = Color(0xFFFF5252); // Red Accent

  @override
  ThemeData get themeData => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    colorScheme: ColorScheme.fromSeed(
      seedColor: vibrantOrange,
      primary: vibrantOrange,
      onPrimary: Colors.white,
      secondary: freshBlue,
      onSecondary: Colors.white,
      tertiary: sunnyYellow,
      error: energeticRed,
      surface: Colors.white,
      surfaceContainerHighest: Color(0xFFFFF3E0), // VERY light orange tint
    ),

    scaffoldBackgroundColor: Colors.white,

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.black87),
      titleTextStyle: TextStyle(color: Colors.black87, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: vibrantOrange,
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        elevation: 6,
        shadowColor: vibrantOrange.withValues(alpha: 0.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: sunnyYellow,
      foregroundColor: Colors.black,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF1F3F4),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: vibrantOrange, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),

    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), // 圓潤風格
    ),
  );

  @override
  LinearGradient? get appGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.3],
    colors: [
      Color(0xFFFFF3E0), // Orange 50
      Colors.white,
    ],
  );

  @override
  LinearGradient? get appBarGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF3E0), Colors.white],
  );

  @override
  LinearGradient? get bottomBarGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFE0B2), // Orange 100 (Deeper)
      Color(0xFFFFF3E0), // Orange 50
    ],
  );

  @override
  LinearGradient? get drawerGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white,
      Color(0xFFFFF3E0), // Orange 50 (Back to subtle)
    ],
  );
}
