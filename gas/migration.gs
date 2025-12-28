/**
 * ============================================================
 * 測試資料遷移腳本 (一次性使用)
 * ============================================================
 * @fileoverview 將現有 Sheet 資料遷移至新的欄位順序
 *               執行完畢後可刪除此檔案
 *
 * 新欄位順序:
 *   - Itinerary: uuid, trip_id, day, name, est_time, altitude, distance, note, image_asset
 *   - Messages: uuid, trip_id, parent_id, user, category, content, timestamp, avatar
 */

/**
 * 主遷移函式
 * 在 GAS 編輯器中手動執行此函式
 */
function migrateToNewSchema() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();

  Logger.log("========================================");
  Logger.log("開始遷移至新 Schema");
  Logger.log("========================================\n");

  // 1. 備份現有工作表
  _backupSheet(ss, "Itinerary", "Itinerary_OLD");
  _backupSheet(ss, "Messages", "Messages_OLD");

  // 2. 遷移 Itinerary
  _migrateItinerary(ss);

  // 3. 遷移 Messages
  _migrateMessages(ss);

  Logger.log("\n========================================");
  Logger.log("遷移完成！");
  Logger.log("");
  Logger.log("後續步驟:");
  Logger.log("1. 確認新資料正確");
  Logger.log("2. 刪除 _OLD 備份工作表");
  Logger.log("3. 刪除此遷移腳本 (migration.gs)");
  Logger.log("========================================");
}

/**
 * 備份工作表
 * @private
 */
function _backupSheet(ss, originalName, backupName) {
  const original = ss.getSheetByName(originalName);
  if (!original) {
    Logger.log(`⚠ 工作表 "${originalName}" 不存在，跳過備份`);
    return;
  }

  // 檢查備份是否已存在
  const existing = ss.getSheetByName(backupName);
  if (existing) {
    Logger.log(`⚠ 備份 "${backupName}" 已存在，跳過`);
    return;
  }

  original.copyTo(ss).setName(backupName);
  Logger.log(`✓ 已備份 "${originalName}" → "${backupName}"`);
}

/**
 * 遷移 Itinerary 工作表
 * 舊順序: day, name, est_time, altitude, distance, note, image_asset, trip_id
 * 新順序: uuid, trip_id, day, name, est_time, altitude, distance, note, image_asset
 * @private
 */
function _migrateItinerary(ss) {
  const sheet = ss.getSheetByName("Itinerary");
  if (!sheet || sheet.getLastRow() < 2) {
    Logger.log("⚠ Itinerary 工作表為空或不存在，跳過");
    return;
  }

  Logger.log("\n--- 遷移 Itinerary ---");

  const data = sheet.getDataRange().getValues();
  const oldHeaders = data[0];

  // 檢查是否已是新格式
  if (oldHeaders[0] === "uuid" && oldHeaders[1] === "trip_id") {
    Logger.log("⚠ Itinerary 已是新格式，跳過");
    return;
  }

  // 找出舊欄位索引
  const colIndex = {};
  oldHeaders.forEach(
    (h, i) => (colIndex[h.toLowerCase().replace(/\s+/g, "_")] = i)
  );

  // 新資料陣列
  const newHeaders = [
    "uuid",
    "trip_id",
    "day",
    "name",
    "est_time",
    "altitude",
    "distance",
    "note",
    "image_asset",
  ];
  const newData = [newHeaders];

  for (let i = 1; i < data.length; i++) {
    const row = data[i];
    const tripId = row[colIndex["trip_id"]] || "";

    newData.push([
      Utilities.getUuid(), // uuid (新增)
      tripId, // trip_id
      row[colIndex["day"]] || "",
      row[colIndex["name"]] || "",
      row[colIndex["est_time"]] || "",
      row[colIndex["altitude"]] || 0,
      row[colIndex["distance"]] || 0,
      row[colIndex["note"]] || "",
      row[colIndex["image_asset"]] || "",
    ]);
  }

  // 清空並寫入新資料
  sheet.clearContents();
  sheet.getRange(1, 1, newData.length, newHeaders.length).setValues(newData);

  Logger.log(`✓ Itinerary 已遷移 ${newData.length - 1} 筆資料`);
}

/**
 * 遷移 Messages 工作表
 * 舊順序: uuid, parent_id, user, category, content, timestamp, avatar, trip_id
 * 新順序: uuid, trip_id, parent_id, user, category, content, timestamp, avatar
 * @private
 */
function _migrateMessages(ss) {
  const sheet = ss.getSheetByName("Messages");
  if (!sheet || sheet.getLastRow() < 2) {
    Logger.log("⚠ Messages 工作表為空或不存在，跳過");
    return;
  }

  Logger.log("\n--- 遷移 Messages ---");

  const data = sheet.getDataRange().getValues();
  const oldHeaders = data[0];

  // 檢查是否舊的 trip_id 在最後
  const tripIdIndex = oldHeaders.indexOf("trip_id");
  if (tripIdIndex === 1) {
    Logger.log("⚠ Messages 已是新格式，跳過");
    return;
  }

  // 找出舊欄位索引
  const colIndex = {};
  oldHeaders.forEach(
    (h, i) => (colIndex[h.toLowerCase().replace(/\s+/g, "_")] = i)
  );

  // 新資料陣列
  const newHeaders = [
    "uuid",
    "trip_id",
    "parent_id",
    "user",
    "category",
    "content",
    "timestamp",
    "avatar",
  ];
  const newData = [newHeaders];

  for (let i = 1; i < data.length; i++) {
    const row = data[i];

    newData.push([
      row[colIndex["uuid"]] || Utilities.getUuid(),
      row[colIndex["trip_id"]] || "",
      row[colIndex["parent_id"]] || "",
      row[colIndex["user"]] || "",
      row[colIndex["category"]] || "",
      row[colIndex["content"]] || "",
      row[colIndex["timestamp"]] || "",
      row[colIndex["avatar"]] || "🐻",
    ]);
  }

  // 清空並寫入新資料
  sheet.clearContents();
  sheet.getRange(1, 1, newData.length, newHeaders.length).setValues(newData);

  Logger.log(`✓ Messages 已遷移 ${newData.length - 1} 筆資料`);
}

/**
 * 驗證遷移結果
 */
function verifyMigration() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();

  Logger.log("========================================");
  Logger.log("驗證遷移結果");
  Logger.log("========================================\n");

  // 驗證 Itinerary
  const itinerary = ss.getSheetByName("Itinerary");
  if (itinerary) {
    const headers = itinerary.getRange(1, 1, 1, 9).getValues()[0];
    const expected = [
      "uuid",
      "trip_id",
      "day",
      "name",
      "est_time",
      "altitude",
      "distance",
      "note",
      "image_asset",
    ];
    const match = JSON.stringify(headers) === JSON.stringify(expected);
    Logger.log(`Itinerary: ${match ? "✓ 正確" : "✖ 欄位順序不符"}`);
    if (!match) Logger.log(`  現有: ${headers.join(", ")}`);
  }

  // 驗證 Messages
  const messages = ss.getSheetByName("Messages");
  if (messages) {
    const headers = messages.getRange(1, 1, 1, 8).getValues()[0];
    const expected = [
      "uuid",
      "trip_id",
      "parent_id",
      "user",
      "category",
      "content",
      "timestamp",
      "avatar",
    ];
    const match = JSON.stringify(headers) === JSON.stringify(expected);
    Logger.log(`Messages: ${match ? "✓ 正確" : "✖ 欄位順序不符"}`);
    if (!match) Logger.log(`  現有: ${headers.join(", ")}`);
  }
}
