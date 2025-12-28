/**
 * ============================================================
 * 核心功能模組
 * ============================================================
 * @fileoverview HTTP Router (doGet/doPost) 與工具函式
 */

// ============================================================
// === PUBLIC API ===
// ============================================================

/**
 * 取得當前試算表
 * @returns {Spreadsheet} 試算表物件
 */
function getSpreadsheet() {
  return SpreadsheetApp.getActiveSpreadsheet();
}

/**
 * GET 請求處理器
 * @param {Object} e - 請求事件物件
 * @returns {TextOutput} JSON 回應
 */
function doGet(e) {
  const action = e.parameter.action;
  const tripId = e.parameter.trip_id;

  try {
    switch (action) {
      case 'fetch_all':
        return _createJsonResponse(fetchAll(tripId));
      case 'fetch_itinerary':
        return _createJsonResponse({
          itinerary: getItineraryData(getSpreadsheet(), tripId),
        });
      case 'fetch_messages':
        return _createJsonResponse({
          messages: getMessagesData(getSpreadsheet(), tripId),
        });
      case 'fetch_trips':
        return _createJsonResponse(fetchTrips());
      case 'fetch_weather':
        return _createJsonResponse(getWeatherData());
      case 'poll':
        return _createJsonResponse(
          handlePollAction(e.parameter.subAction, e.parameter)
        );
      case 'health':
        return _createJsonResponse({
          status: 'ok',
          timestamp: new Date().toISOString(),
        });
      default:
        return _createJsonResponse({ error: '未知動作 (Unknown action)' }, 400);
    }
  } catch (error) {
    return _createJsonResponse({ error: error.message }, 500);
  }
}

/**
 * POST 請求處理器
 * @param {Object} e - 請求事件物件
 * @returns {TextOutput} JSON 回應
 */
function doPost(e) {
  try {
    const data = JSON.parse(e.postData.contents);
    const action = data.action;

    switch (action) {
      // === 留言 ===
      case 'add_message':
        return _createJsonResponse(addMessage(data.data));
      case 'batch_add_messages':
        return _createJsonResponse(batchAddMessages(data.data));
      case 'delete_message':
        return _createJsonResponse(deleteMessage(data.uuid));
        
      // === 行程節點 ===
      case 'update_itinerary':
        return _createJsonResponse(updateItinerary(data.data, data.trip_id));
        
      // === 多行程 ===
      case 'add_trip':
        return _createJsonResponse(addTrip(data));
      case 'update_trip':
        return _createJsonResponse(updateTrip(data));
      case 'delete_trip':
        return _createJsonResponse(deleteTrip(data.id));
      case 'set_active_trip':
        return _createJsonResponse(setActiveTrip(data.id));
        
      // === 裝備庫 ===
      case 'fetch_gear_sets':
        return _createJsonResponse(fetchGearSets());
      case 'fetch_gear_set_by_key':
        return _createJsonResponse(fetchGearSetByKey(data.key));
      case 'download_gear_set':
        return _createJsonResponse(downloadGearSet(data.uuid, data.key));
      case 'upload_gear_set':
        return _createJsonResponse(uploadGearSet(data));
      case 'delete_gear_set':
        return _createJsonResponse(deleteGearSet(data.uuid, data.key));
        
      // === 其他 ===
      case 'upload_logs':
        return _createJsonResponse(uploadLogs(data.logs, data.device_info));
      case 'heartbeat':
        return _createJsonResponse(recordHeartbeat(data));
      case 'poll':
        return _createJsonResponse(handlePollAction(data.subAction, data));
        
      default:
        return _createJsonResponse({ error: '未知動作 (Unknown action)' }, 400);
    }
  } catch (error) {
    return _createJsonResponse({ error: error.message }, 500);
  }
}

// ============================================================
// === INTERNAL HELPERS ===
// ============================================================

/**
 * 建立 JSON 回應
 * @private
 * @param {Object} data - 回應資料
 * @param {number} [statusCode=200] - HTTP 狀態碼 (僅供文件參考)
 * @returns {TextOutput} JSON 格式的回應
 */
function _createJsonResponse(data, statusCode = 200) {
  return ContentService.createTextOutput(JSON.stringify(data)).setMimeType(
    ContentService.MimeType.JSON
  );
}

/**
 * 將標題名稱轉換為 snake_case 鍵值
 * @private
 * @param {string} header - 欄位標題
 * @returns {string} snake_case 格式的鍵值
 * @example
 * _headerToKey('Est Time') // 'est_time'
 * _headerToKey('Day') // 'day'
 */
function _headerToKey(header) {
  return header
    .toLowerCase()
    .trim()
    .replace(/\s+/g, '_')
    .replace(/[^a-z0-9_]/g, '');
}

/**
 * 取得或建立工作表
 * @private
 * @param {string} name - 工作表名稱
 * @param {string[]} headers - 欄位標題陣列
 * @returns {Sheet} 工作表物件
 */
function _getSheetOrCreate(name, headers) {
  const ss = getSpreadsheet();
  let sheet = ss.getSheetByName(name);
  
  if (!sheet) {
    sheet = ss.insertSheet(name);
    sheet.appendRow(headers);
  }
  
  return sheet;
}

/**
 * 確保工作表有指定欄位
 * @private
 * @param {Sheet} sheet - 工作表物件
 * @param {string} columnName - 欄位名稱
 */
function _ensureColumn(sheet, columnName) {
  const headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
  if (!headers.includes(columnName)) {
    sheet.getRange(1, headers.length + 1).setValue(columnName);
  }
}
