import 'package:flutter_test/flutter_test.dart';

import 'package:summitmate/data/models/user_profile.dart';
import 'package:summitmate/presentation/providers/auth_provider.dart';
import 'package:summitmate/domain/interfaces/i_auth_service.dart';

// ============================================================
// === MOCKS ===
// ============================================================

/// Mock AuthService implementing IAuthService for testing AuthProvider
class MockAuthService implements IAuthService {
  // Mock control flags
  AuthResult? mockRegisterResult;
  AuthResult? mockLoginResult;
  AuthResult? mockValidateResult;
  AuthResult? mockDeleteResult;
  AuthResult? mockVerifyEmailResult;
  AuthResult? mockResendCodeResult;
  AuthResult? mockUpdateProfileResult;
  bool logoutCalled = false;
  String? storedToken;
  UserProfile? cachedUser;
  bool isLoggedInValue = false;
  bool _isOfflineMode = false;

  @override
  bool get isOfflineMode => _isOfflineMode;

  @override
  Future<AuthResult> register({
    required String email,
    required String password,
    required String displayName,
    String? avatar,
  }) async {
    return mockRegisterResult ?? AuthResult.failure(errorCode: 'ERROR', errorMessage: 'Not configured');
  }

  @override
  Future<AuthResult> login({required String email, required String password}) async {
    return mockLoginResult ?? AuthResult.failure(errorCode: 'ERROR', errorMessage: 'Not configured');
  }

  @override
  Future<AuthResult> loginWithProvider(OAuthProvider provider) async {
    return AuthResult.failure(errorCode: 'NOT_IMPLEMENTED', errorMessage: 'Not implemented');
  }

  @override
  Future<AuthResult> verifyEmail({required String email, required String code}) async {
    return mockVerifyEmailResult ?? AuthResult.failure(errorCode: 'ERROR', errorMessage: 'Not configured');
  }

  @override
  Future<AuthResult> resendVerificationCode({required String email}) async {
    return mockResendCodeResult ?? AuthResult.failure(errorCode: 'ERROR', errorMessage: 'Not configured');
  }

  @override
  Future<AuthResult> validateSession() async {
    return mockValidateResult ?? AuthResult.failure(errorCode: 'NO_TOKEN', errorMessage: 'Not configured');
  }

  @override
  Future<AuthResult> refreshToken() async {
    return AuthResult.failure(errorCode: 'NOT_SUPPORTED', errorMessage: 'Not supported');
  }

  @override
  Future<AuthResult> deleteAccount() async {
    return mockDeleteResult ?? AuthResult.failure(errorCode: 'ERROR', errorMessage: 'Not configured');
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }

  @override
  Future<String?> getAccessToken() async => storedToken;

  @override
  Future<String?> getRefreshToken() async => null;

  @override
  Future<UserProfile?> getCachedUserProfile() async => cachedUser;

  @override
  Future<AuthResult> updateProfile({String? displayName, String? avatar}) async {
    return mockUpdateProfileResult ?? AuthResult.failure(errorCode: 'ERROR', errorMessage: 'Not configured');
  }

  @override
  Future<bool> isLoggedIn() async => isLoggedInValue;
}

// ============================================================
// === TEST DATA ===
// ============================================================

UserProfile createTestUser({
  String uuid = 'test-uuid',
  String email = 'test@example.com',
  String displayName = 'Test User',
  String avatar = '🐻',
  bool isVerified = true,
}) {
  return UserProfile(uuid: uuid, email: email, displayName: displayName, avatar: avatar, isVerified: isVerified);
}

// ============================================================
// === TESTS ===
// ============================================================

void main() {
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
  });

  group('AuthProvider initialization', () {
    test('starts in loading state', () {
      // Note: _initSession is called in constructor, so we test immediate state
      mockAuthService.isLoggedInValue = false;
      mockAuthService.mockValidateResult = AuthResult.failure(errorCode: 'NO_TOKEN', errorMessage: '');

      final provider = AuthProvider(authService: mockAuthService);

      // Initial state is loading, then changes after _initSession
      expect(provider.state, anyOf(AuthState.loading, AuthState.unauthenticated));
    });

    test('transitions to unauthenticated when no session exists', () async {
      mockAuthService.isLoggedInValue = false;

      final provider = AuthProvider(authService: mockAuthService);

      // Wait for _initSession to complete
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.state, AuthState.unauthenticated);
    });

    test('transitions to authenticated when valid session exists', () async {
      mockAuthService.isLoggedInValue = true;
      mockAuthService.mockValidateResult = AuthResult.success(user: createTestUser(), accessToken: 'valid-token');

      final provider = AuthProvider(authService: mockAuthService);

      // Wait for _initSession to complete
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.state, AuthState.authenticated);
      expect(provider.user?.email, 'test@example.com');
    });
  });

  group('AuthProvider.register', () {
    test('updates state to authenticated on successful verified registration', () async {
      mockAuthService.isLoggedInValue = false;
      mockAuthService.mockValidateResult = AuthResult.failure(errorCode: 'NO_TOKEN', errorMessage: '');
      mockAuthService.mockRegisterResult = AuthResult.success(
        user: createTestUser(isVerified: true),
        accessToken: 'new-token',
      );

      final provider = AuthProvider(authService: mockAuthService);
      await Future.delayed(const Duration(milliseconds: 50));

      final result = await provider.register(email: 'new@example.com', password: 'password', displayName: 'New User');

      expect(result.isSuccess, isTrue);
      expect(provider.state, AuthState.authenticated);
    });

    test('stays unauthenticated on unverified registration', () async {
      mockAuthService.isLoggedInValue = false;
      mockAuthService.mockValidateResult = AuthResult.failure(errorCode: 'NO_TOKEN', errorMessage: '');
      mockAuthService.mockRegisterResult = AuthResult.success(
        user: createTestUser(isVerified: false),
        accessToken: 'new-token',
      );

      final provider = AuthProvider(authService: mockAuthService);
      await Future.delayed(const Duration(milliseconds: 50));

      final result = await provider.register(email: 'new@example.com', password: 'password', displayName: 'New User');

      expect(result.isSuccess, isTrue);
      expect(provider.state, AuthState.unauthenticated);
    });

    test('stays unauthenticated on registration failure', () async {
      mockAuthService.isLoggedInValue = false;
      mockAuthService.mockValidateResult = AuthResult.failure(errorCode: 'NO_TOKEN', errorMessage: '');
      mockAuthService.mockRegisterResult = AuthResult.failure(errorCode: '0801', errorMessage: '此信箱已被註冊');

      final provider = AuthProvider(authService: mockAuthService);
      await Future.delayed(const Duration(milliseconds: 50));

      final result = await provider.register(email: 'existing@example.com', password: 'password', displayName: 'User');

      expect(result.isSuccess, isFalse);
      expect(provider.state, AuthState.unauthenticated);
    });
  });

  group('AuthProvider.login', () {
    test('updates state to authenticated on successful login', () async {
      mockAuthService.isLoggedInValue = false;
      mockAuthService.mockValidateResult = AuthResult.failure(errorCode: 'NO_TOKEN', errorMessage: '');
      mockAuthService.mockLoginResult = AuthResult.success(user: createTestUser(), accessToken: 'login-token');

      final provider = AuthProvider(authService: mockAuthService);
      await Future.delayed(const Duration(milliseconds: 50));

      final result = await provider.login(email: 'test@example.com', password: 'password');

      expect(result.isSuccess, isTrue);
      expect(provider.state, AuthState.authenticated);
      expect(provider.isOffline, isFalse);
    });

    test('sets offline flag when login returns offline', () async {
      mockAuthService.isLoggedInValue = false;
      mockAuthService.mockValidateResult = AuthResult.failure(errorCode: 'NO_TOKEN', errorMessage: '');
      mockAuthService.mockLoginResult = AuthResult.success(
        user: createTestUser(),
        accessToken: 'cached-token',
        isOffline: true,
      );

      final provider = AuthProvider(authService: mockAuthService);
      await Future.delayed(const Duration(milliseconds: 50));

      await provider.login(email: 'test@example.com', password: 'password');

      expect(provider.state, AuthState.authenticated);
      expect(provider.isOffline, isTrue);
    });

    test('stays unauthenticated on login failure', () async {
      mockAuthService.isLoggedInValue = false;
      mockAuthService.mockValidateResult = AuthResult.failure(errorCode: 'NO_TOKEN', errorMessage: '');
      mockAuthService.mockLoginResult = AuthResult.failure(errorCode: '0802', errorMessage: '帳號或密碼錯誤');

      final provider = AuthProvider(authService: mockAuthService);
      await Future.delayed(const Duration(milliseconds: 50));

      final result = await provider.login(email: 'test@example.com', password: 'wrong');

      expect(result.isSuccess, isFalse);
      expect(provider.state, AuthState.unauthenticated);
    });
  });

  group('AuthProvider.logout', () {
    test('resets state to unauthenticated', () async {
      mockAuthService.isLoggedInValue = true;
      mockAuthService.mockValidateResult = AuthResult.success(user: createTestUser(), accessToken: 'token');

      final provider = AuthProvider(authService: mockAuthService);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.state, AuthState.authenticated);

      await provider.logout();

      expect(provider.state, AuthState.unauthenticated);
      expect(provider.user, isNull);
      expect(provider.isOffline, isFalse);
      expect(mockAuthService.logoutCalled, isTrue);
    });
  });

  group('AuthProvider.skipLogin', () {
    test('sets authenticated state with offline flag for guest mode', () async {
      mockAuthService.isLoggedInValue = false;
      mockAuthService.mockValidateResult = AuthResult.failure(errorCode: 'NO_TOKEN', errorMessage: '');

      final provider = AuthProvider(authService: mockAuthService);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.state, AuthState.unauthenticated);

      provider.skipLogin();

      expect(provider.state, AuthState.authenticated);
      expect(provider.isOffline, isTrue);
      expect(provider.user, isNull);
      expect(provider.displayName, '訪客');
    });
  });

  group('AuthProvider.deleteAccount', () {
    test('resets state on successful deletion', () async {
      mockAuthService.isLoggedInValue = true;
      mockAuthService.mockValidateResult = AuthResult.success(user: createTestUser(), accessToken: 'token');
      mockAuthService.mockDeleteResult = AuthResult.success();

      final provider = AuthProvider(authService: mockAuthService);
      await Future.delayed(const Duration(milliseconds: 50));

      final result = await provider.deleteAccount();

      expect(result.isSuccess, isTrue);
      expect(provider.state, AuthState.unauthenticated);
      expect(provider.user, isNull);
    });

    test('keeps state on deletion failure', () async {
      mockAuthService.isLoggedInValue = true;
      mockAuthService.mockValidateResult = AuthResult.success(user: createTestUser(), accessToken: 'token');
      mockAuthService.mockDeleteResult = AuthResult.failure(errorCode: 'ERROR', errorMessage: 'Failed');

      final provider = AuthProvider(authService: mockAuthService);
      await Future.delayed(const Duration(milliseconds: 50));

      final result = await provider.deleteAccount();

      expect(result.isSuccess, isFalse);
      expect(provider.state, AuthState.authenticated);
    });
  });

  group('AuthProvider getters', () {
    test('displayName returns user name or 訪客', () async {
      mockAuthService.isLoggedInValue = false;
      mockAuthService.mockValidateResult = AuthResult.failure(errorCode: 'NO_TOKEN', errorMessage: '');

      final provider = AuthProvider(authService: mockAuthService);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.displayName, '訪客');

      mockAuthService.mockLoginResult = AuthResult.success(
        user: createTestUser(displayName: 'Alice'),
        accessToken: 'token',
      );
      await provider.login(email: 'a', password: 'b');

      expect(provider.displayName, 'Alice');
    });

    test('avatar returns user avatar or default', () async {
      mockAuthService.isLoggedInValue = false;
      mockAuthService.mockValidateResult = AuthResult.failure(errorCode: 'NO_TOKEN', errorMessage: '');

      final provider = AuthProvider(authService: mockAuthService);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.avatar, '🐻');
    });

    test('isAuthenticated reflects state correctly', () async {
      mockAuthService.isLoggedInValue = false;
      mockAuthService.mockValidateResult = AuthResult.failure(errorCode: 'NO_TOKEN', errorMessage: '');

      final provider = AuthProvider(authService: mockAuthService);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.isAuthenticated, isFalse);

      provider.skipLogin();

      expect(provider.isAuthenticated, isTrue);
    });
  });
}
