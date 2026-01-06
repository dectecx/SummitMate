import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/models/user_profile.dart';
import '../../services/log_service.dart';
import 'interfaces/i_auth_session_repository.dart';

/// Repository responsible for managing local authentication session.
class AuthSessionRepository implements IAuthSessionRepository {
  static const String _source = 'AuthSessionRepository';

  // Secure Storage Keys
  static const String _keyAuthToken = 'auth_token';
  static const String _keyUserProfile = 'user_profile';

  final FlutterSecureStorage _secureStorage;

  AuthSessionRepository({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  @override
  Future<void> saveSession(String token, UserProfile user) async {
    try {
      await _secureStorage.write(key: _keyAuthToken, value: token);
      await _secureStorage.write(key: _keyUserProfile, value: jsonEncode(user.toJson()));
      LogService.debug('Session saved for user: ${user.email}', source: _source);
    } catch (e) {
      LogService.error('Failed to save session: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<void> clearSession() async {
    try {
      await _secureStorage.delete(key: _keyAuthToken);
      await _secureStorage.delete(key: _keyUserProfile);
      LogService.debug('Session cleared', source: _source);
    } catch (e) {
      LogService.error('Failed to clear session: $e', source: _source);
      rethrow; // Optional: maybe swallow? But caller might want to know.
    }
  }

  @override
  Future<String?> getAuthToken() async {
    try {
      return await _secureStorage.read(key: _keyAuthToken);
    } catch (e) {
      LogService.error('Failed to read auth token: $e', source: _source);
      return null;
    }
  }

  @override
  Future<UserProfile?> getUserProfile() async {
    try {
      final json = await _secureStorage.read(key: _keyUserProfile);
      if (json == null) return null;
      return UserProfile.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (e) {
      LogService.warning('Failed to parse cached user profile: $e', source: _source);
      return null;
    }
  }

  @override
  Future<bool> hasSession() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }
}
