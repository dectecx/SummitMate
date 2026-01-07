import 'package:flutter_test/flutter_test.dart';

import 'package:summitmate/services/gas_api_client.dart';

// ============================================================
// === TESTS ===
// ============================================================
// Note: GasApiClient.get/post methods are difficult to unit test directly
// because Dio doesn't allow easy mocking without external packages.
// These tests focus on GasApiResponse parsing which is the core testable logic.

void main() {
  group('GasApiResponse', () {
    test('isSuccess returns true for code 0000', () {
      final response = GasApiResponse.fromJson({
        'code': '0000',
        'message': 'Success',
        'data': {},
      });

      expect(response.isSuccess, isTrue);
      expect(response.code, '0000');
      expect(response.message, 'Success');
    });

    test('isSuccess returns false for error codes', () {
      final response = GasApiResponse.fromJson({
        'code': '0801',
        'message': 'Email already exists',
        'data': {},
      });

      expect(response.isSuccess, isFalse);
      expect(response.code, '0801');
    });

    test('message is extracted correctly', () {
      final response = GasApiResponse.fromJson({
        'code': '0000',
        'message': 'Custom message here',
        'data': {},
      });

      expect(response.message, 'Custom message here');
    });

    test('data returns empty map when data field is missing', () {
      final response = GasApiResponse.fromJson({
        'code': '0000',
        'message': 'Success',
      });

      expect(response.data, isEmpty);
    });

    test('data returns empty map when data field is null', () {
      final response = GasApiResponse.fromJson({
        'code': '0000',
        'message': 'Success',
        'data': null,
      });

      expect(response.data, isEmpty);
    });

    test('data returns empty map when data field is non-map', () {
      final response = GasApiResponse.fromJson({
        'code': '0000',
        'message': 'Success',
        'data': 'string data',
      });

      expect(response.data, isEmpty);
    });

    test('data returns correct map when data is valid', () {
      final response = GasApiResponse.fromJson({
        'code': '0000',
        'message': 'Success',
        'data': {'key': 'value', 'number': 123},
      });

      expect(response.data['key'], 'value');
      expect(response.data['number'], 123);
    });

    test('fromJsonString parses JSON string correctly', () {
      final jsonString = '{"code": "0000", "message": "OK", "data": {"key": "value"}}';
      final response = GasApiResponse.fromJsonString(jsonString);

      expect(response.isSuccess, isTrue);
      expect(response.data['key'], 'value');
    });

    test('raw returns original JSON', () {
      final originalJson = {
        'code': '0000',
        'message': 'Test',
        'data': {'a': 1},
      };
      final response = GasApiResponse.fromJson(originalJson);

      expect(response.raw, originalJson);
    });

    test('code returns empty string when code is null', () {
      final response = GasApiResponse.fromJson({
        'message': 'No code',
        'data': {},
      });

      expect(response.code, '');
      expect(response.isSuccess, isFalse);
    });

    test('message returns empty string when message is null', () {
      final response = GasApiResponse.fromJson({
        'code': '0000',
        'data': {},
      });

      expect(response.message, '');
    });
  });

  group('kGasCodeSuccess', () {
    test('is defined as 0000', () {
      expect(kGasCodeSuccess, '0000');
    });
  });
}
