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
 * @param {string} [tripId] - 可選，篩選特定行程的資料 (含全域留言)
 * @returns {Object[]} 留言陣列 (DTO)
 */
function getMessages(tripId) {
  const ss = getSpreadsheet();
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
        msg[header] = row[index];
      });
      const formattedMsg = _formatData(msg, SHEET_MESSAGES);

      // 使用 Mapper 轉換為 DTO
      return Mapper.Message.toDTO(formattedMsg);
    })
    .filter((msg) => {
      if (!msg.id) return false;
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
function createMessage(messageData) {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_MESSAGES);
  if (!sheet)
    return _error(API_CODES.MESSAGE_SHEET_MISSING, "Messages sheet not found");

  // 確保有必要欄位
  _ensureColumn(sheet, "avatar");
  _ensureColumn(sheet, "trip_id");

  // 檢查是否有重複的 UUID
  const existingData = sheet.getDataRange().getValues();
  for (let i = 1; i < existingData.length; i++) {
    if (existingData[i][0] === messageData.id) {
      return _success(null, "訊息已存在 (Message already exists)");
    }
  }

  // 準備資料
  messageData.id = messageData.id || Utilities.getUuid();
  const operatorId = messageData.user || DEFAULT_USER;

  // 使用 Mapper 轉換為 Persistence 格式
  const pObj = Mapper.Message.toPersistence(messageData, operatorId);
  const row = HEADERS_MESSAGES.map((h) =>
    pObj[h] !== undefined ? pObj[h] : ""
  );
  sheet.appendRow(row);

  return _success({ id: messageData.id }, "訊息已新增");
}

/**
 * 批次新增留言
 * @param {Object[]} messages - 留言陣列
 * @returns {Object} { code, data, message }
 */
function batchCreateMessages(messages) {
  if (!messages || messages.length === 0) {
    return _success(null, "無訊息可新增");
  }

  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_MESSAGES);
  if (!sheet)
    return _error(API_CODES.MESSAGE_SHEET_MISSING, "Messages sheet not found");
  _ensureColumn(sheet, "avatar");
  _ensureColumn(sheet, "trip_id");

  // 使用 Mapper 轉換為 Persistence 格式
  const rows = messages.map((messageData) => {
    messageData.id = messageData.id || Utilities.getUuid();
    const operatorId = messageData.user || DEFAULT_USER;
    const pObj = Mapper.Message.toPersistence(messageData, operatorId);
    return HEADERS_MESSAGES.map((h) => (pObj[h] !== undefined ? pObj[h] : ""));
  });

  if (rows.length > 0) {
    sheet
      .getRange(sheet.getLastRow() + 1, 1, rows.length, HEADERS_MESSAGES.length)
      .setValues(rows);
  }

  return _success({ count: rows.length }, `批次新增了 ${rows.length} 則訊息`);
}

/**
 * 刪除留言
 * @param {string} id - 留言 UUID
 * @returns {Object} { code, data, message }
 */
function deleteMessage(id) {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_MESSAGES);

  if (!sheet) {
    return _error(API_CODES.MESSAGE_SHEET_MISSING, "找不到 Messages 工作表");
  }

  const data = sheet.getDataRange().getValues();

  for (let i = 1; i < data.length; i++) {
    if (data[i][0] === id) {
      sheet.deleteRow(i + 1);
      return _success(null, "訊息已刪除");
    }
  }

  return _error(API_CODES.MESSAGE_NOT_FOUND, "找不到該訊息");
}
