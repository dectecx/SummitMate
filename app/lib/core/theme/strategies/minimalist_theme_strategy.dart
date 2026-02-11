import 'package:flutter/material.dart';
import '../i_theme_strategy.dart';

/// 極簡黑 (Minimalist Theme)
///
/// 設計理念：高對比黑白為主，強調俐落、專業與現代感。去除多餘裝飾，專注於內容與結構。
class MinimalistThemeStrategy implements AppThemeStrategy {
  @override
  String get name => '極簡黑';

  // --- 核心配色 ---
  static const Color pureBlack = Color(0xFF121212);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color lightGrey = Color(0xFFEEEEEE);
  static const Color mediumGrey = Color(0xFF9E9E9E);
  static const Color darkGrey = Color(0xFF212121);

  @override
  ThemeData get themeData => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // Standard Color Scheme
    colorScheme: ColorScheme.fromSeed(
      seedColor: pureBlack,
      primary: pureBlack,
      onPrimary: pureWhite,
      secondary: darkGrey,
      onSecondary: pureWhite,
      surface: pureWhite,
      onSurface: pureBlack,
      surfaceContainerHighest: lightGrey,
    ),

    scaffoldBackgroundColor: pureWhite,

    appBarTheme: const AppBarTheme(
      backgroundColor: pureWhite,
      foregroundColor: pureBlack,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(color: pureBlack, fontWeight: FontWeight.bold, fontSize: 20),
      iconTheme: IconThemeData(color: pureBlack),
    ),

    cardTheme: CardThemeData(
      color: pureWhite,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero, // Keep zero radius but standard shape
        side: BorderSide(color: Colors.black12),
      ),
      margin: EdgeInsets.zero,
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: pureBlack,
        foregroundColor: pureWhite,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        elevation: 0,
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: pureBlack,
      foregroundColor: pureWhite,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),

    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFFFAFAFA),
      border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black26)),
      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black26)),
      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: pureBlack, width: 2)),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      labelStyle: TextStyle(color: mediumGrey),
    ),

    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: pureBlack, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(color: pureBlack, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: pureBlack),
      bodyMedium: TextStyle(color: darkGrey),
    ),
  );

  @override
  LinearGradient? get appGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [pureWhite, Color(0xFFF5F5F5)], // Grey 50
  );

  @override
  LinearGradient? get appBarGradient =>
      const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [pureWhite, pureWhite]);

  @override
  LinearGradient? get bottomBarGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFEEEEEE), // Grey 200 (Deeper)
      Color(0xFFF5F5F5), // Grey 50
    ],
  );

  @override
  LinearGradient? get drawerGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      pureWhite,
      Color(0xFFEEEEEE), // Grey 200 (Visible)
    ],
  );
}
