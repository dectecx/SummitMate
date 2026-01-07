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
      // === 行程 (Trips) ===
      case API_ACTIONS.TRIP_LIST:
        return _createJsonResponse(fetchTrips());

      // === 行程節點 + 留言 ===
      case API_ACTIONS.TRIP_GET_FULL:
        return _createJsonResponse(fetchAll(tripId));
      case API_ACTIONS.ITINERARY_LIST:
        return _createJsonResponse(
          _success({ itinerary: getItineraryData(getSpreadsheet(), tripId) })
        );
      case API_ACTIONS.MESSAGE_LIST:
        return _createJsonResponse(
          _success({ messages: getMessagesData(getSpreadsheet(), tripId) })
        );

      // === 投票 (Polls) ===
      // Flattened for RESTful resource style
      case API_ACTIONS.POLL_LIST:
        return _createJsonResponse(handlePollAction("get", e.parameter));

      // === 氣象 (Weather) ===
      case API_ACTIONS.WEATHER_GET:
        return _createJsonResponse(getWeatherData());

      // === 健康檢查 ===
      case API_ACTIONS.SYSTEM_HEALTH:
        return _createJsonResponse(
          _success(
            { status: "ok", timestamp: new Date().toISOString() },
            "服務正常"
          )
        );
      default:
        return _createJsonResponse(
          _error(API_CODES.UNKNOWN_ACTION, "未知動作 (Unknown action)")
        );
    }
  } catch (error) {
    return _createJsonResponse(_error(API_CODES.SYSTEM_ERROR, error.message));
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
      // === 行程 (Trips) ===
      case API_ACTIONS.TRIP_LIST:
        return _createJsonResponse(fetchTrips());
      case API_ACTIONS.TRIP_CREATE:
        return _createJsonResponse(addTrip(data));
      case API_ACTIONS.TRIP_UPDATE:
        return _createJsonResponse(updateTrip(data));
      case API_ACTIONS.TRIP_DELETE:
        return _createJsonResponse(deleteTrip(data.trip_id || data.id));
      case API_ACTIONS.TRIP_SET_ACTIVE:
        return _createJsonResponse(setActiveTrip(data.id));
      case API_ACTIONS.TRIP_SYNC:
        return _createJsonResponse(handleSyncTripFull(data));

      // === 行程節點 (Itinerary) ===
      case API_ACTIONS.ITINERARY_UPDATE:
        return _createJsonResponse(updateItinerary(data.data, data.trip_id));

      // === 留言 (Messages) ===
      case API_ACTIONS.MESSAGE_CREATE:
        return _createJsonResponse(addMessage(data.data));
      case API_ACTIONS.MESSAGE_CREATE_BATCH:
        return _createJsonResponse(batchAddMessages(data.data));
      case API_ACTIONS.MESSAGE_DELETE:
        return _createJsonResponse(deleteMessage(data.uuid));

      // === 裝備組合 (Gear) ===
      case API_ACTIONS.GEAR_SET_LIST:
        return _createJsonResponse(fetchGearSets());
      case API_ACTIONS.GEAR_SET_GET:
        return _createJsonResponse(fetchGearSetByKey(data.key));
      case API_ACTIONS.GEAR_SET_DOWNLOAD:
        return _createJsonResponse(downloadGearSet(data.uuid, data.key));
      case API_ACTIONS.GEAR_SET_UPLOAD:
        return _createJsonResponse(uploadGearSet(data));
      case API_ACTIONS.GEAR_SET_DELETE:
        return _createJsonResponse(deleteGearSet(data.uuid, data.key));

      // === 個人裝備庫 (GearLibrary) ===
      case API_ACTIONS.GEAR_LIBRARY_UPLOAD:
        return _createJsonResponse(
          uploadGearLibrary(data.owner_key, data.items)
        );
      case API_ACTIONS.GEAR_LIBRARY_DOWNLOAD:
        return _createJsonResponse(downloadGearLibrary(data.owner_key));

      // === 投票 (Polls) ===
      case API_ACTIONS.POLL_LIST:
        return _createJsonResponse(handlePollAction("get", data));
      case API_ACTIONS.POLL_CREATE:
        return _createJsonResponse(handlePollAction("create", data));
      case API_ACTIONS.POLL_VOTE:
        return _createJsonResponse(handlePollAction("vote", data));
      case API_ACTIONS.POLL_ADD_OPTION:
        return _createJsonResponse(handlePollAction("add_option", data));
      case API_ACTIONS.POLL_DELETE_OPTION:
        return _createJsonResponse(handlePollAction("delete_option", data));
      case API_ACTIONS.POLL_CLOSE:
        return _createJsonResponse(handlePollAction("close", data));
      case API_ACTIONS.POLL_DELETE:
        return _createJsonResponse(handlePollAction("delete", data));

      // === 監控 (Logs/Heartbeat) ===
      case API_ACTIONS.LOG_UPLOAD:
        return _createJsonResponse(uploadLogs(data.logs, data.device_info));
      case API_ACTIONS.SYSTEM_HEARTBEAT:
        return _createJsonResponse(recordHeartbeat(data));

      // === 會員 (Auth) ===
      case API_ACTIONS.AUTH_REGISTER:
        return _createJsonResponse(authRegister(data));
      case API_ACTIONS.AUTH_LOGIN:
        return _createJsonResponse(authLogin(data));
      case API_ACTIONS.AUTH_VALIDATE:
        return _createJsonResponse(authValidate(data));
      case API_ACTIONS.AUTH_VERIFY_EMAIL:
        return _createJsonResponse(authVerifyEmail(data));
      case API_ACTIONS.AUTH_RESEND_CODE:
        return _createJsonResponse(authResendCode(data));
      case API_ACTIONS.AUTH_DELETE_USER:
        return _createJsonResponse(authDeleteUser(data));
      case API_ACTIONS.AUTH_REFRESH_TOKEN:
        return _createJsonResponse(authRefreshToken(data));

      default:
        return _createJsonResponse(
          _error(API_CODES.UNKNOWN_ACTION, "未知動作 (Unknown action)")
        );
    }
  } catch (error) {
    return _createJsonResponse(_error(API_CODES.SYSTEM_ERROR, error.message));
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
 * 建立成功回應
 * @param {Object|Array|null} data - 回傳資料
 * @param {string} [message="操作成功"] - 成功訊息
 * @returns {Object} { code: "0000", data, message }
 */
function _success(data, message = "操作成功") {
  return { code: API_CODES.SUCCESS, data, message };
}

/**
 * 建立錯誤回應
 * @param {string} code - 錯誤代碼 (使用 API_CODES)
 * @param {string} message - 錯誤訊息
 * @returns {Object} { code, data: null, message }
 */
function _error(code, message) {
  return { code, data: null, message };
}

/**
 * 建立標準 API 回應 (公開給 api_*.gs 使用)
 * @param {string} code - 回應代碼 (API_CODES)
 * @param {Object|null} data - 回傳資料
 * @param {string} [message=""] - 訊息
 * @returns {Object} { code, data, message }
 */
function buildResponse(code, data, message = "") {
  return { code, data, message };
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
    .replace(/\s+/g, "_")
    .replace(/[^a-z0-9_]/g, "");
}

/**
 * 將各種日期格式轉為標準 ISO 8601 字串
 * @private
 * @param {string|Date} value - 輸入的日期
 * @returns {string} ISO 8601 字串 (如 "2023-01-01T12:00:00.000Z")，若無效則回傳 ""
 */
function _toIsoString(value) {
  if (!value) return "";

  // 已經是 Date 物件
  if (value instanceof Date) {
    return value.toISOString();
  }

  // 嘗試解析字串
  if (typeof value === "string") {
    // 簡單判斷是否已經是 ISO 格式 (避免重複處理)
    // 但為了確保標準化，還是 parse 一次較保險
    const date = new Date(value);
    if (!isNaN(date.getTime())) {
      return date.toISOString();
    }
  }

  return "";
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

/**
 * 依據 Schema 格式化資料物件 (強制轉型)
 * @private
 * @param {Object} data - 資料物件
 * @param {string} schemaName - Schema 名稱 (Sheet Name)
 * @returns {Object} 格式化後的資料物件
 */
function _formatData(data, schemaName) {
  if (!data || typeof data !== "object") return data;

  const schema =
    typeof SHEET_SCHEMA !== "undefined" ? SHEET_SCHEMA[schemaName] : null;
  if (!schema) return data;

  for (const key in data) {
    if (Object.prototype.hasOwnProperty.call(data, key) && schema[key]) {
      const type = schema[key].type;
      const value = data[key];

      if (type === "text") {
        // 強制轉為字串 (除了 null/undefined)
        data[key] = value === null || value === undefined ? "" : String(value);
      } else if (type === "date") {
        // 日期統一轉為 ISO 8601 字串
        if (value instanceof Date) {
          data[key] = value.toISOString();
        } else if (typeof value === "string" && value.trim() !== "") {
          // 嘗試解析字串日期
          const parsedDate = new Date(value);
          if (!isNaN(parsedDate.getTime())) {
            data[key] = parsedDate.toISOString();
          }
        }
      } else if (type === "number") {
        // 強制轉為數字
        if (value === null || value === undefined || value === "") {
          data[key] = 0;
        } else {
          data[key] = Number(value);
          if (isNaN(data[key])) data[key] = 0;
        }
      }
    }
  }
  return data;
}
