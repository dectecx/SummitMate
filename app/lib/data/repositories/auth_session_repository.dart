import 'package:injectable/injectable.dart';
import '../../data/models/user_profile.dart';
import '../../infrastructure/tools/log_service.dart';
import 'interfaces/i_auth_session_repository.dart';
import '../datasources/interfaces/i_auth_session_local_data_source.dart';

/// 用於管理本地身份驗證工作階段的 Repository (支援 DataSource 模式)
///
/// 透過 IAuthSessionLocalDataSource 存取 SecureStorage，
/// 管理使用者登入 Session (Token, UserProfile)。
@LazySingleton(as: IAuthSessionRepository)
class AuthSessionRepository implements IAuthSessionRepository {
  static const String _source = 'AuthSessionRepository';

  final IAuthSessionLocalDataSource _localDataSource;

  AuthSessionRepository({required IAuthSessionLocalDataSource localDataSource}) : _localDataSource = localDataSource;

  // ========== Session Operations ==========

  @override
  Future<void> saveSession(String accessToken, UserProfile user, {String? refreshToken}) async {
    try {
      await _localDataSource.saveToken(accessToken);
      await _localDataSource.saveUserId(user.id);
      await _localDataSource.saveEmail(user.email);
      await _localDataSource.saveUsername(user.displayName);
      await _localDataSource.saveAvatar(user.avatar);
      // Note: refreshToken is stored via token if needed, or use a separate method
      LogService.debug('Session saved for user: ${user.email}', source: _source);
    } catch (e) {
      LogService.error('Failed to save session: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<void> clearSession() async {
    try {
      await _localDataSource.clearAll();
      LogService.debug('Session cleared', source: _source);
    } catch (e) {
      LogService.error('Failed to clear session: $e', source: _source);
      rethrow;
    }
  }

  // ========== Token Operations ==========

  @override
  Future<String?> getAccessToken() async {
    try {
      return await _localDataSource.getToken();
    } catch (e) {
      LogService.error('Failed to read access token: $e', source: _source);
      return null;
    }
  }

  @override
  Future<String?> getRefreshToken() async {
    // RefreshToken is not stored separately in this implementation
    // If needed, add a separate key to IAuthSessionLocalDataSource
    return null;
  }

  // ========== User Profile Operations ==========

  @override
  Future<UserProfile?> getUserProfile() async {
    try {
      final userId = await _localDataSource.getUserId();
      final email = await _localDataSource.getEmail();
      final username = await _localDataSource.getUsername();
      final avatar = await _localDataSource.getAvatar();

      if (userId == null || email == null) return null;

      return UserProfile(id: userId, email: email, displayName: username ?? '', avatar: avatar ?? '🐻');
    } catch (e) {
      LogService.warning('Failed to get user profile: $e', source: _source);
      return null;
    }
  }

  @override
  Future<bool> hasSession() async {
    return await _localDataSource.hasValidSession();
  }
}
