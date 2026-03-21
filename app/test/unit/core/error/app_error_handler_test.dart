import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/core/error/api_exception.dart';
import 'package:summitmate/core/error/app_error_handler.dart';
import 'package:summitmate/core/error/result.dart'; // For AppException

class _TestAppException extends AppException {
  _TestAppException(super.message);
}

void main() {
  group('AppErrorHandler', () {
    test('getUserMessage returns ApiException message directly', () {
      final apiException = ApiException(
        statusCode: 400,
        type: ApiErrorType.validationError,
        code: 'bad_input',
        message: 'This is a test message from ApiException',
      );

      final message = AppErrorHandler.getUserMessage(apiException);

      expect(message, 'This is a test message from ApiException');
    });

    test('getUserMessage returns generic AppException message directly', () {
      final appException = _TestAppException('Test app exception');

      final message = AppErrorHandler.getUserMessage(appException);

      expect(message, 'Test app exception');
    });

    test('getUserMessage removes "Exception: " prefix from regular Exception', () {
      final exception = Exception('Regular internal error');

      final message = AppErrorHandler.getUserMessage(exception);

      expect(message, 'Regular internal error');
    });

    test('getUserMessage returns default message for unknown errors', () {
      final message = AppErrorHandler.getUserMessage(12345);

      expect(message, '發生未預期的錯誤: 12345');
    });

    group('DioException handling', () {
      test('getUserMessage handles connection timeouts', () {
        final error = DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionTimeout,
        );

        final message = AppErrorHandler.getUserMessage(error);

        expect(message, '連線逾時，請檢查網路設定');
      });

      test('getUserMessage parses structured badResponse errors', () {
        final error = DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 403,
            data: {
              'error': {'type': 'auth_error', 'code': 'forbidden', 'message': 'Structured forbidden message'},
            },
          ),
        );

        final message = AppErrorHandler.getUserMessage(error);

        expect(message, 'Structured forbidden message');
      });

      test('getUserMessage falls back to status code for unstructured badResponse (401)', () {
        final error = DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 401,
            data: 'Unauthorized string',
          ),
        );

        final message = AppErrorHandler.getUserMessage(error);

        expect(message, '授權失敗，請重新登入');
      });

      test('getUserMessage falls back to status code for unstructured badResponse (500)', () {
        final error = DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 502,
            data: null, // No data
          ),
        );

        final message = AppErrorHandler.getUserMessage(error);

        expect(message, '伺服器內部錯誤 (502)');
      });
    });
  });
}
