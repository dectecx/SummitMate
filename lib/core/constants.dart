/// SummitMate 核心常數定義
library;

/// App 基本資訊
class AppInfo {
  static const String appName = 'SummitMate';
  static const String appNameChinese = '山友';
  static const String version = '0.0.1';
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
  static const String important = 'Important'; // 重要公告
  static const String chat = 'Chat'; // 討論/閒聊
  static const String gear = 'Gear'; // 裝備

  static const List<String> all = [important, chat, gear];
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
  static const String windyUrl = 'https://www.windy.com/23.293/121.034?23.284,121.034,14';
  static const String cwaUrl = 'https://www.cwa.gov.tw/V8/C/L/Mountain/Mountain.html?PID=D055';

  // 嘉明湖步道資訊
  static const String trailPageUrl = 'https://recreation.forest.gov.tw/Trail/RT?tr_id=139';
  static const String permitUrl = 'https://hike.taiwan.gov.tw/';
  static const String cabinUrl = 'https://jmlnt.forest.gov.tw/room/';
  static const String gpxUrl = 'https://hiking.biji.co/index.php?q=trail&act=gpx_list&city=全部&keyword=嘉明湖國家步道';
  static const String gearPdfUrl =
      'https://recreation.forest.gov.tw/Files/RT/UploadFiles/Package/139_%E5%98%89%E6%98%8E%E6%B9%96%E5%9C%8B%E5%AE%B6%E6%AD%A5%E9%81%93_%E5%A4%9A%E6%97%A5%E7%99%BB%E5%B1%B1%E5%9E%8B%E6%AD%A5%E9%81%93%E5%BB%BA%E8%AD%B0%E8%A3%9D%E5%82%99%E6%B8%85%E5%96%AE.pdf';

  static const String accommodationUrl =
      'https://www.booking.com/hotel/tw/farming-hostel.zh-tw.html?aid=399012&label=pu-li-hnxFhu60_gPvpQoVknixWASM392942680216%3Apl%3Ata%3Ap1%3Ap2%3Aac%3Aap%3Aneg%3Afi%3Atiaud-2382347442848%3Akwd-55863106651%3Alp9197983%3Ali%3Adem%3Adm%3Appccp%3DUmFuZG9tSVYkc2RlIyh9YR10fBTovuitswFzoSdli7I-nJpMwLg%401765802782&sid=cdaeaa92c377688191f979ae73a24f94&all_sr_blocks=226294003_103750000_0_0_0&checkin=2025-12-30&checkout=2025-12-31&dest_id=-2627848&dest_type=city&dist=0&group_adults=1&group_children=0&hapos=1&highlighted_blocks=226294003_103750000_0_0_0&hpos=1&matching_block_id=226294003_103750000_0_0_0&no_rooms=1&req_adults=1&req_children=0&room1=A&sb_price_type=total&sr_order=popularity&sr_pri_blocks=226294003_103750000_0_0_0__86850&srepoch=1766398689&srpvid=3c8743972d03168e582b5cf3dff69155&type=total&ucfs=1&';
}

/// SharedPreferences Keys
class PrefKeys {
  static const String username = 'username';
  static const String lastSyncTime = 'lastSyncTime';
}

/// API 配置
class ApiConfig {
  // API Actions
  static const String actionFetchAll = 'fetch_all';
  static const String actionFetchItinerary = 'fetch_itinerary';
  static const String actionFetchMessages = 'fetch_messages';
  static const String actionAddMessage = 'add_message';
  static const String actionDeleteMessage = 'delete_message';
  static const String actionFetchWeather = 'fetch_weather';
  static const String actionPoll = 'poll';
  static const String actionHeartbeat = 'heartbeat';
}

/// Hive Box 名稱
class HiveBoxNames {
  static const String settings = 'settings';
  static const String itinerary = 'itinerary';
  static const String messages = 'messages';
  static const String gear = 'gear';
  static const String weather = 'weather_cache';
  static const String logs = 'app_logs';
  static const String polls = 'polls';
}
