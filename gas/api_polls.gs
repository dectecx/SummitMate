/**
 * ============================================================
 * 投票功能 API
 * ============================================================
 * @fileoverview 投票 (Polls) 相關 CRUD 操作
 *
 * API Actions:
 *   - poll_create: 建立投票
 *   - poll_list: 取得投票列表
 *   - poll_vote: 執行投票
 *   - poll_add_option: 新增選項
 *   - poll_delete_option: 刪除選項
 *   - poll_close: 關閉投票
 *   - poll_delete: 刪除投票
 */

// ============================================================
// === PUBLIC API ===
// ============================================================

/**
 * 建立新投票
 * @param {Object} data - 投票資料
 * @returns {Object} { code, data, message }
 */
function createPoll(data) {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName("Polls");
  if (!sheet) {
    return _error(
      API_CODES.POLL_SHEET_MISSING,
      "缺少 Polls 工作表，請先執行 setupPollSheets()。"
    );
  }

  const optionsSheet = ss.getSheetByName("PollOptions");
  if (!optionsSheet) {
    return _error(API_CODES.POLL_SHEET_MISSING, "缺少 PollOptions 工作表。");
  }

  // 準備資料
  const pollId = data.id || Utilities.getUuid();
  const creatorId = String(data.creator_id || "anonymous");

  // 讀取設定
  const config = data.config || {};
  const pollData = {
    id: pollId,
    title: data.title,
    description: data.description,
    creator_id: creatorId,
    deadline: data.deadline,
    is_allow_add_option: config.is_allow_add_option === true,
    max_option_limit: config.max_option_limit || 20,
    allow_multiple_votes: config.allow_multiple_votes === true,
    result_display_type: config.result_display_type || "realtime",
    status: "active",
  };

  // 使用 Mapper 轉換為 Persistence 格式
  const pObj = Mapper.Poll.toPersistence(pollData, creatorId);
  const row = HEADERS_POLLS.map((h) => (pObj[h] !== undefined ? pObj[h] : ""));
  sheet.appendRow(row);

  // 新增初始選項
  if (data.initial_options && Array.isArray(data.initial_options)) {
    const now = new Date().toISOString();
    data.initial_options.forEach((optText) => {
      const optId = Utilities.getUuid();
      const optRow = [
        optId, // id (PK)
        pollId, // poll_id (FK)
        String(optText), // text
        creatorId, // creator_id
        now, // created_at
        creatorId, // created_by
        now, // updated_at
        creatorId, // updated_by
      ];
      optionsSheet.appendRow(optRow);
    });
  }

  return _success({ id: pollId }, "投票建立成功");
}

/**
 * 取得投票列表 (包含選項與我的投票狀態)
 * @param {string} [userId] - 可選，當前使用者 ID (用於計算 my_votes)
 * @returns {Object} { code, data, message }
 */
function getPolls(userId) {
  const ss = getSpreadsheet();
  const pollSheet = ss.getSheetByName("Polls");
  const optSheet = ss.getSheetByName("PollOptions");
  const voteSheet = ss.getSheetByName("PollVotes");

  if (!pollSheet || !optSheet || !voteSheet) {
    return _error(API_CODES.POLL_SHEET_MISSING, "相關工作表缺失");
  }

  const pollsRaw = getDataAsObjects(pollSheet);
  const optionsRaw = getDataAsObjects(optSheet);
  const votesRaw = getDataAsObjects(voteSheet);

  // 使用 Mapper 轉換為 DTO
  const polls = pollsRaw.map((pollRow) =>
    Mapper.Poll.toDTO(pollRow, optionsRaw, votesRaw, userId)
  );

  return _success({ polls }, "取得投票列表成功");
}

/**
 * 執行投票動作
 * @returns {Object} { code, data, message }
 */
function votePoll(data) {
  const ss = getSpreadsheet();
  const voteSheet = ss.getSheetByName("PollVotes");
  const pollSheet = ss.getSheetByName("Polls");

  const pollId = data.poll_id; // FK to Poll
  const optionIds = data.option_ids || [];
  const userId = data.user_id;

  if (!pollId || !userId || optionIds.length === 0) {
    return _error(API_CODES.INVALID_PARAMS, "資料不完整 (缺 ID 或選項)");
  }

  // 1. 檢查投票狀態
  const polls = getDataAsObjects(pollSheet);
  const poll = polls.find((p) => p.id === pollId);
  if (!poll) {
    return _error(API_CODES.POLL_NOT_FOUND, "找不到此投票");
  }

  if (poll.status !== "active") {
    return _error(API_CODES.POLL_CLOSED, "此投票已關閉");
  }

  if (poll.deadline) {
    const deadline = new Date(poll.deadline).getTime();
    if (new Date().getTime() > deadline) {
      return _error(API_CODES.POLL_EXPIRED, "此投票已過期");
    }
  }

  // 2. 刪除舊投票紀錄
  const allVotes = voteSheet.getDataRange().getValues();
  const toDelete = [];

  for (let i = allVotes.length - 1; i >= 1; i--) {
    const row = allVotes[i];
    if (row[1] === pollId && row[3] === userId) {
      toDelete.push(i + 1);
    }
  }

  toDelete.forEach((rowIndex) => voteSheet.deleteRow(rowIndex));

  // 3. 寫入新票
  const now = new Date().toISOString();
  const createdBy = String(data.user_id || UUID_SYSTEM);

  optionIds.forEach((optId) => {
    voteSheet.appendRow([
      Utilities.getUuid(),
      pollId,
      optId,
      userId,
      String(data.user_name || "Anonymous"),
      "'" + now,
      createdBy,
      "'" + now,
      createdBy,
    ]);
  });

  return _success(null, "投票成功");
}

/**
 * 新增投票選項
 * @returns {Object} { code, data, message }
 */
function addOption(data) {
  const ss = getSpreadsheet();
  const optSheet = ss.getSheetByName("PollOptions");
  const pollSheet = ss.getSheetByName("Polls");

  const pollId = data.poll_id;
  const text = data.text;

  const polls = getDataAsObjects(pollSheet);
  const poll = polls.find((p) => p.id === pollId);
  if (!poll) {
    return _error(API_CODES.POLL_NOT_FOUND, "找不到此投票");
  }

  const isAllowAdd =
    poll.is_allow_add_option === true || poll.is_allow_add_option === "TRUE";
  if (!isAllowAdd) {
    return _error(API_CODES.POLL_ADD_OPTION_DISABLED, "此投票不允許新增選項");
  }

  const opts = getDataAsObjects(optSheet);
  const currentCount = opts.filter((o) => o.poll_id === pollId).length;
  if (currentCount >= (poll.max_option_limit || 20)) {
    return _error(API_CODES.POLL_OPTION_LIMIT, "已達選項數量上限");
  }

  const now = new Date().toISOString();
  const createdBy = String(data.user_id || UUID_SYSTEM);

  optSheet.appendRow([
    Utilities.getUuid(), // id (PK)
    pollId, // FK
    String(text || ""),
    createdBy, // creator_id
    "'" + now, // created_at
    createdBy, // created_by
    "'" + now, // updated_at
    createdBy, // updated_by
  ]);

  return _success(null, "選項已新增");
}

/**
 * 刪除投票選項
 * @returns {Object} { code, data, message }
 */
function deleteOption(data) {
  const ss = getSpreadsheet();
  const optSheet = ss.getSheetByName("PollOptions");
  const voteSheet = ss.getSheetByName("PollVotes");

  const id = data.id || data.option_id; // Compatible input

  const votes = getDataAsObjects(voteSheet);
  const hasVotes = votes.some((v) => v.option_id === id);
  if (hasVotes) {
    return _error(API_CODES.POLL_OPTION_HAS_VOTES, "該選項已有票數，無法刪除");
  }

  const opts = optSheet.getDataRange().getValues();
  for (let i = 1; i < opts.length; i++) {
    if (opts[i][0] === id) {
      optSheet.deleteRow(i + 1);
      return _success(null, "選項已刪除");
    }
  }

  return _error(API_CODES.POLL_OPTION_NOT_FOUND, "找不到該選項");
}

/**
 * 關閉投票
 * @returns {Object} { code, data, message }
 */
function closePoll(data) {
  const ss = getSpreadsheet();
  const pollSheet = ss.getSheetByName("Polls");
  const id = data.id || data.poll_id;
  const userId = data.user_id;

  const polls = pollSheet.getDataRange().getValues();
  for (let i = 1; i < polls.length; i++) {
    if (polls[i][0] === id) {
      if (polls[i][3] !== userId) {
        return _error(API_CODES.POLL_CREATOR_ONLY, "只有發起人可以關閉投票");
      }

      pollSheet.getRange(i + 1, 11).setValue("ended");
      return _success(null, "投票已關閉");
    }
  }

  return _error(API_CODES.POLL_NOT_FOUND, "找不到此投票");
}

/**
 * 刪除投票 (Hard Delete)
 * @returns {Object} { code, data, message }
 */
function deletePoll(data) {
  const ss = getSpreadsheet();
  const pollSheet = ss.getSheetByName("Polls");
  const optSheet = ss.getSheetByName("PollOptions");
  const voteSheet = ss.getSheetByName("PollVotes");

  const id = data.id || data.poll_id;
  const userId = data.user_id;

  // 1. Verify creator
  const polls = pollSheet.getDataRange().getValues();
  let pollRowIndex = -1;
  for (let i = 1; i < polls.length; i++) {
    if (polls[i][0] === id) {
      if (polls[i][3] !== userId) {
        return _error(API_CODES.POLL_CREATOR_ONLY, "只有發起人可以刪除投票");
      }
      pollRowIndex = i + 1;
      break;
    }
  }

  if (pollRowIndex === -1) {
    return _error(API_CODES.POLL_NOT_FOUND, "找不到此投票");
  }

  // 2. Delete Votes
  const votes = voteSheet.getDataRange().getValues();
  for (let i = votes.length - 1; i >= 1; i--) {
    if (votes[i][1] === id) voteSheet.deleteRow(i + 1);
  }

  // 3. Delete Options
  const opts = optSheet.getDataRange().getValues();
  for (let i = opts.length - 1; i >= 1; i--) {
    if (opts[i][1] === id) optSheet.deleteRow(i + 1);
  }

  // 4. Delete Poll
  pollSheet.deleteRow(pollRowIndex);

  return _success(null, "投票已刪除");
}

// ============================================================
// 輔助函式
// ============================================================

/**
 * 將 Sheet 資料轉換為物件陣列
 */
function getDataAsObjects(sheet) {
  const data = sheet.getDataRange().getValues();
  if (data.length <= 1) return [];

  const headers = data[0];
  const sheetName = sheet.getName();

  return data.slice(1).map((row) => {
    const obj = {};
    headers.forEach((h, i) => {
      obj[h] = row[i];
    });
    return _formatData(obj, sheetName);
  });
}

/**
 * 初始化投票相關工作表
 * (請手動執行此函式一次以建立工作表)
 */
function setupPollSheets() {
  const ss = getSpreadsheet();

  if (!ss.getSheetByName("Polls")) {
    _setupSheet(ss, "Polls", HEADERS_POLLS);
  }

  if (!ss.getSheetByName("PollOptions")) {
    _setupSheet(ss, "PollOptions", HEADERS_POLL_OPTIONS);
  }

  if (!ss.getSheetByName("PollVotes")) {
    _setupSheet(ss, "PollVotes", HEADERS_POLL_VOTES);
  }

  Logger.log("投票工作表 (Polls, Options, Votes) 初始化完成");
}
