library;

import '../data/models/mountain_location.dart';

/// App 基本資訊
class AppInfo {
  static const String appName = 'SummitMate';
  static const String appNameChinese = '山友';
  static const String version = '0.0.10';
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
  static const String windyUrl = 'https://www.windy.com/';
  static const String cwaUrl = 'https://www.cwa.gov.tw/V8/C/L/Mountain/Mountain.html';
}

/// 山岳資料
class MountainData {
  static const MountainLocation jiamingLake = MountainLocation(
    id: 'jiaming_lake',
    name: '三叉山 (嘉明湖)',
    altitude: 3496,
    region: MountainRegion.south,
    category: MountainCategory.baiyue,
    introduction:
        '三叉山位於臺灣臺東縣海端鄉利稻村、花蓮縣卓溪鄉古風村與高雄市桃源區梅山里之間，為台灣知名山峰，也是台灣百岳之一，排名第27。三叉山3,496公尺，屬於中央山脈。三叉山南方有向陽山，北邊連接雲峰。三叉山具特色為山頂平緩，全是淺竹，視野良好。',
    features: '嘉明湖位於三叉山東南側，海拔約3310公尺，是台灣第二高的高山湖泊。湖面呈橢圓形，湖水為湛藍色，有「天使的眼淚」之稱。三叉山山頂展望廣闊，可眺望玉山、秀姑巒山等名山。',
    trailheads: ['向陽登山口'],
    mapRef: '上河文化 M22 丹大‧東郡橫斷',
    jurisdiction: '林務局臺東林區管理處',
    isBeginnerFriendly: false,
    cwaPid: 'D055',
    windyParams: '23.293/121.034?23.284,121.034,14',
    links: [
      MountainLink(type: LinkType.permit, title: '申請入山證', url: 'https://hike.taiwan.gov.tw/'),
      MountainLink(type: LinkType.cabin, title: '山屋預約申請', url: 'https://jmlnt.forest.gov.tw/room/'),
      MountainLink(
        type: LinkType.trail,
        title: '台灣山林悠遊網 (官網)',
        url: 'https://recreation.forest.gov.tw/Trail/RT?tr_id=139',
      ),
      MountainLink(
        type: LinkType.gpx,
        title: 'GPX 軌跡檔下載 (健行筆記)',
        url: 'https://hiking.biji.co/index.php?q=trail&act=gpx_list&city=全部&keyword=嘉明湖國家步道',
      ),
      MountainLink(
        type: LinkType.gearPdf,
        title: '官方建議裝備清單',
        url:
            'https://recreation.forest.gov.tw/Files/RT/UploadFiles/Package/139_%E5%98%89%E6%98%8E%E6%B9%96%E5%9C%8B%E5%AE%B6%E6%AD%A5%E9%81%93_%E5%A4%9A%E6%97%A5%E7%99%BB%E5%B1%B1%E5%9E%8B%E6%AD%A5%E9%81%93%E5%BB%BA%E8%AD%B0%E8%A3%9D%E5%82%99%E6%B8%85%E5%96%AE.pdf',
      ),
      MountainLink(
        type: LinkType.accommodation,
        title: '鋤禾日好-站前館 (住宿)',
        url: 'https://www.booking.com/hotel/tw/farming-hostel.zh-tw.html',
      ),
    ],
  );

  static const MountainLocation jadeMountain = MountainLocation(
    id: 'jade_mountain',
    name: '玉山主峰',
    altitude: 3952,
    region: MountainRegion.central,
    category: MountainCategory.baiyue,
    introduction: '玉山主峰海拔3952公尺，為台灣第一高峰，也是東北亞最高峰。玉山山容氣勢磅礡，四季景致變化萬千，是台灣登山客心目中的聖山。',
    features: '玉山群峰氣勢磅礡，主峰視野遼闊，可俯瞰全台。冬季雪景壯麗，有「玉山積雪」之稱。生態資源豐富，植被隨海拔變化明顯。',
    trailheads: ['塔塔加登山口'],
    mapRef: '上河文化 M19 玉山群峰',
    jurisdiction: '玉山國家公園',
    isBeginnerFriendly: true,
    cwaPid: 'D033', // 玉山
    windyParams: '23.470/120.957?23.470,120.957,14',
    links: [
      MountainLink(type: LinkType.permit, title: '入園入山申請', url: 'https://npm.cpami.gov.tw/'),
      MountainLink(type: LinkType.cabin, title: '排雲山莊抽籤', url: 'https://npm.cpami.gov.tw/bed_1.aspx'),
    ],
  );

  static const MountainLocation snowMountain = MountainLocation(
    id: 'snow_mountain',
    name: '雪山主峰',
    altitude: 3886,
    region: MountainRegion.central,
    category: MountainCategory.baiyue,
    introduction: '雪山主峰海拔3886公尺，為台灣第二高峰。雪山圈谷為台灣目前發現最完整的冰斗地形，景色壯麗。雪山主東峰路線是熱門的百岳路線。',
    features: '雪山圈谷冰河地形完整，景色壯觀。黑森林冷杉純林蒼鬱挺拔。高山杜鵑花季美不勝收。',
    trailheads: ['雪山登山口 (武陵農場)'],
    mapRef: '上河文化 M06 雪山聖稜線',
    jurisdiction: '雪霸國家公園',
    isBeginnerFriendly: true,
    cwaPid: 'D003', // 雪山
    windyParams: '24.383/121.234?24.383,121.234,14',
    links: [
      MountainLink(type: LinkType.permit, title: '入園申請', url: 'https://npm.cpami.gov.tw/'),
      MountainLink(type: LinkType.cabin, title: '三六九山莊/七卡山莊', url: 'https://npm.cpami.gov.tw/bed_1.aspx'),
    ],
  );

  static const List<MountainLocation> all = [jiamingLake, jadeMountain, snowMountain];
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
  static const String actionGroupEventLike = 'group_event_like';
  static const String actionGroupEventUnlike = 'group_event_unlike';
  static const String actionGroupEventAddComment = 'group_event_add_comment';
  static const String actionGroupEventGetComments = 'group_event_get_comments';
  static const String actionGroupEventDeleteComment = 'group_event_delete_comment';
  static const String actionGroupEventGetApplications = 'group_event_get_applications';

  // Favorites API Actions
  static const String actionFavoritesGet = 'favorites_get';
  static const String actionFavoritesUpdate = 'favorites_update';
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
  static const String mountainFavorites = 'mountain_favorites';
  static const String groupEventFavorites = 'group_event_favorites';
}
