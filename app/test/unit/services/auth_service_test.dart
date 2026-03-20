import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/infrastructure/clients/network_aware_client.dart';
import 'package:summitmate/data/models/user_profile.dart';
import 'package:summitmate/data/repositories/interfaces/i_auth_session_repository.dart';
import 'package:summitmate/infrastructure/services/auth_service.dart';
import 'package:summitmate/domain/interfaces/i_token_validator.dart';

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
}
