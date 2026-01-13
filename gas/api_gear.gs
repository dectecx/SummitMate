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
  const sheet = _initGearSheet();
  const data = sheet.getDataRange().getValues();

  if (data.length <= 1) {
    return _success({ gear_sets: [] }, "尚無裝備組合");
  }

  const headers = data[0];
  const gearSets = [];

  for (let i = 1; i < data.length; i++) {
    const row = data[i];
    const visibility = row[headers.indexOf("visibility")];

    // 私人組合不顯示在列表中
    if (visibility === "private") continue;

    const gearSet = {
      id: row[headers.indexOf("id")],
      title: row[headers.indexOf("title")],
      author: row[headers.indexOf("author")],
      total_weight: row[headers.indexOf("total_weight")],
      item_count: row[headers.indexOf("item_count")],
      visibility: visibility,
      uploaded_at: row[headers.indexOf("uploaded_at")],
      // 不包含 items，減少傳輸量
    };
    gearSets.push(_formatData(gearSet, SHEET_GEAR_SETS));
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

  const sheet = _initGearSheet();
  const data = sheet.getDataRange().getValues();
  const headers = data[0];
  const keyIndex = headers.indexOf("key");

  for (let i = 1; i < data.length; i++) {
    if (String(data[i][keyIndex]) === String(key)) {
      const row = data[i];
      return _success(
        {
          gear_set: _formatData(
            {
              id: row[headers.indexOf("id")],
              title: row[headers.indexOf("title")],
              author: row[headers.indexOf("author")],
              total_weight: row[headers.indexOf("total_weight")],
              item_count: row[headers.indexOf("item_count")],
              visibility: row[headers.indexOf("visibility")],
              uploaded_at: row[headers.indexOf("uploaded_at")],
              updated_at: row[headers.indexOf("updated_at")],
              items: JSON.parse(row[headers.indexOf("items_json")] || "[]"),
              meals: JSON.parse(row[headers.indexOf("meals_json")] || "[]"),
            },
            SHEET_GEAR_SETS
          ),
        },
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

  const sheet = _initGearSheet();
  const data = sheet.getDataRange().getValues();
  const headers = data[0];
  const idIndex = headers.indexOf("id");

  for (let i = 1; i < data.length; i++) {
    if (data[i][idIndex] === id) {
      const row = data[i];
      const visibility = row[headers.indexOf("visibility")];
      const storedKey = row[headers.indexOf("key")];

      // Protected/Private 需要正確的 key
      if (
        (visibility === "protected" || visibility === "private") &&
        String(storedKey) !== String(key)
      ) {
        return _error(API_CODES.GEAR_KEY_REQUIRED, "需要正確的 Key 才能下載");
      }

      return _success(
        {
          gear_set: {
            id: row[headers.indexOf("id")],
            title: row[headers.indexOf("title")],
            author: row[headers.indexOf("author")],
            total_weight: row[headers.indexOf("total_weight")],
            item_count: row[headers.indexOf("item_count")],
            visibility: visibility,
            uploaded_at: row[headers.indexOf("uploaded_at")],
            updated_at: row[headers.indexOf("updated_at")],
            items: JSON.parse(row[headers.indexOf("items_json")] || "[]"),
            meals: JSON.parse(row[headers.indexOf("meals_json")] || "[]"),
          },
        },
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
    const sheet = _initGearSheet();
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

  // 產生 ID
  const id = Utilities.getUuid();
  const uploadedAt = new Date().toISOString();
  const itemsJson = JSON.stringify(items || []);
  const mealsJson = JSON.stringify(meals || []);

  // 建立 row 物件 (key-value)
  const rowData = {
    id: id,
    trip_id: trip_id || "",
    title: title,
    author: author,
    visibility: visibility || "public",
    key: key || "",
    total_weight: total_weight || 0,
    item_count: item_count || 0,
    uploaded_at: uploadedAt,
    updated_at: uploadedAt,
    updated_by: author,
    items_json: itemsJson,
    meals_json: mealsJson,
  };

  // 依 HEADERS_GEAR 順序自動轉成陣列 (不再依賴手動順序)
  const sheet = _initGearSheet();
  const row = HEADERS_GEAR.map((header) => rowData[header] ?? "");
  sheet.appendRow(row);

  return _success(
    {
      gear_set: {
        id: id,
        title: title,
        author: author,
        total_weight: total_weight || 0,
        item_count: item_count || 0,
        visibility: visibility || "public",
        uploaded_at: uploadedAt,
      },
    },
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

  const sheet = _initGearSheet();
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

// ============================================================
// === INTERNAL HELPERS ===
// ============================================================

/**
 * 初始化 GearSets 工作表
 * @private
 * @returns {Sheet} 工作表物件
 */
function _initGearSheet() {
  return _getSheetOrCreate(SHEET_GEAR_SETS, HEADERS_GEAR);
}
