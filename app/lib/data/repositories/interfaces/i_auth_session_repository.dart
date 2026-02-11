import '../../../data/models/user_profile.dart';

/// 身份驗證 Session 管理的 Repository 介面
///
/// 負責保存與獲取使用者的登入狀態 (Token) 與個人檔案。
abstract class IAuthSessionRepository {
  /// 儲存 Session 資料 (Token 與 用戶資料)
  ///
  /// [accessToken] 存取權杖
  /// [user] 用戶個人檔案
  /// [refreshToken] 刷新權杖 (可選)
  Future<void> saveSession(String accessToken, UserProfile user, {String? refreshToken});

  /// 取得當前的 Access Token
  Future<String?> getAccessToken();

  /// 清除當前的 Session (登出)
  Future<void> clearSession();

  /// 取得當前用戶個人檔案
  Future<UserProfile?> getUserProfile();

  /// 取得 Refresh Token
  Future<String?> getRefreshToken();

  /// 檢查是否存在有效的 Session
  Future<bool> hasSession();
}
