/**
 * ============================================================
 * 常數與設定
 * ============================================================
 * @fileoverview 集中管理所有常數，避免散落各處
 *
 * 排序原則: Trip → Itinerary → Messages → Gear → Polls → Logs → Heartbeat → Weather
 */

// ============================================================
// 工作表名稱
// ============================================================

// 核心資料
const SHEET_TRIPS = "Trips";
const SHEET_ITINERARY = "Itinerary";
const SHEET_MESSAGES = "Messages";

// 輔助功能
const SHEET_GEAR = "GearSets";
const SHEET_GEAR_LIBRARY = "GearLibrary";
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
  "trip_id", // FK → Trips
  "title",
  "author",
  "visibility",
  "key",
  "total_weight",
  "item_count",
  "uploaded_at",
  "items_json",
];

// ============================================================
// 個人裝備庫 (GearLibrary)
// 【未來規劃】owner_key → user_id (會員機制上線後)
// ============================================================
const HEADERS_GEAR_LIBRARY = [
  "uuid", // PK
  "owner_key", // 擁有者識別碼 (未來改為 user_id)
  "name",
  "weight",
  "category",
  "notes",
  "created_at",
  "updated_at",
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

// ============================================================
// API 回應代碼 (XXYY 格式)
// XX: API 分類 (00=通用, 01=Trips, 02=Itinerary...)
// YY: 錯誤編號 (可跳號)
// ============================================================

/**
 * API 回應代碼常數
 * @readonly
 * @enum {string}
 */
const API_CODES = {
  /** 操作成功 */
  SUCCESS: "0000",

  // ========== 00XX - 通用錯誤 ==========
  /** 未知的 API 動作 */
  UNKNOWN_ACTION: "0001",
  /** 參數錯誤或缺失 */
  INVALID_PARAMS: "0002",
  /** 系統內部錯誤 */
  SYSTEM_ERROR: "0099",

  // ========== 01XX - Trips API ==========
  /** 找不到指定的行程 */
  TRIP_NOT_FOUND: "0101",
  /** Trips 工作表不存在 */
  TRIP_SHEET_MISSING: "0102",

  // ========== 02XX - Itinerary API ==========
  /** Itinerary 工作表不存在 */
  ITINERARY_SHEET_MISSING: "0201",

  // ========== 03XX - Messages API ==========
  /** 找不到指定的留言 */
  MESSAGE_NOT_FOUND: "0301",
  /** 留言已存在 (重複 UUID) */
  MESSAGE_ALREADY_EXISTS: "0302",
  /** Messages 工作表不存在 */
  MESSAGE_SHEET_MISSING: "0303",

  // ========== 04XX - Gear API ==========
  /** 找不到指定的裝備組合 */
  GEAR_NOT_FOUND: "0401",
  /** Key 格式錯誤 (需 4 位數) */
  GEAR_KEY_INVALID: "0402",
  /** Key 已被使用 */
  GEAR_KEY_DUPLICATE: "0403",
  /** 需要正確的 Key 才能存取 */
  GEAR_KEY_REQUIRED: "0404",
  /** 缺少必要欄位 */
  GEAR_MISSING_FIELDS: "0405",

  // ========== 05XX - Polls API ==========
  /** 找不到指定的投票 */
  POLL_NOT_FOUND: "0501",
  /** 投票已關閉 */
  POLL_CLOSED: "0502",
  /** 投票已過期 */
  POLL_EXPIRED: "0503",
  /** 此投票不允許新增選項 */
  POLL_ADD_OPTION_DISABLED: "0504",
  /** 已達選項數量上限 */
  POLL_OPTION_LIMIT: "0505",
  /** 只有發起人可以操作 */
  POLL_CREATOR_ONLY: "0506",
  /** 相關工作表缺失 */
  POLL_SHEET_MISSING: "0507",
  /** 該選項已有票數，無法刪除 */
  POLL_OPTION_HAS_VOTES: "0508",
  /** 找不到該選項 */
  POLL_OPTION_NOT_FOUND: "0509",

  // ========== 06XX - Weather API ==========
  /** 氣象資料尚未準備好 */
  WEATHER_NOT_READY: "0601",

  // ========== 07XX - GearLibrary API ==========
  /** owner_key 格式錯誤 */
  GEAR_LIBRARY_KEY_INVALID: "0701",
};

// ============================================================
// 工作表欄位 Schema 定義
// type: 'text' | 'number' | 'boolean' | 'date'
// ============================================================

/**
 * 工作表欄位 Schema 定義
 * @description 定義每個工作表的欄位名稱與型別，用於設定欄位格式
 * @readonly
 */
const SHEET_SCHEMA = {
  Trips: {
    id: { type: "text" },
    name: { type: "text" },
    start_date: { type: "date" },
    end_date: { type: "date" },
    description: { type: "text" },
    cover_image: { type: "text" },
    is_active: { type: "boolean" },
    created_at: { type: "date" },
  },

  Itinerary: {
    uuid: { type: "text" },
    trip_id: { type: "text" },
    day: { type: "text" },
    name: { type: "text" },
    est_time: { type: "text" },
    altitude: { type: "number" },
    distance: { type: "number" },
    note: { type: "text" },
    image_asset: { type: "text" },
  },

  Messages: {
    uuid: { type: "text" },
    trip_id: { type: "text" },
    parent_id: { type: "text" },
    user: { type: "text" },
    category: { type: "text" },
    content: { type: "text" },
    timestamp: { type: "date" },
    avatar: { type: "text" },
  },

  GearSets: {
    uuid: { type: "text" },
    title: { type: "text" },
    author: { type: "text" },
    total_weight: { type: "number" },
    item_count: { type: "number" },
    visibility: { type: "text" },
    key: { type: "text" },
    uploaded_at: { type: "date" },
    items_json: { type: "text" },
  },

  GearLibrary: {
    uuid: { type: "text" },
    owner_key: { type: "text" },
    name: { type: "text" },
    weight: { type: "number" },
    category: { type: "text" },
    notes: { type: "text" },
    created_at: { type: "date" },
    updated_at: { type: "date" },
  },

  Polls: {
    poll_id: { type: "text" },
    title: { type: "text" },
    description: { type: "text" },
    creator_id: { type: "text" },
    created_at: { type: "date" },
    deadline: { type: "date" },
    is_allow_add_option: { type: "boolean" },
    max_option_limit: { type: "number" },
    allow_multiple_votes: { type: "boolean" },
    result_display_type: { type: "text" },
    status: { type: "text" },
  },

  PollOptions: {
    option_id: { type: "text" },
    poll_id: { type: "text" },
    text: { type: "text" },
    creator_id: { type: "text" },
    created_at: { type: "date" },
    votes: { type: "text" },
  },

  PollVotes: {
    vote_id: { type: "text" },
    poll_id: { type: "text" },
    option_id: { type: "text" },
    user_id: { type: "text" },
    user_name: { type: "text" },
    created_at: { type: "date" },
  },

  Logs: {
    upload_time: { type: "date" },
    device_id: { type: "text" },
    device_name: { type: "text" },
    timestamp: { type: "date" },
    level: { type: "text" },
    source: { type: "text" },
    message: { type: "text" },
  },

  Heartbeat: {
    user: { type: "text" },
    avatar: { type: "text" },
    last_seen: { type: "date" },
    view: { type: "text" },
    platform: { type: "text" },
  },
};

/**
 * 取得指定工作表的文字欄位索引 (1-based)
 * @param {string} sheetName - 工作表名稱
 * @returns {number[]} 需要設定為文字格式的欄位索引
 */
function getTextColumnIndices(sheetName) {
  const schema = SHEET_SCHEMA[sheetName];
  if (!schema) return [];

  const indices = [];
  let index = 1;
  for (const field in schema) {
    // text 和 date 類型都需要設定為純文字格式，避免自動轉型
    if (schema[field].type === "text" || schema[field].type === "date") {
      indices.push(index);
    }
    index++;
  }
  return indices;
}
