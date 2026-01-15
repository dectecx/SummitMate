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
    return _success({
      itinerary: getItinerary(tripId),
      messages: getMessages(tripId),
    });
  } catch (e) {
    return _error(API_CODES.SYSTEM_ERROR, e.message);
  }
}

/**
 * 取得行程資料
 * @param {string} [tripId] - 可選，篩選特定行程的資料
 * @returns {Object[]} 行程節點陣列 (DTO)
 */
function getItinerary(tripId) {
  const ss = getSpreadsheet();
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
        item[header] = row[index];
      });
      const formattedItem = _formatData(item, SHEET_ITINERARY);

      // 使用 Mapper 轉換為 DTO
      return Mapper.Itinerary.toDTO(formattedItem);
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
 * @param {string} [operatorId] - 可選，操作者 ID
 * @returns {Object} { code, data, message }
 */
function updateItinerary(itineraryItems, tripId, operatorId) {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_ITINERARY);
  if (!sheet)
    return _error(
      API_CODES.ITINERARY_SHEET_MISSING,
      "Itinerary sheet not found"
    );

  // 清除現有內容 (保留標題列)
  const lastRow = sheet.getLastRow();
  if (lastRow > 1) {
    sheet.getRange(2, 1, lastRow - 1, HEADERS_ITINERARY.length).clearContent();
  }

  if (!itineraryItems || itineraryItems.length === 0) {
    return _success(null, "行程已清空");
  }

  // 使用 Mapper 轉換為 Persistence 格式
  const rows = itineraryItems.map((item) => {
    // 確保 trip_id 一致
    item.trip_id = tripId || item.trip_id;
    item.id = item.id || Utilities.getUuid();

    const pObj = Mapper.Itinerary.toPersistence(
      item,
      operatorId || item.updated_by || ""
    );
    return HEADERS_ITINERARY.map((h) => (pObj[h] !== undefined ? pObj[h] : ""));
  });

  if (rows.length > 0) {
    sheet.getRange(2, 1, rows.length, HEADERS_ITINERARY.length).setValues(rows);
  }

  return _success(null, "行程已更新");
}
