/**
 * ============================================================
 * 揪團功能 API
 * ============================================================
 * @fileoverview 揪團活動 (Group Events) 相關 CRUD 操作
 *
 * API Actions:
 *   - group_event_list: 取得揪團列表
 *   - group_event_get: 取得揪團詳情
 *   - group_event_create: 建立揪團
 *   - group_event_update: 更新揪團
 *   - group_event_close: 關閉揪團
 *   - group_event_delete: 刪除揪團
 *   - group_event_apply: 報名揪團
 *   - group_event_cancel_application: 取消報名
 *   - group_event_review_application: 審核報名
 *   - group_event_my: 我的揪團
 *
 * 依賴: _config.gs, _codes.gs, _mapper.gs
 */

// ============================================================
// === PUBLIC API ===
// ============================================================

/**
 * 取得揪團列表
 * @param {Object} data - { filter, status, user_id }
 * @returns {Object} { code, data, message }
 */
function getGroupEvents(data) {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_GROUP_EVENTS);
  const appSheet = ss.getSheetByName(SHEET_GROUP_EVENT_APPLICATIONS);

  if (!sheet) {
    return _error(
      API_CODES.GROUP_EVENT_SHEET_MISSING,
      "缺少 GroupEvents 工作表"
    );
  }

  const userId = String(data.user_id || "");
  const statusFilter = data.status || "open";

  const eventsRaw = _getSheetDataAsObjects(sheet, HEADERS_GROUP_EVENTS);
  const appsRaw = appSheet
    ? _getSheetDataAsObjects(appSheet, HEADERS_GROUP_EVENT_APPLICATIONS)
    : [];

  // 取得按讚資料
  const likeSheet = ss.getSheetByName(SHEET_GROUP_EVENT_LIKES);
  const likesRaw = likeSheet
    ? _getSheetDataAsObjects(likeSheet, HEADERS_GROUP_EVENT_LIKES)
    : [];

  // 過濾條件
  let events = eventsRaw;
  if (statusFilter && statusFilter !== "all") {
    events = events.filter((e) => e.status === statusFilter);
  }

  // 使用 Mapper 轉換為 DTO，並計算聚合欄位
  const result = events.map((row) => {
    const eventApps = appsRaw.filter(
      (a) => a.event_id === row.id && a.status === "approved"
    );
    const myApp = userId
      ? appsRaw.find((a) => a.event_id === row.id && a.user_id === userId)
      : null;

    // 計算按讚
    const likeCount = likesRaw.filter((l) => l.event_id === row.id).length;
    const isLiked = userId
      ? likesRaw.some((l) => l.event_id === row.id && l.user_id === userId)
      : false;

    // 計算總報名數 (含 pending, approved) - 不含 cancelled/rejected
    const validApps = appsRaw.filter(
      (a) =>
        a.event_id === row.id &&
        (a.status === "approved" || a.status === "pending")
    );

    return Mapper.GroupEvent.toDTO(row, {
      application_count: eventApps.length, // approved count
      my_application_status: myApp ? myApp.status : null,
      is_liked: isLiked,
      like_count: likeCount,
      total_application_count: validApps.length,
    });
  });

  // 排序 (最新優先)
  result.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));

  return _success({ events: result }, "取得揪團列表成功");
}

/**
 * 取得揪團詳情
 * @param {Object} data - { event_id, user_id }
 * @returns {Object} { code, data, message }
 */
function getGroupEvent(data) {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_GROUP_EVENTS);
  const appSheet = ss.getSheetByName(SHEET_GROUP_EVENT_APPLICATIONS);

  const eventId = data.event_id;
  if (!eventId) {
    return _error(API_CODES.INVALID_PARAMS, "缺少 event_id");
  }

  const events = _getSheetDataAsObjects(sheet, HEADERS_GROUP_EVENTS);
  const row = events.find((e) => e.id === eventId);

  if (!row) {
    return _error(API_CODES.GROUP_EVENT_NOT_FOUND, "找不到此揪團活動");
  }

  // 計算報名人數
  const appsRaw = appSheet
    ? _getSheetDataAsObjects(appSheet, HEADERS_GROUP_EVENT_APPLICATIONS)
    : [];
  const eventApps = appsRaw.filter(
    (a) => a.event_id === eventId && a.status === "approved"
  );
  const userId = String(data.user_id || "");
  const myApp = userId
    ? appsRaw.find((a) => a.event_id === eventId && a.user_id === userId)
    : null;

  // 取得按讚資料
  const likeSheet = ss.getSheetByName(SHEET_GROUP_EVENT_LIKES);
  const likesRaw = likeSheet
    ? _getSheetDataAsObjects(likeSheet, HEADERS_GROUP_EVENT_LIKES)
    : [];
  const likeCount = likesRaw.filter((l) => l.event_id === eventId).length;
  const isLiked = userId
    ? likesRaw.some((l) => l.event_id === eventId && l.user_id === userId)
    : false;

  // 計算總報名數
  const validApps = appsRaw.filter(
    (a) =>
      a.event_id === eventId &&
      (a.status === "approved" || a.status === "pending")
  );

  const dto = Mapper.GroupEvent.toDTO(row, {
    application_count: eventApps.length,
    my_application_status: myApp ? myApp.status : null,
    is_liked: isLiked,
    like_count: likeCount,
    total_application_count: validApps.length,
  });

  return _success({ event: dto }, "取得揪團詳情成功");
}

/**
 * 建立揪團
 * @param {Object} data - 揪團資料
 * @returns {Object} { code, data, message }
 */
function createGroupEvent(data) {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_GROUP_EVENTS);

  if (!sheet) {
    return _error(
      API_CODES.GROUP_EVENT_SHEET_MISSING,
      "缺少 GroupEvents 工作表"
    );
  }

  const creatorId = String(data.creator_id || "");
  if (!creatorId || creatorId === "guest") {
    return _error(API_CODES.AUTH_REQUIRED, "請先登入以建立揪團");
  }

  // 取得建立者資訊
  const userInfo = _getUserInfoForGE(ss, creatorId);

  // 使用 Mapper 轉換為 Persistence 格式
  const pObj = Mapper.GroupEvent.toPersistence(data, creatorId, userInfo);
  const row = HEADERS_GROUP_EVENTS.map((h) =>
    pObj[h] !== undefined ? pObj[h] : ""
  );
  sheet.appendRow(row);

  return _success({ id: pObj.id }, "揪團建立成功");
}

/**
 * 更新揪團
 * @param {Object} data - { event_id, user_id, ...fields }
 * @returns {Object} { code, data, message }
 */
function updateGroupEvent(data) {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_GROUP_EVENTS);

  const eventId = data.event_id;
  const userId = String(data.user_id || "");

  const allData = sheet.getDataRange().getValues();
  const headers = allData[0];

  for (let i = 1; i < allData.length; i++) {
    if (allData[i][0] === eventId) {
      // 檢查權限 (只有建立者可更新)
      if (allData[i][1] !== userId) {
        return _error(
          API_CODES.GROUP_EVENT_PERMISSION_DENIED,
          "只有建立者可以編輯揪團"
        );
      }

      const now = new Date().toISOString();

      // 更新欄位 (部分更新)
      const updateFields = {
        title: data.title,
        description: data.description,
        location: data.location,
        start_date: data.start_date,
        end_date: data.end_date,
        max_members: data.max_members,
        approval_required:
          data.approval_required === true ? "TRUE" : data.approval_required,
        private_message: data.private_message,
        updated_at: "'" + now,
        updated_by: userId,
      };

      headers.forEach((h, idx) => {
        if (updateFields[h] !== undefined && updateFields[h] !== null) {
          sheet.getRange(i + 1, idx + 1).setValue(updateFields[h]);
        }
      });

      return _success(null, "揪團已更新");
    }
  }

  return _error(API_CODES.GROUP_EVENT_NOT_FOUND, "找不到此揪團");
}

/**
 * 關閉/取消揪團
 * @param {Object} data - { event_id, user_id, action }
 * @returns {Object} { code, data, message }
 */
function closeGroupEvent(data) {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_GROUP_EVENTS);

  const eventId = data.event_id;
  const userId = String(data.user_id || "");
  const action = data.action || "close"; // close or cancel

  const allData = sheet.getDataRange().getValues();
  const headers = allData[0];
  const statusIdx = headers.indexOf("status");
  const updatedAtIdx = headers.indexOf("updated_at");
  const updatedByIdx = headers.indexOf("updated_by");

  for (let i = 1; i < allData.length; i++) {
    if (allData[i][0] === eventId) {
      if (allData[i][1] !== userId) {
        return _error(
          API_CODES.GROUP_EVENT_PERMISSION_DENIED,
          "只有建立者可以關閉揪團"
        );
      }

      const newStatus = action === "cancel" ? "cancelled" : "closed";
      const now = new Date().toISOString();

      sheet.getRange(i + 1, statusIdx + 1).setValue(newStatus);
      sheet.getRange(i + 1, updatedAtIdx + 1).setValue("'" + now);
      sheet.getRange(i + 1, updatedByIdx + 1).setValue(userId);

      return _success(null, `揪團已${action === "cancel" ? "取消" : "關閉"}`);
    }
  }

  return _error(API_CODES.GROUP_EVENT_NOT_FOUND, "找不到此揪團");
}

/**
 * 刪除揪團 (Hard Delete)
 * @param {Object} data - { event_id, user_id }
 * @returns {Object} { code, data, message }
 */
function deleteGroupEvent(data) {
  const ss = getSpreadsheet();
  const eventSheet = ss.getSheetByName(SHEET_GROUP_EVENTS);
  const appSheet = ss.getSheetByName(SHEET_GROUP_EVENT_APPLICATIONS);

  const eventId = data.event_id;
  const userId = String(data.user_id || "");

  const allData = eventSheet.getDataRange().getValues();
  let eventRowIndex = -1;

  for (let i = 1; i < allData.length; i++) {
    if (allData[i][0] === eventId) {
      if (allData[i][1] !== userId) {
        return _error(
          API_CODES.GROUP_EVENT_PERMISSION_DENIED,
          "只有建立者可以刪除揪團"
        );
      }
      eventRowIndex = i + 1;
      break;
    }
  }

  if (eventRowIndex === -1) {
    return _error(API_CODES.GROUP_EVENT_NOT_FOUND, "找不到此揪團");
  }

  // 刪除相關報名紀錄
  if (appSheet) {
    const apps = appSheet.getDataRange().getValues();
    for (let i = apps.length - 1; i >= 1; i--) {
      if (apps[i][1] === eventId) {
        appSheet.deleteRow(i + 1);
      }
    }
  }

  // 刪除揪團
  eventSheet.deleteRow(eventRowIndex);

  return _success(null, "揪團已刪除");
}

/**
 * 報名揪團
 * @param {Object} data - { event_id, user_id, message }
 * @returns {Object} { code, data, message }
 */
function applyGroupEvent(data) {
  const ss = getSpreadsheet();
  const eventSheet = ss.getSheetByName(SHEET_GROUP_EVENTS);
  const appSheet = ss.getSheetByName(SHEET_GROUP_EVENT_APPLICATIONS);

  const eventId = data.event_id;
  const userId = String(data.user_id || "");

  if (!userId || userId === "guest") {
    return _error(API_CODES.AUTH_REQUIRED, "請先登入以報名揪團");
  }

  // 檢查活動存在與狀態
  const events = _getSheetDataAsObjects(eventSheet, HEADERS_GROUP_EVENTS);
  const event = events.find((e) => e.id === eventId);

  if (!event) {
    return _error(API_CODES.GROUP_EVENT_NOT_FOUND, "找不到此揪團活動");
  }

  if (event.status !== "open") {
    return _error(API_CODES.GROUP_EVENT_CLOSED, "此揪團已截止報名");
  }

  // 檢查是否已報名
  const apps = _getSheetDataAsObjects(
    appSheet,
    HEADERS_GROUP_EVENT_APPLICATIONS
  );
  const existingApp = apps.find(
    (a) =>
      a.event_id === eventId && a.user_id === userId && a.status !== "cancelled"
  );

  if (existingApp) {
    return _error(API_CODES.GROUP_EVENT_ALREADY_APPLIED, "您已報名過此揪團");
  }

  // 取得報名者資訊
  const userInfo = _getUserInfoForGE(ss, userId);

  // 依需審核決定初始狀態
  const initialStatus =
    event.approval_required === "TRUE" || event.approval_required === true
      ? "pending"
      : "approved";

  // 使用 Mapper 轉換為 Persistence 格式
  const appData = {
    event_id: eventId,
    user_id: userId,
    status: initialStatus,
    message: data.message || "",
  };
  const pObj = Mapper.GroupEventApplication.toPersistence(
    appData,
    userId,
    userInfo
  );
  const row = HEADERS_GROUP_EVENT_APPLICATIONS.map((h) =>
    pObj[h] !== undefined ? pObj[h] : ""
  );
  appSheet.appendRow(row);

  const msg =
    initialStatus === "pending" ? "報名申請已送出，等待審核" : "報名成功！";

  return _success({ id: pObj.id, status: initialStatus }, msg);
}

/**
 * 取消報名
 * @param {Object} data - { application_id, user_id }
 * @returns {Object} { code, data, message }
 */
function cancelGroupEventApplication(data) {
  const ss = getSpreadsheet();
  const appSheet = ss.getSheetByName(SHEET_GROUP_EVENT_APPLICATIONS);

  const appId = data.application_id;
  const userId = String(data.user_id || "");

  const allData = appSheet.getDataRange().getValues();
  const headers = allData[0];
  const statusIdx = headers.indexOf("status");
  const updatedAtIdx = headers.indexOf("updated_at");
  const updatedByIdx = headers.indexOf("updated_by");

  for (let i = 1; i < allData.length; i++) {
    if (allData[i][0] === appId) {
      if (allData[i][2] !== userId) {
        return _error(
          API_CODES.GROUP_EVENT_PERMISSION_DENIED,
          "只能取消自己的報名"
        );
      }

      const now = new Date().toISOString();
      appSheet.getRange(i + 1, statusIdx + 1).setValue("cancelled");
      appSheet.getRange(i + 1, updatedAtIdx + 1).setValue("'" + now);
      appSheet.getRange(i + 1, updatedByIdx + 1).setValue(userId);

      return _success(null, "已取消報名");
    }
  }

  return _error(
    API_CODES.GROUP_EVENT_APPLICATION_NOT_FOUND,
    "找不到此報名紀錄"
  );
}

/**
 * 審核報名 (Approve / Reject)
 * @param {Object} data - { application_id, action, user_id }
 * @returns {Object} { code, data, message }
 */
function reviewGroupEventApplication(data) {
  const ss = getSpreadsheet();
  const eventSheet = ss.getSheetByName(SHEET_GROUP_EVENTS);
  const appSheet = ss.getSheetByName(SHEET_GROUP_EVENT_APPLICATIONS);

  const appId = data.application_id;
  const action = data.action; // approve or reject
  const userId = String(data.user_id || "");

  if (!["approve", "reject"].includes(action)) {
    return _error(API_CODES.INVALID_PARAMS, "action 必須是 approve 或 reject");
  }

  const allData = appSheet.getDataRange().getValues();
  const headers = allData[0];
  let appRow = null;
  let appRowIndex = -1;

  for (let i = 1; i < allData.length; i++) {
    if (allData[i][0] === appId) {
      appRow = allData[i];
      appRowIndex = i + 1;
      break;
    }
  }

  if (!appRow) {
    return _error(
      API_CODES.GROUP_EVENT_APPLICATION_NOT_FOUND,
      "找不到此報名紀錄"
    );
  }

  const eventId = appRow[1];

  // 檢查是否為活動建立者
  const events = _getSheetDataAsObjects(eventSheet, HEADERS_GROUP_EVENTS);
  const event = events.find((e) => e.id === eventId);

  if (!event || event.creator_id !== userId) {
    return _error(
      API_CODES.GROUP_EVENT_PERMISSION_DENIED,
      "只有活動建立者可以審核報名"
    );
  }

  const newStatus = action === "approve" ? "approved" : "rejected";
  const now = new Date().toISOString();

  const statusIdx = headers.indexOf("status");
  const updatedAtIdx = headers.indexOf("updated_at");
  const updatedByIdx = headers.indexOf("updated_by");

  appSheet.getRange(appRowIndex, statusIdx + 1).setValue(newStatus);
  appSheet.getRange(appRowIndex, updatedAtIdx + 1).setValue("'" + now);
  appSheet.getRange(appRowIndex, updatedByIdx + 1).setValue(userId);

  return _success(null, `報名已${action === "approve" ? "通過" : "拒絕"}`);
}

/**
 * 我的揪團
 * @param {Object} data - { user_id, type: 'created' | 'applied' | 'liked' }
 * @returns {Object} { code, data, message }
 */
function getMyGroupEvents(data) {
  const ss = getSpreadsheet();
  const eventSheet = ss.getSheetByName(SHEET_GROUP_EVENTS);
  const appSheet = ss.getSheetByName(SHEET_GROUP_EVENT_APPLICATIONS);

  const userId = String(data.user_id || "");
  const type = data.type || "created";

  if (!userId || userId === "guest") {
    return _error(API_CODES.AUTH_REQUIRED, "請先登入");
  }

  const eventsRaw = _getSheetDataAsObjects(eventSheet, HEADERS_GROUP_EVENTS);
  const apps = appSheet
    ? _getSheetDataAsObjects(appSheet, HEADERS_GROUP_EVENT_APPLICATIONS)
    : [];

  let filteredEvents = [];

  switch (type) {
    case "created":
      filteredEvents = eventsRaw.filter((e) => e.creator_id === userId);
      break;

    case "applied":
      const myAppEventIds = apps
        .filter((a) => a.user_id === userId && a.status !== "cancelled")
        .map((a) => a.event_id);
      filteredEvents = eventsRaw.filter((e) => myAppEventIds.includes(e.id));
      break;

    case "liked":
      // TODO: 需要 GroupEventLikes 表
      filteredEvents = [];
      break;
  }

  // 使用 Mapper 轉換為 DTO
  const result = filteredEvents.map((row) => {
    const eventApps = apps.filter(
      (a) => a.event_id === row.id && a.status === "approved"
    );
    const myApp = apps.find(
      (a) => a.event_id === row.id && a.user_id === userId
    );

    return Mapper.GroupEvent.toDTO(row, {
      application_count: eventApps.length,
      my_application_status: myApp ? myApp.status : null,
      is_liked: false,
    });
  });

  result.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));

  return _success({ events: result }, "取得我的揪團成功");
}

// ============================================================
// 輔助函式 (Group Events 專用)
// ============================================================

/**
 * 將 Sheet 資料轉換為物件陣列 (使用 HEADERS 定義)
 * @param {Sheet} sheet - Google Sheet 物件
 * @param {string[]} headers - 欄位標頭陣列
 * @returns {Object[]} 物件陣列
 */
function _getSheetDataAsObjects(sheet, headers) {
  const data = sheet.getDataRange().getValues();
  if (data.length <= 1) return [];

  const sheetHeaders = data[0];
  return data.slice(1).map((row) => {
    const obj = {};
    sheetHeaders.forEach((h, i) => {
      obj[h] = row[i];
    });
    return obj;
  });
}

/**
 * 取得使用者資訊 (for GroupEvents)
 * @param {Spreadsheet} ss - 試算表物件
 * @param {string} userId - 使用者 ID
 * @returns {Object} { name, avatar }
 */
function _getUserInfoForGE(ss, userId) {
  try {
    const userSheet = ss.getSheetByName(SHEET_USERS);
    if (!userSheet) return { name: "", avatar: DEFAULT_AVATAR };

    const users = _getSheetDataAsObjects(userSheet, HEADERS_USERS);
    const user = users.find((u) => u.id === userId);

    return {
      name: user ? String(user.display_name || "") : "",
      avatar: user ? String(user.avatar || DEFAULT_AVATAR) : DEFAULT_AVATAR,
    };
  } catch (e) {
    return { name: "", avatar: DEFAULT_AVATAR };
  }
}

/**
 * 新增留言
 * @param {Object} data - { event_id, user_id, content }
 * @returns {Object} { code, data, message }
 */
function addGroupEventComment(data) {
  const ss = getSpreadsheet();
  const commentSheet = ss.getSheetByName(SHEET_GROUP_EVENT_COMMENTS);
  const eventSheet = ss.getSheetByName(SHEET_GROUP_EVENTS);

  if (!commentSheet) {
    return _error(
      API_CODES.GROUP_EVENT_SHEET_MISSING,
      "缺少 GroupEventComments 工作表"
    );
  }

  const eventId = data.event_id;
  const userId = String(data.user_id || "");
  const content = data.content;

  if (!userId || userId === "guest") {
    return _error(API_CODES.AUTH_REQUIRED, "請先登入以留言");
  }

  if (!eventId) {
    return _error(API_CODES.INVALID_PARAMS, "缺少 event_id");
  }

  if (!content) {
    return _error(API_CODES.INVALID_PARAMS, "缺少留言內容");
  }

  // 檢查揪團是否存在
  const events = _getSheetDataAsObjects(eventSheet, HEADERS_GROUP_EVENTS);
  const event = events.find((e) => e.id === eventId);
  if (!event) {
    return _error(API_CODES.GROUP_EVENT_NOT_FOUND, "找不到此揪團");
  }

  // 取得使用者資訊 (快照)
  const userInfo = _getUserInfoForGE(ss, userId);

  // 建立留言物件 (使用 Mapper)
  const commentData = {
    event_id: eventId,
    user_id: userId,
    content: content,
    user_name: userInfo.name, // 雖然 Mapper 會處理，但這裡為了明確傳入
    user_avatar: userInfo.avatar,
  };

  const pObj = Mapper.GroupEventComment.toPersistence(
    commentData,
    userId,
    userInfo
  );

  // 寫入 Sheet
  const row = HEADERS_GROUP_EVENT_COMMENTS.map((h) =>
    pObj[h] !== undefined ? pObj[h] : ""
  );
  commentSheet.appendRow(row);

  // 回傳 DTO
  const dto = Mapper.GroupEventComment.toDTO(pObj);

  return _success({ comment: dto }, "留言已新增");
}

/**
 * 取得留言列表
 * @param {Object} data - { event_id }
 * @returns {Object} { code, data, message }
 */
function getGroupEventComments(data) {
  const ss = getSpreadsheet();
  const commentSheet = ss.getSheetByName(SHEET_GROUP_EVENT_COMMENTS);

  if (!commentSheet) {
    return _error(
      API_CODES.GROUP_EVENT_SHEET_MISSING,
      "缺少 GroupEventComments 工作表"
    );
  }

  const eventId = data.event_id;
  if (!eventId) {
    return _error(API_CODES.INVALID_PARAMS, "缺少 event_id");
  }

  const commentsRaw = _getSheetDataAsObjects(
    commentSheet,
    HEADERS_GROUP_EVENT_COMMENTS
  );

  // 過濾並排序 (最早的在前)，並轉換為 DTO
  const comments = commentsRaw
    .filter((c) => c.event_id === eventId)
    .sort((a, b) => new Date(a.created_at) - new Date(b.created_at))
    .map((c) => Mapper.GroupEventComment.toDTO(c));

  return _success({ comments: comments }, "取得留言列表成功");
}

/**
 * 刪除留言
 * @param {Object} data - { comment_id, user_id }
 * @returns {Object} { code, data, message }
 */
function deleteGroupEventComment(data) {
  const ss = getSpreadsheet();
  const commentSheet = ss.getSheetByName(SHEET_GROUP_EVENT_COMMENTS);

  const commentId = data.comment_id;
  const userId = String(data.user_id || "");

  if (!userId || userId === "guest") {
    return _error(API_CODES.AUTH_REQUIRED, "權限不足");
  }

  const allData = commentSheet.getDataRange().getValues();
  let foundIndex = -1;

  for (let i = 1; i < allData.length; i++) {
    if (allData[i][0] === commentId) {
      // 權限檢查: 只能刪除自己的留言 (TODO: 揪團主也能刪除?)
      if (allData[i][2] !== userId) {
        return _error(
          API_CODES.GROUP_EVENT_PERMISSION_DENIED,
          "無法刪除他人留言"
        );
      }
      foundIndex = i + 1;
      break;
    }
  }

  if (foundIndex === -1) {
    return _error(API_CODES.GROUP_EVENT_COMMENT_NOT_FOUND, "找不到此留言");
  }

  commentSheet.deleteRow(foundIndex);
  return _success(null, "留言已刪除");
}

/**
 * 收藏揪團 (Like)
 * @param {Object} data - { event_id, user_id }
 * @returns {Object} { code, data, message }
 */
function likeGroupEvent(data) {
  const ss = getSpreadsheet();
  const likeSheet = ss.getSheetByName(SHEET_GROUP_EVENT_LIKES);
  const eventSheet = ss.getSheetByName(SHEET_GROUP_EVENTS);

  if (!likeSheet) {
    return _error(
      API_CODES.GROUP_EVENT_SHEET_MISSING,
      "缺少 GroupEventLikes 工作表"
    );
  }

  const eventId = data.event_id;
  const userId = String(data.user_id || "");

  if (!userId || userId === "guest") {
    return _error(API_CODES.AUTH_REQUIRED, "請先登入以收藏");
  }

  // 檢查揪團是否存在
  const events = _getSheetDataAsObjects(eventSheet, HEADERS_GROUP_EVENTS);
  const event = events.find((e) => e.id === eventId);
  if (!event) {
    return _error(API_CODES.GROUP_EVENT_NOT_FOUND, "找不到此揪團");
  }

  // 檢查是否已收藏
  const likes = _getSheetDataAsObjects(likeSheet, HEADERS_GROUP_EVENT_LIKES);
  const existingLike = likes.find(
    (l) => l.event_id === eventId && l.user_id === userId
  );

  if (existingLike) {
    return _success(null, "已收藏過此揪團");
  }

  // 新增收藏
  const likeData = {
    id: Utilities.getUuid(),
    event_id: eventId,
    user_id: userId,
    created_at: new Date().toISOString(),
    created_by: userId,
  };

  const row = HEADERS_GROUP_EVENT_LIKES.map((h) =>
    likeData[h] !== undefined ? likeData[h] : ""
  );
  likeSheet.appendRow(row);

  return _success({ id: likeData.id }, "已收藏");
}

/**
 * 取消收藏揪團 (Unlike)
 * @param {Object} data - { event_id, user_id }
 * @returns {Object} { code, data, message }
 */
function unlikeGroupEvent(data) {
  const ss = getSpreadsheet();
  const likeSheet = ss.getSheetByName(SHEET_GROUP_EVENT_LIKES);

  if (!likeSheet) {
    return _error(
      API_CODES.GROUP_EVENT_SHEET_MISSING,
      "缺少 GroupEventLikes 工作表"
    );
  }

  const eventId = data.event_id;
  const userId = String(data.user_id || "");

  if (!userId || userId === "guest") {
    return _error(API_CODES.AUTH_REQUIRED, "請先登入");
  }

  const allData = likeSheet.getDataRange().getValues();
  let foundIndex = -1;

  for (let i = 1; i < allData.length; i++) {
    // Column 2 is event_id (index 1), Column 3 is user_id (index 2)
    // Assuming HEADERS_GROUP_EVENT_LIKES order: id, event_id, user_id...
    if (allData[i][1] === eventId && allData[i][2] === userId) {
      foundIndex = i + 1;
      break;
    }
  }

  if (foundIndex === -1) {
    return _error(API_CODES.GROUP_EVENT_NOT_FOUND, "未收藏此揪團");
  }

  likeSheet.deleteRow(foundIndex);
  return _success(null, "已取消收藏");
}
