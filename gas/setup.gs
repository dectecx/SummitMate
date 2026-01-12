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

  // 1. 建立 Trips 工作表並建立預設行程
  _setupSheet(ss, SHEET_TRIPS, HEADERS_TRIPS);
  const defaultTripId = _createDefaultTrip(ss);
  Logger.log("✓ Trips 工作表已建立，預設行程 ID: " + defaultTripId);

  // 2. 建立 Itinerary 工作表 (新欄位順序: id, trip_id, day, name, ...)
  const sampleItinerary = _getSampleItinerary().map((row) => {
    // 插入 id 和 trip_id 到前兩位
    return [
      Utilities.getUuid(), // id (PK)
      defaultTripId, // trip_id (FK)
      ...row, // day, name, est_time, altitude, distance, note, image_asset
    ];
  });
  _setupSheet(ss, SHEET_ITINERARY, HEADERS_ITINERARY, sampleItinerary);
  Logger.log("✓ Itinerary 工作表已建立");

  // 3. 建立 Messages 工作表 (新欄位順序: id, trip_id, parent_id, user, ...)
  _setupSheet(ss, SHEET_MESSAGES, HEADERS_MESSAGES, [
    [
      Utilities.getUuid(), // id (PK)
      defaultTripId, // trip_id (FK)
      "", // parent_id
      "Admin", // user
      "Chat", // category
      "歡迎使用 SummitMate！這是行程協作留言板。", // content
      "'" + new Date().toISOString(), // timestamp
      "🤖", // avatar
    ],
  ]);
  Logger.log("✓ Messages 工作表已建立");

  // 4. 建立 GearSets 工作表
  _setupSheet(ss, SHEET_GEAR_SETS, HEADERS_GEAR);
  Logger.log("✓ GearSets 工作表已建立");

  // 5. 建立 TripGear 工作表 (隨行程裝備)
  _setupSheet(ss, SHEET_TRIP_GEAR, HEADERS_TRIP_GEAR);
  Logger.log("✓ TripGear 工作表已建立");

  // 6. 建立 GearLibrary 工作表 (個人裝備庫)
  // 【未來規劃】owner_key → user_id (會員機制上線後)
  _setupSheet(ss, SHEET_GEAR_LIBRARY, HEADERS_GEAR_LIBRARY);
  Logger.log("✓ GearLibrary 工作表已建立");

  // 6. 建立 Polls 工作表 (若 svc_polls.gs 存在)
  if (typeof setupPollSheets === "function") {
    setupPollSheets();
    Logger.log("✓ Poll 工作表已建立");
  }

  // 7. 建立 Logs 工作表
  _setupSheet(ss, SHEET_LOGS, HEADERS_LOGS);
  Logger.log("✓ Logs 工作表已建立");

  // 8. 建立 Heartbeat 工作表
  _setupSheet(ss, SHEET_HEARTBEAT, HEADERS_HEARTBEAT);
  Logger.log("✓ Heartbeat 工作表已建立");

  // 9. 建立 Users 工作表 (會員系統)
  _setupSheet(ss, SHEET_USERS, HEADERS_USERS);
  Logger.log("✓ Users 工作表已建立");

  // 9. 建立 Users 工作表 (會員系統)
  _setupSheet(ss, SHEET_USERS, HEADERS_USERS);
  Logger.log("✓ Users 工作表已建立");

  // 10. 建立角色權限相關工作表
  _setupSheet(ss, SHEET_ROLES, HEADERS_ROLES);
  _setupSheet(ss, SHEET_PERMISSIONS, HEADERS_PERMISSIONS);
  _setupSheet(ss, SHEET_ROLE_PERMISSIONS, HEADERS_ROLE_PERMISSIONS);

  // 檢查是否需要植入預設角色資料
  _seedDefaultRoles(ss);
  Logger.log("✓ 角色權限工作表與預設資料已建立");

  // 11. 套用文字欄位格式到所有工作表 (確保已存在的工作表也有正確格式)
  applyTextFormatToAll();

  Logger.log("========================================");
  Logger.log("初始化設定完成 (Setup complete)!");
  Logger.log("預設行程: 嘉明湖三天兩夜");
  Logger.log("Trip ID: " + defaultTripId);
}

/**
 * 建立預設行程
 * @private
 * @param {Spreadsheet} ss - 試算表物件
 * @returns {string} 預設行程 ID
 */
function _createDefaultTrip(ss) {
  const sheet = ss.getSheetByName(SHEET_TRIPS);

  // 檢查是否已有行程
  const data = sheet.getDataRange().getValues();
  if (data.length > 1) {
    // 回傳第一個行程的 ID
    return data[1][0];
  }

  // 建立預設行程
  const tripId = Utilities.getUuid();
  const now = new Date().toISOString();

  sheet.appendRow([
    tripId,
    "嘉明湖三天兩夜",
    now,
    "",
    "向陽山屋 → 嘉明湖避難山屋 → 嘉明湖 → 三叉山",
    "",
    true,
    now,
  ]);

  return tripId;
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

    // 設定文字欄位格式為純文字 (@)
    _applyTextFormat(sheet, name);

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
 * 設定工作表的文字欄位格式為純文字 (@)
 * @private
 * @param {Sheet} sheet - 工作表
 * @param {string} sheetName - 工作表名稱
 */
function _applyTextFormat(sheet, sheetName) {
  const textCols = getTextColumnIndices(sheetName);
  if (!textCols || textCols.length === 0) return;

  const maxRows = Math.max(sheet.getMaxRows(), 1000);
  textCols.forEach((col) => {
    // 從第 2 列開始設定 (排除標題列)
    sheet.getRange(2, col, maxRows - 1, 1).setNumberFormat("@");
  });
}

/**
 * 對所有工作表套用文字格式
 * @description 用於現有工作表，在部署後執行一次即可
 */
function applyTextFormatToAll() {
  const ss = getSpreadsheet();
  const sheetNames = Object.keys(SHEET_SCHEMA);

  sheetNames.forEach((sheetName) => {
    const sheet = ss.getSheetByName(sheetName);
    if (sheet) {
      _applyTextFormat(sheet, sheetName);
      Logger.log(`✓ ${sheetName} 文字格式已設定`);
    } else {
      Logger.log(`⚠ ${sheetName} 工作表不存在，跳過`);
    }
  });

  Logger.log("========================================");
  Logger.log("所有工作表文字格式設定完成");
}

/**
 * 取得行程範例資料
 * @private
 * @returns {Array[]} 範例資料
 * @description 欄位順序: day, name, est_time, altitude, distance, note, image_asset
 *              (id 和 trip_id 由 setupSheets 補上)
 */
function _getSampleItinerary() {
  return [
    // D0 - 出發日
    ["'D0", "南港車站出發", "'20:11", 20, 0, "搭乘火車前往池上", ""],
    ["'D0", "抵達池上車站", "'23:41", 260, 0, "前往青旅 Check-in", ""],
    ["'D0", "就寢休息", "'24:30", 260, 0, "整理裝備，準備隔日早起", ""],

    // D1 - 第一天
    ["'D1", "早餐", "'05:00", 260, 0, "", ""],
    ["'D1", "池上車站接駁車出發", "'05:30", 260, 0, "", ""],
    ["'D1", "向陽遊樂區起登", "'07:30", 2312, 0, "檢查哨整裝出發", ""],
    ["'D1", "4.3K向陽山屋", "'09:30", 2850, 4.3, "", ""],
    ["'D1", "休息時間", "'09:40", 2850, 4.3, "", ""],
    ["'D1", "5.3K黑水塘", "'10:40", 2950, 5.3, "", ""],
    ["'D1", "休息時間", "'10:50", 2950, 5.3, "", ""],
    ["'D1", "6K向陽名樹", "'11:40", 3100, 6, "", ""],
    ["'D1", "休息時間", "'11:50", 3100, 6, "", ""],
    ["'D1", "7.4K向陽山登山口", "'13:00", 3480, 7.4, "準備輕裝攻頂", ""],
    ["'D1", "向陽山", "'13:30", 3602, 7.4, "", ""],
    ["'D1", "停留時間", "'13:50", 3602, 7.4, "", ""],
    ["'D1", "回到登山口", "'14:10", 3480, 7.4, "揹起重裝繼續前往山屋", ""],
    ["'D1", "嘉明湖避難山屋", "'15:00", 3380, 8.4, "抵達山屋休息", ""],
    ["'D1", "晚餐", "'17:30", 3380, 8.4, "", ""],
    ["'D1", "就寢休息", "'20:00", 3380, 8.4, "", ""],

    // D2 - 第二天
    ["'D2", "避難山屋出發", "'04:00", 3380, 8.4, "輕裝出發", ""],
    ["'D2", "向陽北峰登山口", "'05:00", 3435, 10, "沿稜線行進", ""],
    ["'D2", "三叉山登山口", "'05:20", 3400, 12, "準備前往湖畔", ""],
    ["'D2", "嘉明湖", "'06:10", 3310, 13, "", ""],
    ["'D2", "停留時間", "'07:30", 3310, 13, "", ""],
    ["'D2", "三叉山東登山口", "'07:50", 3390, 12.3, "回程叉路", ""],
    ["'D2", "三叉山", "'08:20", 3496, 12.5, "", ""],
    ["'D2", "停留時間", "'08:40", 3496, 12.5, "", ""],
    ["'D2", "回到迎賓樹", "'09:20", 3450, 11, "經向陽北峰", ""],
    ["'D2", "回到向陽北峰登山口", "'10:00", 3435, 10, "持續回程", ""],
    ["'D2", "回避難山屋", "'10:45", 3380, 8.4, "", ""],
    ["'D2", "停留時間", "'11:30", 3380, 8.4, "吃點心+午餐", ""],
    ["'D2", "7.4K向陽山登山口", "'12:30", 3480, 7.4, "開始陡降", ""],
    ["'D2", "回到向陽名樹", "'13:30", 3100, 6, "穿過崩壁區", ""],
    ["'D2", "回到向陽山屋", "'14:50", 2850, 4.3, "最後休息點", ""],
    ["'D2", "回到向陽遊樂區", "'16:30", 2312, 0, "平安完登 (Finish)", ""],
  ];
}

/**
 * 植入預設資料 (Roles, Permissions)
 * @private
 */
function _seedDefaultRoles(ss) {
  const roleSheet = ss.getSheetByName(SHEET_ROLES);

  // 檢查是否已有資料
  if (!roleSheet || roleSheet.getLastRow() > 1) return;

  Logger.log("正在植入預設資料...");

  // 1. 建立預設角色
  const roles = [
    { code: "ADMIN", name: "管理員", desc: "系統維護者，擁有所有權限" },
    { code: "LEADER", name: "團長", desc: "行程擁有者，可管理行程與成員" },
    { code: "GUIDE", name: "嚮導/協作", desc: "協助管理行程，不可刪除行程" },
    { code: "MEMBER", name: "一般成員", desc: "僅可檢視與編輯個人資料" },
  ];

  const roleMap = {}; // code -> uuid

  roles.forEach((r) => {
    const uuid = Utilities.getUuid();
    roleMap[r.code] = uuid;
    roleSheet.appendRow([uuid, r.code, r.name, r.desc]);
  });

  // 2. 建立預設權限
  const permissions = [
    // Trip
    { code: "trip.view", cat: "Trip", desc: "檢視行程" },
    { code: "trip.create", cat: "Trip", desc: "建立行程" },
    { code: "trip.edit", cat: "Trip", desc: "編輯行程內容" },
    { code: "trip.delete", cat: "Trip", desc: "刪除行程" },
    { code: "trip.transfer", cat: "Trip", desc: "移交行程擁有權" },

    // Gear
    { code: "gear.view", cat: "Gear", desc: "檢視裝備" },
    { code: "gear.edit", cat: "Gear", desc: "編輯公裝" },

    // Member
    {
      code: "member.manage",
      cat: "Member",
      desc: "管理成員 (新增/移除/變更角色)",
    },

    // System
    { code: "system.admin", cat: "System", desc: "系統管理權限" },
  ];

  const permSheet = ss.getSheetByName(SHEET_PERMISSIONS);
  const permMap = {}; // code -> uuid

  permissions.forEach((p) => {
    const uuid = Utilities.getUuid();
    permMap[p.code] = uuid;
    permSheet.appendRow([uuid, p.code, p.cat, p.desc]);
  });

  // 3. 設定角色權限關聯
  const rpSheet = ss.getSheetByName(SHEET_ROLE_PERMISSIONS);
  const assignments = [
    // ADMIN
    {
      role: "ADMIN",
      perms: [
        "system.admin",
        "trip.view",
        "trip.create",
        "trip.edit",
        "trip.delete",
        "trip.transfer",
        "gear.view",
        "gear.edit",
        "member.manage",
      ],
    },

    // LEADER
    {
      role: "LEADER",
      perms: [
        "trip.view",
        "trip.create",
        "trip.edit",
        "trip.delete",
        "trip.transfer",
        "gear.view",
        "gear.edit",
        "member.manage",
      ],
    },

    // GUIDE
    {
      role: "GUIDE",
      perms: ["trip.view", "trip.edit", "gear.view", "gear.edit"],
    }, // No delete, no transfer, no member manage

    // MEMBER
    { role: "MEMBER", perms: ["trip.view", "gear.view"] },
  ];

  assignments.forEach((assign) => {
    const roleId = roleMap[assign.role];
    assign.perms.forEach((pCode) => {
      const permId = permMap[pCode];
      if (roleId && permId) {
        rpSheet.appendRow([Utilities.getUuid(), roleId, permId]);
      }
    });
  });
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
    id: "test-" + new Date().getTime(),
    user: "TestUser",
    category: "Gear",
    content: "這是一條測試訊息",
    timestamp: new Date().toISOString(),
    avatar: "🐼",
  });
  Logger.log(JSON.stringify(result));
}
