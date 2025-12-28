/**
 * ============================================================
 * 初始化腳本
 * ============================================================
 * @fileoverview 首次執行以建立所有必要的工作表
 *
 * 使用方式：
 * 1. 在 GAS 編輯器中執行 setupSheets() 函式
 * 2. 授權存取 Google Sheets
 * 3. 檢視 Logger 確認結果
 */

// ============================================================
// === PUBLIC API ===
// ============================================================

/**
 * 初始化所有工作表
 * @description 首次部署時執行一次，建立所有必要的工作表結構
 */
function setupSheets() {
  const ss = getSpreadsheet();

  // 建立 Itinerary 工作表
  _setupSheet(ss, SHEET_ITINERARY, HEADERS_ITINERARY, _getSampleItinerary());
  Logger.log("✓ Itinerary 工作表已建立");

  // 建立 Messages 工作表
  _setupSheet(ss, SHEET_MESSAGES, HEADERS_MESSAGES, [
    [
      Utilities.getUuid(),
      "",
      "Admin",
      "Chat",
      "歡迎使用 SummitMate！這是行程協作留言板。",
      "'" + new Date().toISOString(),
      "🤖",
      "",
    ],
  ]);
  Logger.log("✓ Messages 工作表已建立");

  // 建立 Trips 工作表
  _setupSheet(ss, SHEET_TRIPS, HEADERS_TRIPS);
  Logger.log("✓ Trips 工作表已建立");

  // 建立 GearSets 工作表
  _setupSheet(ss, SHEET_GEAR, HEADERS_GEAR);
  Logger.log("✓ GearSets 工作表已建立");

  // 建立 Logs 工作表
  _setupSheet(ss, SHEET_LOGS, HEADERS_LOGS);
  Logger.log("✓ Logs 工作表已建立");

  // 建立 Heartbeat 工作表
  _setupSheet(ss, SHEET_HEARTBEAT, HEADERS_HEARTBEAT);
  Logger.log("✓ Heartbeat 工作表已建立");

  // 初始化投票工作表 (若 svc_polls.gs 存在)
  if (typeof setupPollSheets === "function") {
    setupPollSheets();
    Logger.log("✓ Poll 工作表已建立");
  }

  Logger.log("========================================");
  Logger.log("初始化設定完成 (Setup complete)!");
}

// ============================================================
// === INTERNAL HELPERS ===
// ============================================================

/**
 * 建立或更新工作表
 * @private
 * @param {Spreadsheet} ss - 試算表物件
 * @param {string} name - 工作表名稱
 * @param {string[]} headers - 欄位標題
 * @param {Array[]} [sampleData] - 可選，範例資料
 */
function _setupSheet(ss, name, headers, sampleData) {
  let sheet = ss.getSheetByName(name);

  if (!sheet) {
    sheet = ss.insertSheet(name);
    sheet.appendRow(headers);

    if (sampleData && sampleData.length > 0) {
      sampleData.forEach((row) => sheet.appendRow(row));
    }
  } else {
    // 遷移：確保所有欄位存在
    const existingHeaders = sheet
      .getRange(1, 1, 1, sheet.getLastColumn())
      .getValues()[0];
    headers.forEach((header) => {
      if (!existingHeaders.includes(header)) {
        sheet.getRange(1, existingHeaders.length + 1).setValue(header);
        existingHeaders.push(header);
        Logger.log(`  新增欄位: ${name}.${header}`);
      }
    });
  }
}

/**
 * 取得行程範例資料
 * @private
 * @returns {Array[]} 範例資料
 */
function _getSampleItinerary() {
  return [
    ["'D0", "台北車站出發", "'18:00", 20, 0, "搭乘火車前往池上", "", ""],
    ["'D0", "抵達池上車站", "'22:00", 260, 0, "前往青旅 Check-in", "", ""],
    ["'D1", "向陽登山口 (起登)", "'06:00", 2312, 0, "檢查入山入園證", "", ""],
    ["'D1", "向陽山屋", "'08:40", 2850, 4.3, "大休息 20 分鐘", "", ""],
    ["'D1", "嘉明湖避難山屋", "'14:30", 3347, 8.5, "抵達住宿點", "", ""],
    ["'D2", "嘉明湖 (看日出)", "'06:00", 3310, 4.6, "輕裝前往湖畔", "", ""],
    ["'D2", "回到向陽登山口", "'15:30", 2312, 12.4, "完成登山行程", "", ""],
  ];
}

// ============================================================
// === TEST FUNCTIONS ===
// ============================================================

/**
 * 測試 fetchAll 函式
 */
function testFetchAll() {
  const result = fetchAll();
  Logger.log(JSON.stringify(result, null, 2));
}

/**
 * 測試 addMessage 函式
 */
function testAddMessage() {
  const result = addMessage({
    uuid: "test-" + new Date().getTime(),
    user: "TestUser",
    category: "Gear",
    content: "這是一條測試訊息",
    timestamp: new Date().toISOString(),
    avatar: "🐼",
  });
  Logger.log(JSON.stringify(result));
}
