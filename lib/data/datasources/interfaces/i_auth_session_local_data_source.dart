/// 認證 Session 本地資料來源介面
///
/// 使用 SecureStorage 進行安全儲存，管理使用者登入 Session 相關資訊。
/// 所有敏感資料皆透過此介面存取，確保安全性。
abstract class IAuthSessionLocalDataSource {
  /// 儲存 Session Token
  ///
  /// [token] 認證 Token (由 Google OAuth 或後端簽發)
  Future<void> saveToken(String token);

  /// 取得 Session Token
  ///
  /// 回傳: Token 字串，若不存在則回傳 null
  Future<String?> getToken();

  /// 儲存 User ID
  ///
  /// [userId] 使用者唯一識別碼
  Future<void> saveUserId(String userId);

  /// 取得 User ID
  ///
  /// 回傳: 使用者 ID，若不存在則回傳 null
  Future<String?> getUserId();

  /// 儲存 Email
  ///
  /// [email] 使用者電子郵件
  Future<void> saveEmail(String email);

  /// 取得 Email
  ///
  /// 回傳: 使用者電子郵件，若不存在則回傳 null
  Future<String?> getEmail();

  /// 儲存用戶名稱
  ///
  /// [username] 使用者顯示名稱
  Future<void> saveUsername(String username);

  /// 取得用戶名稱
  ///
  /// 回傳: 使用者名稱，若不存在則回傳 null
  Future<String?> getUsername();

  /// 儲存頭像
  ///
  /// [avatar] 使用者頭像 (Emoji 或 URL)
  Future<void> saveAvatar(String avatar);

  /// 取得頭像
  ///
  /// 回傳: 使用者頭像，若不存在則回傳 null
  Future<String?> getAvatar();

  /// 清除所有 Session 資料
  ///
  /// 用於登出情境，會移除所有認證相關資料。
  Future<void> clearAll();

  /// 是否有有效 Session
  ///
  /// 回傳: true 表示有有效的 Token 存在
  Future<bool> hasValidSession();
}
