/**
 * ============================================================
 * 留言板 API
 * ============================================================
 * @fileoverview 留言 (Messages) 相關 CRUD 操作
 */

// ============================================================
// === PUBLIC API ===
// ============================================================

/**
 * 取得留言資料
 * @param {Spreadsheet} ss - 試算表物件
 * @param {string} [tripId] - 可選，篩選特定行程的資料 (含全域留言)
 * @returns {Object[]} 留言陣列
 */
function getMessagesData(ss, tripId) {
  const sheet = ss.getSheetByName(SHEET_MESSAGES);
  if (!sheet) return [];

  const data = sheet.getDataRange().getValues();
  if (data.length <= 1) return [];

  const headers = data[0];
  const rows = data.slice(1);
  const tripIdIndex = headers.indexOf("trip_id");

  return rows
    .map((row) => {
      const msg = {};
      headers.forEach((header, index) => {
        const key = _headerToKey(header);
        let value = row[index];

        // 處理時間戳記
        if (key === "timestamp" && value instanceof Date) {
          value = value.toISOString();
        }
        // 處理空的 parent_id
        if (key === "parent_id") {
          value = value || null;
        }
        // 若無頭像則提供預設值
        if (key === "avatar" && (value === null || value === "")) {
          value = DEFAULT_AVATAR;
        }

        msg[key] = value;
      });

      // 向下相容：若 avatar 欄位不存在
      if (!msg.avatar) {
        msg.avatar = DEFAULT_AVATAR;
      }

      return msg;
    })
    .filter((msg) => {
      if (!msg.uuid) return false;
      // 若有指定 tripId，則只回傳該行程或全域 (trip_id 為空) 的留言
      if (tripId && tripIdIndex !== -1) {
        return !msg.trip_id || msg.trip_id === tripId;
      }
      return true;
    });
}

/**
 * 新增留言
 * @param {Object} messageData - 留言資料
 * @returns {Object} { code, data, message }
 */
function addMessage(messageData) {
  const sheet = _getSheetOrCreate(SHEET_MESSAGES, HEADERS_MESSAGES);

  // 確保有 avatar 欄位
  _ensureColumn(sheet, "avatar");
  _ensureColumn(sheet, "trip_id");

  // 檢查是否有重複的 UUID
  const existingData = sheet.getDataRange().getValues();
  for (let i = 1; i < existingData.length; i++) {
    if (existingData[i][0] === messageData.uuid) {
      return _success(null, "訊息已存在 (Message already exists)");
    }
  }

  // 新增資料列
  sheet.appendRow([
    messageData.uuid || Utilities.getUuid(),
    messageData.parent_id || "",
    messageData.user || DEFAULT_USER,
    messageData.category || DEFAULT_CATEGORY,
    messageData.content || "",
    "'" + (messageData.timestamp || new Date().toISOString()),
    messageData.avatar || DEFAULT_AVATAR,
    messageData.trip_id || "",
  ]);

  return _success(null, "訊息已新增");
}

/**
 * 批次新增留言
 * @param {Object[]} messages - 留言陣列
 * @returns {Object} { code, data, message }
 */
function batchAddMessages(messages) {
  if (!messages || messages.length === 0) {
    return _success(null, "無訊息可新增");
  }

  const sheet = _getSheetOrCreate(SHEET_MESSAGES, HEADERS_MESSAGES);
  _ensureColumn(sheet, "avatar");
  _ensureColumn(sheet, "trip_id");

  const rows = messages.map((messageData) => [
    messageData.uuid || Utilities.getUuid(),
    messageData.parent_id || "",
    messageData.user || DEFAULT_USER,
    messageData.category || DEFAULT_CATEGORY,
    messageData.content || "",
    "'" + (messageData.timestamp || new Date().toISOString()),
    messageData.avatar || DEFAULT_AVATAR,
    messageData.trip_id || "",
  ]);

  if (rows.length > 0) {
    sheet
      .getRange(sheet.getLastRow() + 1, 1, rows.length, HEADERS_MESSAGES.length)
      .setValues(rows);
  }

  return _success({ count: rows.length }, `批次新增了 ${rows.length} 則訊息`);
}

/**
 * 刪除留言
 * @param {string} uuid - 留言 UUID
 * @returns {Object} { code, data, message }
 */
function deleteMessage(uuid) {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_MESSAGES);

  if (!sheet) {
    return _error(API_CODES.MESSAGE_SHEET_MISSING, "找不到 Messages 工作表");
  }

  const data = sheet.getDataRange().getValues();

  for (let i = 1; i < data.length; i++) {
    if (data[i][0] === uuid) {
      sheet.deleteRow(i + 1);
      return _success(null, "訊息已刪除");
    }
  }

  return _error(API_CODES.MESSAGE_NOT_FOUND, "找不到該訊息");
}
