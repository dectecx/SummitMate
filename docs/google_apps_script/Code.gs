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
      case 'delete_message':
        return createJsonResponse(deleteMessage(data.uuid));
      case 'upload_logs':
        return createJsonResponse(uploadLogs(data.logs, data.device_info));
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
      if (key === 'parent_id' && !value) {
        value = null;
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
    messageData.timestamp ? new Date(messageData.timestamp) : new Date()
  ]);

  return { success: true, message: 'Message added' };
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
    log.timestamp || '',
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
      ['D0', '向陽國家森林遊樂區', '13:00', 2320, 0, '入園整裝', ''],
      ['D0', '松濤營地', '14:30', 2600, 2.0, '通過芒草區', ''],
      ['D1', '向陽山屋', '06:00', 2850, 4.3, '出發', ''],
      ['D1', '向陽山叉路口', '08:00', 3200, 6.5, '休息', ''],
      ['D1', '嘉明湖避難山屋', '11:00', 3380, 10.2, '午餐', ''],
      ['D1', '嘉明湖', '13:00', 3310, 11.5, '拍照', ''],
      ['D1', '嘉明湖避難山屋', '15:00', 3380, 12.8, '住宿', ''],
      ['D2', '嘉明湖避難山屋', '06:00', 3380, 0, '出發下山', ''],
      ['D2', '向陽山屋', '09:00', 2850, 5.9, '休息', ''],
      ['D2', '向陽國家森林遊樂區', '12:00', 2320, 10.2, '完成', '']
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
      new Date()
    ]);

    Logger.log('Messages sheet created with welcome message');
  }

  Logger.log('Setup complete!');
}
