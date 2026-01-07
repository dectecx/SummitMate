import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:summitmate/data/models/user_profile.dart';
import 'package:summitmate/data/repositories/interfaces/i_auth_session_repository.dart';
import 'package:summitmate/presentation/providers/auth_provider.dart';
import 'package:summitmate/services/auth_service.dart';
import 'package:summitmate/services/gas_api_client.dart';

// ============================================================
// === MOCKS ===
// ============================================================

/// Minimal mock GasApiClient for MockAuthService constructor
class _MockGasApiClient extends GasApiClient {
  _MockGasApiClient() : super(baseUrl: 'https://mock.url');

  @override
  Future<Response> post(Map<String, dynamic> body, {bool requiresAuth = false}) async {
    return Response(requestOptions: RequestOptions(path: ''), data: {}, statusCode: 200);
  }
}

/// Minimal mock session repo for MockAuthService constructor
class _MockSessionRepo implements IAuthSessionRepository {
  @override
  Future<void> saveSession(String token, UserProfile user) async {}
  @override
  Future<void> clearSession() async {}
  @override
  Future<String?> getAuthToken() async => null;
  @override
  Future<UserProfile?> getUserProfile() async => null;
  @override
  Future<bool> hasSession() async => false;
}

/// Mock AuthService for testing AuthProvider
/// Extends AuthService but overrides all methods to avoid real API calls
class MockAuthService extends AuthService {
  MockAuthService() : super(
    apiClient: _MockGasApiClient(),
    sessionRepository: _MockSessionRepo(),
  );

  // Mock control flags
  AuthResult? mockRegisterResult;
  AuthResult? mockLoginResult;
  AuthResult? mockValidateResult;
  AuthResult? mockDeleteResult;
  bool logoutCalled = false;
  String? storedToken;
  UserProfile? cachedUser;
  bool isLoggedInValue = false;

  @override
  Future<AuthResult> register({
    required String email,
    required String password,
    required String displayName,
    String? avatar,
  }) async {
    return mockRegisterResult ?? AuthResult.failure(code: 'ERROR', message: 'Not configured');
  }

  @override
  Future<AuthResult> login({required String email, required String password}) async {
    return mockLoginResult ?? AuthResult.failure(code: 'ERROR', message: 'Not configured');
  }

  @override
  Future<AuthResult> validateSession() async {
    return mockValidateResult ?? AuthResult.failure(code: 'NO_TOKEN', message: 'Not configured');
  }

  @override
  Future<AuthResult> deleteAccount() async {
    return mockDeleteResult ?? AuthResult.failure(code: 'ERROR', message: 'Not configured');
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }

  @override
  Future<String?> getAuthToken() async => storedToken;

  @override
  Future<UserProfile?> getCachedUserProfile() async => cachedUser;

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
  return UserProfile(
    uuid: uuid,
    email: email,
    displayName: displayName,
    avatar: avatar,
    isVerified: isVerified,
  );
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
      mockAuthService.mockValidateResult = AuthResult.failure(code: 'NO_TOKEN', message: '');
      
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
      mockAuthService.mockValidateResult = AuthResult.success(
        user: createTestUser(),
        token: 'valid-token',
      );
      
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
      mockAuthService.mockValidateResult = AuthResult.failure(code: 'NO_TOKEN', message: '');
      mockAuthService.mockRegisterResult = AuthResult.success(
        user: createTestUser(isVerified: true),
        token: 'new-token',
      );
      
      final provider = AuthProvider(authService: mockAuthService);
      await Future.delayed(const Duration(milliseconds: 50));
      
      final result = await provider.register(
        email: 'new@example.com',
        password: 'password',
        displayName: 'New User',
      );
      
      expect(result.isSuccess, isTrue);
      expect(provider.state, AuthState.authenticated);
    });

    test('stays unauthenticated on unverified registration', () async {
      mockAuthService.isLoggedInValue = false;
      mockAuthService.mockValidateResult = AuthResult.failure(code: 'NO_TOKEN', message: '');
      mockAuthService.mockRegisterResult = AuthResult.success(
        user: createTestUser(isVerified: false),
        token: 'new-token',
      );
      
      final provider = AuthProvider(authService: mockAuthService);
      await Future.delayed(const Duration(milliseconds: 50));
      
      final result = await provider.register(
        email: 'new@example.com',
        password: 'password',
        displayName: 'New User',
      );
      
      expect(result.isSuccess, isTrue);
      expect(provider.state, AuthState.unauthenticated);
    });

    test('stays unauthenticated on registration failure', () async {
      mockAuthService.isLoggedInValue = false;
      mockAuthService.mockValidateResult = AuthResult.failure(code: 'NO_TOKEN', message: '');
      mockAuthService.mockRegisterResult = AuthResult.failure(
        code: '0801',
        message: '此信箱已被註冊',
      );
      
      final provider = AuthProvider(authService: mockAuthService);
      await Future.delayed(const Duration(milliseconds: 50));
      
      final result = await provider.register(
        email: 'existing@example.com',
        password: 'password',
        displayName: 'User',
      );
      
      expect(result.isSuccess, isFalse);
      expect(provider.state, AuthState.unauthenticated);
    });
  });

  group('AuthProvider.login', () {
    test('updates state to authenticated on successful login', () async {
      mockAuthService.isLoggedInValue = false;
      mockAuthService.mockValidateResult = AuthResult.failure(code: 'NO_TOKEN', message: '');
      mockAuthService.mockLoginResult = AuthResult.success(
        user: createTestUser(),
        token: 'login-token',
      );
      
      final provider = AuthProvider(authService: mockAuthService);
      await Future.delayed(const Duration(milliseconds: 50));
      
      final result = await provider.login(
        email: 'test@example.com',
        password: 'password',
      );
      
      expect(result.isSuccess, isTrue);
      expect(provider.state, AuthState.authenticated);
      expect(provider.isOffline, isFalse);
    });

    test('sets offline flag when login returns offline', () async {
      mockAuthService.isLoggedInValue = false;
      mockAuthService.mockValidateResult = AuthResult.failure(code: 'NO_TOKEN', message: '');
      mockAuthService.mockLoginResult = AuthResult.success(
        user: createTestUser(),
        token: 'cached-token',
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
      mockAuthService.mockValidateResult = AuthResult.failure(code: 'NO_TOKEN', message: '');
      mockAuthService.mockLoginResult = AuthResult.failure(
        code: '0802',
        message: '帳號或密碼錯誤',
      );
      
      final provider = AuthProvider(authService: mockAuthService);
      await Future.delayed(const Duration(milliseconds: 50));
      
      final result = await provider.login(
        email: 'test@example.com',
        password: 'wrong',
      );
      
      expect(result.isSuccess, isFalse);
      expect(provider.state, AuthState.unauthenticated);
    });
  });

  group('AuthProvider.logout', () {
    test('resets state to unauthenticated', () async {
      mockAuthService.isLoggedInValue = true;
      mockAuthService.mockValidateResult = AuthResult.success(
        user: createTestUser(),
        token: 'token',
      );
      
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
      mockAuthService.mockValidateResult = AuthResult.failure(code: 'NO_TOKEN', message: '');
      
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
      mockAuthService.mockValidateResult = AuthResult.success(
        user: createTestUser(),
        token: 'token',
      );
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
      mockAuthService.mockValidateResult = AuthResult.success(
        user: createTestUser(),
        token: 'token',
      );
      mockAuthService.mockDeleteResult = AuthResult.failure(
        code: 'ERROR',
        message: 'Failed',
      );
      
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
      mockAuthService.mockValidateResult = AuthResult.failure(code: 'NO_TOKEN', message: '');
      
      final provider = AuthProvider(authService: mockAuthService);
      await Future.delayed(const Duration(milliseconds: 50));
      
      expect(provider.displayName, '訪客');
      
      mockAuthService.mockLoginResult = AuthResult.success(
        user: createTestUser(displayName: 'Alice'),
        token: 'token',
      );
      await provider.login(email: 'a', password: 'b');
      
      expect(provider.displayName, 'Alice');
    });

    test('avatar returns user avatar or default', () async {
      mockAuthService.isLoggedInValue = false;
      mockAuthService.mockValidateResult = AuthResult.failure(code: 'NO_TOKEN', message: '');
      
      final provider = AuthProvider(authService: mockAuthService);
      await Future.delayed(const Duration(milliseconds: 50));
      
      expect(provider.avatar, '🐻');
    });

    test('isAuthenticated reflects state correctly', () async {
      mockAuthService.isLoggedInValue = false;
      mockAuthService.mockValidateResult = AuthResult.failure(code: 'NO_TOKEN', message: '');
      
      final provider = AuthProvider(authService: mockAuthService);
      await Future.delayed(const Duration(milliseconds: 50));
      
      expect(provider.isAuthenticated, isFalse);
      
      provider.skipLogin();
      
      expect(provider.isAuthenticated, isTrue);
    });
  });
}
