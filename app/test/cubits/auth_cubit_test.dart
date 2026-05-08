import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/infrastructure/infrastructure.dart';
import 'package:summitmate/presentation/cubits/auth/auth_cubit.dart';
import 'package:summitmate/presentation/cubits/auth/auth_state.dart';

class MockAuthService extends Mock implements IAuthService {}

class MockUsageTrackingService extends Mock implements UsageTrackingService {}

void main() {
  late AuthCubit authCubit;
  late MockAuthService mockAuthService;
  late MockUsageTrackingService mockUsageTrackingService;
  late StreamController<UserProfile?> authStreamController;

  final testUser = UserProfile(
    id: 'user-1',
    email: 'test@example.com',
    displayName: 'Test User',
    role: 'user',
    isVerified: true,
  );

  setUp(() {
    mockAuthService = MockAuthService();
    mockUsageTrackingService = MockUsageTrackingService();
    authStreamController = StreamController<UserProfile?>.broadcast();

    when(() => mockAuthService.onAuthStateChanged).thenAnswer((_) => authStreamController.stream);
    when(() => mockAuthService.isOfflineMode).thenReturn(false);
    when(() => mockUsageTrackingService.start(any(), userId: any(named: 'userId'))).thenReturn(null);
    when(() => mockUsageTrackingService.stop()).thenReturn(null);

    authCubit = AuthCubit(mockAuthService, mockUsageTrackingService);
  });

  tearDown(() {
    authStreamController.close();
    authCubit.close();
  });

  group('AuthCubit', () {
    test('initial state is AuthInitial', () {
      expect(authCubit.state, isA<AuthInitial>());
    });

    blocTest<AuthCubit, AuthState>(
      'emits [AuthAuthenticated] when auth stream yields a user',
      build: () => authCubit,
      act: (cubit) => authStreamController.add(testUser),
      expect: () => [
        isA<AuthAuthenticated>()
            .having((s) => s.userId, 'userId', 'user-1')
            .having((s) => s.userName, 'userName', 'Test User'),
      ],
      verify: (_) {
        verify(() => mockUsageTrackingService.start('Test User', userId: 'user-1')).called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthUnauthenticated] when auth stream yields null and was authenticated',
      build: () => authCubit,
      seed: () => const AuthAuthenticated(userId: 'user-1', userName: 'Test User'),
      act: (cubit) => authStreamController.add(null),
      expect: () => [isA<AuthUnauthenticated>()],
      verify: (_) {
        verify(() => mockUsageTrackingService.stop()).called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'login calls authService.login and emits AuthLoading',
      build: () {
        when(
          () => mockAuthService.login(email: 'test@example.com', password: 'password'),
        ).thenAnswer((_) async => AuthResult.success(user: testUser));
        return authCubit;
      },
      act: (cubit) => cubit.login('test@example.com', 'password'),
      expect: () => [isA<AuthLoading>()],
    );

    blocTest<AuthCubit, AuthState>(
      'login emits AuthError on failure',
      build: () {
        when(
          () => mockAuthService.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => AuthResult.failure(errorCode: 'AUTH_FAILED', errorMessage: 'Invalid credentials'));
        return authCubit;
      },
      act: (cubit) => cubit.login('wrong@example.com', 'wrong'),
      expect: () => [isA<AuthLoading>(), isA<AuthError>().having((s) => s.message, 'message', 'Invalid credentials')],
    );

    blocTest<AuthCubit, AuthState>(
      'loginAsGuest emits AuthAuthenticated immediately',
      build: () => authCubit,
      act: (cubit) => cubit.loginAsGuest(),
      expect: () => [
        isA<AuthAuthenticated>().having((s) => s.isGuest, 'isGuest', true).having((s) => s.userId, 'userId', 'guest'),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'logout calls authService.logout',
      build: () {
        when(() => mockAuthService.logout()).thenAnswer((_) async => {});
        return authCubit;
      },
      act: (cubit) => cubit.logout(),
      expect: () => [isA<AuthLoading>()],
      verify: (_) {
        verify(() => mockAuthService.logout()).called(1);
      },
    );
  });
}
