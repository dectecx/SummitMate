/**
 * ============================================================
 * Gear Library API
 * ============================================================
 * @fileoverview 個人裝備庫雲端備份 API
 *
 * 【存取方式】
 * - 使用 accessToken 驗證身份
 * - 資料以 user_id 隔離
 *
 * 【操作模式】
 * - 上傳: 覆寫雲端 (以 user_id 識別)
 * - 下載: 覆寫本地 (取得 user_id 對應的所有資料)
 */

/**
 * 上傳個人裝備庫 (覆寫模式)
 * @param {string} accessToken - 認證 Token
 * @param {Array} items - 裝備列表
 * @returns {Object} { code, data, message }
 */
function uploadGearLibrary(accessToken, items) {
  try {
    // 驗證 Token
    if (!accessToken) {
      return _error(API_CODES.AUTH_REQUIRED, "缺少認證 Token");
    }

    const validation = validateToken(accessToken);
    if (!validation.isValid) {
      return _error(API_CODES.AUTH_ACCESS_TOKEN_INVALID, "Token 無效或已過期");
    }

    const userId = validation.payload.uid;
    const sheet = _getSheetOrCreate(SHEET_GEAR_LIBRARY, HEADERS_GEAR_LIBRARY);

    // 刪除該 user_id 的所有舊資料
    const existingData = sheet.getDataRange().getValues();
    const userIdCol = HEADERS_GEAR_LIBRARY.indexOf("user_id");

    // 從後往前刪除以避免索引問題
    for (let i = existingData.length - 1; i >= 1; i--) {
      if (String(existingData[i][userIdCol]) === String(userId)) {
        sheet.deleteRow(i + 1);
      }
    }

    // 寫入新資料 (文字格式由工作表的 @ 格式處理，不需要 ' 前綴)
    if (items && items.length > 0) {
      const now = new Date().toISOString();
      const rows = items.map((item) => [
        String(item.id || Utilities.getUuid()),
        String(userId),
        String(item.name || ""),
        item.weight || 0,
        String(item.category || "Other"),
        String(item.notes || ""),
        item.created_at || now,
        item.updated_at || now,
      ]);

      sheet
        .getRange(
          sheet.getLastRow() + 1,
          1,
          rows.length,
          HEADERS_GEAR_LIBRARY.length
        )
        .setValues(rows);
    }

    return _success(
      { count: items ? items.length : 0 },
      `已上傳 ${items ? items.length : 0} 個裝備項目`
    );
  } catch (e) {
    return _error(API_CODES.SYSTEM_ERROR, e.toString());
  }
}

/**
 * 下載個人裝備庫
 * @param {string} accessToken - 認證 Token
 * @returns {Object} { code, data, message }
 */
function downloadGearLibrary(accessToken) {
  try {
    // 驗證 Token
    if (!accessToken) {
      return _error(API_CODES.AUTH_REQUIRED, "缺少認證 Token");
    }

    const validation = validateToken(accessToken);
    if (!validation.isValid) {
      return _error(API_CODES.AUTH_ACCESS_TOKEN_INVALID, "Token 無效或已過期");
    }

    const userId = validation.payload.uid;
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    const sheet = ss.getSheetByName(SHEET_GEAR_LIBRARY);

    if (!sheet) {
      return _success({ items: [], count: 0 }, "裝備庫為空");
    }

    const data = sheet.getDataRange().getValues();
    if (data.length <= 1) {
      return _success({ items: [], count: 0 }, "裝備庫為空");
    }

    const headers = data[0];
    const userIdCol = headers.indexOf("user_id");

    // 篩選該 user_id 的資料
    const items = [];
    for (let i = 1; i < data.length; i++) {
      if (String(data[i][userIdCol]) === String(userId)) {
        const item = {};
        headers.forEach((header, index) => {
          if (header !== "user_id") {
            item[header] = data[i][index];
          }
        });
        items.push(_formatData(item, SHEET_GEAR_LIBRARY));
      }
    }

    return _success({ items, count: items.length }, "下載裝備庫成功");
  } catch (e) {
    return _error(API_CODES.SYSTEM_ERROR, e.toString());
  }
}
