// ============================================================
// SummitMate - 投票功能 (Polls)
// ============================================================

/**
 * 處理投票相關的操作請求
 * @param {string} subAction - 子動作：'create', 'get', 'vote', 'add_option', 'delete_option'
 * @param {Object} data - 請求資料 payload
 */
function handlePollAction(subAction, data) {
  switch (subAction) {
    case 'create':
      return createPoll(data);
    case 'get':
      return getPolls(data.user_id);
    case 'vote':
      return votePoll(data);
    case 'add_option':
      return addOption(data);
    case 'delete_option':
      return deleteOption(data);
    default:
      return { error: '未知的投票子動作: ' + subAction };
  }
}

// ============================================================
// 核心邏輯函式
// ============================================================

/**
 * 建立新投票
 */
function createPoll(data) {
  const ss = getSpreadsheet();
  let sheet = ss.getSheetByName('Polls');
  if (!sheet) return { success: false, error: '缺少 Polls 工作表，請先執行 setupPollSheets()。' };

  const optionsSheet = ss.getSheetByName('PollOptions');
  if (!optionsSheet) return { success: false, error: '缺少 PollOptions 工作表。' };

  const pollId = data.poll_id || Utilities.getUuid();
  const createdAt = data.created_at || new Date().toISOString();

  // 讀取設定
  const config = data.config || {};
  const isAllowAdd = config.is_allow_add_option === true;
  const maxOptions = config.max_option_limit || 20;
  const allowMulti = config.allow_multiple_votes === true;
  const displayType = config.result_display_type || 'realtime'; // 'realtime' (即時), 'blind' (盲投)

  // 新增投票主資料
  // 欄位: poll_id, title, description, creator_id, created_at, deadline, is_allow_add_option, max_option_limit, allow_multiple_votes, result_display_type, status
  sheet.appendRow([
    pollId,
    data.title || '未命名投票',
    data.description || '',
    data.creator_id || 'anonymous',
    "'" + createdAt,
    data.deadline ? ("'" + data.deadline) : '',
    isAllowAdd,
    maxOptions,
    allowMulti,
    displayType,
    'active' // 狀態: active, ended, archived
  ]);

  // 新增初始選項
  if (data.initial_options && Array.isArray(data.initial_options)) {
    data.initial_options.forEach(optText => {
      optionsSheet.appendRow([
        Utilities.getUuid(),
        pollId,
        optText,
        data.creator_id,
        "'" + createdAt,
        '' // image_url
      ]);
    });
  }

  return { success: true, message: '投票建立成功', poll_id: pollId };
}

/**
 * 取得投票列表 (包含選項與我的投票狀態)
 */
function getPolls(userId) {
  const ss = getSpreadsheet();
  const pollSheet = ss.getSheetByName('Polls');
  const optSheet = ss.getSheetByName('PollOptions');
  const voteSheet = ss.getSheetByName('PollVotes');

  if (!pollSheet || !optSheet || !voteSheet) return { success: false, error: '相關工作表缺失' };

  const polls = getDataAsObjects(pollSheet);
  const options = getDataAsObjects(optSheet);
  const votes = getDataAsObjects(voteSheet);

  // Todo: 可在此過濾 archived (封存) 的投票

  // 建立投票對照表 Map
  const pollsMap = {};
  polls.forEach(p => {
    // 處理字串轉布林值 (Sheet 有時會存成 TRUE/FALSE 字串)
    p.is_allow_add_option = (p.is_allow_add_option === true || p.is_allow_add_option === 'TRUE');
    p.allow_multiple_votes = (p.allow_multiple_votes === true || p.allow_multiple_votes === 'TRUE');
    
    p.options = [];
    p.my_votes = [];
    p.total_votes = 0;
    pollsMap[p.poll_id] = p;
  });

  // 計算每個選項的票數，並標記使用者投過的選項
  const voteCounts = {}; // { optionId: count }
  votes.forEach(v => {
    voteCounts[v.option_id] = (voteCounts[v.option_id] || 0) + 1;
    
    // 檢查是否為當前使用者投的票
    if (userId && v.user_id === userId && pollsMap[v.poll_id]) {
        pollsMap[v.poll_id].my_votes.push(v.option_id);
    }
  });

  // 將選項歸戶到對應的投票中
  options.forEach(o => {
    if (pollsMap[o.poll_id]) {
      o.vote_count = voteCounts[o.option_id] || 0;
      pollsMap[o.poll_id].options.push(o);
      pollsMap[o.poll_id].total_votes += o.vote_count;
    }
  });

  return { success: true, polls: Object.values(pollsMap) };
}

/**
 * 執行投票動作
 */
function votePoll(data) {
  const ss = getSpreadsheet();
  const voteSheet = ss.getSheetByName('PollVotes');
  const pollSheet = ss.getSheetByName('Polls');
  
  const pollId = data.poll_id;
  const optionIds = data.option_ids || []; // 傳入選取的選項 ID 陣列
  const userId = data.user_id;

  if (!pollId || !userId || optionIds.length === 0) return { success: false, error: '資料不完整 (缺 ID 或選項)' };

  // 1. 檢查投票狀態 (截止時間、是否開啟)
  const polls = getDataAsObjects(pollSheet);
  const poll = polls.find(p => p.poll_id === pollId);
  if (!poll) return { success: false, error: '找不到此投票' };

  if (poll.status !== 'active') return { success: false, error: '此投票已關閉' };
  
  if (poll.deadline) {
    const deadline = new Date(poll.deadline).getTime();
    if (new Date().getTime() > deadline) return { success: false, error: '此投票已過期' };
  }

  // 2. 處理投票邏輯
  // 策略：直接刪除該使用者在此投票的所有舊紀錄，再新增新的選擇。
  // 這樣同時支援「單選改票」與「多選重新選擇」。
  
  const allVotes = voteSheet.getDataRange().getValues();
  const toDelete = [];
  
  // 找出需要刪除的舊票 (從後往前找，避免刪除列時索引跑掉)
  // 假設欄位順序: vote_id, poll_id, option_id, user_id, user_name, created_at
  // 對應索引: 0, 1, 2, 3, 4, 5
  // 注意：我們會讀取全部資料，所以 row[1] 是 poll_id, row[3] 是 user_id
  for (let i = allVotes.length - 1; i >= 1; i--) {
    const row = allVotes[i];
    if (row[1] === pollId && row[3] === userId) {
      toDelete.push(i + 1); // sheet 的列號從 1 開始
    }
  }

  // 執行刪除
  toDelete.forEach(rowIndex => voteSheet.deleteRow(rowIndex));

  // 3. 寫入新票
  const createdAt = new Date().toISOString();
  optionIds.forEach(optId => {
    voteSheet.appendRow([
      Utilities.getUuid(),
      pollId,
      optId,
      userId,
      data.user_name || 'Anonymous',
      "'" + createdAt
    ]);
  });

  return { success: true, message: '投票成功' };
}

/**
 * 新增投票選項
 */
function addOption(data) {
  const ss = getSpreadsheet();
  const optSheet = ss.getSheetByName('PollOptions');
  const pollSheet = ss.getSheetByName('Polls');

  const pollId = data.poll_id;
  const text = data.text;

  // 檢查權限設定
  const polls = getDataAsObjects(pollSheet);
  const poll = polls.find(p => p.poll_id === pollId);
  if (!poll) return { success: false, error: '找不到此投票' };
  
  const isAllowAdd = (poll.is_allow_add_option === true || poll.is_allow_add_option === 'TRUE');
  if (!isAllowAdd) return { success: false, error: '此投票不允許新增選項' };

  // 檢查選項數量上限
  const opts = getDataAsObjects(optSheet);
  const currentCount = opts.filter(o => o.poll_id === pollId).length;
  if (currentCount >= (poll.max_option_limit || 20)) {
     return { success: false, error: '已達選項數量上限' };
  }

  // 新增選項
  optSheet.appendRow([
    Utilities.getUuid(),
    pollId,
    text,
    data.creator_id,
    "'" + new Date().toISOString(),
    '' // image_url
  ]);

  return { success: true, message: '選項已新增' };
}

/**
 * 刪除投票選項
 */
function deleteOption(data) {
    const ss = getSpreadsheet();
    const optSheet = ss.getSheetByName('PollOptions');
    const voteSheet = ss.getSheetByName('PollVotes');

    const optId = data.option_id;
    const userId = data.user_id;

    // 檢查是否有票數 (有票數不可刪除)
    const votes = getDataAsObjects(voteSheet);
    const hasVotes = votes.some(v => v.option_id === optId);
    if (hasVotes) return { success: false, error: '該選項已有票數，無法刪除' };

    // Todo: 可增加檢查是否為建立者 (creator_id)
    
    // 尋找並刪除
    const opts = optSheet.getDataRange().getValues();
    for (let i = 1; i < opts.length; i++) {
        // option_id 在第 0 欄
        if (opts[i][0] === optId) {
            optSheet.deleteRow(i + 1);
            return { success: true, message: '選項已刪除' };
        }
    }
    return { success: false, error: '找不到該選項' };
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
  return data.slice(1).map(row => {
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

  // 建立 Polls 工作表
  if (!ss.getSheetByName('Polls')) {
    const s = ss.insertSheet('Polls');
    s.appendRow(['poll_id', 'title', 'description', 'creator_id', 'created_at', 'deadline', 'is_allow_add_option', 'max_option_limit', 'allow_multiple_votes', 'result_display_type', 'status']);
  }

  // 建立 PollOptions 工作表
  if (!ss.getSheetByName('PollOptions')) {
    const s = ss.insertSheet('PollOptions');
    s.appendRow(['option_id', 'poll_id', 'text', 'creator_id', 'created_at', 'image_url']);
  }

  // 建立 PollVotes 工作表
  if (!ss.getSheetByName('PollVotes')) {
    const s = ss.insertSheet('PollVotes');
    s.appendRow(['vote_id', 'poll_id', 'option_id', 'user_id', 'user_name', 'created_at']);
  }
  
  Logger.log('投票工作表 (Polls, Options, Votes) 初始化完成');
}
