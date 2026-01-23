import 'package:flutter/material.dart';
import '../i_theme_strategy.dart';

/// 大地色 (Earth Theme)
///
/// 設計理念：融合泥土的棕色與草地的綠色，營造豐富的自然層次感，適合露營與登山導航。
class EarthThemeStrategy implements AppThemeStrategy {
  @override
  String get name => '大地色';

  // --- 核心配色 ---
  static const Color clayBrown = Color(0xFF795548); // Brown 500
  static const Color forestGreen = Color(0xFF388E3C); // Green 700
  static const Color sandBeige = Color(0xFFD7CCC8); // Brown 100
  static const Color offWhite = Color(0xFFFBFBE9); // Warm tint white
  static const Color darkLoam = Color(0xFF3E2723); // Brown 900

  @override
  ThemeData get themeData => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    colorScheme: ColorScheme.fromSeed(
      seedColor: clayBrown,
      primary: clayBrown,
      onPrimary: Colors.white,
      secondary: forestGreen, // Green Secondary
      onSecondary: Colors.white,
      tertiary: const Color(0xFF8D6E63),
      surface: const Color(0xFFF5F5F5),
      surfaceContainerHighest: sandBeige.withValues(alpha: 0.4),
    ),

    scaffoldBackgroundColor: offWhite,

    appBarTheme: const AppBarTheme(
      backgroundColor: offWhite,
      foregroundColor: darkLoam,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: darkLoam),
      titleTextStyle: TextStyle(color: darkLoam, fontWeight: FontWeight.w700, fontSize: 20, letterSpacing: 0.5),
    ),

    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: clayBrown.withValues(alpha: 0.15)),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: clayBrown,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: forestGreen,
      foregroundColor: Colors.white,
      elevation: 3,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: clayBrown, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: darkLoam),
      bodyMedium: TextStyle(color: darkLoam),
      titleLarge: TextStyle(color: darkLoam, fontWeight: FontWeight.bold),
    ),
  );

  @override
  LinearGradient? get appGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.4],
    colors: [
      Color(0xFFEFEBE9), // Brown 50
      offWhite,
    ],
  );

  @override
  LinearGradient? get appBarGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFEFEBE9), offWhite],
  );

  @override
  LinearGradient? get bottomBarGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFD7CCC8), // Brown 100 (Deeper)
      Color(0xFFEFEBE9), // Brown 50
    ],
  );

  @override
  LinearGradient? get drawerGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      offWhite,
      Color(0xFFD7CCC8), // Brown 100 (Visible)
    ],
  );
}
