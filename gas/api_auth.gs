/**
 * ============================================================
 * Authentication API
 * ============================================================
 * @fileoverview 處理會員註冊、登入、刪除等操作
 *
 * API Actions:
 *   - register: 註冊新會員
 *   - login: 登入
 *   - validate: 驗證 Token 並取得使用者資料
 *   - deleteUser: 假刪除會員 (設定 is_active = false)
 *
 * Security:
 *   - 密碼使用 SHA-256 雜湊儲存
 *   - Token 為簡易 UUID (未來可改用 JWT)
 *   - 【未來規劃】加入 Email 驗證碼機制
 */

// ============================================================
// === PUBLIC API (doPost Handlers) ===
// ============================================================

/**
 * 註冊新會員
 * @param {Object} payload - { email, password, displayName, avatar? }
 * @returns {Object} 標準 API 回應
 */
function authRegister(payload) {
  const { email, password, displayName, avatar } = payload;

  // 參數驗證
  if (!email || !password || !displayName) {
    return buildResponse(API_CODES.INVALID_PARAMS, null, "缺少必要欄位: email, password, displayName");
  }

  // Email 格式簡易驗證
  if (!_isValidEmail(email)) {
    return buildResponse(API_CODES.INVALID_PARAMS, null, "Email 格式不正確");
  }

  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_USERS);

  if (!sheet) {
    return buildResponse(API_CODES.AUTH_SHEET_MISSING, null, "Users 工作表不存在，請先執行 setupSheets()");
  }

  // 檢查 Email 是否已存在
  const existingUser = _findUserByEmail(sheet, email);
  if (existingUser) {
    return buildResponse(API_CODES.AUTH_EMAIL_EXISTS, null, "此信箱已被註冊");
  }

  // 建立新使用者
  const now = new Date().toISOString();
  const userId = Utilities.getUuid();
  const passwordHash = _hashPassword(password);
  const userAvatar = avatar || DEFAULT_AVATAR;
  const defaultRole = "member"; // 預設角色

  const newRow = [
    userId,
    email.toLowerCase().trim(),
    passwordHash,
    displayName.trim(),
    userAvatar,
    defaultRole,
    true, // is_active
    now,  // created_at
    now,  // updated_at
    now,  // last_login_at
  ];

  sheet.appendRow(newRow);

  // 回傳使用者資料 (不含密碼)
  const userData = {
    uuid: userId,
    email: email.toLowerCase().trim(),
    displayName: displayName.trim(),
    avatar: userAvatar,
    role: defaultRole,
  };

  return buildResponse(API_CODES.SUCCESS, {
    user: userData,
    authToken: userId, // 簡易 Token (使用 userId 作為 Token)
  }, "註冊成功");
}

/**
 * 登入
 * @param {Object} payload - { email, password }
 * @returns {Object} 標準 API 回應
 */
function authLogin(payload) {
  const { email, password } = payload;

  if (!email || !password) {
    return buildResponse(API_CODES.INVALID_PARAMS, null, "缺少必要欄位: email, password");
  }

  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_USERS);

  if (!sheet) {
    return buildResponse(API_CODES.AUTH_SHEET_MISSING, null, "Users 工作表不存在");
  }

  // 查找使用者
  const result = _findUserByEmail(sheet, email);
  if (!result) {
    return buildResponse(API_CODES.AUTH_INVALID_CREDENTIALS, null, "信箱或密碼錯誤");
  }

  const { user, rowIndex } = result;

  // 檢查密碼
  const inputHash = _hashPassword(password);
  if (inputHash !== user.password_hash) {
    return buildResponse(API_CODES.AUTH_INVALID_CREDENTIALS, null, "信箱或密碼錯誤");
  }

  // 檢查帳號狀態
  if (!user.is_active) {
    return buildResponse(API_CODES.AUTH_ACCOUNT_DISABLED, null, "此帳號已停用");
  }

  // 更新最後登入時間
  const now = new Date().toISOString();
  const headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
  const lastLoginCol = headers.indexOf("last_login_at") + 1;
  if (lastLoginCol > 0) {
    sheet.getRange(rowIndex, lastLoginCol).setValue(now);
  }

  // 回傳使用者資料
  const userData = {
    uuid: user.uuid,
    email: user.email,
    displayName: user.display_name,
    avatar: user.avatar,
    role: user.role,
  };

  return buildResponse(API_CODES.SUCCESS, {
    user: userData,
    authToken: user.uuid, // 簡易 Token
  }, "登入成功");
}

/**
 * 驗證 Token 並取得使用者資料
 * @param {Object} payload - { authToken }
 * @returns {Object} 標準 API 回應
 */
function authValidate(payload) {
  const { authToken } = payload;

  if (!authToken) {
    return buildResponse(API_CODES.AUTH_REQUIRED, null, "缺少認證 Token");
  }

  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_USERS);

  if (!sheet) {
    return buildResponse(API_CODES.AUTH_SHEET_MISSING, null, "Users 工作表不存在");
  }

  // 以 Token (= userId) 查找使用者
  const result = _findUserById(sheet, authToken);
  if (!result) {
    return buildResponse(API_CODES.AUTH_TOKEN_INVALID, null, "Token 無效或已過期");
  }

  const { user } = result;

  // 檢查帳號狀態
  if (!user.is_active) {
    return buildResponse(API_CODES.AUTH_ACCOUNT_DISABLED, null, "此帳號已停用");
  }

  const userData = {
    uuid: user.uuid,
    email: user.email,
    displayName: user.display_name,
    avatar: user.avatar,
    role: user.role,
  };

  return buildResponse(API_CODES.SUCCESS, { user: userData }, "驗證成功");
}

/**
 * 假刪除會員
 * @param {Object} payload - { authToken }
 * @returns {Object} 標準 API 回應
 */
function authDeleteUser(payload) {
  const { authToken } = payload;

  if (!authToken) {
    return buildResponse(API_CODES.AUTH_REQUIRED, null, "缺少認證 Token");
  }

  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_USERS);

  if (!sheet) {
    return buildResponse(API_CODES.AUTH_SHEET_MISSING, null, "Users 工作表不存在");
  }

  const result = _findUserById(sheet, authToken);
  if (!result) {
    return buildResponse(API_CODES.AUTH_TOKEN_INVALID, null, "Token 無效");
  }

  const { rowIndex } = result;

  // 設定 is_active = false (假刪除)
  const headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
  const isActiveCol = headers.indexOf("is_active") + 1;
  const updatedAtCol = headers.indexOf("updated_at") + 1;

  if (isActiveCol > 0) {
    sheet.getRange(rowIndex, isActiveCol).setValue(false);
  }
  if (updatedAtCol > 0) {
    sheet.getRange(rowIndex, updatedAtCol).setValue(new Date().toISOString());
  }

  return buildResponse(API_CODES.SUCCESS, null, "帳號已刪除");
}

// ============================================================
// === INTERNAL HELPERS ===
// ============================================================

/**
 * SHA-256 雜湊密碼
 * @private
 * @param {string} password - 原始密碼
 * @returns {string} 雜湊後的密碼 (Hex)
 */
function _hashPassword(password) {
  const rawHash = Utilities.computeDigest(Utilities.DigestAlgorithm.SHA_256, password);
  return rawHash.map(byte => (byte < 0 ? byte + 256 : byte).toString(16).padStart(2, '0')).join('');
}

/**
 * 簡易 Email 格式驗證
 * @private
 * @param {string} email
 * @returns {boolean}
 */
function _isValidEmail(email) {
  const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return regex.test(email);
}

/**
 * 依 Email 查找使用者
 * @private
 * @param {Sheet} sheet - Users 工作表
 * @param {string} email - 查詢的 Email
 * @returns {Object|null} { user, rowIndex } 或 null
 */
function _findUserByEmail(sheet, email) {
  const data = sheet.getDataRange().getValues();
  if (data.length <= 1) return null;

  const headers = data[0];
  const emailCol = headers.indexOf("email");

  const normalizedEmail = email.toLowerCase().trim();

  for (let i = 1; i < data.length; i++) {
    if (data[i][emailCol] && data[i][emailCol].toString().toLowerCase().trim() === normalizedEmail) {
      const user = _rowToUser(headers, data[i]);
      return { user, rowIndex: i + 1 };
    }
  }
  return null;
}

/**
 * 依 UUID 查找使用者
 * @private
 * @param {Sheet} sheet - Users 工作表
 * @param {string} uuid - 使用者 UUID
 * @returns {Object|null} { user, rowIndex } 或 null
 */
function _findUserById(sheet, uuid) {
  const data = sheet.getDataRange().getValues();
  if (data.length <= 1) return null;

  const headers = data[0];
  const uuidCol = headers.indexOf("uuid");

  for (let i = 1; i < data.length; i++) {
    if (data[i][uuidCol] === uuid) {
      const user = _rowToUser(headers, data[i]);
      return { user, rowIndex: i + 1 };
    }
  }
  return null;
}

/**
 * 將資料列轉換為 User 物件
 * @private
 * @param {string[]} headers
 * @param {any[]} row
 * @returns {Object}
 */
function _rowToUser(headers, row) {
  const user = {};
  headers.forEach((header, index) => {
    user[header] = row[index];
  });
  return user;
}
