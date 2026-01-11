/**
 * ============================================================
 * 行程節點 API
 * ============================================================
 * @fileoverview 行程節點 (Itinerary) 相關 CRUD 操作
 */

// ============================================================
// === PUBLIC API ===
// ============================================================

/**
 * 取得所有資料 (行程 + 留言)
 * @param {string} [tripId] - 可選，篩選特定行程的資料
 * @returns {Object} { code, data, message }
 */
function getTripFull(tripId) {
  try {
    const ss = getSpreadsheet();
    return _success({
      itinerary: getItinerary(ss, tripId),
      messages: getMessages(ss, tripId),
    });
  } catch (e) {
    return _error(API_CODES.SYSTEM_ERROR, e.message);
  }
}

/**
 * 取得行程資料
 * @param {Spreadsheet} ss - 試算表物件
 * @param {string} [tripId] - 可選，篩選特定行程的資料
 * @returns {Object[]} 行程節點陣列
 */
function getItinerary(ss, tripId) {
  const sheet = ss.getSheetByName(SHEET_ITINERARY);
  if (!sheet) return [];

  const data = sheet.getDataRange().getValues();
  if (data.length <= 1) return [];

  const headers = data[0];
  const rows = data.slice(1);
  const tripIdIndex = headers.indexOf("trip_id");

  return rows
    .map((row) => {
      const item = {};
      headers.forEach((header, index) => {
        const key = _headerToKey(header);
        let value = row[index];
        item[key] = value;
      });
      return _formatData(item, SHEET_ITINERARY);
    })
    .filter((item) => {
      // 過濾空行
      if (!item.day || !item.name) return false;
      // 若有指定 tripId，則只回傳該行程的資料
      if (tripId && tripIdIndex !== -1) {
        return item.trip_id === tripId;
      }
      return true;
    });
}

/**
 * 更新行程 (覆寫模式)
 * @param {Object[]} itineraryItems - 行程資料列表
 * @param {string} [tripId] - 可選，指定行程 ID
 * @returns {Object} { code, data, message }
 */
function updateItinerary(itineraryItems, tripId) {
  const sheet = _getSheetOrCreate(SHEET_ITINERARY, HEADERS_ITINERARY);

  // 清除現有內容 (保留標題列)
  const lastRow = sheet.getLastRow();
  if (lastRow > 1) {
    sheet.getRange(2, 1, lastRow - 1, HEADERS_ITINERARY.length).clearContent();
  }

  if (!itineraryItems || itineraryItems.length === 0) {
    return _success(null, "行程已清空");
  }

  // 準備資料列 (順序需與 HEADERS_ITINERARY 一致)
  // 文字格式由工作表的 @ 格式處理，不需要 ' 前綴
  const rows = itineraryItems.map((item) => [
    String(item.id || Utilities.getUuid()),
    String(tripId || item.trip_id || ""),
    item.day,
    String(item.name || ""),
    String(item.est_time || item.estTime || ""),
    item.altitude,
    item.distance,
    String(item.note || ""),
    String(item.image_asset || item.imageAsset || ""),
    item.is_checked_in || item.isCheckedIn || false,
    _toIsoString(item.checked_in_at || item.checkedInAt),
    String(item.created_by || ""),
    String(item.updated_by || ""),
  ]);

  if (rows.length > 0) {
    sheet.getRange(2, 1, rows.length, HEADERS_ITINERARY.length).setValues(rows);
  }

  return _success(null, "行程已更新");
}
