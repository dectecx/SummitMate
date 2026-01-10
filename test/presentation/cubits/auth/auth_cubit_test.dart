import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/domain/interfaces/i_auth_service.dart';
import 'package:summitmate/domain/interfaces/i_connectivity_service.dart';
import 'package:summitmate/infrastructure/tools/usage_tracking_service.dart';

import 'package:summitmate/presentation/cubits/auth/auth_cubit.dart';
import 'package:summitmate/presentation/cubits/auth/auth_state.dart';
import 'package:summitmate/data/models/user_profile.dart';

class MockAuthService extends Mock implements IAuthService {}

class MockConnectivityService extends Mock implements IConnectivityService {}

class MockUsageTrackingService extends Mock implements UsageTrackingService {}

void main() {
  late MockAuthService mockAuthService;
  late MockConnectivityService mockConnectivityService;
  late MockUsageTrackingService mockUsageTrackingService;
  late AuthCubit authCubit;

  final testUser = UserProfile(
    uuid: 'test-uuid',
    email: 'test@example.com',
    displayName: 'Test User',
    avatar: 'test-avatar',
    role: 'member',
    isVerified: true,
  );

  final unverifiedUser = UserProfile(
    uuid: 'unverified-uuid',
    email: 'unverified@example.com',
    displayName: 'Unverified User',
    role: 'member',
    isVerified: false,
  );

  setUp(() {
    mockAuthService = MockAuthService();
    mockConnectivityService = MockConnectivityService();
    mockUsageTrackingService = MockUsageTrackingService();

    // Default mock behavior
    when(() => mockUsageTrackingService.start(any(), userId: any(named: 'userId'))).thenAnswer((_) async {});
    when(() => mockConnectivityService.isOffline).thenReturn(false);

    authCubit = AuthCubit(
      authService: mockAuthService,
      connectivityService: mockConnectivityService,
      usageTrackingService: mockUsageTrackingService,
    );
  });

  group('AuthCubit', () {
    test('initial state is AuthInitial', () {
      expect(authCubit.state, isA<AuthInitial>());
    });

    blocTest<AuthCubit, AuthState>(
      'checkAuthStatus emits AuthAuthenticated when validateSession succeeds',
      build: () {
        when(() => mockAuthService.isLoggedIn()).thenAnswer((_) async => true);
        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => testUser);
        when(() => mockAuthService.isOfflineMode).thenReturn(false);
        return authCubit;
      },
      act: (cubit) => cubit.checkAuthStatus(),
      expect: () => [
        isA<AuthAuthenticated>()
            .having((s) => s.userId, 'userId', testUser.uuid)
            .having((s) => s.userName, 'userName', testUser.displayName)
            .having((s) => s.email, 'email', testUser.email)
            .having((s) => s.avatar, 'avatar', testUser.avatar)
            .having((s) => s.isGuest, 'isGuest', false)
            .having((s) => s.isOffline, 'isOffline', false),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'checkAuthStatus emits AuthUnauthenticated when validateSession fails',
      build: () {
        when(() => mockAuthService.isLoggedIn()).thenAnswer((_) async => false);
        return authCubit;
      },
      act: (cubit) => cubit.checkAuthStatus(),
      expect: () => [AuthUnauthenticated()],
    );

    blocTest<AuthCubit, AuthState>(
      'login emits AuthLoading then AuthAuthenticated on success',
      build: () {
        when(
          () => mockAuthService.login(email: 'email', password: 'password'),
        ).thenAnswer((_) async => AuthResult.success(user: testUser));
        return authCubit;
      },
      act: (cubit) => cubit.login('email', 'password'),
      expect: () => [
        AuthLoading(),
        isA<AuthAuthenticated>()
            .having((s) => s.userId, 'userId', testUser.uuid)
            .having((s) => s.userName, 'userName', testUser.displayName)
            .having((s) => s.avatar, 'avatar', testUser.avatar)
            .having((s) => s.isGuest, 'isGuest', false),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'login emits AuthLoading then AuthRequiresVerification if user not verified',
      build: () {
        when(
          () => mockAuthService.login(email: 'email', password: 'password'),
        ).thenAnswer((_) async => AuthResult.success(user: unverifiedUser));
        return authCubit;
      },
      act: (cubit) => cubit.login('email', 'password'),
      expect: () => [AuthLoading(), AuthRequiresVerification('email')],
    );

    blocTest<AuthCubit, AuthState>(
      'login emits AuthLoading then AuthError on failure',
      build: () {
        when(
          () => mockAuthService.login(email: 'email', password: 'password'),
        ).thenAnswer((_) async => AuthResult.failure(errorCode: 'LOGIN_FAILED', errorMessage: 'Login failed'));
        return authCubit;
      },
      act: (cubit) => cubit.login('email', 'password'),
      expect: () => [AuthLoading(), const AuthError('Login failed')],
    );

    blocTest<AuthCubit, AuthState>(
      'loginAsGuest emits AuthAuthenticated with guest=true',
      build: () => authCubit,
      act: (cubit) => cubit.loginAsGuest(),
      expect: () => [
        isA<AuthAuthenticated>()
            .having((s) => s.isGuest, 'isGuest', true)
            .having((s) => s.isOffline, 'isOffline', true)
            .having((s) => s.userId, 'userId', 'guest')
            .having((s) => s.avatar, 'avatar', null),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'register emits AuthLoading then AuthOperationSuccess when verification required',
      build: () {
        when(
          () => mockAuthService.register(email: 'email', password: 'password', displayName: 'name'),
        ).thenAnswer((_) async => AuthResult.requiresVerification());
        return authCubit;
      },
      act: (cubit) => cubit.register(email: 'email', password: 'password', displayName: 'name'),
      expect: () => [AuthLoading(), const AuthRequiresVerification('email')],
    );

    blocTest<AuthCubit, AuthState>(
      'verifyEmail emits AuthLoading then AuthOperationSuccess then AuthUnauthenticated on success',
      build: () {
        when(
          () => mockAuthService.verifyEmail(email: 'email', code: '123456'),
        ).thenAnswer((_) async => AuthResult.success());
        return authCubit;
      },
      act: (cubit) => cubit.verifyEmail('email', '123456'),
      expect: () => [AuthLoading(), const AuthOperationSuccess('驗證成功，請登入'), AuthUnauthenticated()],
    );

    blocTest<AuthCubit, AuthState>(
      'verifyEmail emits AuthLoading then AuthError then AuthUnauthenticated on failure',
      build: () {
        when(
          () => mockAuthService.verifyEmail(email: 'email', code: '123456'),
        ).thenAnswer((_) async => AuthResult.failure(errorCode: 'VERIFY_FAILED', errorMessage: 'Invalid code'));
        return authCubit;
      },
      act: (cubit) => cubit.verifyEmail('email', '123456'),
      expect: () => [AuthLoading(), const AuthError('Invalid code'), AuthUnauthenticated()],
    );
  });
}
