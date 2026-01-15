/**
 * ============================================================
 * 日誌上傳 API
 * ============================================================
 * @fileoverview 應用程式日誌上傳功能
 */

// ============================================================
// === PUBLIC API ===
// ============================================================

/**
 * 上傳應用日誌
 * @param {Object[]} logs - 日誌條目陣列
 * @param {Object} deviceInfo - 裝置資訊
 * @returns {Object} { code, data, message }
 */
function uploadLogs(logs, deviceInfo) {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_LOGS);
  if (!sheet) return _error(API_CODES.SYSTEM_ERROR, "Logs sheet not found");

  if (!logs || logs.length === 0) {
    return _error(API_CODES.INVALID_PARAMS, "未提供日誌資料");
  }

  const uploadTime = new Date().toISOString();
  const deviceId = deviceInfo?.device_id || "unknown";
  const deviceName = deviceInfo?.device_name || "unknown";

  // 批次準備資料列
  const rows = logs.map((log) => [
    uploadTime,
    deviceId,
    deviceName,
    "'" + (log.timestamp || new Date().toISOString()),
    log.level || "info",
    log.source || "",
    log.message || "",
  ]);

  // 一次性寫入以提升效能
  if (rows.length > 0) {
    sheet
      .getRange(sheet.getLastRow() + 1, 1, rows.length, HEADERS_LOGS.length)
      .setValues(rows);
  }

  return _success({ count: logs.length }, `已上傳 ${logs.length} 條日誌`);
}
