import 'package:flutter/material.dart';
import '../i_theme_strategy.dart';

/// 自然山林主題 (Nature Theme)
///
/// 設計理念：以大自然為靈感，使用大地色系與森林綠，營造放鬆、清新的氛圍。
/// 適用場景：戶外活動、登山記錄、放鬆瀏覽。
class NatureThemeStrategy implements AppThemeStrategy {
  @override
  String get name => '自然山林';

  // --- 核心配色 (Color Palette) ---

  /// 背景主色：暖白 (Warm White)
  static const Color baseWhite = Color(0xFFFAFAF9);

  /// 卡片背景：純白 (Pure White)
  static const Color surfaceWhite = Color(0xFFFFFFFF);

  /// 品牌主色：森林綠 (Forest Green)
  static const Color forestGreen = Color(0xFF2E7D32);

  /// 漸層深色：深叢林綠 (Deep Jungle)
  static const Color deepJungle = Color(0xFF1B5E20);

  /// 強調色：陽光金 (Sunny Gold)
  static const Color sunnyGold = Color(0xFFF9A825);

  /// 主要文字：深灰綠
  static const Color textMain = Color(0xFF1A1C19);

  /// 次要文字：深灰
  static const Color textBody = Color(0xFF424242);

  @override
  ThemeData get themeData => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // 定義核心色票 (Color Scheme)
    colorScheme: ColorScheme.fromSeed(
      seedColor: forestGreen,
      primary: forestGreen,
      onPrimary: Colors.white,
      secondary: sunnyGold,
      onSecondary: Colors.black,
      surface: baseWhite,
      onSurface: textMain,
      surfaceContainerHighest: forestGreen.withValues(alpha: 0.08),
    ),

    scaffoldBackgroundColor: baseWhite,

    // AppBar 樣式：融入背景，保持通透
    appBarTheme: const AppBarTheme(
      backgroundColor: baseWhite,
      foregroundColor: forestGreen,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: forestGreen),
      titleTextStyle: TextStyle(color: forestGreen, fontWeight: FontWeight.bold, fontSize: 20),
    ),

    // 卡片樣式：圓角、輕微陰影
    cardTheme: CardThemeData(
      color: surfaceWhite,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // 實心按鈕樣式
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: forestGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        shadowColor: forestGreen.withValues(alpha: 0.4),
      ),
    ),

    // 浮動按鈕樣式 (強調色)
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: sunnyGold,
      foregroundColor: Colors.white,
      elevation: 4,
    ),

    // 輸入框樣式
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: forestGreen, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(color: textBody),
    ),

    // 文字樣式
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: textMain, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(color: textMain, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: textMain),
      bodyMedium: TextStyle(color: textBody),
    ),
  );

  @override
  LinearGradient? get appGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.3],
    colors: [
      Color(0xFFEFF5F1), // Very pale green (softer)
      baseWhite,
    ],
  );

  @override
  LinearGradient? get appBarGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      baseWhite,
      Color(0xFFE8F5E9), // Green 50 (Subtle)
    ],
  );

  @override
  LinearGradient? get bottomBarGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFE8F5E9), // Green 50 (Top)
      Color(0xFFF1F8E9), // Lighter Green 50
    ],
  );

  @override
  LinearGradient? get drawerGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      baseWhite,
      Color(0xFFE8F5E9), // Green 50 (Back to subtle)
    ],
  );
}
