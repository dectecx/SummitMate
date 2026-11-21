/// App 基本資訊
class AppInfo {
  static const String appName = 'SummitMate';
  static const String appNameChinese = '山友';
  static const String version = '0.0.10';
  static const int verificationCodeExpiryMinutes = 10; // 驗證碼有效時間 (分鐘)
}

/// 斷點與佈局常數
class AppBreakpoints {
  /// 手機與平板的分界 (width < 600 為手機)
  static const double mobile = 600;

  /// 平板與桌面的分界 (width < 1024 為平板)
  static const double desktop = 1024;
}

/// 顏色常數 (遵循 Dark Mode 設計)
class AppColors {
  // 主色調
  static const int backgroundValue = 0xFF121212;
  static const int surfaceValue = 0xFF1E1E1E;
  static const int textPrimaryValue = 0xFFE0E0E0;
  static const int textSecondaryValue = 0xFFB0B0B0;
  static const int accentValue = 0xFFFFC107; // Amber
  static const int successValue = 0xFF4CAF50; // Green for checked items
  static const int errorValue = 0xFFF44336;
}
