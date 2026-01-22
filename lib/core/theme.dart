import 'package:flutter/material.dart';

/// App 主題類型
enum AppThemeType {
  /// 自然山林 (預設 - 清新活力)
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

  /// 取得 BottomNavigationBar 漸層 (Optional)
  LinearGradient? get bottomBarGradient;
}

/// 1. 自然山林主題 (Nature Theme)
///
/// 設計理念：以大自然為靈感，使用大地色系與森林綠，營造放鬆、清新的氛圍。
/// 適用場景：戶外活動、登山記錄、放鬆瀏覽。
class MorandiThemeStrategy implements AppThemeStrategy {
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
      Color(0xFFEFF5F1), // 頂部淡綠色暈
      baseWhite, // 底部漸層至白
    ],
  );

  @override
  LinearGradient? get appBarGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      baseWhite,
      Color(0xFFF1F8E9), // 淺綠色漸層
    ],
  );

  @override
  LinearGradient? get bottomBarGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF1F8E9), baseWhite],
  );
}

/// 2. 活力橙主題 (Creative Theme)
///
/// 設計理念：鮮豔、充滿活力，適合年輕化或需要高強度的場景。
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
      titleTextStyle: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5),
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

  @override
  LinearGradient? get bottomBarGradient => null;
}

// --- 未來擴充主題 (Placeholders) ---

/// 極簡黑 (Modern) - 規劃中
class ModernThemeStrategy implements AppThemeStrategy {
  @override
  String get name => '極簡黑';
  @override
  ThemeData get themeData => ThemeData.light();
  @override
  LinearGradient? get appGradient => null;
  @override
  LinearGradient? get appBarGradient => null;
  @override
  LinearGradient? get bottomBarGradient => null;
}

/// 大地棕 (Nature) - 規劃中
class NatureThemeStrategy implements AppThemeStrategy {
  @override
  String get name => '大地棕';
  @override
  ThemeData get themeData => ThemeData.light();
  @override
  LinearGradient? get appGradient => null;
  @override
  LinearGradient? get appBarGradient => null;
  @override
  LinearGradient? get bottomBarGradient => null;
}

/// 月光夜 (Night) - 規劃中
class NightThemeStrategy implements AppThemeStrategy {
  @override
  String get name => '月光夜';
  @override
  ThemeData get themeData => ThemeData.dark();
  @override
  LinearGradient? get appGradient => null;
  @override
  LinearGradient? get appBarGradient => null;
  @override
  LinearGradient? get bottomBarGradient => null;
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
