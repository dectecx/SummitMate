import 'package:flutter/material.dart';
import 'theme_types.dart';
import 'i_theme_strategy.dart';
import 'strategies/nature_theme_strategy.dart';
import 'strategies/creative_theme_strategy.dart';
import 'strategies/minimalist_theme_strategy.dart';
import 'strategies/earth_theme_strategy.dart';
import 'strategies/night_theme_strategy.dart';

/// 主題管理類別
class AppTheme {
  /// 取得當前主題策略
  static AppThemeStrategy getStrategy(AppThemeType type) {
    switch (type) {
      case AppThemeType.nature:
        return NatureThemeStrategy();
      case AppThemeType.creative:
        return CreativeThemeStrategy();
      case AppThemeType.minimalist:
        return MinimalistThemeStrategy();
      case AppThemeType.earth:
        return EarthThemeStrategy();
      case AppThemeType.night:
        return NightThemeStrategy();
    }
  }

  /// 取得 ThemeData (便捷存取)
  static ThemeData getThemeData(AppThemeType type) {
    return getStrategy(type).themeData;
  }
}
