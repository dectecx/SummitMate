/// Token Payload - 解碼後的 JWT 內容
class TokenPayload {
  /// Token 中的 User ID
  final String userId;

  /// Token 簽發時間
  final DateTime issuedAt;

  /// Token 過期時間
  final DateTime expiresAt;

  /// Token 類型: 'access' 或 'refresh'
  final String tokenType;

  /// 額外的 Claims (可選)
  final Map<String, dynamic>? claims;

  const TokenPayload({
    required this.userId,
    required this.issuedAt,
    required this.expiresAt,
    required this.tokenType,
    this.claims,
  });

  /// 檢查 Token 是否已過期
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// 取得距離過期的剩餘時間
  Duration get remainingTime => expiresAt.difference(DateTime.now());

  /// 檢查是否為 Access Token
  bool get isAccessToken => tokenType == 'access';

  /// 檢查是否為 Refresh Token
  bool get isRefreshToken => tokenType == 'refresh';
}

/// Token 驗證結果
class TokenValidationResult {
  /// Token 是否有效
  final bool isValid;

  /// 驗證失敗的錯誤代碼
  /// 可能值: 'EXPIRED', 'INVALID_SIGNATURE', 'MALFORMED', 'MISSING'
  final String? errorCode;

  /// 解碼後的 Token Payload (僅在有效或雖過期但可解碼時存在)
  final TokenPayload? payload;

  const TokenValidationResult({required this.isValid, this.errorCode, this.payload});

  /// 建立有效結果
  ///
  /// [payload] 解碼後的 JWT 內容
  factory TokenValidationResult.valid(TokenPayload payload) {
    return TokenValidationResult(isValid: true, payload: payload);
  }

  /// 建立過期結果
  ///
  /// [payload] 解碼後的 JWT 內容 (即使過期仍可讀取)
  factory TokenValidationResult.expired(TokenPayload payload) {
    return TokenValidationResult(isValid: false, errorCode: 'EXPIRED', payload: payload);
  }

  /// 建立無效結果
  ///
  /// [errorCode] 錯誤代碼
  factory TokenValidationResult.invalid(String errorCode) {
    return TokenValidationResult(isValid: false, errorCode: errorCode);
  }

  /// 建立缺少 Token 結果
  factory TokenValidationResult.missing() {
    return const TokenValidationResult(isValid: false, errorCode: 'MISSING');
  }
}

/// Token 驗證器介面
/// 提供 JWT Token 的驗證與解碼功能。
/// 此抽象介面允許不同的實作：
/// - JwtTokenValidator (目前，用於 GAS JWT)
/// - FirebaseTokenValidator (未來)
abstract class ITokenValidator {
  /// 驗證 Token 並傳回結果
  /// 注意：簽章驗證應在伺服器端進行。
  /// 用戶端驗證主要關注過期時間與格式。
  ///
  /// [token] JWT 字串
  TokenValidationResult validate(String token);

  /// 解碼 Token Payload 而不進行驗證
  /// 若 Token 格式錯誤則傳回 null
  ///
  /// [token] JWT 字串
  TokenPayload? decode(String token);

  /// 檢查 Token 是否即將過期
  ///
  /// [token] JWT 字串
  /// [threshold] 視為「即將過期」的時間閾值 (預設 5 分鐘)
  bool isExpiringSoon(String token, {Duration threshold = const Duration(minutes: 5)});

  /// 檢查 Token 是否已過期
  ///
  /// [token] JWT 字串
  bool isExpired(String token);
}
