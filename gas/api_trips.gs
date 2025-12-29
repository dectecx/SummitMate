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
 * @returns {Object} { code, data, message }
 */
function fetchTrips() {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_TRIPS);

  if (!sheet) {
    return _success({ trips: [] }, "尚無行程資料");
  }

  const data = sheet.getDataRange().getValues();
  if (data.length <= 1) {
    return _success({ trips: [] }, "尚無行程資料");
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
      return _formatData(trip, SHEET_TRIPS);
    })
    .filter((trip) => trip.id); // 過濾空行

  return _success({ trips }, "取得行程列表成功");
}

/**
 * 新增行程
 * @param {Object} tripData - 行程資料
 * @returns {Object} { code, data, message }
 */
function addTrip(tripData) {
  const sheet = _getSheetOrCreate(SHEET_TRIPS, HEADERS_TRIPS);

  const id = tripData.id || Utilities.getUuid();
  const now = new Date().toISOString();

  // 順序需與 HEADERS_TRIPS 一致
  // 文字格式由工作表的 @ 格式處理，不需要 ' 前綴
  sheet.appendRow([
    id,
    String(tripData.name || "新行程"),
    tripData.start_date || now,
    tripData.end_date || "",
    String(tripData.description || ""),
    String(tripData.cover_image || ""),
    tripData.is_active || false,
    now,
  ]);

  return _success({ id }, "行程已新增");
}

/**
 * 更新行程
 * @param {Object} tripData - 行程資料 (必須包含 id)
 * @returns {Object} { code, data, message }
 */
function updateTrip(tripData) {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_TRIPS);

  if (!sheet) {
    return _error(API_CODES.TRIP_SHEET_MISSING, "找不到 Trips 工作表");
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
      return _success(null, "行程已更新");
    }
  }

  return _error(API_CODES.TRIP_NOT_FOUND, "找不到該行程");
}

/**
 * 刪除行程
 * @param {string} tripId - 行程 ID
 * @returns {Object} { code, data, message }
 */
function deleteTrip(tripId) {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_TRIPS);

  if (!sheet) {
    return _error(API_CODES.TRIP_SHEET_MISSING, "找不到 Trips 工作表");
  }

  const data = sheet.getDataRange().getValues();
  const headers = data[0];
  const idIndex = headers.indexOf("id");

  for (let i = 1; i < data.length; i++) {
    if (data[i][idIndex] === tripId) {
      sheet.deleteRow(i + 1);
      return _success(null, "行程已刪除");
    }
  }

  return _error(API_CODES.TRIP_NOT_FOUND, "找不到該行程");
}

/**
 * 設定活動行程
 * @param {string} tripId - 行程 ID
 * @returns {Object} { code, data, message }
 */
function setActiveTrip(tripId) {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_TRIPS);

  if (!sheet) {
    return _error(API_CODES.TRIP_SHEET_MISSING, "找不到 Trips 工作表");
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
      return _success(null, "已設定活動行程");
    }
  }

  return _error(API_CODES.TRIP_NOT_FOUND, "找不到該行程");
}
