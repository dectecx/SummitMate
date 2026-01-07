/**
 * ============================================================
 * 使用狀態追蹤 API
 * ============================================================
 * @fileoverview 心跳記錄功能 (Web 追蹤)
 */

// ============================================================
// === PUBLIC API ===
// ============================================================

/**
 * 記錄使用狀態心跳
 * @param {Object} data - 心跳資料 { username, timestamp, platform, view }
 * @returns {Object} { code, data, message }
 */
function recordHeartbeat(data) {
  const sheet = _getSheetOrCreate(SHEET_HEARTBEAT, HEADERS_HEARTBEAT);

  // 判斷使用者類型與處理邏輯
  const isMember = !!data.user_id;

  // 新增心跳記錄
  sheet.appendRow([
    data.user_id || `Guest-${data.username || DEFAULT_USER}`, // user_id
    data.user_type || (isMember ? "member" : "guest"), // user_type
    // 會員: 不重複記錄 name (從 Users 表查詢); 訪客: 記錄 name
    isMember ? "" : data.username || data.user_name || DEFAULT_USER, // user_name
    data.avatar || DEFAULT_AVATAR,
    data.timestamp || new Date().toISOString(),
    data.view || "",
    data.platform || "unknown",
  ]);

  return _success(null, "心跳已記錄");
}
