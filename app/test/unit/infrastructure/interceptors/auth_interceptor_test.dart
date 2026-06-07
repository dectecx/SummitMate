import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/core/di/injection.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/infrastructure/interceptors/auth_interceptor.dart';
import 'package:summitmate/presentation/cubits/app_error/app_error_cubit.dart';

class MockAuthSessionRepository extends Mock implements IAuthSessionRepository {}

class MockAuthService extends Mock implements IAuthService {}

class MockDio extends Mock implements Dio {}

class MockRequestInterceptorHandler extends Mock implements RequestInterceptorHandler {}

class MockErrorInterceptorHandler extends Mock implements ErrorInterceptorHandler {}

class MockAppErrorCubit extends Mock implements AppErrorCubit {}

void main() {
  late AuthInterceptor interceptor;
  late MockAuthSessionRepository mockSessionRepo;
  late MockAuthService mockAuthService;
  late MockDio mockDio;
  late MockAppErrorCubit mockAppErrorCubit;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
    registerFallbackValue(DioException(requestOptions: RequestOptions(path: '')));
    registerFallbackValue(Response(requestOptions: RequestOptions(path: '')));
  });

  setUp(() async {
    await getIt.reset();
    mockSessionRepo = MockAuthSessionRepository();
    mockAuthService = MockAuthService();
    mockDio = MockDio();
    mockAppErrorCubit = MockAppErrorCubit();

    getIt.registerSingleton<IAuthService>(mockAuthService);
    getIt.registerSingleton<Dio>(mockDio);
    getIt.registerSingleton<AppErrorCubit>(mockAppErrorCubit);

    interceptor = AuthInterceptor(mockSessionRepo);

    // Default stubs
    when(() => mockSessionRepo.clearSession()).thenAnswer((_) async {});
    when(() => mockAuthService.logout()).thenAnswer((_) async {});
    when(() => mockAppErrorCubit.reportAuthExpired()).thenReturn(null);
  });

  group('AuthInterceptor.onRequest', () {
    test('Given token exists, When calling AuthInterceptor.onRequest, Then injects Authorization header', () async {
      final options = RequestOptions(path: '/test');
      when(() => mockSessionRepo.getAccessToken()).thenAnswer((_) async => 'valid-token');

      final handler = MockRequestInterceptorHandler();
      final completer = Completer<void>();
      when(() => handler.next(any())).thenAnswer((_) {
        completer.complete();
      });

      interceptor.onRequest(options, handler);

      await completer.future;
      expect(options.headers['Authorization'], 'Bearer valid-token');
      verify(() => handler.next(options)).called(1);
    });

    test('Given requiresAuth is false, When calling AuthInterceptor.onRequest, Then skips injection', () async {
      final options = RequestOptions(path: '/test', extra: {'requiresAuth': false});

      final handler = MockRequestInterceptorHandler();
      final completer = Completer<void>();
      when(() => handler.next(any())).thenAnswer((_) {
        completer.complete();
      });

      interceptor.onRequest(options, handler);

      await completer.future;
      expect(options.headers.containsKey('Authorization'), isFalse);
      verifyNever(() => mockSessionRepo.getAccessToken());
      verify(() => handler.next(options)).called(1);
    });
  });

  group('AuthInterceptor.onError', () {
    test(
      'Given 401 occurs and refresh is successful, When calling AuthInterceptor.onError, Then retries request',
      () async {
        final options = RequestOptions(path: '/protected');
        final error = DioException(
          requestOptions: options,
          response: Response(requestOptions: options, statusCode: 401),
        );

        when(
          () => mockAuthService.refreshToken(),
        ).thenAnswer((_) async => AuthResult.success(accessToken: 'new-token'));

        when(
          () => mockDio.fetch(any()),
        ).thenAnswer((_) async => Response(requestOptions: options, statusCode: 200, data: {'success': true}));

        final handler = MockErrorInterceptorHandler();
        final completer = Completer<void>();
        when(() => handler.resolve(any())).thenAnswer((_) {
          completer.complete();
        });

        interceptor.onError(error, handler);

        await completer.future;

        verify(() => mockAuthService.refreshToken()).called(1);
        verify(() => mockDio.fetch(any())).called(1);
        verify(() => handler.resolve(any())).called(1);
      },
    );

    test('Given refresh fails, When calling AuthInterceptor.onError, Then clears session and fails', () async {
      final options = RequestOptions(path: '/protected');
      final error = DioException(
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: 401),
      );

      when(
        () => mockAuthService.refreshToken(),
      ).thenAnswer((_) async => AuthResult.failure(errorCode: 'REFRESH_FAILED'));

      final handler = MockErrorInterceptorHandler();
      final completer = Completer<void>();
      when(() => handler.next(any())).thenAnswer((_) {
        completer.complete();
      });

      interceptor.onError(error, handler);

      await completer.future;

      verify(() => mockAuthService.refreshToken()).called(1);
      verify(() => mockAuthService.logout()).called(1);
      verify(() => mockAppErrorCubit.reportAuthExpired()).called(1);
      verify(() => handler.next(error)).called(1);
    });

    test(
      'Given 401 occurs on refresh endpoint, When calling AuthInterceptor.onError, Then avoids infinite loop',
      () async {
        final options = RequestOptions(path: '/auth/refresh');
        final error = DioException(
          requestOptions: options,
          response: Response(requestOptions: options, statusCode: 401),
        );

        final handler = MockErrorInterceptorHandler();
        final completer = Completer<void>();
        when(() => handler.next(any())).thenAnswer((_) {
          completer.complete();
        });

        interceptor.onError(error, handler);

        await completer.future;

        verify(() => mockAuthService.logout()).called(1);
        verify(() => mockAppErrorCubit.reportAuthExpired()).called(1);
        verifyNever(() => mockAuthService.refreshToken());
        verify(() => handler.next(error)).called(1);
      },
    );

    test(
      'Given 401 occurs on logout endpoint, When calling AuthInterceptor.onError, Then passes error through without triggering logout or refresh',
      () async {
        final options = RequestOptions(path: '/auth/logout');
        final error = DioException(
          requestOptions: options,
          response: Response(requestOptions: options, statusCode: 401),
        );

        final handler = MockErrorInterceptorHandler();
        final completer = Completer<void>();
        when(() => handler.next(any())).thenAnswer((_) {
          completer.complete();
        });

        interceptor.onError(error, handler);

        await completer.future;

        verifyNever(() => mockAuthService.logout());
        verifyNever(() => mockAppErrorCubit.reportAuthExpired());
        verifyNever(() => mockAuthService.refreshToken());
        verify(() => handler.next(error)).called(1);
      },
    );
  });
}
