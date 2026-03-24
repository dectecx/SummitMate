import 'package:flutter/material.dart';

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

  /// 取得側邊欄漸層 (Optional)
  LinearGradient? get drawerGradient;

  // --- 狀態色彩 (Status Colors) ---

  /// 成功狀態顏色
  Color get successColor;

  /// 警告狀態顏色
  Color get warningColor;

  /// 提示/資訊狀態顏色
  Color get infoColor;

  /// 錯誤/危險狀態顏色
  Color get errorColor;
}
