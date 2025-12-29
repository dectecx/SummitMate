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

  // 新增心跳記錄
  sheet.appendRow([
    data.username || DEFAULT_USER,
    data.avatar || DEFAULT_AVATAR,
    data.timestamp || new Date().toISOString(),
    data.view || "",
    data.platform || "unknown",
  ]);

  return _success(null, "心跳已記錄");
}
