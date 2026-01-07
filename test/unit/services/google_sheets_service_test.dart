import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:summitmate/core/constants.dart';
import 'package:summitmate/services/google_sheets_service.dart';
import 'package:summitmate/services/gas_api_client.dart';
import 'package:summitmate/data/models/message.dart';

// Mock GasApiClient
class MockGasApiClient extends GasApiClient {
  MockGasApiClient() : super(baseUrl: 'https://mock.url');

  Map<String, dynamic>? expectedResponseData;
  bool shouldFail = false;
  int statusCode = 200;
  Map<String, dynamic>? capturedBody;

  @override
  Future<Response> get({Map<String, String>? queryParams}) async {
    if (shouldFail) {
      return Response(
        requestOptions: RequestOptions(path: ''),
        statusCode: 500,
        statusMessage: 'Internal Server Error',
      );
    }

    final responseBody = {
      'code': statusCode == 200 ? '0000' : '9999',
      'message': 'Mock Message',
      'data': expectedResponseData ?? {},
    };
    return Response(
      requestOptions: RequestOptions(path: ''),
      data: responseBody,
      statusCode: statusCode,
    );
  }

  @override
  Future<Response> post(Map<String, dynamic> body, {bool requiresAuth = false}) async {
    capturedBody = body;
    if (shouldFail) {
      return Response(
        requestOptions: RequestOptions(path: ''),
        statusCode: 500,
        statusMessage: 'Internal Server Error',
      );
    }
    final responseBody = {
      'code': statusCode == 200 ? '0000' : '9999',
      'message': 'Mock Message',
      'data': expectedResponseData ?? {},
    };
    return Response(
      requestOptions: RequestOptions(path: ''),
      data: responseBody,
      statusCode: statusCode,
    );
  }
}

void main() {
  group('GoogleSheetsService Tests', () {
    test('fetchAll should return itinerary and messages on success', () async {
      final mockClient = MockGasApiClient();
      mockClient.expectedResponseData = {
        'itinerary': [
          {
            'day': 'D1',
            'name': 'Mountain Lodge',
            'est_time': '11:30',
            'altitude': 2850,
            'distance': 4.3,
            'note': 'Lunch stop',
          },
        ],
        'messages': [
          {
            'uuid': 'test-uuid-1',
            'parent_id': null,
            'user': 'Alex',
            'category': 'Gear',
            'content': 'Test message',
            'timestamp': '2024-12-15T09:00:00Z',
          },
        ],
      };

      final service = GoogleSheetsService(apiClient: mockClient);
      final result = await service.fetchAll();

      expect(result.isSuccess, isTrue);
      expect(result.itinerary.length, 1);
      expect(result.itinerary.first.name, 'Mountain Lodge');
      expect(result.messages.length, 1);
      expect(result.messages.first.user, 'Alex');
    });

    test('fetchAll should return error on HTTP failure', () async {
      final mockClient = MockGasApiClient();
      mockClient.shouldFail = true;

      final service = GoogleSheetsService(apiClient: mockClient);
      final result = await service.fetchAll();

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('500'));
    });

    test('addMessage should post message data', () async {
      final mockClient = MockGasApiClient();
      final service = GoogleSheetsService(apiClient: mockClient);

      final message = Message(
        uuid: 'new-uuid',
        user: 'Bob',
        category: 'Plan',
        content: 'Test message',
        timestamp: DateTime(2024, 12, 15, 10, 0),
      );

      final result = await service.addMessage(message);

      expect(result.isSuccess, isTrue);
      expect(mockClient.capturedBody, isNotNull);
      expect(mockClient.capturedBody!['action'], ApiConfig.actionMessageCreate);
      expect(mockClient.capturedBody!['data']['uuid'], 'new-uuid');
    });

    test('deleteMessage should send delete request', () async {
      final mockClient = MockGasApiClient();
      final service = GoogleSheetsService(apiClient: mockClient);

      final result = await service.deleteMessage('uuid-to-delete');

      expect(result.isSuccess, isTrue);
      expect(mockClient.capturedBody, isNotNull);
      expect(mockClient.capturedBody!['action'], ApiConfig.actionMessageDelete);
      expect(mockClient.capturedBody!['uuid'], 'uuid-to-delete');
    });
  });
}
