// ============================================================
// SummitMate - Google Apps Script API
// 嘉明湖登山行程助手 Backend API
// ============================================================
//
// 部署步驟：
// 1. 建立 Google Sheets，包含兩個工作表：
//    - "Itinerary" (行程)
//    - "Messages" (留言)
// 2. 點擊「擴充功能」→「Apps Script」
// 3. 複製此檔案內容到 Code.gs
// 4. 點擊「部署」→「新增部署作業」
// 5. 選擇類型「網頁應用程式」
// 6. 設定：
//    - 執行身分：我
//    - 誰可以存取：任何人
// 7. 點擊「部署」並複製網頁應用程式 URL
// 8. 將 URL 更新到 Flutter App 的 constants.dart
//
// ============================================================

// 取得試算表
function getSpreadsheet() {
  return SpreadsheetApp.getActiveSpreadsheet();
}

// ============================================================
// HTTP Request Handlers
// ============================================================

function doGet(e) {
  const action = e.parameter.action;

  try {
    switch (action) {
      case 'fetch_all':
        return createJsonResponse(fetchAll());
      case 'health':
        return createJsonResponse({ status: 'ok', timestamp: new Date().toISOString() });
      default:
        return createJsonResponse({ error: 'Unknown action' }, 400);
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
      case 'add_message':
        return createJsonResponse(addMessage(data.data));
      case 'batch_add_messages':
        return createJsonResponse(batchAddMessages(data.data));
      case 'delete_message':
        return createJsonResponse(deleteMessage(data.uuid));
      case 'upload_logs':
        return createJsonResponse(uploadLogs(data.logs, data.device_info));
      case 'update_itinerary':
        return createJsonResponse(updateItinerary(data.data));
      default:
        return createJsonResponse({ error: 'Unknown action' }, 400);
    }
  } catch (error) {
    return createJsonResponse({ error: error.message }, 500);
  }
}

function createJsonResponse(data, statusCode = 200) {
  return ContentService
    .createTextOutput(JSON.stringify(data))
    .setMimeType(ContentService.MimeType.JSON);
}

// ============================================================
// API Functions
// ============================================================

/**
 * 取得所有資料 (行程 + 留言)
 */
function fetchAll() {
  const ss = getSpreadsheet();

  return {
    itinerary: getItineraryData(ss),
    messages: getMessagesData(ss)
  };
}

/**
 * 取得行程資料
 */
function getItineraryData(ss) {
  const sheet = ss.getSheetByName('Itinerary');
  if (!sheet) return [];

  const data = sheet.getDataRange().getValues();
  if (data.length <= 1) return []; // Only header row

  const headers = data[0];
  const rows = data.slice(1);

  return rows.map(row => {
    const item = {};
    headers.forEach((header, index) => {
      // Convert header to snake_case for API
      const key = headerToKey(header);
      item[key] = row[index];
    });
    return item;
  }).filter(item => item.day && item.name); // Filter empty rows
}

/**
 * 取得留言資料
 */
function getMessagesData(ss) {
  const sheet = ss.getSheetByName('Messages');
  if (!sheet) return [];

  const data = sheet.getDataRange().getValues();
  if (data.length <= 1) return [];

  const headers = data[0];
  const rows = data.slice(1);

  return rows.map(row => {
    const msg = {};
    headers.forEach((header, index) => {
      const key = headerToKey(header);
      let value = row[index];

      // Handle timestamp
      if (key === 'timestamp' && value instanceof Date) {
        value = value.toISOString();
      }
      // Handle empty parent_id
      if (key === 'parent_id') {
        value = value || null;
      }

      // Timestamp is already string if stored with ' prefix, but just in case
      if (key === 'timestamp' && value instanceof Date) {
        value = value.toISOString();
      }

      msg[key] = value;
    });
    return msg;
  }).filter(msg => msg.uuid); // Filter empty rows
}

/**
 * 新增留言
 */
function addMessage(messageData) {
  const ss = getSpreadsheet();
  let sheet = ss.getSheetByName('Messages');

  // Create sheet if not exists
  if (!sheet) {
    sheet = ss.insertSheet('Messages');
    sheet.appendRow(['uuid', 'parent_id', 'user', 'category', 'content', 'timestamp']);
  }

  // Check for duplicate UUID
  const existingData = sheet.getDataRange().getValues();
  for (let i = 1; i < existingData.length; i++) {
    if (existingData[i][0] === messageData.uuid) {
      return { success: true, message: 'Message already exists' };
    }
  }

  // Append new row
  sheet.appendRow([
    messageData.uuid || Utilities.getUuid(),
    messageData.parent_id || '',
    messageData.user || 'Anonymous',
    messageData.category || 'Misc',
    messageData.content || '',
    // Force String format for timestamp to avoid timezone issues
    "'" + (messageData.timestamp || new Date().toISOString())
  ]);

  return { success: true, message: 'Message added' };
}

function batchAddMessages(messages) {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName('Messages');

  if (!messages || messages.length === 0) {
    return { success: true, message: 'No messages to add' };
  }

  const rows = messages.map(messageData => [
    messageData.uuid || Utilities.getUuid(),
    messageData.parent_id || '', // parent_id is optional
    messageData.user || 'Anonymous',
    messageData.category || 'Misc',
    messageData.content || '',
    // Force String format for timestamp to avoid timezone issues
    "'" + (messageData.timestamp || new Date().toISOString())
  ]);

  if (rows.length > 0) {
    sheet.getRange(sheet.getLastRow() + 1, 1, rows.length, 6).setValues(rows);
  }

  return { success: true, message: `Batch added ${rows.length} messages` };
}

/**
 * 刪除留言
 */
function deleteMessage(uuid) {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName('Messages');

  if (!sheet) {
    return { success: false, error: 'Messages sheet not found' };
  }

  const data = sheet.getDataRange().getValues();

  for (let i = 1; i < data.length; i++) {
    if (data[i][0] === uuid) {
      sheet.deleteRow(i + 1); // +1 because array is 0-indexed, rows are 1-indexed
      return { success: true, message: 'Message deleted' };
    }
  }

  return { success: false, error: 'Message not found' };
}

/**
 * 上傳應用日誌
 * @param {Array} logs - 日誌條目陣列
 * @param {Object} deviceInfo - 裝置資訊
 */
function uploadLogs(logs, deviceInfo) {
  const ss = getSpreadsheet();
  let sheet = ss.getSheetByName('Logs');

  // Create sheet if not exists
  if (!sheet) {
    sheet = ss.insertSheet('Logs');
    sheet.appendRow(['upload_time', 'device_id', 'device_name', 'timestamp', 'level', 'source', 'message']);
  }

  if (!logs || logs.length === 0) {
    return { success: false, error: 'No logs provided' };
  }

  const uploadTime = new Date().toISOString();
  const deviceId = deviceInfo?.device_id || 'unknown';
  const deviceName = deviceInfo?.device_name || 'unknown';

  // Batch append logs
  const rows = logs.map(log => [
    uploadTime,
    deviceId,
    deviceName,
    "'" + (log.timestamp || new Date().toISOString()), // Force String
    log.level || 'info',
    log.source || '',
    log.message || ''
  ]);

  // Append all rows at once for better performance
  if (rows.length > 0) {
    sheet.getRange(sheet.getLastRow() + 1, 1, rows.length, 7).setValues(rows);
  }

  return {
    success: true,
    message: `Uploaded ${logs.length} log entries`,
    count: logs.length
  };
}

/**
 * 更新行程 (覆寫)
 * @param {Array} itineraryItems - 行程資料列表
 */
function updateItinerary(itineraryItems) {
  const ss = getSpreadsheet();
  let sheet = ss.getSheetByName('Itinerary');

  if (!sheet) {
    sheet = ss.insertSheet('Itinerary');
    sheet.appendRow(['day', 'name', 'est_time', 'altitude', 'distance', 'note', 'image_asset']);
  }

  // Clear existing content (except header)
  const lastRow = sheet.getLastRow();
  if (lastRow > 1) {
    sheet.getRange(2, 1, lastRow - 1, 7).clearContent();
  }

  if (!itineraryItems || itineraryItems.length === 0) {
    return { success: true, message: 'Itinerary cleared' };
  }

  // Prepare rows
  const rows = itineraryItems.map(item => [
    item.day,
    item.name,
    item.est_time || item.estTime || '', // Handle camelCase or snake_case
    item.altitude,
    item.distance,
    item.note,
    item.image_asset || item.imageAsset || ''
  ]);

  if (rows.length > 0) {
    sheet.getRange(2, 1, rows.length, 7).setValues(rows);
  }

  return { success: true, message: 'Itinerary updated' };
}

// ============================================================
// Helper Functions
// ============================================================

/**
 * Convert header name to snake_case key
 * e.g., "Est Time" -> "est_time", "Day" -> "day"
 */
function headerToKey(header) {
  return header
    .toLowerCase()
    .trim()
    .replace(/\s+/g, '_')
    .replace(/[^a-z0-9_]/g, '');
}

// ============================================================
// Test Functions (for debugging)
// ============================================================

function testFetchAll() {
  const result = fetchAll();
  Logger.log(JSON.stringify(result, null, 2));
}

function testAddMessage() {
  const result = addMessage({
    uuid: 'test-' + new Date().getTime(),
    user: 'TestUser',
    category: 'Gear',
    content: 'This is a test message',
    timestamp: new Date().toISOString()
  });
  Logger.log(JSON.stringify(result));
}

// ============================================================
// Setup Function - Run once to create initial sheets
// ============================================================

function setupSheets() {
  const ss = getSpreadsheet();

  // Create Itinerary sheet
  let itinerarySheet = ss.getSheetByName('Itinerary');
  if (!itinerarySheet) {
    itinerarySheet = ss.insertSheet('Itinerary');
    itinerarySheet.appendRow(['day', 'name', 'est_time', 'altitude', 'distance', 'note', 'image_asset']);

    // Add sample data
    const sampleData = [
      ["'D0", '台北車站出發', "'18:00", 20, 0, '搭乘火車前往池上 (晚餐自理)', 'assets/images/d0_train_station.jpg'],
      ["'D0", '抵達池上車站', "'22:00", 260, 0, '前往青旅 Check-in', 'assets/images/d0_chishang_station.jpg'],
      ["'D0", '就寢休息', "'23:00", 260, 0, '整理裝備，準備隔日早起', 'assets/images/d0_hostel_sleep.jpg'],
      ["'D1", '起床/早餐', "'04:30", 260, 0, '於青旅享用或外帶早餐', 'assets/images/d1_breakfast.jpg'],
      ["'D1", '接駁車出發', "'05:00", 260, 0, '搭乘包車前往向陽森林遊樂區', 'assets/images/d1_shuttle_bus.jpg'],
      ["'D1", '向陽登山口 (起登)', "'06:00", 2312, 0, '檢查入山入園證，熱身起登', 'assets/images/d1_trailhead_start.jpg'],
      ["'D1", '觀景台休息', "'07:30", 2650, 2.5, '休息 10 分鐘，調整衣物', 'assets/images/d1_observation_deck.jpg'],
      ["'D1", '向陽山屋', "'08:40", 2850, 1.8, '大休息 20 分鐘，補充水分', 'assets/images/d1_xiangyang_cabin.jpg'],
      ["'D1", '黑水塘營地', "'10:30", 3100, 1.2, '途經名樹 (Famous Tree) 拍照', 'assets/images/d1_blackwater_pond.jpg'],
      ["'D1", '向陽大崩壁', "'11:30", 3350, 1, '午餐時間 (行動糧)，休息 30 分鐘', 'assets/images/d1_grand_wall.jpg'],
      ["'D1", '向陽山登山口', "'13:00", 3490, 1.4, '輕裝可選攻向陽山 (視體力決定)', 'assets/images/d1_xiangyang_junction.jpg'],
      ["'D1", '嘉明湖避難山屋', "'14:00", 3347, 0.5, '抵達住宿點，整理床位', 'assets/images/d1_jiaming_shelter.jpg'],
      ["'D1", '晚餐時間', "'17:30", 3347, 0, '協作供餐或自煮，觀賞夕陽', 'assets/images/d1_dinner.jpg'],
      ["'D1", '就寢', "'19:00", 3347, 0, '儲備體力迎接日出', 'assets/images/d1_sleep.jpg'],
      ["'D2", '起床/早餐', "'02:30", 3347, 0, '著保暖衣物，攜帶頭燈', 'assets/images/d2_early_wake.jpg'],
      ["'D2", '出發前往嘉明湖', "'03:30", 3347, 0, '輕裝出發，夜行注意路況', 'assets/images/d2_night_hike.jpg'],
      ["'D2", '三叉山登山口', "'05:00", 3400, 3, '稍作休息，腰繞路線', 'assets/images/d2_sancha_junction.jpg'],
      ["'D2", '嘉明湖 (看日出)', "'06:00", 3310, 1.6, '抵達湖畔，等待日出 (Sunrise)', 'assets/images/d2_jiaming_lake_sunrise.jpg'],
      ["'D2", '離開嘉明湖', "'07:30", 3310, 0, '拍照結束，回程', 'assets/images/d2_leaving_lake.jpg'],
      ["'D2", '三叉山 (選攻)', "'08:15", 3496, 0.6, '視體力決定是否登頂', 'assets/images/d2_sancha_peak.jpg'],
      ["'D2", '返回避難山屋', "'09:30", 3347, 4, '休息 40 分鐘，整裝打包', 'assets/images/d2_back_to_shelter.jpg'],
      ["'D2", '開始下山', "'10:10", 3347, 0, '離開避難山屋', 'assets/images/d2_start_descent.jpg'],
      ["'D2", '向陽山屋', "'12:40", 2850, 4.1, '午餐時間 (行動糧)，休息 30 分鐘', 'assets/images/d2_cabin_lunch.jpg'],
      ["'D2", '回到向陽登山口', "'15:30", 2312, 4.3, '完成登山行程，搭乘接駁車', 'assets/images/d2_trailhead_finish.jpg'],
      ["'D2", '慶功宴/晚餐', "'17:30", 260, 0, '於池上市區用餐', 'assets/images/d2_celebration_dinner.jpg'],
      ["'D2", '池上車站 (回程)', "'19:00", 260, 0, '搭乘火車返回台北', 'assets/images/d2_train_home.jpg']
    ];

    sampleData.forEach(row => itinerarySheet.appendRow(row));

    Logger.log('Itinerary sheet created with sample data');
  }

  // Create Messages sheet
  let messagesSheet = ss.getSheetByName('Messages');
  if (!messagesSheet) {
    messagesSheet = ss.insertSheet('Messages');
    messagesSheet.appendRow(['uuid', 'parent_id', 'user', 'category', 'content', 'timestamp']);

    // Add sample message
    messagesSheet.appendRow([
      Utilities.getUuid(),
      '',
      'Admin',
      'Plan',
      '歡迎使用 SummitMate！這是行程協作留言板。',
      "'" + new Date().toISOString()
    ]);

    Logger.log('Messages sheet created with welcome message');
  }

  // Create Logs sheet
  let logsSheet = ss.getSheetByName('Logs');
  if (!logsSheet) {
    logsSheet = ss.insertSheet('Logs');
    logsSheet.appendRow(['upload_time', 'device_id', 'device_name', 'timestamp', 'level', 'source', 'message']);

    Logger.log('Logs sheet created');
  }

  Logger.log('Setup complete!');
}
