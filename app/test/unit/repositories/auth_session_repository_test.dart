import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/data/datasources/interfaces/i_auth_session_local_data_source.dart';
import 'package:summitmate/data/repositories/auth_session_repository.dart';
import 'package:summitmate/domain/domain.dart';

/// 以 Map 模擬 SecureStorage 的資料來源。
class _InMemorySessionDataSource implements IAuthSessionLocalDataSource {
  final store = <String, String>{};

  @override
  Future<void> saveToken(String token) async => store['token'] = token;
  @override
  Future<String?> getToken() async => store['token'];
  @override
  Future<void> saveRefreshToken(String token) async => store['refresh'] = token;
  @override
  Future<String?> getRefreshToken() async => store['refresh'];
  @override
  Future<void> saveUserId(String userId) async => store['id'] = userId;
  @override
  Future<String?> getUserId() async => store['id'];
  @override
  Future<void> saveEmail(String email) async => store['email'] = email;
  @override
  Future<String?> getEmail() async => store['email'];
  @override
  Future<void> saveProfileJson(String profileJson) async => store['profile'] = profileJson;
  @override
  Future<String?> getProfileJson() async => store['profile'];
  @override
  Future<void> saveUsername(String username) async => store['username'] = username;
  @override
  Future<String?> getUsername() async => store['username'];
  @override
  Future<void> saveAvatar(String avatar) async => store['avatar'] = avatar;
  @override
  Future<String?> getAvatar() async => store['avatar'];
  @override
  Future<void> clearAll() async => store.clear();
  @override
  Future<bool> hasValidSession() async => (store['token'] ?? '').isNotEmpty;
}

void main() {
  late _InMemorySessionDataSource dataSource;
  late AuthSessionRepository repository;

  const guide = UserProfile(
    id: 'u1',
    email: 'guide@example.com',
    displayName: 'Guide',
    avatar: '🦊',
    roleId: 'role-guide',
    role: 'guide',
    permissions: ['trip.view', 'trip.edit'],
    isVerified: true,
  );

  setUp(() {
    dataSource = _InMemorySessionDataSource();
    repository = AuthSessionRepository(localDataSource: dataSource);
  });

  group('AuthSessionRepository profile persistence', () {
    test(
      'Given a saved session, When reading the profile back, Then role, permissions and verification survive',
      () async {
        await repository.saveSession('token', guide, refreshToken: 'refresh');

        final profile = await repository.getUserProfile();

        expect(profile, guide);
        expect(profile!.permissions, contains('trip.edit'));
      },
    );

    test(
      'Given a session saved by an older version without the profile, When reading it, Then basic fields are returned',
      () async {
        dataSource.store.addAll({'id': 'u2', 'email': 'old@example.com', 'username': 'Old', 'avatar': '🐻'});

        final profile = await repository.getUserProfile();

        expect(profile?.id, 'u2');
        expect(profile?.displayName, 'Old');
        expect(profile?.permissions, isEmpty);
      },
    );

    test('Given a saved session, When clearing it, Then the profile is gone too', () async {
      await repository.saveSession('token', guide);

      await repository.clearSession();

      expect(await repository.getUserProfile(), isNull);
      expect(await repository.hasSession(), isFalse);
    });

    test(
      'Given a session saved without a refresh token, When saving again, Then the stored refresh token is kept',
      () async {
        await repository.saveSession('token-1', guide, refreshToken: 'refresh-1');

        await repository.saveSession('token-2', guide);

        expect(await repository.getRefreshToken(), 'refresh-1');
      },
    );
  });
}
