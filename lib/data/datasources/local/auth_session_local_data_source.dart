import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../interfaces/i_auth_session_local_data_source.dart';

/// 認證 Session 本地資料來源實作 (SecureStorage)
class AuthSessionLocalDataSource implements IAuthSessionLocalDataSource {
  static const String _keyToken = 'session_token';
  static const String _keyUserId = 'user_id';
  static const String _keyEmail = 'user_email';
  static const String _keyUsername = 'username';
  static const String _keyAvatar = 'user_avatar';

  final FlutterSecureStorage _secureStorage;

  AuthSessionLocalDataSource({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  @override
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _keyToken, value: token);
  }

  @override
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _keyToken);
  }

  @override
  Future<void> saveUserId(String userId) async {
    await _secureStorage.write(key: _keyUserId, value: userId);
  }

  @override
  Future<String?> getUserId() async {
    return await _secureStorage.read(key: _keyUserId);
  }

  @override
  Future<void> saveEmail(String email) async {
    await _secureStorage.write(key: _keyEmail, value: email);
  }

  @override
  Future<String?> getEmail() async {
    return await _secureStorage.read(key: _keyEmail);
  }

  @override
  Future<void> saveUsername(String username) async {
    await _secureStorage.write(key: _keyUsername, value: username);
  }

  @override
  Future<String?> getUsername() async {
    return await _secureStorage.read(key: _keyUsername);
  }

  @override
  Future<void> saveAvatar(String avatar) async {
    await _secureStorage.write(key: _keyAvatar, value: avatar);
  }

  @override
  Future<String?> getAvatar() async {
    return await _secureStorage.read(key: _keyAvatar);
  }

  @override
  Future<void> clearAll() async {
    await _secureStorage.delete(key: _keyToken);
    await _secureStorage.delete(key: _keyUserId);
    await _secureStorage.delete(key: _keyEmail);
    await _secureStorage.delete(key: _keyUsername);
    await _secureStorage.delete(key: _keyAvatar);
  }

  @override
  Future<bool> hasValidSession() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
