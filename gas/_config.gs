/**
 * ============================================================
 * 常數與設定
 * ============================================================
 * @fileoverview 集中管理所有常數，避免散落各處
 *
 * 排序原則: Trip → Itinerary → Messages → Gear → Polls → Logs → Heartbeat → Weather
 */

// ============================================================
// 工作表名稱 (依邏輯重要性排序)
// ============================================================

// 核心資料
const SHEET_TRIPS = "Trips";
const SHEET_ITINERARY = "Itinerary";
const SHEET_MESSAGES = "Messages";

// 輔助功能
const SHEET_GEAR = "GearSets";
const SHEET_POLLS = "Polls";
const SHEET_POLL_OPTIONS = "PollOptions";
const SHEET_POLL_VOTES = "PollVotes";

// 監控與外部服務
const SHEET_LOGS = "Logs";
const SHEET_HEARTBEAT = "Heartbeat";
const SHEET_WEATHER = "Weather_Hiking_App";

// ============================================================
// 工作表欄位定義 (PK → FK → 其他欄位)
// ============================================================

const HEADERS_TRIPS = [
  "id", // PK
  "name",
  "start_date",
  "end_date",
  "description",
  "cover_image",
  "is_active",
  "created_at",
];

const HEADERS_ITINERARY = [
  "uuid", // PK (新增)
  "trip_id", // FK → Trips
  "day",
  "name",
  "est_time",
  "altitude",
  "distance",
  "note",
  "image_asset",
];

const HEADERS_MESSAGES = [
  "uuid", // PK
  "trip_id", // FK → Trips
  "parent_id", // FK → Messages (回覆)
  "user",
  "category",
  "content",
  "timestamp",
  "avatar",
];

const HEADERS_GEAR = [
  "uuid", // PK
  "title",
  "author",
  "visibility",
  "key",
  "total_weight",
  "item_count",
  "uploaded_at",
  "items_json",
];

const HEADERS_LOGS = [
  "upload_time",
  "device_id",
  "device_name",
  "timestamp",
  "level",
  "source",
  "message",
];

const HEADERS_HEARTBEAT = ["user", "avatar", "last_seen", "view", "platform"];

// ============================================================
// 預設值
// ============================================================

const DEFAULT_AVATAR = "🐻";
const DEFAULT_USER = "Anonymous";
const DEFAULT_CATEGORY = "Misc";
