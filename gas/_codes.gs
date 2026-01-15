/**
 * ============================================================
 * API 回應代碼 (XXYY 格式)
 * XX: API 分類 (00=通用, 01=Trips, 02=Itinerary...)
 * YY: 錯誤編號 (可跳號)
 * ============================================================
 */

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
  /** 找不到使用者 (新增成員時) */
  TRIP_USER_NOT_FOUND: "0108",

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
