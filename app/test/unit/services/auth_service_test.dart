import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/infrastructure/clients/network_aware_client.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/infrastructure/services/auth_service.dart';
import 'package:summitmate/infrastructure/database/app_database.dart';

// ============================================================
// === MOCKS ===
// ============================================================

class MockNetworkAwareClient extends Mock implements NetworkAwareClient {}

class MockAuthSessionRepository extends Mock implements IAuthSessionRepository {}

class MockTokenValidator extends Mock implements ITokenValidator {}

class MockAppDatabase extends Mock implements AppDatabase {}

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
  late MockAppDatabase mockDb;

  setUp(() {
    mockApiClient = MockNetworkAwareClient();
    mockSessionRepo = MockAuthSessionRepository();
    mockTokenValidator = MockTokenValidator();
    mockDb = MockAppDatabase();

    when(() => mockSessionRepo.getUserProfile()).thenAnswer((_) async => null);
    when(() => mockSessionRepo.getAccessToken()).thenAnswer((_) async => null);
    when(() => mockDb.clearAllData()).thenAnswer((_) async {});

    authService = AuthService(
      apiClient: mockApiClient,
      sessionRepository: mockSessionRepo,
      tokenValidator: mockTokenValidator,
      db: mockDb,
    );
  });

  group('AuthService.register', () {
    test(
      'Given valid registration, When calling AuthService.register, Then returns success and saves session',
      () async {
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
      },
    );

    test('Given API error, When calling AuthService.register, Then returns failure', () async {
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
    test('Given valid login, When calling AuthService.login, Then returns success and saves session', () async {
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
    test('Given no token exists, When calling AuthService.validateSession, Then returns failure', () async {
      when(() => mockSessionRepo.getAccessToken()).thenAnswer((_) async => null);

      final result = await authService.validateSession();

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, 'NO_TOKEN');
    });

    test('Given /auth/me is valid, When calling AuthService.validateSession, Then returns success', () async {
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
    test('Given AuthService.logout, When executing, Then clears session and resets state', () async {
      when(() => mockSessionRepo.clearSession()).thenAnswer((_) async {});
      when(() => mockDb.clearAllData()).thenAnswer((_) async {});

      await authService.logout();

      verify(() => mockSessionRepo.clearSession()).called(1);
      verify(() => mockDb.clearAllData()).called(1);
      expect(authService.currentUserId, isNull);
    });
  });

  group('AuthService.loginWithProvider', () {
    test(
      'Given AuthService.loginWithProvider, When executing, Then returns failure with NOT_IMPLEMENTED since it is pending design',
      () async {
        final result = await authService.loginWithProvider(OAuthProvider.google);

        expect(result.isSuccess, isFalse);
        expect(result.errorCode, 'NOT_IMPLEMENTED');
      },
    );
  });

  group('AuthService.verifyEmail', () {
    test('Given 200, When calling AuthService.verifyEmail, Then returns success', () async {
      when(
        () => mockApiClient.post('/auth/verify-email', data: any(named: 'data')),
      ).thenAnswer((_) async => Response(requestOptions: RequestOptions(path: '/auth/verify-email'), statusCode: 200));

      final result = await authService.verifyEmail(email: 'test@example.com', code: '123456');
      expect(result.isSuccess, isTrue);
    });

    test('Given error, When calling AuthService.verifyEmail, Then returns failure', () async {
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
    test('Given 200, When calling AuthService.resendVerificationCode, Then returns success', () async {
      when(() => mockApiClient.post('/auth/resend-verification', data: any(named: 'data'))).thenAnswer(
        (_) async => Response(requestOptions: RequestOptions(path: '/auth/resend-verification'), statusCode: 200),
      );

      final result = await authService.resendVerificationCode(email: 'test@example.com');
      expect(result.isSuccess, isTrue);
    });
  });

  group('AuthService.refreshToken', () {
    test('Given AuthService.refreshToken, When executing, Then returns success and saves new token', () async {
      when(() => mockSessionRepo.getRefreshToken()).thenAnswer((_) async => 'old-refresh-token');
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
    test('Given AuthService.deleteAccount, When executing, Then returns success and logs out', () async {
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
    test('Given 200, When calling AuthService.updateProfile, Then returns success and updates session', () async {
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
