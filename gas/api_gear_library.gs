/**
 * ============================================================
 * Gear Library API
 * ============================================================
 * @fileoverview 個人裝備庫雲端備份 API
 *
 * 【存取方式】
 * - 現階段: 使用 owner_key (4 位數) 識別
 * - 未來規劃: 會員機制上線後改用 user_id
 *
 * 【操作模式】
 * - 上傳: 覆寫雲端 (以 owner_key 識別)
 * - 下載: 覆寫本地 (取得 owner_key 對應的所有資料)
 */

/**
 * 上傳個人裝備庫 (覆寫模式)
 * @param {string} ownerKey - 擁有者識別碼 (4 位數)
 * @param {Array} items - 裝備列表
 * @returns {Object} { code, data, message }
 */
function uploadGearLibrary(ownerKey, items) {
  try {
    // 驗證 owner_key
    if (!ownerKey || ownerKey.length !== 4) {
      return _error(
        API_CODES.GEAR_LIBRARY_KEY_INVALID,
        "owner_key 必須為 4 位數"
      );
    }

    const ss = SpreadsheetApp.getActiveSpreadsheet();
    let sheet = ss.getSheetByName("GearLibrary");

    // 如果工作表不存在，建立它
    if (!sheet) {
      sheet = ss.insertSheet("GearLibrary");
      sheet
        .getRange(1, 1, 1, HEADERS_GEAR_LIBRARY.length)
        .setValues([HEADERS_GEAR_LIBRARY]);
    }

    // 刪除該 owner_key 的所有舊資料 (轉字串比較)
    const existingData = sheet.getDataRange().getValues();
    const ownerKeyCol = HEADERS_GEAR_LIBRARY.indexOf("owner_key");

    // 從後往前刪除以避免索引問題
    for (let i = existingData.length - 1; i >= 1; i--) {
      if (String(existingData[i][ownerKeyCol]) === String(ownerKey)) {
        sheet.deleteRow(i + 1);
      }
    }

    // 寫入新資料 (文字格式由工作表的 @ 格式處理，不需要 ' 前綴)
    if (items && items.length > 0) {
      const now = new Date().toISOString();
      const rows = items.map((item) => [
        String(item.uuid || Utilities.getUuid()),
        String(ownerKey),
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
 * @param {string} ownerKey - 擁有者識別碼 (4 位數)
 * @returns {Object} { code, data, message }
 */
function downloadGearLibrary(ownerKey) {
  try {
    // 驗證 owner_key
    if (!ownerKey || ownerKey.length !== 4) {
      return _error(
        API_CODES.GEAR_LIBRARY_KEY_INVALID,
        "owner_key 必須為 4 位數"
      );
    }

    const ss = SpreadsheetApp.getActiveSpreadsheet();
    const sheet = ss.getSheetByName("GearLibrary");

    if (!sheet) {
      return _success({ items: [], count: 0 }, "裝備庫為空");
    }

    const data = sheet.getDataRange().getValues();
    if (data.length <= 1) {
      return _success({ items: [], count: 0 }, "裝備庫為空");
    }

    const headers = data[0];
    const ownerKeyCol = headers.indexOf("owner_key");

    // 篩選該 owner_key 的資料 (轉字串比較，避免數字 vs 字串問題)
    const items = [];
    for (let i = 1; i < data.length; i++) {
      if (String(data[i][ownerKeyCol]) === String(ownerKey)) {
        const item = {};
        headers.forEach((header, index) => {
          if (header !== "owner_key") {
            let value = data[i][index];
            // 強制型別轉換
            const schema =
              typeof SHEET_SCHEMA !== "undefined"
                ? SHEET_SCHEMA["GearLibrary"]
                : null;
            if (schema && schema[header]) {
              if (schema[header].type === "text") {
                value =
                  value === null || value === undefined ? "" : String(value);
              }
            }
            item[header] = value;
          }
        });
        items.push(item);
      }
    }

    return _success({ items, count: items.length }, "下載裝備庫成功");
  } catch (e) {
    return _error(API_CODES.SYSTEM_ERROR, e.toString());
  }
}
