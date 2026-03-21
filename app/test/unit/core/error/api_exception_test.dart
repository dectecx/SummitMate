import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/core/error/api_exception.dart';
import 'package:summitmate/core/error/app_error.dart';

void main() {
  group('ApiException', () {
    test('fromAppError parses valid AppError correctly', () {
      final appError = AppError(
        type: 'validation_error',
        code: 'invalid_input',
        message: 'Invalid input data',
        param: 'email',
      );

      final exception = ApiException.fromAppError(400, appError);

      expect(exception.statusCode, 400);
      expect(exception.type, ApiErrorType.validationError);
      expect(exception.code, 'invalid_input');
      expect(exception.message, 'Invalid input data');
      expect(exception.param, 'email');
    });

    test('fromAppError maps unknown type to ApiErrorType.unknown', () {
      final appError = AppError(type: 'some_weird_type', code: 'unknown_code', message: 'Something went wrong');

      final exception = ApiException.fromAppError(500, appError);

      expect(exception.type, ApiErrorType.unknown);
      expect(exception.code, 'unknown_code');
      expect(exception.message, 'Something went wrong');
      expect(exception.param, null);
    });

    test('tryParse returns null for non-map data', () {
      final exception = ApiException.tryParse(400, 'Just a regular string error');

      expect(exception, isNull);
    });

    test('tryParse returns null for map data missing typical keys', () {
      final json = {'data': 'Some data'}; // No "error" wrapper AND no "type"/"message"

      final exception = ApiException.tryParse(400, json);

      expect(exception, isNull);
    });

    test('tryParse successfully parses wrapped error {"error": {...}}', () {
      final json = {
        'error': {'type': 'business_logic_error', 'code': 'item_not_found', 'message': 'Item not found in database'},
      };

      final exception = ApiException.tryParse(404, json);

      expect(exception, isNotNull);
      expect(exception!.type, ApiErrorType.businessLogicError);
      expect(exception.code, 'item_not_found');
      expect(exception.message, 'Item not found in database');
    });
  });
}
