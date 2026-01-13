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

  // 解析 Access Token 取得 User ID
  if (!tripData.accessToken) {
    return _error(API_CODES.AUTH_REQUIRED, "缺少認證 Token (createTrip)");
  }

  const validation = validateToken(tripData.accessToken);
  if (!validation.isValid) {
    return _error(API_CODES.AUTH_ACCESS_TOKEN_INVALID, "Token 無效或已過期");
  }

  const creatorId = validation.payload.uid;
  if (!creatorId) {
    return _error(API_CODES.AUTH_ACCESS_TOKEN_INVALID, "Token Payload 異常");
  }

  // 順序需與 HEADERS_TRIPS 一致
  // [id, name, start_date, end_date, description, cover_image, is_active, day_names, created_at, created_by, updated_at, updated_by]
  sheet.appendRow([
    id,
    String(tripData.name || "新行程"),
    _toIsoString(tripData.start_date || now),
    _toIsoString(tripData.end_date || ""),
    String(tripData.description || ""),
    String(tripData.cover_image || ""),
    tripData.is_active || false,
    JSON.stringify(tripData.day_names || []),
    now,
    String(creatorId),
    now,
    String(creatorId),
  ]);

  // 自動將建立者加入成員列表 (Role: Leader)
  if (creatorId) {
    updateMemberRole({
      trip_id: id,
      user_id: creatorId,
      role: "leader",
      operator_id: creatorId,
    });
  }

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
  
  // 找出需要自動更新的欄位索引
  const updatedAtIdx = headers.indexOf("updated_at");
  const updatedByIdx = headers.indexOf("updated_by");
  
  // 取得 Operator ID (if available, passed via tripData.accessToken usually, but updateTrip signature doesn't enforce it yet? 
  // Standard practice: tripData should contain accessToken or we rely on 'updated_by' being passed in payload, or we skip updated_by if unknown.
  // For now, let's proceed with updated_at.)
  const now = new Date().toISOString();

  for (let i = 1; i < data.length; i++) {
    if (data[i][idIndex] === tripData.id) {
      // 更新該列
      headers.forEach((header, colIndex) => {
        // Skip id, created_at, created_by (immutable usually)
        if (
          tripData[header] !== undefined &&
          header !== "id" &&
          header !== "created_at" &&
          header !== "created_by"
        ) {
          let value = tripData[header];
          // 如果是日期欄位，強制轉為 ISO String
          if (schema && schema[header] && schema[header].type === "date") {
            value = _toIsoString(value);
          }
          sheet.getRange(i + 1, colIndex + 1).setValue(value);
        }
      });
      
      // 自動更新 updated_at
      if (updatedAtIdx >= 0) {
        sheet.getRange(i + 1, updatedAtIdx + 1).setValue(now);
      }
      
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

    // 構建 Trip Row - [id, name, start, end, desc, cover, active, day_names, created_at, created_by, updated_at, updated_by]
    var tripRowData = [
      tripId,
      String(trip.name || ""),
      _toIsoString(trip.start_date || trip.startDate),
      _toIsoString(trip.end_date || trip.endDate),
      String(trip.description || ""),
      String(trip.cover_image || trip.coverImage || ""),
      trip.is_active || trip.isActive || false,
      JSON.stringify(trip.day_names || []), // day_names
      createdAt, // created_at
      String(trip.created_by || ""),
      _toIsoString(now), // updated_at
      String(trip.updated_by || ""),
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
        // [id, trip_id, day, name, est_time, altitude, distance, note, image_asset, is_checked_in, checked_in_at, created_at, created_by, updated_at, updated_by]
        newItinRows.push([
          item.id || Utilities.getUuid(),
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
          createdAt, // created_at (default to trip creation or now)
          String(item.created_by || ""),
          _toIsoString(now), // updated_at
          String(item.updated_by || ""),
        ]);
      });
    }

    // 3. Clear & Insert Gear
    var gearSheet = _getSheetOrCreate(SHEET_TRIP_GEAR, HEADERS_TRIP_GEAR);
    var gearRows = gearSheet.getDataRange().getValues();
    var newGearRows = [];
    var gearTargetColCount = HEADERS_TRIP_GEAR.length;
    

    if (gear && gear.length > 0) {
      gear.forEach(function (item) {
        // [id, trip_id, name, weight, category, is_checked, quantity, created_at, created_by, updated_at, updated_by]
        newGearRows.push([
          item.id || Utilities.getUuid(),
          tripId,
          item.name || "",
          item.weight || 0,
          item.category || "Other",
          item.is_checked || item.isChecked || false,
          item.quantity || 1,
          createdAt, // created_at
          "", // created_by
          _toIsoString(now), // updated_at
          "", // updated_by
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

/**
 * 取得行程成員列表
 * @param {string} tripId
 * @returns {Object} { code, data, message }
 */
function getTripMembers(tripId) {
  if (!tripId) {
    return _error(API_CODES.INVALID_PARAMS, "Trip ID is required");
  }

  const ss = getSpreadsheet();
  const tmSheet = ss.getSheetByName(SHEET_TRIP_MEMBERS);
  const uSheet = ss.getSheetByName(SHEET_USERS);

  // 若尚未有成員表，回傳空列表 (或自動建立)
  if (!tmSheet) {
    return _success({ members: [] }, "尚無成員");
  }

  // 1. 取得該行程的所有成員關聯
  const tmData = tmSheet.getDataRange().getValues();
  // Headers: id, trip_id, user_id, role_code, created_at, updated_at
  // Index:   0,  1,       2,       3,         4,          5

  const tripMembers = [];
  // Skip header
  for (let i = 1; i < tmData.length; i++) {
    if (tmData[i][1] === tripId) {
      tripMembers.push({
        relationship_id: tmData[i][0],
        user_id: tmData[i][2],
        role_code: tmData[i][3],
      });
    }
  }

  if (tripMembers.length === 0) {
    return _success({ members: [] });
  }

  // 2. 取得使用者詳細資料 (Join Users)
  const userMap = {};
  if (uSheet) {
    const uData = uSheet.getDataRange().getValues();
    const h = uData[0];
    const idx = {
      id: h.indexOf("id"),
      name: h.indexOf("display_name"),
      avatar: h.indexOf("avatar"),
      email: h.indexOf("email"),
    };

    for (let i = 1; i < uData.length; i++) {
      const uid = uData[i][idx.id];
      userMap[uid] = {
        display_name: uData[i][idx.name],
        avatar: uData[i][idx.avatar],
        email: uData[i][idx.email],
      };
    }
  }

  // 3. 組合結果
  const result = tripMembers.map((m) => {
    const u = userMap[m.user_id] || {};
    return {
      id: m.user_id, // Client expects member list with User IDs primarily
      relationship_id: m.relationship_id,
      role_code: m.role_code,
      display_name: u.display_name || "Unknown",
      avatar: u.avatar || DEFAULT_AVATAR,
      email: u.email || "",
    };
  });

  return _success({ members: result });
}

/**
 * 更新成員角色
 * @param {Object} payload - { trip_id, user_id, role, operator_id? }
 * @returns {Object}
 */
function updateMemberRole(payload) {
  const { trip_id, user_id, role, operator_id } = payload;
  if (!trip_id || !user_id || !role) {
    return _error(API_CODES.INVALID_PARAMS, "缺少必要參數");
  }

  const ss = getSpreadsheet();
  const sheet = _getSheetOrCreate(SHEET_TRIP_MEMBERS, HEADERS_TRIP_MEMBERS);
  const data = sheet.getDataRange().getValues();
  
  // Find column indices
  const headers = data[0];
  const tripIdIdx = headers.indexOf("trip_id");
  const userIdIdx = headers.indexOf("user_id");
  const roleIdx = headers.indexOf("role_code");
  const updatedAtIdx = headers.indexOf("updated_at");
  const updatedByIdx = headers.indexOf("updated_by");
  const createdByIdx = headers.indexOf("created_by");

  // 尋找是否已存在
  let found = false;
  const now = new Date().toISOString();
  
  for (let i = 1; i < data.length; i++) {
    if (data[i][tripIdIdx] === trip_id && data[i][userIdIdx] === user_id) {
      // Update role
      sheet.getRange(i + 1, roleIdx + 1).setValue(role);
      if (updatedAtIdx >= 0) sheet.getRange(i + 1, updatedAtIdx + 1).setValue(now);
      if (updatedByIdx >= 0 && operator_id) sheet.getRange(i + 1, updatedByIdx + 1).setValue(operator_id);
      
      found = true;
      break;
    }
  }

  if (!found) {
    // Insert new
    // HEADERS: [id, trip_id, user_id, role_code, created_at, created_by, updated_at, updated_by]
    const row = [];
    // Initialize row with strings
    HEADERS_TRIP_MEMBERS.forEach(() => row.push(""));
    
    const h = HEADERS_TRIP_MEMBERS;
    row[h.indexOf("id")] = Utilities.getUuid();
    row[h.indexOf("trip_id")] = trip_id;
    row[h.indexOf("user_id")] = user_id;
    row[h.indexOf("role_code")] = role;
    row[h.indexOf("created_at")] = now;
    if (h.indexOf("created_by") >= 0) row[h.indexOf("created_by")] = operator_id || "";
    row[h.indexOf("updated_at")] = now;
    if (h.indexOf("updated_by") >= 0) row[h.indexOf("updated_by")] = operator_id || "";
    
    sheet.appendRow(row);
  }

  return _success(null, "成員角色已更新");
}

/**
 * 移除成員
 * @param {Object} payload - { trip_id, user_id }
 * @returns {Object}
 */
function removeMember(payload) {
  const { trip_id, user_id } = payload;
  if (!trip_id || !user_id) {
    return _error(API_CODES.INVALID_PARAMS, "缺少必要參數");
  }

  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_TRIP_MEMBERS);
  if (!sheet) return _error(API_CODES.TRIP_NOT_FOUND, "成員表不存在");

  const data = sheet.getDataRange().getValues();

  for (let i = 1; i < data.length; i++) {
    if (data[i][1] === trip_id && data[i][2] === user_id) {
      sheet.deleteRow(i + 1);
      return _success(null, "成員已移除");
    }
  }

  return _success(null, "成員已移除");
}

/**
 * 透過 Email 搜尋使用者
 * @param {Object} payload - { email }
 * @returns {Object} { user: { id, display_name, email, avatar } }
 */
function searchUserByEmail(payload) {
  const { email } = payload;
  if (!email) {
    return _error(API_CODES.INVALID_PARAMS, "缺少 email 參數");
  }

  const ss = getSpreadsheet();
  const uSheet = ss.getSheetByName(SHEET_USERS);

  // Strict check: Verify it looks like an email? (Optional but requested strictness)
  // const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  // if (!emailRegex.test(email)) {
  //   return _error(API_CODES.INVALID_PARAMS, "Email 格式不正確");
  // }
  // User asked for separation to avoid cross-match. Just searching by email is enough.

  const result = _findUserByEmail(uSheet, email);
  if (!result) {
    return _error(API_CODES.TRIP_USER_NOT_FOUND, "找不到此 Email 的使用者");
  }

  return _success({
    user: {
      id: result.user.id,
      display_name: result.user.display_name,
      email: result.user.email,
      avatar: result.user.avatar,
    },
  });
}

/**
 * 透過 User ID 搜尋使用者
 * @param {Object} payload - { user_id }
 * @returns {Object} { user: { id, display_name, email, avatar } }
 */
function searchUserById(payload) {
  const { user_id } = payload;
  if (!user_id) {
    return _error(API_CODES.INVALID_PARAMS, "缺少 user_id 參數");
  }

  const ss = getSpreadsheet();
  const uSheet = ss.getSheetByName(SHEET_USERS);

  const result = _findUserById(uSheet, user_id);
  if (!result) {
    return _error(API_CODES.TRIP_USER_NOT_FOUND, "找不到此 User ID 的使用者");
  }

  return _success({
    user: {
      id: result.user.id,
      display_name: result.user.display_name,
      email: result.user.email,
      avatar: result.user.avatar,
    },
  });
}

/**
 * 新增成員 (透過 Email)
 * @param {Object} payload - { trip_id, email, role? }
 * @returns {Object}
 */
function addMemberByEmail(payload) {
  const { trip_id, email, role } = payload;

  if (!trip_id) {
    return _error(API_CODES.INVALID_PARAMS, "缺少 trip_id");
  }
  if (!email) {
    return _error(API_CODES.INVALID_PARAMS, "缺少 email");
  }

  const ss = getSpreadsheet();
  const uSheet = ss.getSheetByName(SHEET_USERS);

  // 搜尋 USER ID
  const result = _findUserByEmail(uSheet, email);
  if (!result) {
    return _error(API_CODES.TRIP_USER_NOT_FOUND, "找不到此 Email 對應的使用者");
  }

  const targetUserId = result.user.id;
  const targetRole = role || "member";

  return updateMemberRole({
    trip_id: trip_id,
    user_id: targetUserId,
    role: targetRole,
  });
}

/**
 * 新增成員 (透過 User ID)
 * @param {Object} payload - { trip_id, user_id, role? }
 * @returns {Object}
 */
function addMemberById(payload) {
  const { trip_id, user_id, role } = payload;

  if (!trip_id) {
    return _error(API_CODES.INVALID_PARAMS, "缺少 trip_id");
  }
  if (!user_id) {
    return _error(API_CODES.INVALID_PARAMS, "缺少 user_id");
  }

  // 驗證 User 是否存在 (可選)
  const ss = getSpreadsheet();
  const uSheet = ss.getSheetByName(SHEET_USERS);
  const check = _findUserById(uSheet, user_id);
  if (!check) {
    return _error(API_CODES.TRIP_USER_NOT_FOUND, "找不到此 User ID");
  }

  const targetRole = role || "member";

  return updateMemberRole({
    trip_id: trip_id,
    user_id: user_id,
    role: targetRole,
  });
}

/**
 * 取得行程成員列表
 * @param {Object} payload - { trip_id }
 * @returns {Object} { members: [{ relationship_id, user_id, role_code }] }
 */
function getTripMembers(payload) {
  const { trip_id: tripId } = payload;
  if (!tripId) {
    return _error(API_CODES.INVALID_PARAMS, "缺少 trip_id 參數");
  }

  const ss = getSpreadsheet();
  const tmSheet = ss.getSheetByName(SHEET_TRIP_MEMBERS);
  if (!tmSheet) {
    return _error(API_CODES.TRIP_NOT_FOUND, "成員表不存在");
  }

  // 1. 取得該行程的所有成員關聯
  const tmData = tmSheet.getDataRange().getValues();
  // Dynamic Headers
  const tmHeaders = tmData[0];
  const idx = {
    id: tmHeaders.indexOf("id"),
    trip_id: tmHeaders.indexOf("trip_id"),
    user_id: tmHeaders.indexOf("user_id"),
    role_code: tmHeaders.indexOf("role_code"),
  };

  const tripMembers = [];
  // Skip header
  for (let i = 1; i < tmData.length; i++) {
    if (tmData[i][idx.trip_id] === tripId) {
      tripMembers.push({
        relationship_id: tmData[i][idx.id],
        user_id: tmData[i][idx.user_id],
        role_code: tmData[i][idx.role_code],
      });
    }
  }

  return _success({ members: tripMembers });
}

/**
 * 內部 Helper: 透過 ID 尋找使用者
 * @param {Sheet} sheet
 * @param {string} id
 * @returns {Object|null} { user, rowIndex }
 */
function _findUserById(sheet, id) {
  const data = sheet.getDataRange().getValues();
  const headers = data[0];
  const idx = headers.indexOf("id"); // 通常是 0

  for (let i = 1; i < data.length; i++) {
    if (data[i][idx] === id) {
      // 讀取整列資料轉 Object
      const user = {};
      headers.forEach((h, col) => {
        user[h] = data[i][col];
      });
      return { user: user, rowIndex: i + 1 };
    }
  }
  return null;
}
