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
    return buildResponse(
      API_CODES.INVALID_PARAMS,
      null,
      "缺少必要欄位: email, password, displayName"
    );
  }

  // Email 格式簡易驗證
  if (!_isValidEmail(email)) {
    return buildResponse(API_CODES.INVALID_PARAMS, null, "Email 格式不正確");
  }

  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_USERS);

  if (!sheet) {
    return buildResponse(
      API_CODES.AUTH_SHEET_MISSING,
      null,
      "Users 工作表不存在，請先執行 setupSheets()"
    );
  }

  // 檢查 Email 是否已存在
  const existingResult = _findUserByEmail(sheet, email);
  if (existingResult) {
    const existingUser = existingResult.user;
    const rowIndex = existingResult.rowIndex;

    // 如果帳號已驗證，阻擋重複註冊
    if (
      existingUser.is_verified === true ||
      existingUser.is_verified === "TRUE"
    ) {
      return buildResponse(API_CODES.AUTH_EMAIL_EXISTS, null, "此信箱已被註冊");
    }

    // 帳號未驗證：更新密碼/資料並重發驗證碼
    const verificationCode = _generateVerificationCode();
    const verificationExpiry = new Date(
      Date.now() + 30 * 60 * 1000
    ).toISOString();
    const now = new Date().toISOString();
    const passwordHash = _hashPassword(password);
    const userAvatar = avatar || existingUser.avatar || DEFAULT_AVATAR;

    // 更新現有列
    const dataRange = sheet.getRange(rowIndex, 1, 1, HEADERS_USERS.length);
    const rowData = dataRange.getValues()[0];

    // 更新欄位 (保留 uuid, email, role, is_active)
    rowData[HEADERS_USERS.indexOf("password_hash")] = passwordHash;
    rowData[HEADERS_USERS.indexOf("display_name")] = displayName.trim();
    rowData[HEADERS_USERS.indexOf("avatar")] = userAvatar;
    rowData[HEADERS_USERS.indexOf("verification_code")] = verificationCode;
    rowData[HEADERS_USERS.indexOf("verification_expiry")] = verificationExpiry;
    rowData[HEADERS_USERS.indexOf("updated_at")] = now;

    dataRange.setValues([rowData]);

    // 發送驗證信
    _sendVerificationEmail(email, verificationCode);

    // 回傳使用者資料 (不含 accessToken，因為註冊後需重新登入)
    const userData = {
      uuid: existingUser.uuid,
      email: email.toLowerCase().trim(),
      displayName: displayName.trim(),
      avatar: userAvatar,
      role: existingUser.role,
      isVerified: false,
    };

    return buildResponse(API_CODES.SUCCESS, {
      user: userData,
    });
  }

  // 建立新使用者
  const now = new Date().toISOString();
  const userId = Utilities.getUuid();
  const passwordHash = _hashPassword(password);
  const userAvatar = avatar || DEFAULT_AVATAR;
  const defaultRole = "member"; // 預設角色

  // 生成驗證資料
  const verificationCode = _generateVerificationCode();
  const verificationExpiry = new Date(
    Date.now() + 30 * 60 * 1000
  ).toISOString(); // 30分鐘後過期

  const newRow = [
    userId,
    email.toLowerCase().trim(),
    passwordHash,
    displayName.trim(),
    userAvatar,
    defaultRole,
    true, // is_active
    false, // is_verified (預設未驗證)
    verificationCode,
    verificationExpiry,
    now, // created_at
    now, // updated_at
    now, // last_login_at
  ];

  sheet.appendRow(newRow);

  // 發送驗證信
  _sendVerificationEmail(email, verificationCode);

  // 回傳使用者資料 (不含密碼)
  const userData = {
    uuid: userId,
    email: email.toLowerCase().trim(),
    displayName: displayName.trim(),
    avatar: userAvatar,
    role: defaultRole,
    isVerified: false,
  };

  return buildResponse(
    API_CODES.SUCCESS,
    {
      user: userData,
      accessToken: userId, // 簡易 Token (使用 userId 作為 Token)
    },
    "註冊成功"
  );
}

/**
 * 登入
 * @param {Object} payload - { email, password }
 * @returns {Object} 標準 API 回應
 */
function authLogin(payload) {
  const { email, password } = payload;

  if (!email || !password) {
    return buildResponse(
      API_CODES.INVALID_PARAMS,
      null,
      "缺少必要欄位: email, password"
    );
  }

  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_USERS);

  if (!sheet) {
    return buildResponse(
      API_CODES.AUTH_SHEET_MISSING,
      null,
      "Users 工作表不存在"
    );
  }

  // 查找使用者
  const result = _findUserByEmail(sheet, email);
  if (!result) {
    return buildResponse(
      API_CODES.AUTH_INVALID_CREDENTIALS,
      null,
      "信箱或密碼錯誤"
    );
  }

  const { user, rowIndex } = result;

  // 檢查密碼
  const inputHash = _hashPassword(password);
  if (inputHash !== user.password_hash) {
    return buildResponse(
      API_CODES.AUTH_INVALID_CREDENTIALS,
      null,
      "信箱或密碼錯誤"
    );
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
    isVerified: user.is_verified,
  };

  // 生成 JWT Tokens
  const accessToken = generateAccessToken(user.uuid);
  const refreshToken = generateRefreshToken(user.uuid);

  return buildResponse(
    API_CODES.SUCCESS,
    {
      user: userData,
      accessToken: accessToken,
      refreshToken: refreshToken,
    },
    "登入成功"
  );
}

/**
 * 驗證 Token 並取得使用者資料
 * @param {Object} payload - { accessToken }
 * @returns {Object} 標準 API 回應
 */
function authValidate(payload) {
  const { accessToken } = payload;

  if (!accessToken) {
    return buildResponse(API_CODES.AUTH_REQUIRED, null, "缺少認證 Token");
  }

  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_USERS);

  if (!sheet) {
    return buildResponse(
      API_CODES.AUTH_SHEET_MISSING,
      null,
      "Users 工作表不存在"
    );
  }

  // 驗證 JWT Token
  const validation = validateToken(accessToken);

  if (!validation.isValid) {
    if (validation.errorCode === "EXPIRED") {
      return buildResponse(
        API_CODES.AUTH_ACCESS_TOKEN_EXPIRED,
        null,
        "Token 已過期，請重新登入"
      );
    }
    return buildResponse(
      API_CODES.AUTH_ACCESS_TOKEN_INVALID,
      null,
      "Token 無效"
    );
  }

  const userId = validation.payload.uid;

  // 以 userId 查找使用者
  const result = _findUserById(sheet, userId);
  if (!result) {
    return buildResponse(
      API_CODES.AUTH_ACCESS_TOKEN_INVALID,
      null,
      "Token 無效或使用者不存在"
    );
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
    isVerified: user.is_verified,
  };

  return buildResponse(API_CODES.SUCCESS, { user: userData }, "驗證成功");
}

/**
 * 假刪除會員
 * @param {Object} payload - { accessToken }
 * @returns {Object} 標準 API 回應
 */
function authDeleteUser(payload) {
  const { accessToken } = payload;

  if (!accessToken) {
    return buildResponse(API_CODES.AUTH_REQUIRED, null, "缺少認證 Token");
  }

  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_USERS);

  if (!sheet) {
    return buildResponse(
      API_CODES.AUTH_SHEET_MISSING,
      null,
      "Users 工作表不存在"
    );
  }

  // 驗證 Token 並取得 userId
  const validation = validateToken(accessToken);
  if (!validation.isValid) {
    return buildResponse(
      API_CODES.AUTH_ACCESS_TOKEN_INVALID,
      null,
      "Token 無效"
    );
  }
  const userId = validation.payload.uid;

  const result = _findUserById(sheet, userId);
  if (!result) {
    return buildResponse(
      API_CODES.AUTH_ACCESS_TOKEN_INVALID,
      null,
      "Token 無效"
    );
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

/**
 * 刷新 Access Token
 * @param {Object} payload - { refreshToken }
 * @returns {Object} 標準 API 回應
 */
function authRefreshToken(payload) {
  const { refreshToken } = payload;

  if (!refreshToken) {
    return buildResponse(API_CODES.AUTH_REQUIRED, null, "缺少 Refresh Token");
  }

  // 驗證 Refresh Token
  const validation = validateToken(refreshToken);

  if (!validation.isValid) {
    if (validation.errorCode === "EXPIRED") {
      return buildResponse(
        API_CODES.AUTH_ACCESS_TOKEN_EXPIRED,
        null,
        "Refresh Token 已過期，請重新登入"
      );
    }
    return buildResponse(
      API_CODES.AUTH_ACCESS_TOKEN_INVALID,
      null,
      "Refresh Token 無效"
    );
  }

  // 確認是 refresh 類型的 Token
  if (validation.payload.type !== "refresh") {
    return buildResponse(
      API_CODES.AUTH_ACCESS_TOKEN_INVALID,
      null,
      "需使用 Refresh Token"
    );
  }

  const userId = validation.payload.uid;

  // 確認使用者存在且活躍
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_USERS);
  const result = _findUserById(sheet, userId);

  if (!result || !result.user.is_active) {
    return buildResponse(
      API_CODES.AUTH_ACCESS_TOKEN_INVALID,
      null,
      "使用者不存在或已停用"
    );
  }

  // 生成新的 Access Token
  const newAccessToken = generateAccessToken(userId);

  return buildResponse(
    API_CODES.SUCCESS,
    { accessToken: newAccessToken },
    "Token 刷新成功"
  );
}

/**
 * 驗證 Email (輸入驗證碼)
 * @param {Object} payload - { email, code }
 * @returns {Object}
 */
function authVerifyEmail(payload) {
  const { email, code } = payload;

  if (!email || !code) {
    return buildResponse(API_CODES.INVALID_PARAMS, null, "缺少必要欄位");
  }

  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_USERS);
  const result = _findUserByEmail(sheet, email);

  if (!result) {
    return buildResponse(
      API_CODES.AUTH_INVALID_CREDENTIALS,
      null,
      "找不到此信箱"
    );
  }

  const { user, rowIndex } = result;

  // 檢查是否已驗證
  if (user.is_verified) {
    return buildResponse(API_CODES.SUCCESS, null, "信箱已驗證");
  }

  // 檢查驗證碼
  if (String(user.verification_code) !== String(code)) {
    return buildResponse(API_CODES.AUTH_CODE_INVALID, null, "驗證碼錯誤");
  }

  // 檢查過期
  if (new Date(user.verification_expiry) < new Date()) {
    return buildResponse(
      API_CODES.AUTH_CODE_EXPIRED,
      null,
      "驗證碼已過期，請重新發送"
    );
  }

  // 更新狀態
  const headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
  const isVerifiedCol = headers.indexOf("is_verified") + 1;
  const verifiedCodeCol = headers.indexOf("verification_code") + 1; // 清空 code

  if (isVerifiedCol > 0) {
    sheet.getRange(rowIndex, isVerifiedCol).setValue(true);
    // 選擇性清空驗證碼，避免重複使用
    if (verifiedCodeCol > 0)
      sheet.getRange(rowIndex, verifiedCodeCol).setValue("");
  }

  return buildResponse(API_CODES.SUCCESS, { isVerified: true }, "驗證成功");
}

/**
 * 重發驗證碼
 * @param {Object} payload - { email }
 * @returns {Object}
 */
function authResendCode(payload) {
  const { email } = payload;

  if (!email)
    return buildResponse(API_CODES.INVALID_PARAMS, null, "缺少 Email");

  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_USERS);
  const result = _findUserByEmail(sheet, email);

  if (!result) {
    return buildResponse(
      API_CODES.AUTH_INVALID_CREDENTIALS,
      null,
      "找不到此信箱"
    );
  }

  const { user, rowIndex } = result;

  if (user.is_verified) {
    return buildResponse(API_CODES.SUCCESS, null, "信箱已驗證，無需重發");
  }

  // 生成新碼
  const code = _generateVerificationCode();
  const expiry = new Date(Date.now() + 30 * 60 * 1000).toISOString();

  const headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
  const codeCol = headers.indexOf("verification_code") + 1;
  const expiryCol = headers.indexOf("verification_expiry") + 1;

  if (codeCol > 0 && expiryCol > 0) {
    sheet.getRange(rowIndex, codeCol).setValue(code);
    sheet.getRange(rowIndex, expiryCol).setValue(expiry);
  }

  _sendVerificationEmail(email, code);

  return buildResponse(API_CODES.SUCCESS, null, "驗證碼已發送");
}

/**
 * 生成 6 碼數字
 */
function _generateVerificationCode() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

/**
 * 發送驗證信 (使用 MailApp)
 */
function _sendVerificationEmail(email, code) {
  const subject = "[SummitMate] 您的驗證碼: " + code;
  const body = `
    親愛的用戶您好，

    您的 SummitMate 驗證碼為：${code} (30分鐘內有效)。
    若非本人操作，請忽略此信。

    SummitMate 團隊
  `;

  try {
    MailApp.sendEmail({
      to: email,
      subject: subject,
      body: body,
    });
  } catch (e) {
    console.error("Email 發送失敗: " + e.toString());
    // 不阻擋流程，但需記錄 Log
  }
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
  const rawHash = Utilities.computeDigest(
    Utilities.DigestAlgorithm.SHA_256,
    password
  );
  return rawHash
    .map((byte) => (byte < 0 ? byte + 256 : byte).toString(16).padStart(2, "0"))
    .join("");
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
    if (
      data[i][emailCol] &&
      data[i][emailCol].toString().toLowerCase().trim() === normalizedEmail
    ) {
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
