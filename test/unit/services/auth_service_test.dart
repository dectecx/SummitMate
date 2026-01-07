import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:summitmate/data/models/user_profile.dart';
import 'package:summitmate/data/repositories/interfaces/i_auth_session_repository.dart';
import 'package:summitmate/services/auth_service.dart';
import 'package:summitmate/services/gas_api_client.dart';

// ============================================================
// === MOCKS ===
// ============================================================

/// Mock GasApiClient for testing API calls
class MockGasApiClient extends GasApiClient {
  MockGasApiClient() : super(baseUrl: 'https://mock.url');

  Map<String, dynamic>? mockResponseData;
  String mockResponseCode = '0000';
  String mockResponseMessage = 'Success';
  bool shouldThrowError = false;

  @override
  Future<Response> post(Map<String, dynamic> body, {bool requiresAuth = false}) async {
    if (shouldThrowError) {
      throw DioException(
        requestOptions: RequestOptions(path: ''),
        message: 'Network error',
      );
    }

    final responseBody = {
      'code': mockResponseCode,
      'message': mockResponseMessage,
      'data': mockResponseData ?? {},
    };

    return Response(
      requestOptions: RequestOptions(path: ''),
      data: responseBody,
      statusCode: 200,
    );
  }
}

/// Mock AuthSessionRepository for testing session persistence
class MockAuthSessionRepository implements IAuthSessionRepository {
  String? storedToken;
  UserProfile? storedUser;
  bool hasValidSession = false;

  @override
  Future<void> saveSession(String token, UserProfile user) async {
    storedToken = token;
    storedUser = user;
    hasValidSession = true;
  }

  @override
  Future<void> clearSession() async {
    storedToken = null;
    storedUser = null;
    hasValidSession = false;
  }

  @override
  Future<String?> getAuthToken() async => storedToken;

  @override
  Future<UserProfile?> getUserProfile() async => storedUser;

  @override
  Future<bool> hasSession() async => hasValidSession;
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

Map<String, dynamic> createUserJson({
  String uuid = 'test-uuid',
  String email = 'test@example.com',
  String displayName = 'Test User',
  String avatar = '🐻',
  bool isVerified = true,
}) {
  return {
    'uuid': uuid,
    'email': email,
    'displayName': displayName,
    'avatar': avatar,
    'role': 'member',
    'isVerified': isVerified,
  };
}

// ============================================================
// === TESTS ===
// ============================================================

void main() {
  late AuthService authService;
  late MockGasApiClient mockApiClient;
  late MockAuthSessionRepository mockSessionRepo;

  setUp(() {
    mockApiClient = MockGasApiClient();
    mockSessionRepo = MockAuthSessionRepository();
    authService = AuthService(
      apiClient: mockApiClient,
      sessionRepository: mockSessionRepo,
    );
  });

  group('AuthService.register', () {
    test('returns success and saves session on valid registration', () async {
      mockApiClient.mockResponseData = {
        'user': createUserJson(isVerified: false),
        'authToken': 'new-token-123',
      };

      final result = await authService.register(
        email: 'new@example.com',
        password: 'password123',
        displayName: 'New User',
      );

      expect(result.isSuccess, isTrue);
      expect(result.user?.email, 'test@example.com');
      expect(result.token, 'new-token-123');
      expect(mockSessionRepo.storedToken, 'new-token-123');
    });

    test('returns failure on API error', () async {
      mockApiClient.mockResponseCode = '0801';
      mockApiClient.mockResponseMessage = '此信箱已被註冊';

      final result = await authService.register(
        email: 'existing@example.com',
        password: 'password123',
        displayName: 'User',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, '0801');
      expect(result.errorMessage, '此信箱已被註冊');
    });

    test('returns network error on exception', () async {
      mockApiClient.shouldThrowError = true;

      final result = await authService.register(
        email: 'test@example.com',
        password: 'password123',
        displayName: 'User',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, 'NETWORK_ERROR');
    });
  });

  group('AuthService.login', () {
    test('returns success and saves session on valid login', () async {
      mockApiClient.mockResponseData = {
        'user': createUserJson(),
        'authToken': 'login-token-456',
      };

      final result = await authService.login(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result.isSuccess, isTrue);
      expect(result.user?.email, 'test@example.com');
      expect(result.token, 'login-token-456');
      expect(mockSessionRepo.storedToken, 'login-token-456');
    });

    test('returns failure on invalid credentials', () async {
      mockApiClient.mockResponseCode = '0802';
      mockApiClient.mockResponseMessage = '帳號或密碼錯誤';

      final result = await authService.login(
        email: 'test@example.com',
        password: 'wrongpassword',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, '0802');
    });

    test('returns network error on exception', () async {
      mockApiClient.shouldThrowError = true;

      final result = await authService.login(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, 'NETWORK_ERROR');
    });
  });

  group('AuthService.verifyEmail', () {
    test('returns success on valid code', () async {
      // Set up session first for validateSession call
      mockSessionRepo.storedToken = 'existing-token';
      mockApiClient.mockResponseData = {
        'user': createUserJson(isVerified: true),
      };

      final result = await authService.verifyEmail(
        email: 'test@example.com',
        code: '123456',
      );

      expect(result.isSuccess, isTrue);
    });

    test('returns failure on invalid code', () async {
      mockApiClient.mockResponseCode = '0805';
      mockApiClient.mockResponseMessage = '驗證碼無效';

      final result = await authService.verifyEmail(
        email: 'test@example.com',
        code: '000000',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, '0805');
    });
  });

  group('AuthService.resendVerificationCode', () {
    test('returns success on valid request', () async {
      mockApiClient.mockResponseData = {};

      final result = await authService.resendVerificationCode(
        email: 'test@example.com',
      );

      expect(result.isSuccess, isTrue);
    });

    test('returns network error on exception', () async {
      mockApiClient.shouldThrowError = true;

      final result = await authService.resendVerificationCode(
        email: 'test@example.com',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, 'NETWORK_ERROR');
    });
  });

  group('AuthService.validateSession', () {
    test('returns failure when no token exists', () async {
      mockSessionRepo.storedToken = null;

      final result = await authService.validateSession();

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, 'NO_TOKEN');
    });

    test('returns success and refreshes session on valid token', () async {
      mockSessionRepo.storedToken = 'valid-token';
      mockApiClient.mockResponseData = {
        'user': createUserJson(),
      };

      final result = await authService.validateSession();

      expect(result.isSuccess, isTrue);
      expect(result.user?.email, 'test@example.com');
      expect(result.isOffline, isFalse);
    });

    test('clears session and returns failure on invalid token', () async {
      mockSessionRepo.storedToken = 'invalid-token';
      mockSessionRepo.hasValidSession = true;
      mockApiClient.mockResponseCode = '0803';
      mockApiClient.mockResponseMessage = 'Token 無效';

      final result = await authService.validateSession();

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, '0803');
      expect(mockSessionRepo.hasValidSession, isFalse); // Session cleared
    });

    test('returns offline success with cached user on network error', () async {
      mockSessionRepo.storedToken = 'cached-token';
      mockSessionRepo.storedUser = createTestUser();
      mockApiClient.shouldThrowError = true;

      final result = await authService.validateSession();

      expect(result.isSuccess, isTrue);
      expect(result.isOffline, isTrue);
      expect(result.user?.email, 'test@example.com');
    });
  });

  group('AuthService.deleteAccount', () {
    test('returns failure when no token exists', () async {
      mockSessionRepo.storedToken = null;

      final result = await authService.deleteAccount();

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, 'NO_TOKEN');
    });

    test('returns success and clears session on successful deletion', () async {
      mockSessionRepo.storedToken = 'valid-token';
      mockSessionRepo.hasValidSession = true;
      mockApiClient.mockResponseData = {};

      final result = await authService.deleteAccount();

      expect(result.isSuccess, isTrue);
      expect(mockSessionRepo.hasValidSession, isFalse);
    });
  });

  group('AuthService.logout', () {
    test('clears session on logout', () async {
      mockSessionRepo.storedToken = 'token';
      mockSessionRepo.storedUser = createTestUser();
      mockSessionRepo.hasValidSession = true;

      await authService.logout();

      expect(mockSessionRepo.storedToken, isNull);
      expect(mockSessionRepo.storedUser, isNull);
      expect(mockSessionRepo.hasValidSession, isFalse);
    });
  });

  group('AuthService helper methods', () {
    test('getAuthToken returns stored token', () async {
      mockSessionRepo.storedToken = 'my-token';

      final token = await authService.getAuthToken();

      expect(token, 'my-token');
    });

    test('getCachedUserProfile returns stored user', () async {
      mockSessionRepo.storedUser = createTestUser();

      final user = await authService.getCachedUserProfile();

      expect(user?.email, 'test@example.com');
    });

    test('isLoggedIn returns session status', () async {
      mockSessionRepo.hasValidSession = true;

      final isLoggedIn = await authService.isLoggedIn();

      expect(isLoggedIn, isTrue);
    });
  });
}
