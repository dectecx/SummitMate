// ============================================================
// SummitMate - Google Apps Script API
// SummitMate 應用程式後端 API
// ============================================================
//
// 部署說明 (Deployment Instructions):
// 1. 建立一個 Google Sheets 試算表，並包含以下工作表 (Sheets):
//    "Itinerary" (行程), "Messages" (留言), "Logs" (日誌), 
//    "Weather_CWA_Hiking_Raw" (氣象原始資料), "Weather_Hiking_App" (App 用氣象資料),
//    "Heartbeat" (使用狀態追蹤), "GearSets" (雲端裝備庫)。
//    (注意: Heartbeat 和 GearSets 會在首次使用時自動建立)
// 2. 開啟 "擴充功能" (Extensions) -> "Apps Script"。
// 3. 將 `gas/Code.gs` 的內容複製到專案的 `Code.gs`。
// 4. 建立新的腳本檔案 `weather_etl.gs` 並複製 `gas/weather_etl.gs` 的內容。
// 5. 建立新的腳本檔案 `polls.gs` 並複製 `gas/polls.gs` 的內容。
// 6. 設定指令碼屬性 (Project Settings -> Script Properties):
//    - CWA_API_KEY: [您的氣象局 CWA API Key]
// 7. 設定觸發器 (Triggers):
//    - 函式: syncWeatherToSheets
//    - 事件來源: 時間驅動 (Time-driven)
//    - 類型: 每小時 (Hourly) 或依需求調整
// 8. 部署為網頁應用程式 (Deploy as Web App):
//    - 執行身分 (Execute as): 我 (Me)
//    - 存取權限 (Who has access): 所有人 (Anyone)
// 9. 將產生的 API URL 更新至 Flutter App 的 constants 中。
//
// ============================================================

// 取得當前試算表
function getSpreadsheet() {
  return SpreadsheetApp.getActiveSpreadsheet();
}

// ============================================================
// HTTP 請求處理器 (Request Handlers)
// ============================================================

function doGet(e) {
  const action = e.parameter.action;

  try {
    switch (action) {
      case "fetch_all":
        return createJsonResponse(fetchAll());
      case "fetch_itinerary":
        return createJsonResponse({
          itinerary: getItineraryData(getSpreadsheet()),
        });
      case "fetch_messages":
        return createJsonResponse({
          messages: getMessagesData(getSpreadsheet()),
        });
      case "fetch_weather":
        // 需搭配 weather_etl.gs 中的 getWeatherData()
        return createJsonResponse(getWeatherData());
      case "poll":
        return createJsonResponse(
          handlePollAction(e.parameter.subAction, e.parameter)
        );
      case "health":
        return createJsonResponse({
          status: "ok",
          timestamp: new Date().toISOString(),
        });
      default:
        return createJsonResponse({ error: "未知動作 (Unknown action)" }, 400);
    }
  } catch (error) {
    return createJsonResponse({ error: error.message }, 500);
  }
}

function doPost(e) {
  try {
    const data = JSON.parse(e.postData.contents);
    const action = data.action;

    switch (action) {
      case "add_message":
        return createJsonResponse(addMessage(data.data));
      case "batch_add_messages":
        return createJsonResponse(batchAddMessages(data.data));
      case "delete_message":
        return createJsonResponse(deleteMessage(data.uuid));
      case "upload_logs":
        return createJsonResponse(uploadLogs(data.logs, data.device_info));
      case "update_itinerary":
        return createJsonResponse(updateItinerary(data.data));
      case "poll":
        // 處理投票相關請求 (請見 polls.gs)
        return createJsonResponse(handlePollAction(data.subAction, data));
      case "heartbeat":
        // 處理使用狀態心跳 (Web 追蹤)
        return createJsonResponse(recordHeartbeat(data));
      case "fetch_gear_sets":
        // 取得公開/保護的裝備組合列表
        return createJsonResponse(fetchGearSets());
      case "fetch_gear_set_by_key":
        // 用 Key 取得特定裝備組合
        return createJsonResponse(fetchGearSetByKey(data.key));
      case "download_gear_set":
        // 下載指定裝備組合
        return createJsonResponse(downloadGearSet(data.uuid, data.key));
      case "upload_gear_set":
        // 上傳裝備組合
        return createJsonResponse(uploadGearSet(data));
      default:
        return createJsonResponse({ error: "未知動作 (Unknown action)" }, 400);
    }
  } catch (error) {
    return createJsonResponse({ error: error.message }, 500);
  }
}

function createJsonResponse(data, statusCode = 200) {
  return ContentService.createTextOutput(JSON.stringify(data)).setMimeType(
    ContentService.MimeType.JSON
  );
}

// ============================================================
// API 功能函式 (API Functions)
// ============================================================

/**
 * 取得所有資料 (行程 + 留言)
 */
function fetchAll() {
  const ss = getSpreadsheet();

  return {
    itinerary: getItineraryData(ss),
    messages: getMessagesData(ss),
  };
}

/**
 * 取得行程資料
 */
function getItineraryData(ss) {
  const sheet = ss.getSheetByName("Itinerary");
  if (!sheet) return [];

  const data = sheet.getDataRange().getValues();
  if (data.length <= 1) return []; // 只有標題列

  const headers = data[0];
  const rows = data.slice(1);

  return rows
    .map((row) => {
      const item = {};
      headers.forEach((header, index) => {
        // 將標題轉為 snake_case 以供 API 使用
        const key = headerToKey(header);
        item[key] = row[index];
      });
      return item;
    })
    .filter((item) => item.day && item.name); // 過濾空行
}

/**
 * 取得留言資料
 */
function getMessagesData(ss) {
  const sheet = ss.getSheetByName("Messages");
  if (!sheet) return [];

  const data = sheet.getDataRange().getValues();
  if (data.length <= 1) return [];

  const headers = data[0];
  const rows = data.slice(1);

  return rows
    .map((row) => {
      const msg = {};
      headers.forEach((header, index) => {
        const key = headerToKey(header);
        let value = row[index];

        // 處理時間戳記
        if (key === "timestamp" && value instanceof Date) {
          value = value.toISOString();
        }
        // 處理空的 parent_id
        if (key === "parent_id") {
          value = value || null;
        }
        // 若無頭像則提供預設值
        if (key === "avatar" && (value === null || value === "")) {
          value = "🐻";
        }

        msg[key] = value;
      });

      // 向下相容：若 avatar 欄位不存在
      if (!msg.avatar) {
        msg.avatar = "🐻";
      }

      return msg;
    })
    .filter((msg) => msg.uuid); // 過濾空行
}

/**
 * 新增留言
 */
function addMessage(messageData) {
  const ss = getSpreadsheet();
  let sheet = ss.getSheetByName("Messages");

  // 若工作表不存在則建立
  if (!sheet) {
    sheet = ss.insertSheet("Messages");
    sheet.appendRow([
      "uuid",
      "parent_id",
      "user",
      "category",
      "content",
      "timestamp",
      "avatar",
    ]);
  } else {
    // 檢查是否有 'avatar' 欄位，若無則新增
    const headers = sheet
      .getRange(1, 1, 1, sheet.getLastColumn())
      .getValues()[0];
    if (!headers.includes("avatar")) {
      sheet.getRange(1, headers.length + 1).setValue("avatar");
    }
  }

  // 檢查是否有重複的 UUID
  const existingData = sheet.getDataRange().getValues();
  for (let i = 1; i < existingData.length; i++) {
    if (existingData[i][0] === messageData.uuid) {
      return { success: true, message: "訊息已存在 (Message already exists)" };
    }
  }

  // 新增資料列
  // 注意：appendRow 只是加到第一列空白處，需確保順序與標題一致。
  // 假設欄位順序為：uuid, parent_id, user, category, content, timestamp, avatar

  sheet.appendRow([
    messageData.uuid || Utilities.getUuid(),
    messageData.parent_id || "",
    messageData.user || "Anonymous",
    messageData.category || "Misc",
    messageData.content || "",
    "'" + (messageData.timestamp || new Date().toISOString()),
    messageData.avatar || "🐻",
  ]);

  return { success: true, message: "訊息已新增 (Message added)" };
}

/**
 * 批次新增留言
 */
function batchAddMessages(messages) {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName("Messages");

  if (!messages || messages.length === 0) {
    return { success: true, message: "無訊息可新增" };
  }

  // 確保標題列存在
  const headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
  if (!headers.includes("avatar")) {
    sheet.getRange(1, headers.length + 1).setValue("avatar");
  }

  const rows = messages.map((messageData) => [
    messageData.uuid || Utilities.getUuid(),
    messageData.parent_id || "", // parent_id 是選填的
    messageData.user || "Anonymous",
    messageData.category || "Misc",
    messageData.content || "",
    // 強制轉換為字串以避免時區問題
    "'" + (messageData.timestamp || new Date().toISOString()),
    messageData.avatar || "🐻",
  ]);

  if (rows.length > 0) {
    // 假設目前有 7 個欄位
    sheet.getRange(sheet.getLastRow() + 1, 1, rows.length, 7).setValues(rows);
  }

  return { success: true, message: `批次新增了 ${rows.length} 則訊息` };
}

/**
 * 刪除留言
 */
function deleteMessage(uuid) {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName("Messages");

  if (!sheet) {
    return { success: false, error: "找不到 Messages 工作表" };
  }

  const data = sheet.getDataRange().getValues();

  for (let i = 1; i < data.length; i++) {
    if (data[i][0] === uuid) {
      sheet.deleteRow(i + 1); // +1 因為陣列是 0-indexed，列號是 1-indexed
      return { success: true, message: "訊息已刪除" };
    }
  }

  return { success: false, error: "找不到該訊息" };
}

/**
 * 上傳應用日誌
 * @param {Array} logs - 日誌條目陣列
 * @param {Object} deviceInfo - 裝置資訊
 */
function uploadLogs(logs, deviceInfo) {
  const ss = getSpreadsheet();
  let sheet = ss.getSheetByName("Logs");

  // 若工作表不存在則建立
  if (!sheet) {
    sheet = ss.insertSheet("Logs");
    sheet.appendRow([
      "upload_time",
      "device_id",
      "device_name",
      "timestamp",
      "level",
      "source",
      "message",
    ]);
  }

  if (!logs || logs.length === 0) {
    return { success: false, error: "未提供日誌資料" };
  }

  const uploadTime = new Date().toISOString();
  const deviceId = deviceInfo?.device_id || "unknown";
  const deviceName = deviceInfo?.device_name || "unknown";

  // 批次準備資料列
  const rows = logs.map((log) => [
    uploadTime,
    deviceId,
    deviceName,
    "'" + (log.timestamp || new Date().toISOString()), // 強制字串
    log.level || "info",
    log.source || "",
    log.message || "",
  ]);

  // 一次性寫入以提升效能
  if (rows.length > 0) {
    sheet.getRange(sheet.getLastRow() + 1, 1, rows.length, 7).setValues(rows);
  }

  return {
    success: true,
    message: `已上傳 ${logs.length} 條日誌`,
    count: logs.length,
  };
}

/**
 * 更新行程 (覆寫模式)
 * @param {Array} itineraryItems - 行程資料列表
 */
function updateItinerary(itineraryItems) {
  const ss = getSpreadsheet();
  let sheet = ss.getSheetByName("Itinerary");

  if (!sheet) {
    sheet = ss.insertSheet("Itinerary");
    sheet.appendRow([
      "day",
      "name",
      "est_time",
      "altitude",
      "distance",
      "note",
      "image_asset",
    ]);
  }

  // 清除現有內容 (保留標題列)
  const lastRow = sheet.getLastRow();
  if (lastRow > 1) {
    sheet.getRange(2, 1, lastRow - 1, 7).clearContent();
  }

  if (!itineraryItems || itineraryItems.length === 0) {
    return { success: true, message: "行程已清空" };
  }

  // 準備資料列
  const rows = itineraryItems.map((item) => [
    item.day,
    item.name,
    item.est_time || item.estTime || "", // 處理 camelCase 或 snake_case
    item.altitude,
    item.distance,
    item.note,
    item.image_asset || item.imageAsset || "",
  ]);

  if (rows.length > 0) {
    sheet.getRange(2, 1, rows.length, 7).setValues(rows);
  }

  return { success: true, message: "行程已更新" };
}

/**
 * 記錄使用狀態心跳 (Web 追蹤)
 * @param {Object} data - 心跳資料 { username, timestamp, platform }
 */
function recordHeartbeat(data) {
  const ss = getSpreadsheet();
  let sheet = ss.getSheetByName("Heartbeat");

  // 若工作表不存在則建立
  if (!sheet) {
    sheet = ss.insertSheet("Heartbeat");
    sheet.appendRow(["timestamp", "username", "platform"]);
  }

  // 新增心跳記錄
  sheet.appendRow([
    data.timestamp || new Date().toISOString(),
    data.username || "Anonymous",
    data.platform || "unknown",
  ]);

  return { success: true, message: "心跳已記錄" };
}

// ============================================================
// 雲端裝備庫 (Gear Cloud Library)
// ============================================================

const GEAR_SHEET_NAME = "GearSets";
const GEAR_HEADERS = ["uuid", "title", "author", "total_weight", "item_count", "visibility", "key", "uploaded_at", "items_json"];

/**
 * 初始化 GearSets 工作表
 */
function initGearSheet() {
  const ss = getSpreadsheet();
  let sheet = ss.getSheetByName(GEAR_SHEET_NAME);
  if (!sheet) {
    sheet = ss.insertSheet(GEAR_SHEET_NAME);
    sheet.appendRow(GEAR_HEADERS);
  }
  return sheet;
}

/**
 * 取得公開/保護的裝備組合列表 (不含 items 詳細資料)
 */
function fetchGearSets() {
  const sheet = initGearSheet();
  const data = sheet.getDataRange().getValues();

  if (data.length <= 1) {
    return { success: true, gear_sets: [] };
  }

  const headers = data[0];
  const gearSets = [];

  for (let i = 1; i < data.length; i++) {
    const row = data[i];
    const visibility = row[headers.indexOf("visibility")];

    // 私人組合不顯示在列表中
    if (visibility === "private") continue;

    gearSets.push({
      uuid: row[headers.indexOf("uuid")],
      title: row[headers.indexOf("title")],
      author: row[headers.indexOf("author")],
      total_weight: row[headers.indexOf("total_weight")],
      item_count: row[headers.indexOf("item_count")],
      visibility: visibility,
      uploaded_at: row[headers.indexOf("uploaded_at")],
      // 不包含 items，減少傳輸量
    });
  }

  return { success: true, gear_sets: gearSets };
}

/**
 * 用 Key 取得特定裝備組合 (含 items)
 * @param {string} key - 4 位數 Key
 */
function fetchGearSetByKey(key) {
  if (!key || key.length !== 4) {
    return { success: false, error: "請輸入 4 位數 Key" };
  }

  const sheet = initGearSheet();
  const data = sheet.getDataRange().getValues();
  const headers = data[0];
  const keyIndex = headers.indexOf("key");

  for (let i = 1; i < data.length; i++) {
    // 將兩邊都轉為字串比對 (Sheets 可能存為數字)
    if (String(data[i][keyIndex]) === String(key)) {
      const row = data[i];
      return {
        success: true,
        gear_set: {
          uuid: row[headers.indexOf("uuid")],
          title: row[headers.indexOf("title")],
          author: row[headers.indexOf("author")],
          total_weight: row[headers.indexOf("total_weight")],
          item_count: row[headers.indexOf("item_count")],
          visibility: row[headers.indexOf("visibility")],
          uploaded_at: row[headers.indexOf("uploaded_at")],
          items: JSON.parse(row[headers.indexOf("items_json")] || "[]"),
        },
      };
    }
  }

  return { success: false, error: "找不到符合的裝備組合" };
}

/**
 * 下載指定裝備組合
 * @param {string} uuid - 組合 UUID
 * @param {string} key - 可選，若為 protected 需要 key
 */
function downloadGearSet(uuid, key) {
  if (!uuid) {
    return { success: false, error: "缺少 UUID" };
  }

  const sheet = initGearSheet();
  const data = sheet.getDataRange().getValues();
  const headers = data[0];
  const uuidIndex = headers.indexOf("uuid");

  for (let i = 1; i < data.length; i++) {
    if (data[i][uuidIndex] === uuid) {
      const row = data[i];
      const visibility = row[headers.indexOf("visibility")];
      const storedKey = row[headers.indexOf("key")];

      // Protected/Private 需要正確的 key (將兩邊轉為字串比對)
      if ((visibility === "protected" || visibility === "private") && String(storedKey) !== String(key)) {
        return { success: false, error: "需要正確的 Key 才能下載" };
      }

      return {
        success: true,
        gear_set: {
          uuid: row[headers.indexOf("uuid")],
          title: row[headers.indexOf("title")],
          author: row[headers.indexOf("author")],
          total_weight: row[headers.indexOf("total_weight")],
          item_count: row[headers.indexOf("item_count")],
          visibility: visibility,
          uploaded_at: row[headers.indexOf("uploaded_at")],
          items: JSON.parse(row[headers.indexOf("items_json")] || "[]"),
        },
      };
    }
  }

  return { success: false, error: "找不到指定的裝備組合" };
}

/**
 * 上傳裝備組合
 * @param {Object} data - 上傳資料
 */
function uploadGearSet(data) {
  const { title, author, visibility, key, total_weight, item_count, items } = data;

  if (!title || !author) {
    return { success: false, error: "缺少必要欄位 (title, author)" };
  }

  // Protected/Private 必須有 key
  if ((visibility === "protected" || visibility === "private") && (!key || key.length !== 4)) {
    return { success: false, error: "Protected/Private 模式需要 4 位數 Key" };
  }

  // 檢查 key 是否重複
  if (key) {
    const sheet = initGearSheet();
    const existingData = sheet.getDataRange().getValues();
    const headers = existingData[0];
    const keyIndex = headers.indexOf("key");

    for (let i = 1; i < existingData.length; i++) {
      // 將兩邊轉為字串比對
      if (String(existingData[i][keyIndex]) === String(key)) {
        return { success: false, error: "Key 重複，請換一個 4 位數" };
      }
    }
  }

  // 產生 UUID
  const uuid = Utilities.getUuid();
  const uploadedAt = new Date().toISOString();
  const itemsJson = JSON.stringify(items || []);

  // 寫入資料
  const sheet = initGearSheet();
  sheet.appendRow([
    uuid,
    title,
    author,
    total_weight || 0,
    item_count || 0,
    visibility || "public",
    key || "",
    uploadedAt,
    itemsJson,
  ]);

  return {
    success: true,
    gear_set: {
      uuid: uuid,
      title: title,
      author: author,
      total_weight: total_weight || 0,
      item_count: item_count || 0,
      visibility: visibility || "public",
      uploaded_at: uploadedAt,
    },
  };
}

// ============================================================
// 輔助函式 (Helper Functions)
// ============================================================

/**
 * 將標題名稱轉換為 snake_case 鍵值
 * 例如: "Est Time" -> "est_time", "Day" -> "day"
 */
function headerToKey(header) {
  return header
    .toLowerCase()
    .trim()
    .replace(/\s+/g, "_")
    .replace(/[^a-z0-9_]/g, "");
}

// ============================================================
// 測試函式 (Test Functions - 供偵錯用)
// ============================================================

function testFetchAll() {
  const result = fetchAll();
  Logger.log(JSON.stringify(result, null, 2));
}

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

// ============================================================
// 初始化函式 (Setup Function) - 執行一次以建立初始工作表
// ============================================================

function setupSheets() {
  const ss = getSpreadsheet();

  // 建立 Itinerary 工作表
  let itinerarySheet = ss.getSheetByName("Itinerary");
  if (!itinerarySheet) {
    itinerarySheet = ss.insertSheet("Itinerary");
    itinerarySheet.appendRow([
      "day",
      "name",
      "est_time",
      "altitude",
      "distance",
      "note",
      "image_asset",
    ]);

    // 加入範例資料
    const sampleData = [
      [
        "'D0",
        "台北車站出發",
        "'18:00",
        20,
        0,
        "搭乘火車前往池上 (晚餐自理)",
        "assets/images/d0_train_station.jpg",
      ],
      [
        "'D0",
        "抵達池上車站",
        "'22:00",
        260,
        0,
        "前往青旅 Check-in",
        "assets/images/d0_chishang_station.jpg",
      ],
      [
        "'D0",
        "就寢休息",
        "'23:00",
        260,
        0,
        "整理裝備，準備隔日早起",
        "assets/images/d0_hostel_sleep.jpg",
      ],
      [
        "'D1",
        "起床/早餐",
        "'04:30",
        260,
        0,
        "於青旅享用或外帶早餐",
        "assets/images/d1_breakfast.jpg",
      ],
      [
        "'D1",
        "接駁車出發",
        "'05:00",
        260,
        0,
        "搭乘包車前往向陽森林遊樂區",
        "assets/images/d1_shuttle_bus.jpg",
      ],
      [
        "'D1",
        "向陽登山口 (起登)",
        "'06:00",
        2312,
        0,
        "檢查入山入園證，熱身起登",
        "assets/images/d1_trailhead_start.jpg",
      ],
      [
        "'D1",
        "觀景台休息",
        "'07:30",
        2650,
        2.5,
        "休息 10 分鐘，調整衣物",
        "assets/images/d1_observation_deck.jpg",
      ],
      [
        "'D1",
        "向陽山屋",
        "'08:40",
        2850,
        1.8,
        "大休息 20 分鐘，補充水分",
        "assets/images/d1_xiangyang_cabin.jpg",
      ],
      [
        "'D1",
        "黑水塘營地",
        "'10:30",
        3100,
        1.2,
        "途經名樹 (Famous Tree) 拍照",
        "assets/images/d1_blackwater_pond.jpg",
      ],
      [
        "'D1",
        "向陽大崩壁",
        "'11:30",
        3350,
        1,
        "午餐時間 (行動糧)，休息 30 分鐘",
        "assets/images/d1_grand_wall.jpg",
      ],
      [
        "'D1",
        "向陽山登山口",
        "'13:00",
        3490,
        1.4,
        "輕裝可選攻向陽山 (視體力決定)",
        "assets/images/d1_xiangyang_junction.jpg",
      ],
      [
        "'D1",
        "嘉明湖避難山屋",
        "'14:00",
        3347,
        0.5,
        "抵達住宿點，整理床位",
        "assets/images/d1_jiaming_shelter.jpg",
      ],
      [
        "'D1",
        "晚餐時間",
        "'17:30",
        3347,
        0,
        "協作供餐或自煮，觀賞夕陽",
        "assets/images/d1_dinner.jpg",
      ],
      [
        "'D1",
        "就寢",
        "'19:00",
        3347,
        0,
        "儲備體力迎接日出",
        "assets/images/d1_sleep.jpg",
      ],
      [
        "'D2",
        "起床/早餐",
        "'02:30",
        3347,
        0,
        "著保暖衣物，攜帶頭燈",
        "assets/images/d2_early_wake.jpg",
      ],
      [
        "'D2",
        "出發前往嘉明湖",
        "'03:30",
        3347,
        0,
        "輕裝出發，夜行注意路況",
        "assets/images/d2_night_hike.jpg",
      ],
      [
        "'D2",
        "三叉山登山口",
        "'05:00",
        3400,
        3,
        "稍作休息，腰繞路線",
        "assets/images/d2_sancha_junction.jpg",
      ],
      [
        "'D2",
        "嘉明湖 (看日出)",
        "'06:00",
        3310,
        1.6,
        "抵達湖畔，等待日出 (Sunrise)",
        "assets/images/d2_jiaming_lake_sunrise.jpg",
      ],
      [
        "'D2",
        "離開嘉明湖",
        "'07:30",
        3310,
        0,
        "拍照結束，回程",
        "assets/images/d2_leaving_lake.jpg",
      ],
      [
        "'D2",
        "三叉山 (選攻)",
        "'08:15",
        3496,
        0.6,
        "視體力決定是否登頂",
        "assets/images/d2_sancha_peak.jpg",
      ],
      [
        "'D2",
        "返回避難山屋",
        "'09:30",
        3347,
        4,
        "休息 40 分鐘，整裝打包",
        "assets/images/d2_back_to_shelter.jpg",
      ],
      [
        "'D2",
        "開始下山",
        "'10:10",
        3347,
        0,
        "離開避難山屋",
        "assets/images/d2_start_descent.jpg",
      ],
      [
        "'D2",
        "向陽山屋",
        "'12:40",
        2850,
        4.1,
        "午餐時間 (行動糧)，休息 30 分鐘",
        "assets/images/d2_cabin_lunch.jpg",
      ],
      [
        "'D2",
        "回到向陽登山口",
        "'15:30",
        2312,
        4.3,
        "完成登山行程，搭乘接駁車",
        "assets/images/d2_trailhead_finish.jpg",
      ],
      [
        "'D2",
        "慶功宴/晚餐",
        "'17:30",
        260,
        0,
        "於池上市區用餐",
        "assets/images/d2_celebration_dinner.jpg",
      ],
      [
        "'D2",
        "池上車站 (回程)",
        "'19:00",
        260,
        0,
        "搭乘火車返回台北",
        "assets/images/d2_train_home.jpg",
      ],
    ];

    sampleData.forEach((row) => itinerarySheet.appendRow(row));

    Logger.log("Itinerary 工作表已建立並寫入範例資料");
  }

  // 建立 Messages 工作表
  let messagesSheet = ss.getSheetByName("Messages");
  if (!messagesSheet) {
    messagesSheet = ss.insertSheet("Messages");
    messagesSheet.appendRow([
      "uuid",
      "parent_id",
      "user",
      "category",
      "content",
      "timestamp",
      "avatar",
    ]);

    // 加入歡迎訊息
    messagesSheet.appendRow([
      Utilities.getUuid(),
      "",
      "Admin",
      "Chat",
      "歡迎使用 SummitMate！這是行程協作留言板。",
      "'" + new Date().toISOString(),
      "🤖",
    ]);

    Logger.log("Messages 工作表已建立並寫入歡迎訊息");
  } else {
    // 遷移：若缺少 avatar 欄位則補上
    const headers = messagesSheet
      .getRange(1, 1, 1, messagesSheet.getLastColumn())
      .getValues()[0];
    if (!headers.includes("avatar")) {
      messagesSheet.getRange(1, headers.length + 1).setValue("avatar");
      Logger.log("已新增 avatar 欄位至 Messages 工作表");
    }
  }

  // 建立 Logs 工作表
  let logsSheet = ss.getSheetByName("Logs");
  if (!logsSheet) {
    logsSheet = ss.insertSheet("Logs");
    logsSheet.appendRow([
      "upload_time",
      "device_id",
      "device_name",
      "timestamp",
      "level",
      "source",
      "message",
    ]);

    Logger.log("Logs 工作表已建立");
  }

  // 初始化投票工作表 (呼叫 polls.gs)
  if (typeof setupPollSheets === "function") {
    setupPollSheets();
  } else {
    Logger.log(
      "警告: 找不到 setupPollSheets 函式，請確認 polls.gs 是否已包含在專案中。"
    );
  }

  // 建立 Heartbeat 工作表 (使用狀態追蹤)
  let heartbeatSheet = ss.getSheetByName("Heartbeat");
  if (!heartbeatSheet) {
    heartbeatSheet = ss.insertSheet("Heartbeat");
    heartbeatSheet.appendRow([
      "user",
      "avatar",
      "last_seen",
      "view",
      "platform",
    ]);
    Logger.log("Heartbeat 工作表已建立");
  }

  // 建立 GearSets 工作表 (雲端裝備庫)
  let gearSetsSheet = ss.getSheetByName("GearSets");
  if (!gearSetsSheet) {
    gearSetsSheet = ss.insertSheet("GearSets");
    gearSetsSheet.appendRow([
      "uuid",
      "title",
      "author",
      "total_weight",
      "item_count",
      "visibility",
      "key",
      "uploaded_at",
      "items_json",
    ]);
    Logger.log("GearSets 工作表已建立");
  }

  Logger.log("初始化設定完成 (Setup complete)!");
}
