// ============================================================
// SummitMate - 投票功能 (Polls)
// ============================================================

/**
 * 處理投票相關的操作請求
 * @param {string} subAction - 子動作：'create', 'get', 'vote', 'add_option', 'delete_option'
 * @param {Object} data - 請求資料 payload
 * @returns {Object} { code, data, message }
 */
function handlePollAction(subAction, data) {
  switch (subAction) {
    case "create":
      return createPoll(data);
    case "get":
      return getPolls(data.user_id);
    case "vote":
      return votePoll(data);
    case "add_option":
      return addOption(data);
    case "delete_option":
      return deleteOption(data);
    case "close":
      return closePoll(data);
    case "delete":
      return deletePoll(data);
    default:
      return _error(API_CODES.UNKNOWN_ACTION, "未知的投票子動作: " + subAction);
  }
}

// ============================================================
// 核心邏輯函式
// ============================================================

/**
 * 建立新投票
 * @returns {Object} { code, data, message }
 */
function createPoll(data) {
  const ss = getSpreadsheet();
  let sheet = ss.getSheetByName("Polls");
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

  const pollId = data.poll_id || Utilities.getUuid();
  const createdAt = data.created_at || new Date().toISOString();

  // 讀取設定
  const config = data.config || {};
  const isAllowAdd = config.is_allow_add_option === true;
  const maxOptions = config.max_option_limit || 20;
  const allowMulti = config.allow_multiple_votes === true;
  const displayType = config.result_display_type || "realtime";

  // 新增投票主資料
  sheet.appendRow([
    pollId,
    data.title || "未命名投票",
    data.description || "",
    data.creator_id || "anonymous",
    "'" + createdAt,
    data.deadline ? "'" + data.deadline : "",
    isAllowAdd,
    maxOptions,
    allowMulti,
    displayType,
    "active",
  ]);

  // 新增初始選項
  if (data.initial_options && Array.isArray(data.initial_options)) {
    data.initial_options.forEach((optText) => {
      optionsSheet.appendRow([
        Utilities.getUuid(),
        pollId,
        optText,
        data.creator_id,
        "'" + createdAt,
        "",
      ]);
    });
  }

  return _success({ poll_id: pollId }, "投票建立成功");
}

/**
 * 取得投票列表 (包含選項與我的投票狀態)
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

  const polls = getDataAsObjects(pollSheet);
  const options = getDataAsObjects(optSheet);
  const votes = getDataAsObjects(voteSheet);

  // 建立投票對照表 Map
  const pollsMap = {};
  polls.forEach((p) => {
    p.is_allow_add_option =
      p.is_allow_add_option === true || p.is_allow_add_option === "TRUE";
    p.allow_multiple_votes =
      p.allow_multiple_votes === true || p.allow_multiple_votes === "TRUE";

    p.options = [];
    p.my_votes = [];
    p.total_votes = 0;
    pollsMap[p.poll_id] = p;
  });

  // 計算每個選項的票數與投票者
  const voteCounts = {};
  const voteVoters = {};

  votes.forEach((v) => {
    voteCounts[v.option_id] = (voteCounts[v.option_id] || 0) + 1;

    if (!voteVoters[v.option_id]) voteVoters[v.option_id] = [];
    voteVoters[v.option_id].push({
      user_id: v.user_id,
      user_name: v.user_name,
    });

    if (userId && v.user_id === userId && pollsMap[v.poll_id]) {
      pollsMap[v.poll_id].my_votes.push(v.option_id);
    }
  });

  options.forEach((o) => {
    if (pollsMap[o.poll_id]) {
      o.vote_count = voteCounts[o.option_id] || 0;
      o.voters = voteVoters[o.option_id] || [];
      pollsMap[o.poll_id].options.push(o);
      pollsMap[o.poll_id].total_votes += o.vote_count;
    }
  });

  return _success({ polls: Object.values(pollsMap) }, "取得投票列表成功");
}

/**
 * 執行投票動作
 * @returns {Object} { code, data, message }
 */
function votePoll(data) {
  const ss = getSpreadsheet();
  const voteSheet = ss.getSheetByName("PollVotes");
  const pollSheet = ss.getSheetByName("Polls");

  const pollId = data.poll_id;
  const optionIds = data.option_ids || [];
  const userId = data.user_id;

  if (!pollId || !userId || optionIds.length === 0) {
    return _error(API_CODES.INVALID_PARAMS, "資料不完整 (缺 ID 或選項)");
  }

  // 1. 檢查投票狀態
  const polls = getDataAsObjects(pollSheet);
  const poll = polls.find((p) => p.poll_id === pollId);
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
  const createdAt = new Date().toISOString();
  optionIds.forEach((optId) => {
    voteSheet.appendRow([
      Utilities.getUuid(),
      pollId,
      optId,
      userId,
      data.user_name || "Anonymous",
      "'" + createdAt,
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
  const poll = polls.find((p) => p.poll_id === pollId);
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

  optSheet.appendRow([
    Utilities.getUuid(),
    pollId,
    text,
    data.creator_id,
    "'" + new Date().toISOString(),
    "",
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

  const optId = data.option_id;

  const votes = getDataAsObjects(voteSheet);
  const hasVotes = votes.some((v) => v.option_id === optId);
  if (hasVotes) {
    return _error(API_CODES.POLL_OPTION_HAS_VOTES, "該選項已有票數，無法刪除");
  }

  const opts = optSheet.getDataRange().getValues();
  for (let i = 1; i < opts.length; i++) {
    if (opts[i][0] === optId) {
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
  const pollId = data.poll_id;
  const userId = data.user_id;

  const polls = pollSheet.getDataRange().getValues();
  for (let i = 1; i < polls.length; i++) {
    if (polls[i][0] === pollId) {
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

  const pollId = data.poll_id;
  const userId = data.user_id;

  // 1. Verify creator
  const polls = pollSheet.getDataRange().getValues();
  let pollRowIndex = -1;
  for (let i = 1; i < polls.length; i++) {
    if (polls[i][0] === pollId) {
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
    if (votes[i][1] === pollId) voteSheet.deleteRow(i + 1);
  }

  // 3. Delete Options
  const opts = optSheet.getDataRange().getValues();
  for (let i = opts.length - 1; i >= 1; i--) {
    if (opts[i][1] === pollId) optSheet.deleteRow(i + 1);
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
  return data.slice(1).map((row) => {
    const obj = {};
    headers.forEach((h, i) => {
      obj[h] = row[i];
    });
    return obj;
  });
}

/**
 * 初始化投票相關工作表
 * (請手動執行此函式一次以建立工作表)
 */
function setupPollSheets() {
  const ss = getSpreadsheet();

  if (!ss.getSheetByName("Polls")) {
    const s = ss.insertSheet("Polls");
    s.appendRow([
      "poll_id",
      "title",
      "description",
      "creator_id",
      "created_at",
      "deadline",
      "is_allow_add_option",
      "max_option_limit",
      "allow_multiple_votes",
      "result_display_type",
      "status",
    ]);
  }

  if (!ss.getSheetByName("PollOptions")) {
    const s = ss.insertSheet("PollOptions");
    s.appendRow([
      "option_id",
      "poll_id",
      "text",
      "creator_id",
      "created_at",
      "image_url",
    ]);
  }

  if (!ss.getSheetByName("PollVotes")) {
    const s = ss.insertSheet("PollVotes");
    s.appendRow([
      "vote_id",
      "poll_id",
      "option_id",
      "user_id",
      "user_name",
      "created_at",
    ]);
  }

  Logger.log("投票工作表 (Polls, Options, Votes) 初始化完成");
}
