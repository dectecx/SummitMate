/**
 * ============================================================
 * 雲端裝備庫 API
 * ============================================================
 * @fileoverview 裝備組合 (GearSets) 相關 CRUD 操作
 */

// ============================================================
// === PUBLIC API ===
// ============================================================

/**
 * 取得公開/保護的裝備組合列表 (不含 items 詳細資料)
 * @returns {Object} { code, data, message }
 */
function getGearSets() {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_GEAR_SETS);
  if (!sheet)
    return _error(API_CODES.GEAR_NOT_FOUND, "GearSets sheet not found");
  const data = sheet.getDataRange().getValues();

  if (data.length <= 1) {
    return _success({ gear_sets: [] }, "尚無裝備組合");
  }

  const headers = data[0];
  const gearSets = [];

  for (let i = 1; i < data.length; i++) {
    const row = {};
    headers.forEach((header, index) => {
      row[header] = data[i][index];
    });
    const formattedRow = _formatData(row, SHEET_GEAR_SETS);

    // 私人組合不顯示在列表中
    if (formattedRow.visibility === "private") continue;

    // 使用 Mapper 轉換為 Summary DTO (不含 items/meals)
    gearSets.push(Mapper.GearSet.toSummaryDTO(formattedRow));
  }

  return _success({ gear_sets: gearSets }, "取得裝備組合列表成功");
}

/**
 * 用 Key 取得特定裝備組合 (含 items)
 * @param {string} key - 4 位數 Key
 * @returns {Object} { code, data, message }
 */
function getGearSet(key) {
  if (!key || key.length !== 4) {
    return _error(API_CODES.GEAR_KEY_INVALID, "請輸入 4 位數 Key");
  }

  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_GEAR_SETS);
  if (!sheet)
    return _error(API_CODES.GEAR_NOT_FOUND, "GearSets sheet not found");
  const data = sheet.getDataRange().getValues();
  const headers = data[0];
  const keyIndex = headers.indexOf("key");

  for (let i = 1; i < data.length; i++) {
    if (String(data[i][keyIndex]) === String(key)) {
      const row = {};
      headers.forEach((header, index) => {
        row[header] = data[i][index];
      });
      const formattedRow = _formatData(row, SHEET_GEAR_SETS);

      // 使用 Mapper 轉換為完整 DTO (含 items/meals)
      return _success(
        { gear_set: Mapper.GearSet.toDTO(formattedRow) },
        "取得裝備組合成功"
      );
    }
  }

  return _error(API_CODES.GEAR_NOT_FOUND, "找不到符合的裝備組合");
}

/**
 * 下載指定裝備組合
 * @param {string} id - 組合 ID
 * @param {string} [key] - 可選，若為 protected 需要 key
 * @returns {Object} { code, data, message }
 */
function downloadGearSet(id, key) {
  if (!id) {
    return _error(API_CODES.INVALID_PARAMS, "缺少 ID");
  }

  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_GEAR_SETS);
  if (!sheet)
    return _error(API_CODES.GEAR_NOT_FOUND, "GearSets sheet not found");
  const data = sheet.getDataRange().getValues();
  const headers = data[0];
  const idIndex = headers.indexOf("id");

  for (let i = 1; i < data.length; i++) {
    if (data[i][idIndex] === id) {
      const row = {};
      headers.forEach((header, index) => {
        row[header] = data[i][index];
      });
      const formattedRow = _formatData(row, SHEET_GEAR_SETS);
      const storedKey = formattedRow.key;

      // Protected/Private 需要正確的 key
      if (
        (formattedRow.visibility === "protected" ||
          formattedRow.visibility === "private") &&
        String(storedKey) !== String(key)
      ) {
        return _error(API_CODES.GEAR_KEY_REQUIRED, "需要正確的 Key 才能下載");
      }

      // 使用 Mapper 轉換為完整 DTO
      return _success(
        { gear_set: Mapper.GearSet.toDTO(formattedRow) },
        "下載裝備組合成功"
      );
    }
  }

  return _error(API_CODES.GEAR_NOT_FOUND, "找不到指定的裝備組合");
}

/**
 * 上傳裝備組合
 * @param {Object} data - 上傳資料
 * @returns {Object} { code, data, message }
 */
function uploadGearSet(data) {
  const {
    trip_id,
    title,
    author,
    visibility,
    key,
    total_weight,
    item_count,
    items,
    meals,
  } = data;

  if (!title || !author) {
    return _error(
      API_CODES.GEAR_MISSING_FIELDS,
      "缺少必要欄位 (title, author)"
    );
  }

  // Protected/Private 必須有 key
  if (
    (visibility === "protected" || visibility === "private") &&
    (!key || key.length !== 4)
  ) {
    return _error(
      API_CODES.GEAR_KEY_INVALID,
      "Protected/Private 模式需要 4 位數 Key"
    );
  }

  // 檢查 key 是否重複
  if (key) {
    const ss = getSpreadsheet();
    const sheet = ss.getSheetByName(SHEET_GEAR_SETS);
    if (!sheet)
      return _error(API_CODES.GEAR_NOT_FOUND, "GearSets sheet not found");
    const existingData = sheet.getDataRange().getValues();
    const headers = existingData[0];
    const keyIndex = headers.indexOf("key");

    for (let i = 1; i < existingData.length; i++) {
      if (String(existingData[i][keyIndex]) === String(key)) {
        return _error(
          API_CODES.GEAR_KEY_DUPLICATE,
          "Key 重複，請換一個 4 位數"
        );
      }
    }
  }

  // 準備資料
  const gearData = {
    id: Utilities.getUuid(),
    trip_id: trip_id,
    title: title,
    author: author,
    visibility: visibility,
    key: key,
    total_weight: total_weight,
    item_count: item_count,
    items: items,
    meals: meals,
  };

  // 使用 Mapper 轉換為 Persistence 格式
  const pObj = Mapper.GearSet.toPersistence(gearData, author);

  // 依 HEADERS_GEAR 順序自動轉成陣列
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_GEAR_SETS);
  if (!sheet)
    return _error(API_CODES.GEAR_NOT_FOUND, "GearSets sheet not found");
  const row = HEADERS_GEAR.map((header) => pObj[header] ?? "");
  sheet.appendRow(row);

  // 回傳 Summary DTO
  return _success(
    { gear_set: Mapper.GearSet.toSummaryDTO(pObj) },
    "裝備組合已上傳"
  );
}

/**
 * 刪除裝備組合
 * @param {string} id - 裝備組合 ID
 * @param {string} key - 4 位數 Key (protected/private 需要驗證)
 * @returns {Object} { code, data, message }
 */
function deleteGearSet(id, key) {
  if (!id) {
    return _error(API_CODES.INVALID_PARAMS, "缺少 ID");
  }

  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_GEAR_SETS);
  if (!sheet)
    return _error(API_CODES.GEAR_NOT_FOUND, "GearSets sheet not found");
  const data = sheet.getDataRange().getValues();
  const headers = data[0];
  const idIndex = headers.indexOf("id");
  const keyIndex = headers.indexOf("key");
  const visibilityIndex = headers.indexOf("visibility");

  for (let i = 1; i < data.length; i++) {
    if (data[i][idIndex] === id) {
      const storedKey = data[i][keyIndex];
      const visibility = data[i][visibilityIndex];

      // public 不需要 Key，可直接刪除
      // protected/private 需要驗證 Key
      if (visibility !== "public") {
        if (!key || key.length !== 4) {
          return _error(API_CODES.GEAR_KEY_REQUIRED, "需要正確的 Key 才能刪除");
        }
        if (String(storedKey) !== String(key)) {
          return _error(API_CODES.GEAR_KEY_REQUIRED, "Key 不正確，無法刪除");
        }
      }

      // 刪除該列
      sheet.deleteRow(i + 1);
      return _success(null, "已刪除裝備組合");
    }
  }

  return _error(API_CODES.GEAR_NOT_FOUND, "找不到指定的裝備組合");
}
