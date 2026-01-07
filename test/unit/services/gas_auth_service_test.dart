import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:summitmate/data/models/user_profile.dart';
import 'package:summitmate/data/repositories/interfaces/i_auth_session_repository.dart';
import 'package:summitmate/services/gas_auth_service.dart';
import 'package:summitmate/services/gas_api_client.dart';
import 'package:summitmate/services/interfaces/i_token_validator.dart';

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

    final responseBody = {'code': mockResponseCode, 'message': mockResponseMessage, 'data': mockResponseData ?? {}};

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
  String? storedRefreshToken;
  UserProfile? storedUser;
  bool hasValidSession = false;

  @override
  Future<void> saveSession(String accessToken, UserProfile user, {String? refreshToken}) async {
    storedToken = accessToken;
    storedUser = user;
    if (refreshToken != null) {
      storedRefreshToken = refreshToken;
    }
    hasValidSession = true;
  }

  @override
  Future<void> clearSession() async {
    storedToken = null;
    storedRefreshToken = null;
    storedUser = null;
    hasValidSession = false;
  }

  @override
  Future<String?> getAuthToken() async => storedToken;

  @override
  Future<String?> getRefreshToken() async => storedRefreshToken;

  @override
  Future<UserProfile?> getUserProfile() async => storedUser;

  @override
  Future<bool> hasSession() async => hasValidSession;
}

class MockTokenValidator implements ITokenValidator {
  bool shouldBeExpired = false;
  bool shouldBeExpiringSoon = false;

  @override
  TokenValidationResult validate(String token) {
    if (shouldBeExpired) {
      return TokenValidationResult.invalid('EXPIRED');
    }
    return TokenValidationResult.valid(
      TokenPayload(
        userId: 'test-uid',
        issuedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        expiresAt: DateTime.now().add(const Duration(minutes: 30)),
        tokenType: 'access',
      ),
    );
  }

  @override
  TokenPayload? decode(String token) => null;

  @override
  bool isExpired(String token) => shouldBeExpired;

  @override
  bool isExpiringSoon(String token, {Duration threshold = const Duration(minutes: 5)}) => shouldBeExpiringSoon;
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
  late GasAuthService authService;
  late MockGasApiClient mockApiClient;
  late MockAuthSessionRepository mockSessionRepo;
  late MockTokenValidator mockTokenValidator;

  setUp(() {
    mockApiClient = MockGasApiClient();
    mockSessionRepo = MockAuthSessionRepository();
    mockTokenValidator = MockTokenValidator();
    authService = GasAuthService(
      apiClient: mockApiClient,
      sessionRepository: mockSessionRepo,
      tokenValidator: mockTokenValidator,
    );
  });

  group('GasAuthService.register', () {
    test('returns requiresVerification on valid registration', () async {
      mockApiClient.mockResponseData = {'user': createUserJson(isVerified: false)};

      final result = await authService.register(
        email: 'new@example.com',
        password: 'password123',
        displayName: 'New User',
      );

      // GasAuthService returns requiresVerification, not success with token immediately
      expect(result.isSuccess, isFalse);
      expect(result.errorCode, 'REQUIRES_VERIFICATION');
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
  });

  group('GasAuthService.login', () {
    test('returns success, saves session and tokens on valid login', () async {
      mockApiClient.mockResponseData = {
        'user': createUserJson(),
        'accessToken': 'login-access-token',
        'refreshToken': 'login-refresh-token',
      };

      final result = await authService.login(email: 'test@example.com', password: 'password123');

      expect(result.isSuccess, isTrue);
      expect(result.user?.email, 'test@example.com');
      expect(result.accessToken, 'login-access-token');
      expect(result.refreshToken, 'login-refresh-token');
      expect(mockSessionRepo.storedToken, 'login-access-token');
      expect(mockSessionRepo.storedRefreshToken, 'login-refresh-token');
    });
  });

  group('GasAuthService.validateSession', () {
    test('returns failure when no token exists', () async {
      mockSessionRepo.storedToken = null;

      final result = await authService.validateSession();

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, 'NO_TOKEN');
    });

    test('returns success on valid token', () async {
      mockSessionRepo.storedToken = 'valid-token';
      mockApiClient.mockResponseData = {'user': createUserJson()};

      final result = await authService.validateSession();

      expect(result.isSuccess, isTrue);
      expect(result.user?.email, 'test@example.com');
      expect(result.isOffline, isFalse);
    });

    test('refreshes token if expiring soon', () async {
      mockSessionRepo.storedToken = 'expiring-token';
      mockSessionRepo.storedRefreshToken = 'valid-refresh-token';
      mockTokenValidator.shouldBeExpiringSoon = true;

      // Mock refresh API response
      // Note: validateSession calls refreshToken() which calls API action 'auth_refresh_token'
      // But here we can't easily distinguish multiple API calls in this simple mock.
      // We will assume the mock client returns success for whatever is called.
      // If validateSession calls refresh first, it returns.

      mockApiClient.mockResponseData = {
        'accessToken': 'new-access-token',
        'refreshToken': 'valid-refresh-token', // typically returns same or new refresh token
        'user': createUserJson(),
      };

      final result = await authService.validateSession();

      expect(result.isSuccess, isTrue);
      expect(result.accessToken, 'new-access-token');
      expect(mockSessionRepo.storedToken, 'new-access-token');
    });
  });

  group('GasAuthService.refreshToken', () {
    test('returns success and updates session on valid refresh', () async {
      mockSessionRepo.storedRefreshToken = 'old-refresh-token';
      mockSessionRepo.storedUser = createTestUser();

      mockApiClient.mockResponseData = {'accessToken': 'brand-new-token'};

      final result = await authService.refreshToken();

      expect(result.isSuccess, isTrue);
      expect(result.accessToken, 'brand-new-token');
      expect(mockSessionRepo.storedToken, 'brand-new-token');
    });

    test('returns failure if no refresh token', () async {
      mockSessionRepo.storedRefreshToken = null;

      final result = await authService.refreshToken();

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, 'NO_REFRESH_TOKEN');
    });
  });
}
