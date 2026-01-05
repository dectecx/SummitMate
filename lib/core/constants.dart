/// SummitMate 核心常數定義
library;

/// App 基本資訊
class AppInfo {
  static const String appName = 'SummitMate';
  static const String appNameChinese = '山友';
  static const String version = '0.0.4';
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

  // Gear Cloud API Actions
  static const String actionFetchGearSets = 'fetch_gear_sets';
  static const String actionFetchGearSetByKey = 'fetch_gear_set_by_key';
  static const String actionDownloadGearSet = 'download_gear_set';
  static const String actionUploadGearSet = 'upload_gear_set';
  static const String actionDeleteGearSet = 'delete_gear_set';

  // GearLibrary API Actions (個人裝備庫)
  // 【未來規劃】owner_key → user_id (會員機制上線後)
  static const String actionUploadGearLibrary = 'upload_gear_library';
  static const String actionDownloadGearLibrary = 'download_gear_library';

  // Trip Cloud API Actions (行程雲端同步)
  static const String actionFetchTrips = 'fetch_trips';
  static const String actionAddTrip = 'add_trip';
  static const String actionUpdateTrip = 'update_trip';
  static const String actionDeleteTrip = 'delete_trip';
}

/// CWA 開放資料 ID
class CwaDataId {
  /// 鄉鎮天氣預報-全臺灣各鄉鎮市區預報資料
  static const String townshipForecastAll = 'F-D0047-093';

  // 宜蘭縣
  static const String townshipForecastYilan3Day = 'F-D0047-001';
  static const String townshipForecastYilan7Day = 'F-D0047-003';

  // 桃園市
  static const String townshipForecastTaoyuan3Day = 'F-D0047-005';
  static const String townshipForecastTaoyuan7Day = 'F-D0047-007';

  // 新竹縣
  static const String townshipForecastHsinchuCounty3Day = 'F-D0047-009';
  static const String townshipForecastHsinchuCounty7Day = 'F-D0047-011';

  // 苗栗縣
  static const String townshipForecastMiaoli3Day = 'F-D0047-013';
  static const String townshipForecastMiaoli7Day = 'F-D0047-015';

  // 彰化縣
  static const String townshipForecastChanghua3Day = 'F-D0047-017';
  static const String townshipForecastChanghua7Day = 'F-D0047-019';

  // 南投縣
  static const String townshipForecastNantou3Day = 'F-D0047-021';
  static const String townshipForecastNantou7Day = 'F-D0047-023';

  // 雲林縣
  static const String townshipForecastYunlin3Day = 'F-D0047-025';
  static const String townshipForecastYunlin7Day = 'F-D0047-027';

  // 嘉義縣
  static const String townshipForecastChiayiCounty3Day = 'F-D0047-029';
  static const String townshipForecastChiayiCounty7Day = 'F-D0047-031';

  // 屏東縣
  static const String townshipForecastPingtung3Day = 'F-D0047-033';
  static const String townshipForecastPingtung7Day = 'F-D0047-035';

  // 臺東縣
  static const String townshipForecastTaitung3Day = 'F-D0047-037';
  static const String townshipForecastTaitung7Day = 'F-D0047-039';

  // 花蓮縣
  static const String townshipForecastHualien3Day = 'F-D0047-041';
  static const String townshipForecastHualien7Day = 'F-D0047-043';

  // 澎湖縣
  static const String townshipForecastPenghu3Day = 'F-D0047-045';
  static const String townshipForecastPenghu7Day = 'F-D0047-047';

  // 基隆市
  static const String townshipForecastKeelung3Day = 'F-D0047-049';
  static const String townshipForecastKeelung7Day = 'F-D0047-051';

  // 新竹市
  static const String townshipForecastHsinchuCity3Day = 'F-D0047-053';
  static const String townshipForecastHsinchuCity7Day = 'F-D0047-055';

  // 嘉義市
  static const String townshipForecastChiayiCity3Day = 'F-D0047-057';
  static const String townshipForecastChiayiCity7Day = 'F-D0047-059';

  // 臺北市
  static const String townshipForecastTaipei3Day = 'F-D0047-061';
  static const String townshipForecastTaipei7Day = 'F-D0047-063';

  // 高雄市
  static const String townshipForecastKaohsiung3Day = 'F-D0047-065';
  static const String townshipForecastKaohsiung7Day = 'F-D0047-067';

  // 新北市
  static const String townshipForecastNewTaipei3Day = 'F-D0047-069';
  static const String townshipForecastNewTaipei7Day = 'F-D0047-071';

  // 臺中市
  static const String townshipForecastTaichung3Day = 'F-D0047-073';
  static const String townshipForecastTaichung7Day = 'F-D0047-075';

  // 臺南市
  static const String townshipForecastTainan3Day = 'F-D0047-077';
  static const String townshipForecastTainan7Day = 'F-D0047-079';

  // 連江縣
  static const String townshipForecastLienchiang3Day = 'F-D0047-081';
  static const String townshipForecastLienchiang7Day = 'F-D0047-083';

  // 金門縣
  static const String townshipForecastKinmen3Day = 'F-D0047-085';
  static const String townshipForecastKinmen7Day = 'F-D0047-087';

  // 臺灣 (Global)
  static const String townshipForecastTaiwan3Day = 'F-D0047-089';
  static const String townshipForecastTaiwan7Day = 'F-D0047-091';

  /// 育樂天氣預報資料-登山一週日夜天氣預報
  static const String hikingForecast = 'F-B0053-031';

  /// 縣市鄉鎮預報 ID 對照表 (1週預報)
  static const Map<String, String> countyForecastIds = {
    '宜蘭縣': townshipForecastYilan7Day,
    '桃園市': townshipForecastTaoyuan7Day,
    '新竹縣': townshipForecastHsinchuCounty7Day,
    '苗栗縣': townshipForecastMiaoli7Day,
    '彰化縣': townshipForecastChanghua7Day,
    '南投縣': townshipForecastNantou7Day,
    '雲林縣': townshipForecastYunlin7Day,
    '嘉義縣': townshipForecastChiayiCounty7Day,
    '屏東縣': townshipForecastPingtung7Day,
    '臺東縣': townshipForecastTaitung7Day,
    '花蓮縣': townshipForecastHualien7Day,
    '澎湖縣': townshipForecastPenghu7Day,
    '基隆市': townshipForecastKeelung7Day,
    '新竹市': townshipForecastHsinchuCity7Day,
    '嘉義市': townshipForecastChiayiCity7Day,
    '臺北市': townshipForecastTaipei7Day,
    '高雄市': townshipForecastKaohsiung7Day,
    '新北市': townshipForecastNewTaipei7Day,
    '臺中市': townshipForecastTaichung7Day,
    '臺南市': townshipForecastTainan7Day,
    '連江縣': townshipForecastLienchiang7Day,
    '金門縣': townshipForecastKinmen7Day,
  };
}

/// Hive Box 名稱
class HiveBoxNames {
  // 核心資料
  static const String trips = 'trips';
  static const String itinerary = 'itinerary';
  static const String messages = 'messages';

  // 輔助功能
  static const String gear = 'gear';
  static const String gearLibrary = 'gear_library';
  static const String polls = 'polls';
  static const String weather = 'weather_cache';

  // 監控與設定
  static const String logs = 'app_logs';
  static const String settings = 'settings';
}
