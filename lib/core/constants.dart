/// SummitMate 核心常數定義
library;

/// App 基本資訊
class AppInfo {
  static const String appName = 'SummitMate';
  static const String appNameChinese = '山友';
  static const String version = '0.0.9';
  static const int verificationCodeExpiryMinutes = 10; // 驗證碼有效時間 (分鐘)
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
  static const String actionTripGetFull = 'trip_get_full';
  static const String actionItineraryList = 'itinerary_list';
  static const String actionItineraryUpdate = 'itinerary_update';
  static const String actionMessageList = 'message_list';
  static const String actionMessageCreate = 'message_create';
  static const String actionMessageCreateBatch = 'message_create_batch';
  static const String actionMessageDelete = 'message_delete';
  static const String actionWeatherGet = 'weather_get';

  // Poll API Actions (Flattened)
  static const String actionPollList = 'poll_list';
  static const String actionPollCreate = 'poll_create';
  static const String actionPollVote = 'poll_vote';
  static const String actionPollAddOption = 'poll_add_option';
  static const String actionPollDeleteOption = 'poll_delete_option';
  static const String actionPollClose = 'poll_close';
  static const String actionPollDelete = 'poll_delete';

  static const String actionSystemHeartbeat = 'system_heartbeat';
  static const String actionLogUpload = 'log_upload';

  // Gear Cloud API Actions
  static const String actionGearSetList = 'gear_set_list';
  static const String actionGearSetGet = 'gear_set_get';
  static const String actionGearSetDownload = 'gear_set_download';
  static const String actionGearSetUpload = 'gear_set_upload';
  static const String actionGearSetDelete = 'gear_set_delete';

  // GearLibrary API Actions (個人裝備庫)
  // 【未來規劃】owner_key → user_id (會員機制上線後)
  static const String actionGearLibraryUpload = 'gear_library_upload';
  static const String actionGearLibraryDownload = 'gear_library_download';

  // Trip Cloud API Actions (行程雲端同步)
  static const String actionTripList = 'trip_list';
  static const String actionTripCreate = 'trip_create';
  static const String actionTripUpdate = 'trip_update';
  static const String actionTripDelete = 'trip_delete';
  static const String actionTripSetActive = 'trip_set_active';
  static const String actionTripSync = 'trip_sync';

  // Auth API Actions
  static const String actionAuthRegister = 'auth_register';
  static const String actionAuthLogin = 'auth_login';
  static const String actionAuthValidate = 'auth_validate';
  static const String actionAuthVerifyEmail = 'auth_verify_email';
  static const String actionAuthResendCode = 'auth_resend_code';
  static const String actionAuthDeleteUser = 'auth_delete_user';
  static const String actionAuthRefreshToken = 'auth_refresh_token';
  static const String actionAuthUpdateProfile = 'auth_update_profile';

  // GroupEvent API Actions (揪團)
  static const String actionGroupEventList = 'group_event_list';
  static const String actionGroupEventGet = 'group_event_get';
  static const String actionGroupEventCreate = 'group_event_create';
  static const String actionGroupEventUpdate = 'group_event_update';
  static const String actionGroupEventClose = 'group_event_close';
  static const String actionGroupEventDelete = 'group_event_delete';
  static const String actionGroupEventApply = 'group_event_apply';
  static const String actionGroupEventCancelApplication = 'group_event_cancel_application';
  static const String actionGroupEventReviewApplication = 'group_event_review_application';
  static const String actionGroupEventMy = 'group_event_my';
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
  static const String groupEvents = 'group_events';
  static const String groupEventApplications = 'group_event_applications';
  static const String weather = 'weather_cache';

  // 監控與設定
  static const String logs = 'app_logs';
  static const String settings = 'settings';
}
