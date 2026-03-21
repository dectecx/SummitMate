import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/core/error/api_exception.dart';

void main() {
  group('ApiException', () {
    test('fromResponse parses valid JSON error response correctly', () {
      final json = {
        'error': {
          'type': 'validation_error',
          'code': 'invalid_input',
          'message': 'Invalid input data',
          'param': 'email',
        },
      };

      final exception = ApiException.fromResponse(400, json);

      expect(exception.statusCode, 400);
      expect(exception.type, ApiErrorType.validationError);
      expect(exception.code, 'invalid_input');
      expect(exception.message, 'Invalid input data');
      expect(exception.param, 'email');
    });

    test('fromResponse maps unknown type to ApiErrorType.unknown', () {
      final json = {
        'error': {'type': 'some_weird_type', 'code': 'unknown_code', 'message': 'Something went wrong'},
      };

      final exception = ApiException.fromResponse(500, json);

      expect(exception.type, ApiErrorType.unknown);
      expect(exception.code, 'unknown_code');
      expect(exception.message, 'Something went wrong');
      expect(exception.param, null);
    });

    test('fromResponse handles missing required fields gracefully', () {
      final json = {
        'error': {
          // Missing code and message
          'type': 'auth_error',
        },
      };

      final exception = ApiException.fromResponse(401, json);

      expect(exception.type, ApiErrorType.authError);
      expect(exception.code, 'unknown'); // default fallback
      expect(exception.message, '發生未知錯誤'); // default fallback
    });

    test('tryParse returns null for non-map data', () {
      final exception = ApiException.tryParse(400, 'Just a regular string error');

      expect(exception, isNull);
    });

    test('tryParse returns null for map data missing "error" key', () {
      final json = {'data': 'Some data', 'message': 'Failure without error key'};

      final exception = ApiException.tryParse(400, json);

      expect(exception, isNull);
    });

    test('tryParse successfully parses valid structured error', () {
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
