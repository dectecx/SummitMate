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
const SHEET_GEAR_SETS = "GearSets";
const SHEET_TRIP_GEAR = "TripGear";
const SHEET_GEAR_LIBRARY = "GearLibrary";
const SHEET_POLLS = "Polls";
const SHEET_POLL_OPTIONS = "PollOptions";
const SHEET_POLL_VOTES = "PollVotes";

// 會員系統
const SHEET_USERS = "Users";

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
  "day_names",
  "created_by", // 建立者 (User Email/ID)
  "updated_by", // 更新者 (User Email/ID)
];

const HEADERS_ITINERARY = [
  "id", // PK (新增)
  "trip_id", // FK → Trips
  "day",
  "name",
  "est_time",
  "altitude",
  "distance",
  "note",
  "image_asset",
  "is_checked_in",
  "checked_in_at",
  "created_by", // 建立者
  "updated_by", // 更新者
];

const HEADERS_MESSAGES = [
  "id", // PK
  "trip_id", // FK → Trips
  "parent_id", // FK → Messages (回覆)
  "user",
  "category",
  "content",
  "timestamp",
  "avatar",
];

const HEADERS_GEAR = [
  "id", // PK
  "trip_id", // FK → Trips
  "title",
  "author",
  "visibility",
  "key",
  "total_weight",
  "item_count",
  "uploaded_at",
  "items_json",
  "meals_json",
];

const HEADERS_TRIP_GEAR = [
  "id", // PK
  "trip_id", // FK → Trips
  "name",
  "weight",
  "category",
  "is_checked",
  "quantity",
];

// ============================================================
// 個人裝備庫 (GearLibrary)
// 【未來規劃】owner_key → user_id (會員機制上線後)
// ============================================================
const HEADERS_GEAR_LIBRARY = [
  "id", // PK
  "user_id", // 擁有者識別碼 (對應 Users.uuid)
  "name",
  "weight",
  "category",
  "notes",
  "created_at",
  "updated_at",
];

// ============================================================
// 會員系統 (Users)
// role: 預留欄位供未來權限擴充 (團長/團員/管理員)
// ============================================================
const HEADERS_USERS = [
  "id", // PK
  "email", // Unique, 作為登入帳號
  "password_hash", // 密碼雜湊 (SHA-256)
  "display_name", // 顯示名稱
  "avatar", // 頭像 Emoji
  "role", // 角色: member, leader, admin (預留)
  "is_active", // 帳號狀態 (false = 假刪除)
  "is_verified", // Email 驗證狀態
  "verification_code",
  "verification_expiry",
  "created_at",
  "updated_at",
  "last_login_at",
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

const HEADERS_HEARTBEAT = [
  "user_id",
  "user_type",
  "user_name",
  "avatar",
  "last_seen",
  "view",
  "platform",
];

// ============================================================
// 預設值
// ============================================================

const DEFAULT_AVATAR = "🐻";
const DEFAULT_USER = "Anonymous";
const DEFAULT_CATEGORY = "Misc";

const API_ACTIONS = {
  // === 行程 (Trips) ===
  TRIP_LIST: "trip_list",
  TRIP_CREATE: "trip_create",
  TRIP_UPDATE: "trip_update",
  TRIP_DELETE: "trip_delete",
  TRIP_SET_ACTIVE: "trip_set_active",
  TRIP_SYNC: "trip_sync",

  // === 行程節點 (Itinerary) ===
  TRIP_GET_FULL: "trip_get_full",
  ITINERARY_LIST: "itinerary_list",
  ITINERARY_UPDATE: "itinerary_update",

  // === 留言 (Messages) ===
  MESSAGE_LIST: "message_list",
  MESSAGE_CREATE: "message_create",
  MESSAGE_CREATE_BATCH: "message_create_batch",
  MESSAGE_DELETE: "message_delete",

  // === 裝備組合 (Gear Sets) ===
  GEAR_SET_LIST: "gear_set_list",
  GEAR_SET_GET: "gear_set_get",
  GEAR_SET_DOWNLOAD: "gear_set_download",
  GEAR_SET_UPLOAD: "gear_set_upload",
  GEAR_SET_DELETE: "gear_set_delete",

  // === 個人裝備庫 (Gear Library) ===
  GEAR_LIBRARY_UPLOAD: "gear_library_upload",
  GEAR_LIBRARY_DOWNLOAD: "gear_library_download",

  // === 投票 (Polls) ===
  POLL_LIST: "poll_list",
  POLL_CREATE: "poll_create",
  POLL_VOTE: "poll_vote",
  POLL_ADD_OPTION: "poll_add_option",
  POLL_DELETE_OPTION: "poll_delete_option",
  POLL_CLOSE: "poll_close",
  POLL_DELETE: "poll_delete",

  // === 氣象 (Weather) ===
  WEATHER_GET: "weather_get",

  // === 監控 (Logs/Heartbeat) ===
  LOG_UPLOAD: "log_upload",
  SYSTEM_HEARTBEAT: "system_heartbeat",
  SYSTEM_HEALTH: "system_health",

  // === 會員 (Auth) ===
  AUTH_REGISTER: "auth_register",
  AUTH_LOGIN: "auth_login",
  AUTH_VALIDATE: "auth_validate",
  AUTH_VERIFY_EMAIL: "auth_verify_email",
  AUTH_RESEND_CODE: "auth_resend_code",
  AUTH_DELETE_USER: "auth_delete_user",
  AUTH_REFRESH_TOKEN: "auth_refresh_token",
  AUTH_UPDATE_PROFILE: "auth_update_profile",
};

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
  /** 缺少行程 ID */
  TRIP_ID_REQUIRED: "0103",
  /** 日期格式錯誤 */
  TRIP_INVALID_DATE: "0104",
  /** 行程建立失敗 */
  TRIP_CREATE_FAILED: "0105",
  /** 行程更新失敗 */
  TRIP_UPDATE_FAILED: "0106",
  /** 行程同步失敗 */
  TRIP_SYNC_FAILED: "0107",

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

  // ========== 08XX - Auth API ==========
  /** 信箱已被註冊 */
  AUTH_EMAIL_EXISTS: "0801",
  /** 信箱或密碼錯誤 */
  AUTH_INVALID_CREDENTIALS: "0802",
  /** 帳號已停用或刪除 */
  AUTH_ACCOUNT_DISABLED: "0803",
  /** 認證 Token 無效 */
  AUTH_ACCESS_TOKEN_INVALID: "0804",
  /** 缺少認證資訊 */
  AUTH_REQUIRED: "0805",
  /** Users 工作表不存在 */
  AUTH_SHEET_MISSING: "0806",
  /** 驗證碼錯誤 */
  AUTH_CODE_INVALID: "0807",
  /** 驗證碼已過期 */
  AUTH_CODE_EXPIRED: "0808",
  /** Token 已過期 */
  AUTH_ACCESS_TOKEN_EXPIRED: "0809",
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
    created_by: { type: "text" },
    updated_by: { type: "text" },
  },

  Itinerary: {
    id: { type: "text" },
    trip_id: { type: "text" },
    day: { type: "text" },
    name: { type: "text" },
    est_time: { type: "text" },
    altitude: { type: "number" },
    distance: { type: "number" },
    note: { type: "text" },
    image_asset: { type: "text" },
    is_checked_in: { type: "boolean" },
    checked_in_at: { type: "date" },
    created_by: { type: "text" },
    updated_by: { type: "text" },
  },

  Messages: {
    id: { type: "text" },
    trip_id: { type: "text" },
    parent_id: { type: "text" },
    user: { type: "text" },
    category: { type: "text" },
    content: { type: "text" },
    timestamp: { type: "date" },
    avatar: { type: "text" },
  },

  GearSets: {
    id: { type: "text" },
    title: { type: "text" },
    author: { type: "text" },
    total_weight: { type: "number" },
    item_count: { type: "number" },
    visibility: { type: "text" },
    key: { type: "text" },
    uploaded_at: { type: "date" },
    items_json: { type: "text" },
    meals_json: { type: "text" },
  },

  TripGear: {
    id: { type: "text" },
    trip_id: { type: "text" },
    name: { type: "text" },
    weight: { type: "number" },
    category: { type: "text" },
    is_checked: { type: "boolean" },
    quantity: { type: "number" },
  },

  GearLibrary: {
    id: { type: "text" },
    user_id: { type: "text" },
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
    user_id: { type: "text" },
    user_type: { type: "text" },
    user_name: { type: "text" },
    avatar: { type: "text" },
    last_seen: { type: "date" },
    view: { type: "text" },
    platform: { type: "text" },
  },

  Users: {
    id: { type: "text" },
    email: { type: "text" },
    password_hash: { type: "text" },
    display_name: { type: "text" },
    avatar: { type: "text" },
    role: { type: "text" },
    is_active: { type: "boolean" },
    is_verified: { type: "boolean" }, // Email 驗證狀態
    verification_code: { type: "text" }, // 驗證碼 (6碼)
    verification_expiry: { type: "date" }, // 驗證碼過期時間
    created_at: { type: "date" },
    updated_at: { type: "date" },
    last_login_at: { type: "date" },
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
