/**
 * ============================================================
 * Role & Permission API
 * ============================================================
 * @fileoverview 處理角色與權限相關邏輯
 *
 * API Actions:
 *   - auth_get_roles: 取得可用角色列表
 *   - auth_assign_role: 指派角色給使用者 (Admin Only)
 */

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
// 會員系統 (Users)
// role_id: 關聯 Roles 表的 UUID
// ============================================================
const HEADERS_USERS = [
  "id", // PK
  "email", // Unique, 作為登入帳號
  "password_hash", // 密碼雜湊 (SHA-256)
  "display_name", // 顯示名稱
  "avatar", // 頭像 Emoji
  "role_id", // FK: Roles.id
  "is_active", // 帳號是否啟用
  "is_verified", // Email 是否已驗證
  "verification_code", // Email 驗證碼
  "verification_expiry", // 驗證碼過期時間
  "created_at", // 建立時間
  "updated_at", // 更新時間
  "last_login_at", // 最後登入時間
];

// ============================================================
// === PUBLIC API (doPost Handlers) ===
// ============================================================

/**
 * 註冊新會員
 * @param {Object} payload - { email, password, displayName, avatar? }
 * @returns {Object} 標準 API 回應
 */
function registerUser(payload) {
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
      id: existingUser.id,
      email: email.toLowerCase().trim(),
      display_name: displayName.trim(),
      avatar: userAvatar,
      role: existingUser.role,
      is_verified: false,
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

  // [Role] 查找 Member Role ID
  const memberRole = _getRoleByCode("MEMBER");
  const defaultRoleId = memberRole ? memberRole.id : "";
  const defaultRoleCode = memberRole ? memberRole.code : "member"; // Fallback

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
    defaultRoleId,
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
    id: userId,
    email: email.toLowerCase().trim(),
    display_name: displayName.trim(),
    avatar: userAvatar,
    role_id: defaultRoleId,
    role_code: defaultRoleCode,
    is_verified: false,
  };

  return buildResponse(
    API_CODES.SUCCESS,
    {
      user: userData,
      accessToken: userId, // 簡易 Token
      role: memberRole
        ? { id: memberRole.id, code: memberRole.code, name: memberRole.name }
        : null,
      permissions: _getRolePermissions(defaultRoleId),
    },
    "註冊成功"
  );
}

/**
 * 登入
 * @param {Object} payload - { email, password }
 * @returns {Object} 標準 API 回應
 */
function loginUser(payload) {
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
  const roleId = user.role_id;

  // [Role] 解析 Role & Permissions
  const roleObj = _getRoleById(roleId);
  const permissions = _getRolePermissions(roleId);

  const userData = {
    id: user.id,
    email: user.email,
    display_name: user.display_name,
    avatar: user.avatar,
    role_id: roleId,
    role_code: roleObj ? roleObj.code : user.role || "MEMBER", // Fallback
    is_verified: user.is_verified,
  };

  // 生成 JWT Tokens
  const accessToken = generateAccessToken(user.id);
  const refreshToken = generateRefreshToken(user.id);

  return buildResponse(
    API_CODES.SUCCESS,
    {
      user: userData,
      accessToken: accessToken,
      refreshToken: refreshToken,
      role: roleObj
        ? { id: roleObj.id, code: roleObj.code, name: roleObj.name }
        : null,
      permissions: permissions,
    },
    "登入成功"
  );
}

/**
 * 驗證 Token 並取得使用者資料
 * @param {Object} payload - { accessToken }
 * @returns {Object} 標準 API 回應
 */
function validateSession(payload) {
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
    id: user.id,
    email: user.email,
    display_name: user.display_name,
    avatar: user.avatar,
    role_id: user.role_id,
    is_verified: user.is_verified,
  };

  // [Role]
  const roleId = user.role_id;
  const roleObj = _getRoleById(roleId);
  const permissions = _getRolePermissions(roleId);

  return buildResponse(
    API_CODES.SUCCESS,
    {
      user: userData,
      role: roleObj
        ? { id: roleObj.id, code: roleObj.code, name: roleObj.name }
        : null,
      permissions: permissions,
    },
    "驗證成功"
  );
}

/**
 * 假刪除會員
 * @param {Object} payload - { accessToken }
 * @returns {Object} 標準 API 回應
 */
function deleteUser(payload) {
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
function refreshSession(payload) {
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
 * 更新使用者資料 (暱稱、頭像)
 * @param {Object} payload - { accessToken, displayName, avatar }
 * @returns {Object} 標準 API 回應
 */
function updateProfile(payload) {
  const { accessToken, displayName, avatar } = payload;

  if (!accessToken) {
    return buildResponse(API_CODES.AUTH_REQUIRED, null, "缺少認證 Token");
  }

  // 驗證 Token
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
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_USERS);

  // 查找使用者
  const result = _findUserById(sheet, userId);
  if (!result) {
    return buildResponse(
      API_CODES.AUTH_ACCESS_TOKEN_INVALID,
      null,
      "使用者不存在"
    );
  }

  const { user, rowIndex } = result;

  // 檢查帳號狀態
  if (!user.is_active) {
    return buildResponse(API_CODES.AUTH_ACCOUNT_DISABLED, null, "此帳號已停用");
  }

  // 準備更新
  const headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
  const nameCol = headers.indexOf("display_name") + 1;
  const avatarCol = headers.indexOf("avatar") + 1;
  const updateCol = headers.indexOf("updated_at") + 1;

  if (nameCol > 0 && displayName) {
    sheet.getRange(rowIndex, nameCol).setValue(displayName.trim());
    user.display_name = displayName.trim();
  }

  if (avatarCol > 0 && avatar) {
    sheet.getRange(rowIndex, avatarCol).setValue(avatar);
    user.avatar = avatar;
  }

  if (updateCol > 0) {
    sheet.getRange(rowIndex, updateCol).setValue(new Date().toISOString());
  }

  // 回傳更新後的資料
  const userData = {
    id: user.id,
    email: user.email,
    display_name: user.display_name,
    avatar: user.avatar,
    role: user.role,
    is_verified: user.is_verified,
  };

  return buildResponse(
    API_CODES.SUCCESS,
    { user: userData },
    "個人資料更新成功"
  );
}

/**
 * 驗證 Email (輸入驗證碼)
 * @param {Object} payload - { email, code }
 * @returns {Object}
 */
function verifyEmail(payload) {
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
function resendCode(payload) {
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
 * 依 ID 查找使用者
 * @private
 * @param {Sheet} sheet - Users 工作表
 * @param {string} id - 使用者 ID
 * @returns {Object|null} { user, rowIndex } 或 null
 */
function _findUserById(sheet, id) {
  const data = sheet.getDataRange().getValues();
  if (data.length <= 1) return null;

  const headers = data[0];
  const idCol = headers.indexOf("id");

  for (let i = 1; i < data.length; i++) {
    if (data[i][idCol] === id) {
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
