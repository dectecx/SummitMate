/**
 * ============================================================
 * 最愛功能 API
 * ============================================================
 * @fileoverview 使用者最愛 (Favorites) 相關 CRUD 操作
 */

// ============================================================
// === PUBLIC API ===
// ============================================================

/**
 * 取得使用者的最愛列表
 * @param {Object} payload - { user_id }
 * @returns {Object} { code, data, message }
 */
function getFavorites(payload) {
  const { user_id } = payload;
  if (!user_id) {
    return _error(API_CODES.INVALID_PARAMS, "缺少 user_id");
  }

  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_FAVORITES);

  if (!sheet) {
    return _success({ favorites: [] }, "尚無最愛資料");
  }

  const data = sheet.getDataRange().getValues();
  // Headers: id, user_id, target_id, type, created_at, created_by, updated_at, updated_by
  // Indices:  0, 1,       2,         3,    4,          5,          6,          7

  const favorites = [];
  // Skip header
  for (let i = 1; i < data.length; i++) {
    const rowUserId = data[i][1]; // user_id

    if (rowUserId == user_id) {
      favorites.push({
        targetId: data[i][2], // target_id
        type: data[i][3], // type
        createdAt: data[i][4], // created_at
      });
    }
  }

  return _success({ favorites }, "取得最愛列表成功");
}

/**
 * 更新最愛狀態 (新增或修改)
 * @param {Object} payload - { user_id, target_id, type, is_favorite }
 * @returns {Object} { code, data, message }
 */
function updateFavorite(payload) {
  const { user_id, target_id, type, is_favorite } = payload;

  if (!user_id || !target_id || !type) {
    return _error(API_CODES.INVALID_PARAMS, "缺少必要參數");
  }

  const ss = getSpreadsheet();
  // 確保工作表存在 (若無則自動建立，雖 _ensureColumn 可處理欄位，但這裡先用簡單邏輯)
  let sheet = ss.getSheetByName(SHEET_FAVORITES);
  if (!sheet) {
    sheet = ss.insertSheet(SHEET_FAVORITES);
    sheet.appendRow(HEADERS_FAVORITES);
  }

  const data = sheet.getDataRange().getValues();
  let rowIndex = -1;
  const now = new Date().toISOString();

  // Headers: id, user_id, target_id, type, created_at, created_by, updated_at, updated_by
  // Indices: 0,  1,       2,         3,    4,          5,          6,          7

  for (let i = 1; i < data.length; i++) {
    if (
      data[i][1] == user_id &&
      data[i][2] == target_id &&
      data[i][3] == type
    ) {
      rowIndex = i + 1; // 1-based index
      break;
    }
  }

  if (is_favorite) {
    if (rowIndex > 0) {
      return _success(null, "已在最愛列表中");
    } else {
      // Insert new
      const newId = Utilities.getUuid();
      sheet.appendRow([
        newId, // id
        user_id, // user_id
        target_id, // target_id
        type, // type
        now, // created_at
        user_id, // created_by
        now, // updated_at
        user_id, // updated_by
      ]);
    }
  } else {
    // Remove if exists
    if (rowIndex > 0) {
      sheet.deleteRow(rowIndex);
    }
  }

  return _success(null, "最愛狀態已更新");
}
