/// SummitMate 核心常數定義
library;

/// App 基本資訊
class AppInfo {
  static const String appName = 'SummitMate';
  static const String appNameChinese = '山友';
  static const String version = '0.1.0';
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

/// 留言分類
class MessageCategory {
  static const String gear = 'Gear';
  static const String plan = 'Plan';
  static const String misc = 'Misc';

  static const List<String> all = [gear, plan, misc];
}

/// 裝備分類
class GearCategory {
  static const String sleep = 'Sleep';
  static const String cook = 'Cook';
  static const String wear = 'Wear';
  static const String other = 'Other';

  static const List<String> all = [sleep, cook, wear, other];
}

/// 行程天數
class ItineraryDay {
  static const String d0 = 'D0';
  static const String d1 = 'D1';
  static const String d2 = 'D2';

  static const List<String> all = [d0, d1, d2];
}

/// 外部連結
class ExternalLinks {
  static const String windyUrl = 'https://www.windy.com/?23.298,120.960,12';
  static const String cwaUrl = 'https://www.cwa.gov.tw/V8/C/W/Town/Town.html?TID=1001708';
}

/// SharedPreferences Keys
class PrefKeys {
  static const String username = 'username';
  static const String lastSyncTime = 'lastSyncTime';
}

/// API 配置
class ApiConfig {
  // Google Apps Script Web App URL (需於實際部署時替換)
  static const String gasBaseUrl = 'YOUR_GOOGLE_APPS_SCRIPT_URL';
  
  // API Actions
  static const String actionFetchAll = 'fetch_all';
  static const String actionAddMessage = 'add_message';
  static const String actionDeleteMessage = 'delete_message';
}
