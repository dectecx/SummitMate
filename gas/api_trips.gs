/**
 * ============================================================
 * 多行程管理 API
 * ============================================================
 * @fileoverview 行程 (Trips) 相關 CRUD 操作
 */

// ============================================================
// === PUBLIC API ===
// ============================================================

/**
 * 取得所有行程
 * @returns {Object} { success: boolean, trips: Object[] }
 */
function fetchTrips() {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_TRIPS);

  if (!sheet) {
    return { success: true, trips: [] };
  }

  const data = sheet.getDataRange().getValues();
  if (data.length <= 1) {
    return { success: true, trips: [] };
  }

  const headers = data[0];
  const trips = data
    .slice(1)
    .map((row) => {
      const trip = {};
      headers.forEach((header, index) => {
        let value = row[index];
        // 處理日期
        if (
          (header === "start_date" ||
            header === "end_date" ||
            header === "created_at") &&
          value instanceof Date
        ) {
          value = value.toISOString();
        }
        trip[header] = value;
      });
      return trip;
    })
    .filter((trip) => trip.id); // 過濾空行

  return { success: true, trips: trips };
}

/**
 * 新增行程
 * @param {Object} tripData - 行程資料
 * @returns {Object} { success: boolean, id?: string }
 */
function addTrip(tripData) {
  const sheet = _getSheetOrCreate(SHEET_TRIPS, HEADERS_TRIPS);

  const id = tripData.id || Utilities.getUuid();
  const now = new Date().toISOString();

  sheet.appendRow([
    id,
    tripData.name || "新行程",
    tripData.start_date || now,
    tripData.end_date || "",
    tripData.description || "",
    tripData.cover_image || "",
    tripData.is_active || false,
    now,
  ]);

  return { success: true, id: id };
}

/**
 * 更新行程
 * @param {Object} tripData - 行程資料 (必須包含 id)
 * @returns {Object} { success: boolean, error?: string }
 */
function updateTrip(tripData) {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_TRIPS);

  if (!sheet) {
    return { success: false, error: "找不到 Trips 工作表" };
  }

  const data = sheet.getDataRange().getValues();
  const headers = data[0];
  const idIndex = headers.indexOf("id");

  for (let i = 1; i < data.length; i++) {
    if (data[i][idIndex] === tripData.id) {
      // 更新該列
      headers.forEach((header, colIndex) => {
        if (
          tripData[header] !== undefined &&
          header !== "id" &&
          header !== "created_at"
        ) {
          sheet.getRange(i + 1, colIndex + 1).setValue(tripData[header]);
        }
      });
      return { success: true };
    }
  }

  return { success: false, error: "找不到該行程" };
}

/**
 * 刪除行程
 * @param {string} tripId - 行程 ID
 * @returns {Object} { success: boolean, error?: string }
 */
function deleteTrip(tripId) {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_TRIPS);

  if (!sheet) {
    return { success: false, error: "找不到 Trips 工作表" };
  }

  const data = sheet.getDataRange().getValues();
  const headers = data[0];
  const idIndex = headers.indexOf("id");

  for (let i = 1; i < data.length; i++) {
    if (data[i][idIndex] === tripId) {
      sheet.deleteRow(i + 1);
      return { success: true };
    }
  }

  return { success: false, error: "找不到該行程" };
}

/**
 * 設定活動行程
 * @param {string} tripId - 行程 ID
 * @returns {Object} { success: boolean, error?: string }
 */
function setActiveTrip(tripId) {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_TRIPS);

  if (!sheet) {
    return { success: false, error: "找不到 Trips 工作表" };
  }

  const data = sheet.getDataRange().getValues();
  const headers = data[0];
  const idIndex = headers.indexOf("id");
  const activeIndex = headers.indexOf("is_active");

  // 先將所有行程設為非活動
  for (let i = 1; i < data.length; i++) {
    sheet.getRange(i + 1, activeIndex + 1).setValue(false);
  }

  // 設定指定行程為活動
  for (let i = 1; i < data.length; i++) {
    if (data[i][idIndex] === tripId) {
      sheet.getRange(i + 1, activeIndex + 1).setValue(true);
      return { success: true };
    }
  }

  return { success: false, error: "找不到該行程" };
}
