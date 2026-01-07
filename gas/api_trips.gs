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
function getTrips() {
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
function createTrip(tripData) {
  const sheet = _getSheetOrCreate(SHEET_TRIPS, HEADERS_TRIPS);

  const id = tripData.id || Utilities.getUuid();
  const now = new Date().toISOString();

  // 順序需與 HEADERS_TRIPS 一致
  // 文字格式由工作表的 @ 格式處理，不需要 ' 前綴
  sheet.appendRow([
    id,
    String(tripData.name || "新行程"),
    _toIsoString(tripData.start_date || now),
    _toIsoString(tripData.end_date || ""),
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
  if (!tripData || !tripData.id) {
    return _error(API_CODES.TRIP_ID_REQUIRED, "缺少行程 ID");
  }

  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_TRIPS);

  if (!sheet) {
    return _error(API_CODES.TRIP_SHEET_MISSING, "找不到 Trips 工作表");
  }

  const data = sheet.getDataRange().getValues();
  const headers = data[0];
  const idIndex = headers.indexOf("id");

  // 取得 Schema 以判斷欄位型別
  const schema =
    typeof SHEET_SCHEMA !== "undefined" ? SHEET_SCHEMA[SHEET_TRIPS] : null;

  for (let i = 1; i < data.length; i++) {
    if (data[i][idIndex] === tripData.id) {
      // 更新該列
      headers.forEach((header, colIndex) => {
        if (
          tripData[header] !== undefined &&
          header !== "id" &&
          header !== "created_at"
        ) {
          let value = tripData[header];
          // 如果是日期欄位，強制轉為 ISO String
          if (schema && schema[header] && schema[header].type === "date") {
            value = _toIsoString(value);
          }
          sheet.getRange(i + 1, colIndex + 1).setValue(value);
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
  if (!tripId) {
    return _error(API_CODES.TRIP_ID_REQUIRED, "缺少行程 ID");
  }

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
function setTripActive(tripId) {
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

/**
 * 完整同步行程 (包含行程表與裝備)
 * @param {Object} data - 包含 trip, itinerary, gear 的物件
 * @returns {Object} { code, data, message }
 */
function syncTripFull(data) {
  var lock = LockService.getScriptLock();
  // 最多等待 30 秒
  if (!lock.tryLock(30000)) {
    return _error(API_CODES.SYSTEM_ERROR, "系統忙碌中，請稍後再試");
  }

  try {
    var trip = data.trip;
    var itinerary = data.itinerary; // List of objects
    var gear = data.gear; // List of objects

    // 容錯: 支援 trip_id 或 id
    var tripId = trip.trip_id || trip.id;

    if (!tripId) {
      return _error(API_CODES.INVALID_PARAM, "Trip ID is missing");
    }

    var ss = getSpreadsheet();

    // 1. Update/Insert Trip Sheet
    var tripSheet = _getSheetOrCreate(SHEET_TRIPS, HEADERS_TRIPS);
    var tripRows = tripSheet.getDataRange().getValues();
    var tripRowIndex = -1;
    var idIndex = 0; // 假設 ID 在第一欄 (既有邏輯)

    // Check if trip exists
    for (var i = 1; i < tripRows.length; i++) {
      if (tripRows[i][idIndex] == tripId) {
        tripRowIndex = i + 1;
        break;
      }
    }

    // 構建 Trip Row
    var now = new Date().toISOString();
    var createdAt = now;
    if (tripRowIndex > 0) {
      // 保留原有 created_at (假設在最後一欄)
      createdAt = tripRows[tripRowIndex - 1][7];
    } else if (trip.created_at) {
      createdAt = _toIsoString(trip.created_at);
    }

    var tripRowData = [
      tripId,
      String(trip.name || ""),
      _toIsoString(trip.start_date || trip.startDate),
      _toIsoString(trip.end_date || trip.endDate),
      String(trip.description || ""),
      String(trip.cover_image || trip.coverImage || ""),
      trip.is_active || trip.isActive || false,
      createdAt,
    ];

    if (tripRowIndex > 0) {
      // Update: setValues 需要二維陣列
      tripSheet
        .getRange(tripRowIndex, 1, 1, tripRowData.length)
        .setValues([tripRowData]);
    } else {
      // Insert
      tripSheet.appendRow(tripRowData);
    }

    // 2. Clear & Insert Itinerary
    var itinSheet = _getSheetOrCreate(SHEET_ITINERARY, HEADERS_ITINERARY);

    // Filter out old items for this trip (Simple logical delete & rewrite)
    var itinRows = itinSheet.getDataRange().getValues();
    var newItinRows = [];

    // We will enforce the new structure defined in HEADERS_ITINERARY
    var targetColCount = HEADERS_ITINERARY.length;

    if (itinRows.length > 0) {
      newItinRows.push(HEADERS_ITINERARY);

      // Preserve other trips' data (and ensure column alignment)
      for (var i = 1; i < itinRows.length; i++) {
        var row = itinRows[i];
        if (row[1] != tripId) {
          while (row.length < targetColCount) row.push("");
          newItinRows.push(row);
        }
      }
    } else {
      newItinRows.push(HEADERS_ITINERARY);
    }

    // Append new items to memory
    if (itinerary && itinerary.length > 0) {
      itinerary.forEach(function (item) {
        // Must match HEADERS_ITINERARY order:
        // [uuid, trip_id, day, name, est_time, altitude, distance, note, image_asset, is_checked_in, checked_in_at]
        newItinRows.push([
          item.uuid || Utilities.getUuid(),
          tripId,
          item.day || "",
          item.name || "",
          item.est_time || item.estTime || "",
          item.altitude || 0,
          item.distance || 0,
          item.note || "",
          item.image_asset || item.imageAsset || "",
          item.is_checked_in || item.isCheckedIn || false,
          _toIsoString(item.checked_in_at || item.checkedInAt),
        ]);
      });
    }

    // Rewrite Itinerary Sheet
    itinSheet.clearContents();
    if (newItinRows.length > 0) {
      if (itinSheet.getMaxColumns() < targetColCount) {
        itinSheet.insertColumnsAfter(
          itinSheet.getMaxColumns(),
          targetColCount - itinSheet.getMaxColumns()
        );
      }
      itinSheet
        .getRange(1, 1, newItinRows.length, newItinRows[0].length)
        .setValues(newItinRows);
    }

    // 3. Clear & Insert Gear
    var gearSheet = _getSheetOrCreate(SHEET_TRIP_GEAR, HEADERS_TRIP_GEAR);
    var gearRows = gearSheet.getDataRange().getValues();
    var newGearRows = [];
    var gearTargetColCount = HEADERS_TRIP_GEAR.length;

    if (gearRows.length > 0) {
      newGearRows.push(HEADERS_TRIP_GEAR);
      for (var i = 1; i < gearRows.length; i++) {
        var row = gearRows[i];
        if (row[1] != tripId) {
          while (row.length < gearTargetColCount) row.push("");
          newGearRows.push(row);
        }
      }
    } else {
      newGearRows.push(HEADERS_TRIP_GEAR);
    }

    if (gear && gear.length > 0) {
      gear.forEach(function (item) {
        newGearRows.push([
          item.uuid || Utilities.getUuid(),
          tripId,
          item.name || "",
          item.weight || 0,
          item.category || "Other",
          item.is_checked || item.isChecked || false,
          item.quantity || 1,
        ]);
      });
    }

    gearSheet.clearContents();
    if (newGearRows.length > 0) {
      if (gearSheet.getMaxColumns() < gearTargetColCount) {
        gearSheet.insertColumnsAfter(
          gearSheet.getMaxColumns(),
          gearTargetColCount - gearSheet.getMaxColumns()
        );
      }
      gearSheet
        .getRange(1, 1, newGearRows.length, newGearRows[0].length)
        .setValues(newGearRows);
    }

    return _success({ id: tripId }, "同步成功");
  } catch (e) {
    return _error(API_CODES.TRIP_SYNC_FAILED, e.toString());
  } finally {
    lock.releaseLock();
  }
}
