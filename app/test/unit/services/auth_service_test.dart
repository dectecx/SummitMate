import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/infrastructure/clients/network_aware_client.dart';
import 'package:summitmate/data/models/user_profile.dart';
import 'package:summitmate/data/repositories/interfaces/i_auth_session_repository.dart';
import 'package:summitmate/infrastructure/services/auth_service.dart';
import 'package:summitmate/domain/interfaces/i_token_validator.dart';
import 'package:summitmate/domain/interfaces/i_auth_service.dart';

// ============================================================
// === MOCKS ===
// ============================================================

class MockNetworkAwareClient extends Mock implements NetworkAwareClient {}

class MockAuthSessionRepository extends Mock implements IAuthSessionRepository {}

class MockTokenValidator extends Mock implements ITokenValidator {}

// ============================================================
// === TEST DATA ===
// ============================================================

UserProfile createTestUser({
  String id = 'test-uuid',
  String email = 'test@example.com',
  String displayName = 'Test User',
  String avatar = '🐻',
}) {
  return UserProfile(id: id, email: email, displayName: displayName, avatar: avatar);
}

Map<String, dynamic> createUserJson({
  String id = 'test-uuid',
  String email = 'test@example.com',
  String name = 'Test User',
  String avatar = '🐻',
}) {
  return {'id': id, 'email': email, 'display_name': name, 'avatar': avatar};
}

class FakeUserProfile extends Fake implements UserProfile {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeUserProfile());
  });

  late AuthService authService;
  late MockNetworkAwareClient mockApiClient;
  late MockAuthSessionRepository mockSessionRepo;
  late MockTokenValidator mockTokenValidator;

  setUp(() {
    mockApiClient = MockNetworkAwareClient();
    mockSessionRepo = MockAuthSessionRepository();
    mockTokenValidator = MockTokenValidator();

    when(() => mockSessionRepo.getUserProfile()).thenAnswer((_) async => null);

    authService = AuthService(
      apiClient: mockApiClient,
      sessionRepository: mockSessionRepo,
      tokenValidator: mockTokenValidator,
    );
  });

  group('AuthService.register', () {
    test('returns success and saves session on valid registration', () async {
      final userJson = createUserJson();
      final responseData = {'user': userJson, 'token': 'test-token'};

      when(() => mockApiClient.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/auth/register'),
          data: responseData,
          statusCode: 201,
        ),
      );

      when(() => mockSessionRepo.saveSession(any(), any())).thenAnswer((_) async {});

      final result = await authService.register(
        email: 'test@example.com',
        password: 'password123',
        displayName: 'Test User',
      );

      expect(result.isSuccess, isTrue);
      expect(result.user?.id, 'test-uuid');
      expect(result.accessToken, 'test-token');
      verify(() => mockSessionRepo.saveSession('test-token', any())).called(1);
    });

    test('returns failure on API error', () async {
      when(() => mockApiClient.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/auth/register'),
          data: {'error': 'Email already exists'},
          statusCode: 400,
        ),
      );

      final result = await authService.register(
        email: 'test@example.com',
        password: 'password123',
        displayName: 'Test User',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('Email already exists'));
    });
  });

  group('AuthService.login', () {
    test('returns success and saves session on valid login', () async {
      final userJson = createUserJson();
      final responseData = {'user': userJson, 'token': 'login-token'};

      when(() => mockApiClient.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          data: responseData,
          statusCode: 200,
        ),
      );

      when(() => mockSessionRepo.saveSession(any(), any())).thenAnswer((_) async {});

      final result = await authService.login(email: 'test@example.com', password: 'password123');

      expect(result.isSuccess, isTrue);
      expect(result.user?.email, 'test@example.com');
      expect(result.accessToken, 'login-token');
      verify(() => mockSessionRepo.saveSession('login-token', any())).called(1);
    });
  });

  group('AuthService.validateSession', () {
    test('returns failure when no token exists', () async {
      when(() => mockSessionRepo.getAccessToken()).thenAnswer((_) async => null);

      final result = await authService.validateSession();

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, 'NO_TOKEN');
    });

    test('returns success when /auth/me is valid', () async {
      when(() => mockSessionRepo.getAccessToken()).thenAnswer((_) async => 'valid-token');
      when(() => mockApiClient.get('/auth/me')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/auth/me'),
          data: createUserJson(),
          statusCode: 200,
        ),
      );
      when(() => mockSessionRepo.saveSession(any(), any())).thenAnswer((_) async {});

      final result = await authService.validateSession();

      expect(result.isSuccess, isTrue);
      expect(result.user?.id, 'test-uuid');
    });
  });

  group('AuthService.logout', () {
    test('clears session and resets state', () async {
      when(() => mockSessionRepo.clearSession()).thenAnswer((_) async {});

      await authService.logout();

      verify(() => mockSessionRepo.clearSession()).called(1);
      expect(authService.currentUserId, isNull);
    });
  });

  group('AuthService.loginWithProvider', () {
    test('returns failure with NOT_IMPLEMENTED since it is pending design', () async {
      final result = await authService.loginWithProvider(OAuthProvider.google);

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, 'NOT_IMPLEMENTED');
    });
  });

  group('AuthService.verifyEmail', () {
    test('returns success on 200', () async {
      when(
        () => mockApiClient.post('/auth/verify-email', data: any(named: 'data')),
      ).thenAnswer((_) async => Response(requestOptions: RequestOptions(path: '/auth/verify-email'), statusCode: 200));

      final result = await authService.verifyEmail(email: 'test@example.com', code: '123456');
      expect(result.isSuccess, isTrue);
    });

    test('returns failure on error', () async {
      when(() => mockApiClient.post('/auth/verify-email', data: any(named: 'data'))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/verify-email'),
          response: Response(requestOptions: RequestOptions(path: ''), statusCode: 400),
        ),
      );

      final result = await authService.verifyEmail(email: 'test@example.com', code: '123456');
      expect(result.isSuccess, isFalse);
    });
  });

  group('AuthService.resendVerificationCode', () {
    test('returns success on 200', () async {
      when(() => mockApiClient.post('/auth/resend-verification', data: any(named: 'data'))).thenAnswer(
        (_) async => Response(requestOptions: RequestOptions(path: '/auth/resend-verification'), statusCode: 200),
      );

      final result = await authService.resendVerificationCode(email: 'test@example.com');
      expect(result.isSuccess, isTrue);
    });
  });

  group('AuthService.refreshToken', () {
    test('returns success and saves new token', () async {
      when(() => mockSessionRepo.getAccessToken()).thenAnswer((_) async => 'old-token');
      when(() => mockApiClient.post('/auth/refresh', data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/auth/refresh'),
          data: {'token': 'new-token', 'user': createUserJson()},
          statusCode: 200,
        ),
      );
      when(() => mockSessionRepo.saveSession(any(), any())).thenAnswer((_) async {});

      final result = await authService.refreshToken();

      expect(result.isSuccess, isTrue);
      expect(result.accessToken, 'new-token');
      verify(() => mockSessionRepo.saveSession('new-token', any())).called(1);
    });
  });

  group('AuthService.deleteAccount', () {
    test('returns success and logs out', () async {
      when(
        () => mockApiClient.delete('/auth/me'),
      ).thenAnswer((_) async => Response(requestOptions: RequestOptions(path: '/auth/me'), statusCode: 204));
      when(() => mockSessionRepo.clearSession()).thenAnswer((_) async {});

      final result = await authService.deleteAccount();

      expect(result.isSuccess, isTrue);
      verify(() => mockSessionRepo.clearSession()).called(1);
    });
  });

  group('AuthService.updateProfile', () {
    test('returns success and updates session on 200', () async {
      when(() => mockApiClient.put('/auth/me', data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/auth/me'),
          data: {'id': 'test-uuid', 'email': 'test@example.com', 'display_name': 'New Name', 'avatar': '🐻'},
          statusCode: 200,
        ),
      );
      when(() => mockSessionRepo.getUserProfile()).thenAnswer((_) async => createTestUser());
      when(() => mockSessionRepo.getAccessToken()).thenAnswer((_) async => 'token');
      when(() => mockSessionRepo.saveSession(any(), any())).thenAnswer((_) async {});

      final result = await authService.updateProfile(displayName: 'New Name');

      expect(result.isSuccess, isTrue);
      expect(result.user?.displayName, 'New Name');
    });
  });
}
