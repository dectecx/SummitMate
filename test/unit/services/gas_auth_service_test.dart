import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/infrastructure/clients/network_aware_client.dart';
import 'package:summitmate/domain/interfaces/i_connectivity_service.dart';

import 'package:summitmate/data/models/user_profile.dart';
import 'package:summitmate/data/repositories/interfaces/i_auth_session_repository.dart';
import 'package:summitmate/infrastructure/services/gas_auth_service.dart';
import 'package:summitmate/infrastructure/clients/gas_api_client.dart';
import 'package:summitmate/domain/interfaces/i_token_validator.dart';
import 'package:summitmate/core/constants/gas_error_codes.dart';

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
  String? storedAccessToken;
  String? storedRefreshToken;
  UserProfile? storedUser;
  bool hasValidSession = false;

  @override
  Future<void> saveSession(String accessToken, UserProfile user, {String? refreshToken}) async {
    storedAccessToken = accessToken;
    storedUser = user;
    if (refreshToken != null) {
      storedRefreshToken = refreshToken;
    }
    hasValidSession = true;
  }

  @override
  Future<void> clearSession() async {
    storedAccessToken = null;
    storedRefreshToken = null;
    storedUser = null;
    hasValidSession = false;
  }

  @override
  Future<String?> getAccessToken() async => storedAccessToken;

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

class MockConnectivityService extends Mock implements IConnectivityService {}

// ============================================================
// === TEST DATA ===
// ============================================================

UserProfile createTestUser({
  String id = 'test-uuid',
  String email = 'test@example.com',
  String displayName = 'Test User',
  String avatar = '🐻',
  bool isVerified = true,
}) {
  return UserProfile(id: id, email: email, displayName: displayName, avatar: avatar, isVerified: isVerified);
}

Map<String, dynamic> createUserJson({
  String id = 'test-uuid',
  String email = 'test@example.com',
  String displayName = 'Test User',
  String avatar = '🐻',
  bool isVerified = true,
}) {
  return {
    'id': id,
    'email': email,
    'display_name': displayName,
    'avatar': avatar,
    'role': 'member',
    'is_verified': isVerified,
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
  late MockConnectivityService mockConnectivity;

  setUp(() {
    mockApiClient = MockGasApiClient();
    mockConnectivity = MockConnectivityService();
    when(() => mockConnectivity.isOffline).thenReturn(false);

    final networkClient = NetworkAwareClient(apiClient: mockApiClient, connectivity: mockConnectivity);

    mockSessionRepo = MockAuthSessionRepository();
    mockTokenValidator = MockTokenValidator();
    authService = GasAuthService(
      apiClient: networkClient,
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

      // GasAuthService returns requiresVerification, sets isSuccess to true
      expect(result.isSuccess, isTrue);
      expect(result.errorCode, 'REQUIRES_VERIFICATION');
    });

    test('returns failure on API error', () async {
      mockApiClient.mockResponseCode = GasErrorCodes.authEmailExists; // '0801'
      mockApiClient.mockResponseMessage = '此信箱已被註冊';

      final result = await authService.register(
        email: 'existing@example.com',
        password: 'password123',
        displayName: 'User',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, GasErrorCodes.authEmailExists);
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
      expect(mockSessionRepo.storedAccessToken, 'login-access-token');
      expect(mockSessionRepo.storedRefreshToken, 'login-refresh-token');
    });
  });

  group('GasAuthService.validateSession', () {
    test('returns failure when no token exists', () async {
      mockSessionRepo.storedAccessToken = null;

      final result = await authService.validateSession();

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, 'NO_TOKEN');
    });

    test('clears session and returns failure on invalid token', () async {
      mockSessionRepo.storedAccessToken = 'invalid-token';
      mockSessionRepo.hasValidSession = true;
      mockApiClient.mockResponseCode = GasErrorCodes.authAccessTokenInvalid; // '0804'
      mockApiClient.mockResponseMessage = 'Token 無效';

      final result = await authService.validateSession();

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, GasErrorCodes.authAccessTokenInvalid);
      expect(mockSessionRepo.hasValidSession, isFalse); // Session cleared
    });

    test('refreshes token if expiring soon', () async {
      mockSessionRepo.storedAccessToken = 'expiring-token';
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
      expect(mockSessionRepo.storedAccessToken, 'new-access-token');
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
      expect(mockSessionRepo.storedAccessToken, 'brand-new-token');
    });

    test('returns failure if no refresh token', () async {
      mockSessionRepo.storedRefreshToken = null;

      final result = await authService.refreshToken();

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, 'NO_REFRESH_TOKEN');
    });
  });

  group('GasAuthService helper methods & cases', () {
    test('getAccessToken returns stored token', () async {
      mockSessionRepo.storedAccessToken = 'my-token';

      final token = await authService.getAccessToken();

      expect(token, 'my-token');
    });

    test('Exception: login handles network timeout (DioException)', () async {
      mockApiClient.shouldThrowError = true;
      // NetworkAwareClient will catch this and throw OfflineException if connectivity says offline
      // But here mockConnectivity says online (false), so it should propagate or be caught by login()

      final result = await authService.login(email: 'e@e.com', password: 'p');

      // GasAuthService.login catches error and returns failure with NETWORK_ERROR
      expect(result.isSuccess, isFalse);
      expect(result.errorCode, 'NETWORK_ERROR');
    });

    test('Negative: verifyEmail returns failure on invalid code', () async {
      mockApiClient.mockResponseCode = '0810'; // Assume some error code
      mockApiClient.mockResponseMessage = 'Invalid code';

      final result = await authService.verifyEmail(email: 'e@e.com', code: 'wrong');

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, '0810');
      expect(result.errorMessage, 'Invalid code');
    });

    test('Extreme: login handles empty JSON response data', () async {
      mockApiClient.mockResponseData = {};

      final result = await authService.login(email: 'e@e.com', password: 'p');

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, 'DATA_ERROR');
    });

    test('Positive: updateProfile successfully updates local session', () async {
      mockSessionRepo.storedAccessToken = 'token';
      mockApiClient.mockResponseData = {'user': createTestUser(displayName: 'New Name').toJson()};

      final result = await authService.updateProfile(displayName: 'New Name');

      expect(result.isSuccess, isTrue);
      expect(result.user?.displayName, 'New Name');
      expect(mockSessionRepo.storedUser?.displayName, 'New Name');
    });

    test('Negative: updateProfile returns failure on API error', () async {
      mockSessionRepo.storedAccessToken = 'token';
      mockApiClient.mockResponseCode = '0805';
      mockApiClient.mockResponseMessage = 'Update failed';

      final result = await authService.updateProfile(displayName: 'Fail');

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, '0805');
      expect(result.errorMessage, 'Update failed');
    });

    test('Positive: verifyEmail returns success', () async {
      mockApiClient.mockResponseCode = '0000';
      final result = await authService.verifyEmail(email: 'e@e.com', code: '1234');
      expect(result.isSuccess, isTrue);
    });

    test('Exception: resendVerificationCode handles network error', () async {
      mockApiClient.shouldThrowError = true;
      final result = await authService.resendVerificationCode(email: 'e@e.com');
      expect(result.isSuccess, isFalse);
      expect(result.errorCode, 'NETWORK_ERROR');
    });
  });
}
