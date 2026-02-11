import '../../../data/models/user_profile.dart';

/// 認證結果
/// 代表認證操作的結果
class AuthResult {
  final bool isSuccess;
  final UserProfile? user;
  final String? errorCode;
  final String? errorMessage;
  final String? accessToken;
  final String? refreshToken;
  final bool requiresVerification;
  final bool isOffline;

  const AuthResult({
    required this.isSuccess,
    this.user,
    this.errorCode,
    this.errorMessage,
    this.accessToken,
    this.refreshToken,
    this.requiresVerification = false,
    this.isOffline = false,
  });

  /// 建立成功結果
  ///
  /// [user] 使用者資料
  /// [accessToken] 存取權杖
  /// [refreshToken] 刷新權杖
  /// [isOffline] 是否為離線登入模式
  factory AuthResult.success({UserProfile? user, String? accessToken, String? refreshToken, bool isOffline = false}) {
    return AuthResult(
      isSuccess: true,
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
      isOffline: isOffline,
    );
  }

  /// 建立失敗結果
  ///
  /// [errorCode] 錯誤代碼 (例如: 'INVALID_PASSWORD')
  /// [errorMessage] 錯誤訊息描述
  factory AuthResult.failure({required String errorCode, String? errorMessage}) {
    return AuthResult(isSuccess: false, errorCode: errorCode, errorMessage: errorMessage);
  }

  /// 建立需要驗證結果
  ///
  /// [errorMessage] 提示訊息
  /// [user] 使用者暫存資料
  factory AuthResult.requiresVerification({String? errorMessage, UserProfile? user}) {
    return AuthResult(
      isSuccess: true, // 操作成功，但需要驗證
      user: user,
      requiresVerification: true,
      errorCode: 'REQUIRES_VERIFICATION',
      errorMessage: errorMessage,
    );
  }
}

/// 第三方 OAuth 認證提供者
enum OAuthProvider { google, facebook, apple, line }

/// 抽象認證服務介面
/// 所有認證後端皆實作此介面。
/// 這使得認證實作可抽換：
/// - GasAuthService (目前)
/// - FirebaseAuthService (未來)
/// - AzureAuthService (未來)
/// - OAuthSSOService (未來)
abstract class IAuthService {
  /// 使用 Email 與密碼註冊新使用者
  ///
  /// [email] 使用者電子郵件
  /// [password] 使用者密碼
  /// [displayName] 顯示名稱
  /// [avatar] 頭像 URL (可選)
  Future<AuthResult> register({
    required String email,
    required String password,
    required String displayName,
    String? avatar,
  });

  /// 更新使用者資料 (顯示名稱、頭像)
  ///
  /// [displayName] 新的顯示名稱 (若為 null 則不更新)
  /// [avatar] 新的頭像 URL (若為 null 則不更新)
  Future<AuthResult> updateProfile({String? displayName, String? avatar});

  /// 使用 Email 與密碼登入
  ///
  /// [email] 使用者電子郵件
  /// [password] 使用者密碼
  Future<AuthResult> login({required String email, required String password});

  /// 使用第三方 OAuth 提供者登入
  ///
  /// [provider] OAuth 提供者 (Google, Facebook, etc.)
  Future<AuthResult> loginWithProvider(OAuthProvider provider);

  /// 使用驗證碼驗證 Email
  ///
  /// [email] 使用者電子郵件
  /// [code] 驗證碼
  Future<AuthResult> verifyEmail({required String email, required String code});

  /// 重送驗證碼
  ///
  /// [email] 使用者電子郵件
  Future<AuthResult> resendVerificationCode({required String email});

  /// 驗證目前與伺服器的 Session
  Future<AuthResult> validateSession();

  /// 使用 Refresh Token 刷新 Access Token
  Future<AuthResult> refreshToken();

  /// 登出並清除 Session
  Future<void> logout();

  /// 刪除使用者帳號 (軟刪除)
  Future<AuthResult> deleteAccount();

  /// 取得目前的 Access Token
  Future<String?> getAccessToken();

  /// 取得目前的 Refresh Token
  Future<String?> getRefreshToken();

  /// 取得快取的使用者資料
  Future<UserProfile?> getCachedUserProfile();

  /// 檢查使用者是否已登入 (擁有有效 Session)
  Future<bool> isLoggedIn();

  /// 檢查目前是否處於離線模式
  bool get isOfflineMode;

  /// 取得當前登入使用者的 Email (同步，用於資料過濾)
  String? get currentUserEmail;

  /// 取得當前登入使用者的 UUID (同步，用於資料所有權標記)
  String? get currentUserId;
}
