import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:summitmate/core/constants.dart';
import 'package:summitmate/infrastructure/services/google_sheets_service.dart';
import 'package:summitmate/infrastructure/clients/gas_api_client.dart';
import 'package:summitmate/data/models/message.dart';
import 'package:summitmate/infrastructure/clients/network_aware_client.dart';
import 'package:summitmate/domain/interfaces/i_connectivity_service.dart';
import 'package:summitmate/core/error/result.dart';
import 'package:summitmate/domain/dto/data_service_result.dart';

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

class MockConnectivityService extends Mock implements IConnectivityService {}

void main() {
  late MockGasApiClient mockClient;
  late MockConnectivityService mockConnectivity;

  setUp(() {
    mockClient = MockGasApiClient();
    mockConnectivity = MockConnectivityService();
    when(() => mockConnectivity.isOffline).thenReturn(false);
  });

  group('GoogleSheetsService Tests', () {
    late GoogleSheetsService service;

    setUp(() {
      final networkClient = NetworkAwareClient(apiClient: mockClient, connectivity: mockConnectivity);
      service = GoogleSheetsService(apiClient: networkClient);
    });

    test('getAll should return itinerary and messages on success', () async {
      mockClient.expectedResponseData = {
        'itinerary': [
          {
            'id': 'test-itinerary-id',
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
            'id': 'test-uuid-1',
            'parent_id': null,
            'user': 'Alex',
            'category': 'Gear',
            'content': 'Test message',
            'timestamp': '2024-12-15T09:00:00Z',
            'created_at': '2024-12-15T09:00:00Z',
            'created_by': 'Alex',
            'updated_at': '2024-12-15T09:00:00Z',
            'updated_by': 'Alex',
          },
        ],
      };

      final result = await service.getAll();

      expect(result, isA<Success<DataServiceResult, Exception>>());
      final data = (result as Success<DataServiceResult, Exception>).value;
      expect(data.itinerary.length, 1);
      expect(data.itinerary.first.name, 'Mountain Lodge');
      expect(data.messages.length, 1);
      expect(data.messages.first.user, 'Alex');
    });

    test('getAll should return error on HTTP failure', () async {
      mockClient.shouldFail = true;

      final result = await service.getAll();

      expect(result, isA<Failure>());
      expect((result as Failure).exception.toString(), contains('500'));
    });

    test('addMessage should post message data', () async {
      final message = Message(
        id: 'new-uuid',
        user: 'Bob',
        category: 'Plan',
        content: 'Test message',
        timestamp: DateTime(2024, 12, 15, 10, 0),
        createdAt: DateTime(2024, 12, 15, 10, 0),
        createdBy: 'Bob',
        updatedAt: DateTime(2024, 12, 15, 10, 0),
        updatedBy: 'Bob',
      );

      final result = await service.addMessage(message);

      expect(result, isA<Success>());
      expect(mockClient.capturedBody, isNotNull);
      expect(mockClient.capturedBody!['action'], ApiConfig.actionMessageCreate);
      expect(mockClient.capturedBody!['data']['id'], 'new-uuid');
    });

    test('deleteMessage should send delete request', () async {
      final result = await service.deleteMessage('uuid-to-delete');

      expect(result, isA<Success>());
      expect(mockClient.capturedBody, isNotNull);
      expect(mockClient.capturedBody!['action'], ApiConfig.actionMessageDelete);
      expect(mockClient.capturedBody!['id'], 'uuid-to-delete');
    });
  });
}
