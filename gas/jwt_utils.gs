/**
 * ============================================================
 * JWT Utilities for Authentication
 * ============================================================
 * @fileoverview JWT Token 生成與驗證工具
 *
 * Token 結構:
 *   - header: { alg: 'HS256', typ: 'JWT' }
 *   - payload: { uid, iat, exp, type }
 *   - signature: HMAC-SHA256(header.payload, secret)
 *
 * Token 類型:
 *   - access: 存取 Token (1 小時過期)
 *   - refresh: 刷新 Token (30 天過期)
 *
 * 使用方式:
 *   const accessToken = generateAccessToken(userId);
 *   const refreshToken = generateRefreshToken(userId);
 *   const result = validateToken(token);
 */

// ============================================================
// === CONSTANTS ===
// ============================================================

/** Access Token 有效期 (毫秒) - 1 小時 */
const ACCESS_TOKEN_TTL_MS = 60 * 60 * 1000;

/** Refresh Token 有效期 (毫秒) - 30 天 */
const REFRESH_TOKEN_TTL_MS = 30 * 24 * 60 * 60 * 1000;

/** 離線寬限期 (毫秒) - 7 天 */
const OFFLINE_GRACE_PERIOD_MS = 7 * 24 * 60 * 60 * 1000;

// ============================================================
// === PUBLIC API ===
// ============================================================

/**
 * 生成 Access Token
 * @param {string} userId - 使用者 UUID
 * @returns {string} JWT Access Token
 */
function generateAccessToken(userId) {
  return _generateToken(userId, "access", ACCESS_TOKEN_TTL_MS);
}

/**
 * 生成 Refresh Token
 * @param {string} userId - 使用者 UUID
 * @returns {string} JWT Refresh Token
 */
function generateRefreshToken(userId) {
  return _generateToken(userId, "refresh", REFRESH_TOKEN_TTL_MS);
}

/**
 * 驗證 Token
 * @param {string} token - JWT Token
 * @returns {Object} { isValid, errorCode, payload }
 *   - isValid: boolean
 *   - errorCode: 'EXPIRED' | 'INVALID_SIGNATURE' | 'MALFORMED' | null
 *   - payload: { uid, iat, exp, type } | null
 */
function validateToken(token) {
  if (!token || typeof token !== "string") {
    return { isValid: false, errorCode: "MALFORMED", payload: null };
  }

  const parts = token.split(".");
  if (parts.length !== 3) {
    return { isValid: false, errorCode: "MALFORMED", payload: null };
  }

  const [headerB64, payloadB64, signatureB64] = parts;

  // 驗證簽章
  const secret = _getJwtSecret();
  const expectedSignature = _computeSignature(headerB64, payloadB64, secret);

  if (signatureB64 !== expectedSignature) {
    return { isValid: false, errorCode: "INVALID_SIGNATURE", payload: null };
  }

  // 解碼 Payload
  let payload;
  try {
    const payloadJson = Utilities.newBlob(
      Utilities.base64DecodeWebSafe(payloadB64)
    ).getDataAsString();
    payload = JSON.parse(payloadJson);
  } catch (e) {
    return { isValid: false, errorCode: "MALFORMED", payload: null };
  }

  // 檢查過期
  const now = Date.now();
  if (payload.exp && payload.exp < now) {
    return { isValid: false, errorCode: "EXPIRED", payload: payload };
  }

  return { isValid: true, errorCode: null, payload: payload };
}

/**
 * 從 Token 解碼 Payload (不驗證簽章)
 * @param {string} token - JWT Token
 * @returns {Object|null} payload 或 null
 */
function decodeTokenPayload(token) {
  if (!token || typeof token !== "string") {
    return null;
  }

  const parts = token.split(".");
  if (parts.length !== 3) {
    return null;
  }

  try {
    const payloadJson = Utilities.newBlob(
      Utilities.base64DecodeWebSafe(parts[1])
    ).getDataAsString();
    return JSON.parse(payloadJson);
  } catch (e) {
    return null;
  }
}

/**
 * 檢查 Token 是否在離線寬限期內
 * @param {string} token - JWT Token
 * @returns {boolean}
 */
function isWithinOfflineGracePeriod(token) {
  const payload = decodeTokenPayload(token);
  if (!payload || !payload.iat) {
    return false;
  }

  const tokenAge = Date.now() - payload.iat;
  return tokenAge < OFFLINE_GRACE_PERIOD_MS;
}

// ============================================================
// === PRIVATE HELPERS ===
// ============================================================

/**
 * 生成 JWT Token
 * @private
 */
function _generateToken(userId, tokenType, ttlMs) {
  const secret = _getJwtSecret();
  const now = Date.now();

  // Header
  const header = {
    alg: "HS256",
    typ: "JWT",
  };

  // Payload
  const payload = {
    uid: userId,
    iat: now,
    exp: now + ttlMs,
    type: tokenType,
  };

  // Encode
  const headerB64 = Utilities.base64EncodeWebSafe(JSON.stringify(header));
  const payloadB64 = Utilities.base64EncodeWebSafe(JSON.stringify(payload));

  // Sign
  const signature = _computeSignature(headerB64, payloadB64, secret);

  return `${headerB64}.${payloadB64}.${signature}`;
}

/**
 * 計算 HMAC-SHA256 簽章
 * @private
 */
function _computeSignature(headerB64, payloadB64, secret) {
  const message = `${headerB64}.${payloadB64}`;
  const signature = Utilities.computeHmacSha256Signature(message, secret);
  return Utilities.base64EncodeWebSafe(signature);
}

/**
 * 取得 JWT Secret
 * @private
 * @returns {string}
 */
function _getJwtSecret() {
  const props = PropertiesService.getScriptProperties();
  let secret = props.getProperty("JWT_SECRET");

  if (!secret) {
    // 首次使用時自動生成 Secret
    secret = Utilities.getUuid() + "-" + Utilities.getUuid();
    props.setProperty("JWT_SECRET", secret);
    Logger.log("⚠️ JWT_SECRET 已自動生成，請妥善保管！");
  }

  return secret;
}
