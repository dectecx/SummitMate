import 'package:flutter/material.dart';

/// App 主題類型
enum AppThemeType {
  /// 莫蘭迪綠 (預設 - 自然優雅)
  morandi,

  /// 活力橙 (清新活力)
  creative,

  /// 極簡黑 (未來規劃)
  modern,

  /// 大地棕 (未來規劃)
  nature,

  /// 月光夜 (護眼模式 - 未來規劃)
  night,
}

/// 主題策略介面
abstract class AppThemeStrategy {
  String get name;
  ThemeData get themeData;

  /// 取得 App 背景漸層 (Optional)
  LinearGradient? get appGradient;

  /// 取得 AppBar 漸層 (Optional)
  LinearGradient? get appBarGradient;
}

/// 1. 莫蘭迪主題 (Default/Green/Nature)
class MorandiThemeStrategy implements AppThemeStrategy {
  @override
  String get name => '莫蘭迪綠';

  // 莫蘭迪色票 (Refined v2)
  static const Color forestGreen = Color(0xFF4A6358); // 主色
  static const Color sageGreen = Color(0xFF8FA895); // 次要色
  static const Color paleMist = Color(0xFFF9FAF9); // 背景色
  static const Color charcoal = Color(0xFF1F2B26); // 文字深色
  
  @override
  ThemeData get themeData => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: forestGreen,
      primary: forestGreen,
      secondary: sageGreen,
      surface: paleMist,
      onSurface: charcoal,
      surfaceContainerHighest: sageGreen.withValues(alpha: 0.15),
    ),
    scaffoldBackgroundColor: paleMist,
    appBarTheme: const AppBarTheme(
      backgroundColor: forestGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: forestGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 1,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: forestGreen, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: charcoal, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(color: charcoal, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: charcoal),
      bodyMedium: TextStyle(color: Color(0xFF444444)),
    ),
  );

  @override
  LinearGradient? get appGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF2F5F3), Color(0xFFF9FAF9)], // Subtle top-down fade
      );

  @override
  LinearGradient? get appBarGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [forestGreen, Color(0xFF5F7A6A)], // Forest Green -> Slightly Lighter
      );
}

/// 2. 創意活力主題 (Fresh/Vibrant)
class CreativeThemeStrategy implements AppThemeStrategy {
  @override
  String get name => '活力橙';

  static const Color vibrantOrange = Color(0xFFFF6B6B);
  static const Color sunnyYellow = Color(0xFFFFD93D);
  static const Color freshTeal = Color(0xFF4D96FF);

  @override
  ThemeData get themeData => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: vibrantOrange,
      primary: vibrantOrange,
      secondary: freshTeal,
      surface: Colors.grey[50],
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.black87),
      titleTextStyle: TextStyle(
          color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: vibrantOrange,
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        elevation: 4,
        shadowColor: vibrantOrange.withValues(alpha: 0.4),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: vibrantOrange, width: 2),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );

  @override
  LinearGradient? get appGradient => null;

  @override
  LinearGradient? get appBarGradient => null;
}

// Future Placeholders
class ModernThemeStrategy implements AppThemeStrategy {
  @override
  String get name => '極簡黑';
  @override
  ThemeData get themeData => ThemeData.light();
  @override
  LinearGradient? get appGradient => null;
  @override
  LinearGradient? get appBarGradient => null;
}

class NatureThemeStrategy implements AppThemeStrategy {
  @override
  String get name => '大地棕';
  @override
  ThemeData get themeData => ThemeData.light();
  @override
  LinearGradient? get appGradient => null;
  @override
  LinearGradient? get appBarGradient => null;
}

class NightThemeStrategy implements AppThemeStrategy {
  @override
  String get name => '月光夜';
  @override
  ThemeData get themeData => ThemeData.dark();
  @override
  LinearGradient? get appGradient => null;
  @override
  LinearGradient? get appBarGradient => null;
}

/// 主題管理類別
class AppTheme {
  /// 取得當前主題策略
  static AppThemeStrategy getStrategy(AppThemeType type) {
    switch (type) {
      case AppThemeType.morandi:
        return MorandiThemeStrategy();
      case AppThemeType.creative:
        return CreativeThemeStrategy();
      case AppThemeType.modern:
        return ModernThemeStrategy();
      case AppThemeType.nature:
        return NatureThemeStrategy();
      case AppThemeType.night:
        return NightThemeStrategy();
    }
  }

  /// 取得 ThemeData (便捷存取)
  static ThemeData getThemeData(AppThemeType type) {
    return getStrategy(type).themeData;
  }
}
