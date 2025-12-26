// ============================================================
// SummitMate - 多行程遷移腳本
// Multi-Trip Migration Script
// ============================================================
//
// 使用說明:
// 1. 將此檔案加入現有 GAS 專案
// 2. 執行 migrateToMultiTrip() 函式進行資料表結構升級
// 3. 部署新版 API
//
// ============================================================

/**
 * 遷移現有資料庫以支援多行程功能
 * 執行此函式一次以升級資料表結構
 */
function migrateToMultiTrip() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const results = [];

  // 1. 建立 Trips 工作表
  results.push(createTripsSheet(ss));

  // 2. 升級 Itinerary 工作表 (新增 trip_id 欄位)
  results.push(addTripIdToSheet(ss, "Itinerary"));

  // 3. 升級 Messages 工作表 (新增 trip_id 欄位)
  results.push(addTripIdToSheet(ss, "Messages"));

  // 4. 建立預設行程並設定現有資料的 trip_id
  results.push(assignDefaultTripId(ss));

  Logger.log("Migration Results:");
  results.forEach((r) => Logger.log(r));

  return { success: true, results: results };
}

/**
 * 建立 Trips 工作表
 */
function createTripsSheet(ss) {
  const sheetName = "Trips";
  let sheet = ss.getSheetByName(sheetName);

  if (sheet) {
    return `[SKIP] ${sheetName} 工作表已存在`;
  }

  sheet = ss.insertSheet(sheetName);
  sheet.appendRow([
    "id",
    "name",
    "start_date",
    "end_date",
    "description",
    "cover_image",
    "is_active",
    "created_at",
  ]);

  return `[CREATED] ${sheetName} 工作表已建立`;
}

/**
 * 為工作表新增 trip_id 欄位
 */
function addTripIdToSheet(ss, sheetName) {
  const sheet = ss.getSheetByName(sheetName);

  if (!sheet) {
    return `[SKIP] ${sheetName} 工作表不存在`;
  }

  // 檢查是否已有 trip_id 欄位
  const headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];

  if (headers.includes("trip_id")) {
    return `[SKIP] ${sheetName} 已有 trip_id 欄位`;
  }

  // 在最後一欄新增 trip_id 標題
  const newColIndex = sheet.getLastColumn() + 1;
  sheet.getRange(1, newColIndex).setValue("trip_id");

  return `[UPDATED] ${sheetName} 新增 trip_id 欄位於第 ${newColIndex} 欄`;
}

/**
 * 為現有資料設定預設 trip_id
 */
function assignDefaultTripId(ss) {
  const tripsSheet = ss.getSheetByName("Trips");
  const defaultTripId = Utilities.getUuid();

  // 檢查是否已有行程
  const tripsData = tripsSheet.getDataRange().getValues();
  if (tripsData.length > 1) {
    // 已有行程，使用第一個 (is_active=true) 的 ID
    const activeTrip = tripsData
      .slice(1)
      .find((row) => row[6] === true || row[6] === "true");
    if (activeTrip) {
      return `[SKIP] 已有活動行程: ${activeTrip[1]} (${activeTrip[0]})`;
    }
  }

  // 建立預設行程
  tripsSheet.appendRow([
    defaultTripId,
    "預設登山計畫",
    new Date().toISOString(),
    "",
    "由系統自動建立的預設行程",
    "",
    true,
    new Date().toISOString(),
  ]);

  // 為 Itinerary 現有資料設定 trip_id
  updateSheetWithTripId(ss, "Itinerary", defaultTripId);

  // 為 Messages 現有資料設定 trip_id
  updateSheetWithTripId(ss, "Messages", defaultTripId);

  return `[CREATED] 預設行程已建立 (ID: ${defaultTripId})，並已設定所有現有資料`;
}

/**
 * 更新工作表所有資料的 trip_id
 */
function updateSheetWithTripId(ss, sheetName, tripId) {
  const sheet = ss.getSheetByName(sheetName);
  if (!sheet) return;

  const data = sheet.getDataRange().getValues();
  if (data.length <= 1) return;

  const headers = data[0];
  const tripIdColIndex = headers.indexOf("trip_id");

  if (tripIdColIndex === -1) return;

  // 為所有空的 trip_id 欄位設定預設值
  const lastRow = sheet.getLastRow();
  if (lastRow > 1) {
    const tripIdRange = sheet.getRange(2, tripIdColIndex + 1, lastRow - 1, 1);
    const values = tripIdRange.getValues();

    const updated = values.map((row) => {
      return [row[0] || tripId];
    });

    tripIdRange.setValues(updated);
  }
}

// ============================================================
// 驗證函式 (Verification Functions)
// ============================================================

/**
 * 驗證遷移是否成功
 */
function verifyMigration() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const results = {};

  // 檢查 Trips 工作表
  const tripsSheet = ss.getSheetByName("Trips");
  results.trips = {
    exists: !!tripsSheet,
    rowCount: tripsSheet ? tripsSheet.getLastRow() - 1 : 0,
  };

  // 檢查 Itinerary trip_id
  const itSheet = ss.getSheetByName("Itinerary");
  if (itSheet) {
    const headers = itSheet
      .getRange(1, 1, 1, itSheet.getLastColumn())
      .getValues()[0];
    results.itinerary = {
      hasTripId: headers.includes("trip_id"),
      rowCount: itSheet.getLastRow() - 1,
    };
  }

  // 檢查 Messages trip_id
  const msgSheet = ss.getSheetByName("Messages");
  if (msgSheet) {
    const headers = msgSheet
      .getRange(1, 1, 1, msgSheet.getLastColumn())
      .getValues()[0];
    results.messages = {
      hasTripId: headers.includes("trip_id"),
      rowCount: msgSheet.getLastRow() - 1,
    };
  }

  Logger.log("Migration Verification:");
  Logger.log(JSON.stringify(results, null, 2));

  return results;
}

// ============================================================
// 回滾函式 (Rollback - 如需還原)
// ============================================================

/**
 * 移除 trip_id 欄位 (慎用!)
 */
function removeTripIdColumn(sheetName) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(sheetName);

  if (!sheet) {
    Logger.log(`Sheet ${sheetName} not found`);
    return;
  }

  const headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
  const tripIdIndex = headers.indexOf("trip_id");

  if (tripIdIndex === -1) {
    Logger.log(`trip_id column not found in ${sheetName}`);
    return;
  }

  // 刪除該欄位
  sheet.deleteColumn(tripIdIndex + 1);
  Logger.log(`Removed trip_id column from ${sheetName}`);
}
