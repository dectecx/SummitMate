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
const SHEET_GEAR_SETS = "GearSets";
const SHEET_TRIP_GEAR = "TripGear";
const SHEET_GEAR_LIBRARY = "GearLibrary";
const SHEET_POLLS = "Polls";
const SHEET_POLL_OPTIONS = "PollOptions";
const SHEET_POLL_VOTES = "PollVotes";
const SHEET_TRIP_MEMBERS = "TripMembers";

// 揪團模組
const SHEET_GROUP_EVENTS = "GroupEvents";
const SHEET_GROUP_EVENT_APPLICATIONS = "GroupEventApplications";
const SHEET_GROUP_EVENT_LIKES = "GroupEventLikes"; // TODO
const SHEET_GROUP_EVENT_COMMENTS = "GroupEventComments";

// 會員系統
const SHEET_USERS = "Users";
const SHEET_ROLES = "Roles";
const SHEET_PERMISSIONS = "Permissions";
const SHEET_ROLE_PERMISSIONS = "RolePermissions";

// 監控與外部服務
const SHEET_LOGS = "Logs";
const SHEET_HEARTBEAT = "Heartbeat";
const SHEET_WEATHER = "Weather_Hiking_App";
const SHEET_WEATHER_RAW = "Weather_CWA_Hiking_Raw";

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
  "day_names",
  "created_at",
  "created_by", // 建立者 (User Email/ID)
  "updated_at", // 更新時間
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
  "created_at", // 建立時間
  "created_by", // 建立者
  "updated_at", // 更新時間
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
  "created_at",
  "created_by",
  "updated_at",
  "updated_by",
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
  "items_json",
  "meals_json",
  "uploaded_at", // ~ created_at
  "updated_at",
  "updated_by",
];

const HEADERS_TRIP_GEAR = [
  "id", // PK
  "trip_id", // FK → Trips
  "name",
  "weight",
  "category",
  "is_checked",
  "quantity",
  "created_at",
  "created_by",
  "updated_at",
  "updated_by",
];

const HEADERS_TRIP_MEMBERS = [
  "id", // PK
  "trip_id", // FK
  "user_id", // FK
  "role_code", // e.g., 'leader', 'guide', 'member'
  "created_at",
  "created_by",
  "updated_at",
  "updated_by",
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
  "created_by",
  "updated_at",
  "updated_by",
];

const HEADERS_POLLS = [
  "id", // PK
  "title",
  "description",
  "creator_id",
  "deadline",
  "is_allow_add_option",
  "max_option_limit",
  "allow_multiple_votes",
  "result_display_type",
  "status",
  "created_at",
  "created_by",
  "updated_at",
  "updated_by",
];

const HEADERS_POLL_OPTIONS = [
  "id", // PK
  "poll_id", // FK
  "text",
  "creator_id",
  "created_at",
  "created_by",
  "updated_at",
  "updated_by",
];

const HEADERS_POLL_VOTES = [
  "id", // PK
  "poll_id", // FK
  "option_id", // FK
  "user_id",
  "user_name",
  "created_at",
  "created_by",
  "updated_at",
  "updated_by",
];

// ============================================================
// 揪團模組 (GroupEvents)
// ============================================================
const HEADERS_GROUP_EVENTS = [
  "id", // PK
  "creator_id", // FK → Users.id
  "title",
  "description",
  "location",
  "start_date",
  "end_date",
  "max_members",
  "status", // open, closed, cancelled
  "approval_required",
  "private_message",
  "linked_trip_id", // FK → Trips.id (TODO)
  "like_count", // 快取
  "comment_count", // 快取
  "creator_name", // 快照
  "creator_avatar", // 快照
  "created_at",
  "created_by",
  "updated_at",
  "updated_by",
];

const HEADERS_GROUP_EVENT_APPLICATIONS = [
  "id", // PK
  "event_id", // FK → GroupEvents.id
  "user_id", // FK → Users.id
  "status", // pending, approved, rejected, cancelled
  "message",
  "user_name", // 快照
  "user_avatar", // 快照
  "created_at",
  "created_by",
  "updated_at",
  "updated_by",
];

const HEADERS_GROUP_EVENT_COMMENTS = [
  "id", // PK
  "event_id", // FK → GroupEvents.id
  "user_id", // FK → Users.id
  "content",
  "user_name", // 快照
  "user_avatar", // 快照
  "created_at",
  "created_by",
  "updated_at",
  "updated_by",
];

// ============================================================
// 會員系統 (Users)
// role_id: 關聯 Roles 表的 UUID
// ============================================================
const HEADERS_USERS = [
  "id", // PK
  "email", // Unique, 作為登入帳號
  "password_hash", // 密碼雜湊 (SHA-256)
  "display_name", // 顯示名稱
  "avatar", // 頭像 Emoji
  "role_id", // FK: Roles.id
  "is_active", // 帳號是否啟用
  "is_verified", // Email 是否已驗證
  "verification_code", // Email 驗證碼
  "verification_expiry", // 驗證碼過期時間
  "created_at", // 建立時間
  "updated_at", // 更新時間
  "last_login_at", // 最後登入時間
];

const HEADERS_ROLES = [
  "id", // PK
  "code", // UK (ADMIN, LEADER)
  "name", // Display Name
  "description",
];

const HEADERS_PERMISSIONS = [
  "id", // PK
  "code", // UK (trip.edit)
  "category",
  "description",
];

const HEADERS_ROLE_PERMISSIONS = [
  "id", // PK
  "role_id", // FK
  "permission_id", // FK
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

// 系統預設 UUID (用於 Audit Fields)
const UUID_SYSTEM = "9999-9999-9999-9999"; // 系統操作
const UUID_GUEST = "8888-8888-8888-8888"; // 訪客操作

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

  // === 行程成員 (Trip Members) ===
  TRIP_GET_MEMBERS: "trip_get_members",
  TRIP_UPDATE_MEMBER_ROLE: "trip_update_member_role",
  TRIP_REMOVE_MEMBER: "trip_remove_member",
  TRIP_ADD_MEMBER_BY_EMAIL: "trip_add_member_by_email",
  TRIP_ADD_MEMBER_BY_ID: "trip_add_member_by_id",
  TRIP_SEARCH_USER_BY_EMAIL: "trip_search_user_by_email",
  TRIP_SEARCH_USER_BY_ID: "trip_search_user_by_id",

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
  AUTH_GET_ROLES: "auth_get_roles", // 取得角色列表
  AUTH_ASSIGN_ROLE: "auth_assign_role", // 指派角色

  // === 揪團 (Group Events) ===
  GROUP_EVENT_LIST: "group_event_list",
  GROUP_EVENT_GET: "group_event_get",
  GROUP_EVENT_CREATE: "group_event_create",
  GROUP_EVENT_UPDATE: "group_event_update",
  GROUP_EVENT_CLOSE: "group_event_close",
  GROUP_EVENT_DELETE: "group_event_delete",
  GROUP_EVENT_APPLY: "group_event_apply",
  GROUP_EVENT_CANCEL_APPLICATION: "group_event_cancel_application",
  GROUP_EVENT_REVIEW_APPLICATION: "group_event_review_application",
  GROUP_EVENT_MY: "group_event_my",
  GROUP_EVENT_ADD_COMMENT: "group_event_add_comment",
  GROUP_EVENT_GET_COMMENTS: "group_event_get_comments",
  GROUP_EVENT_DELETE_COMMENT: "group_event_delete_comment",
};

const SHEET_SCHEMA = {
  Trips: {
    id: { type: "text" },
    name: { type: "text" },
    start_date: { type: "date" },
    end_date: { type: "date" },
    description: { type: "text" },
    cover_image: { type: "text" },
    is_active: { type: "boolean" },
    day_names: { type: "text" },
    created_at: { type: "date" },
    created_by: { type: "text" },
    updated_at: { type: "date" },
    updated_by: { type: "text" },
  },

  GroupEventComments: {
    id: { type: "text" },
    event_id: { type: "text" },
    user_id: { type: "text" },
    content: { type: "text" },
    user_name: { type: "text" },
    user_avatar: { type: "text" },
    created_at: { type: "date" },
    created_by: { type: "text" },
    updated_at: { type: "date" },
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
    created_at: { type: "date" },
    created_by: { type: "text" },
    updated_at: { type: "date" },
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
    created_at: { type: "date" },
    created_by: { type: "text" },
    updated_at: { type: "date" },
    updated_by: { type: "text" },
  },

  GearSets: {
    id: { type: "text" },
    trip_id: { type: "text" },
    title: { type: "text" },
    author: { type: "text" },
    total_weight: { type: "number" },
    item_count: { type: "number" },
    visibility: { type: "text" },
    key: { type: "text" },
    items_json: { type: "text" },
    meals_json: { type: "text" },
    uploaded_at: { type: "date" },
    updated_at: { type: "date" },
    updated_by: { type: "text" },
  },

  TripGear: {
    id: { type: "text" },
    trip_id: { type: "text" },
    name: { type: "text" },
    weight: { type: "number" },
    category: { type: "text" },
    is_checked: { type: "boolean" },
    quantity: { type: "number" },
    created_at: { type: "date" },
    created_by: { type: "text" },
    updated_at: { type: "date" },
    updated_by: { type: "text" },
  },

  TripMembers: {
    id: { type: "text" },
    trip_id: { type: "text" },
    user_id: { type: "text" },
    role_code: { type: "text" },
    created_at: { type: "date" },
    created_by: { type: "text" },
    updated_at: { type: "date" },
    updated_by: { type: "text" },
  },

  GearLibrary: {
    id: { type: "text" },
    user_id: { type: "text" },
    name: { type: "text" },
    weight: { type: "number" },
    category: { type: "text" },
    notes: { type: "text" },
    created_at: { type: "date" },
    created_by: { type: "text" },
    updated_at: { type: "date" },
    updated_by: { type: "text" },
  },

  Polls: {
    id: { type: "text" },
    title: { type: "text" },
    description: { type: "text" },
    creator_id: { type: "text" },
    deadline: { type: "date" },
    is_allow_add_option: { type: "boolean" },
    max_option_limit: { type: "number" },
    allow_multiple_votes: { type: "boolean" },
    result_display_type: { type: "text" },
    status: { type: "text" },
    created_at: { type: "date" },
    created_by: { type: "text" },
    updated_at: { type: "date" },
    updated_by: { type: "text" },
  },

  PollOptions: {
    id: { type: "text" },
    poll_id: { type: "text" },
    text: { type: "text" },
    creator_id: { type: "text" },
    votes: { type: "text" },
    created_at: { type: "date" },
    created_by: { type: "text" },
    updated_at: { type: "date" },
    updated_by: { type: "text" },
  },

  PollVotes: {
    id: { type: "text" },
    poll_id: { type: "text" },
    option_id: { type: "text" },
    user_id: { type: "text" },
    user_name: { type: "text" },
    created_at: { type: "date" },
    created_by: { type: "text" },
    updated_at: { type: "date" },
    updated_by: { type: "text" },
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
    role_id: { type: "text" },
    is_active: { type: "boolean" },
    is_verified: { type: "boolean" },
    verification_code: { type: "text" },
    verification_expiry: { type: "date" },
    created_at: { type: "date" },
    updated_at: { type: "date" },
    last_login_at: { type: "date" },
  },

  Roles: {
    id: { type: "text" },
    code: { type: "text" },
    name: { type: "text" },
    description: { type: "text" },
  },

  Permissions: {
    id: { type: "text" },
    code: { type: "text" },
    category: { type: "text" },
    description: { type: "text" },
  },

  RolePermissions: {
    id: { type: "text" },
    role_id: { type: "text" },
    permission_id: { type: "text" },
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
