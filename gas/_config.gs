/**
 * ============================================================
 * 常數與設定
 * ============================================================
 * @fileoverview 集中管理所有常數，避免散落各處
 */

// ============================================================
// 工作表名稱
// ============================================================

const SHEET_ITINERARY = "Itinerary";
const SHEET_MESSAGES = "Messages";
const SHEET_TRIPS = "Trips";
const SHEET_GEAR = "GearSets";
const SHEET_LOGS = "Logs";
const SHEET_HEARTBEAT = "Heartbeat";
const SHEET_POLLS = "Polls";
const SHEET_POLL_OPTIONS = "PollOptions";
const SHEET_POLL_VOTES = "PollVotes";
const SHEET_WEATHER = "Weather_Hiking_App";

// ============================================================
// 工作表欄位定義
// ============================================================

const HEADERS_ITINERARY = [
  "day",
  "name",
  "est_time",
  "altitude",
  "distance",
  "note",
  "image_asset",
  "trip_id",
];

const HEADERS_MESSAGES = [
  "uuid",
  "parent_id",
  "user",
  "category",
  "content",
  "timestamp",
  "avatar",
  "trip_id",
];

const HEADERS_TRIPS = [
  "id",
  "name",
  "start_date",
  "end_date",
  "description",
  "cover_image",
  "is_active",
  "created_at",
];

const HEADERS_GEAR = [
  "uuid",
  "title",
  "author",
  "total_weight",
  "item_count",
  "visibility",
  "key",
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
