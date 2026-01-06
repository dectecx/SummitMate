import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:summitmate/data/models/gear_set.dart';
import 'package:summitmate/data/models/gear_item.dart';
import 'package:summitmate/services/gas_api_client.dart';
import 'package:summitmate/services/gear_cloud_service.dart';

// Mock GasApiClient (Reused pattern)
class MockGasApiClient extends GasApiClient {
  MockGasApiClient() : super(baseUrl: 'https://mock.url');

  Map<String, dynamic>? expectedResponseData;
  bool shouldFail = false;
  int statusCode = 200;

  @override
  Future<http.Response> post(Map<String, dynamic> body, {bool requiresAuth = false}) async {
    if (shouldFail) {
      return http.Response('Error', 500);
    }

    final responseBody = {
      'code': statusCode == 200 ? '0000' : '9999',
      'message': 'Mock Message',
      'data': expectedResponseData ?? {},
    };

    return http.Response(jsonEncode(responseBody), statusCode);
  }
}

void main() {
  late GearCloudService service;
  late MockGasApiClient mockClient;

  setUp(() {
    mockClient = MockGasApiClient();
    service = GearCloudService(apiClient: mockClient);
  });

  group('GearCloudService', () {
    test('fetchGearSets returns list of GearSets', () async {
      mockClient.expectedResponseData = {
        'gear_sets': [
          {
            'uuid': 'uuid1',
            'title': 'Set 1',
            'author': 'User',
            'total_weight': 1000,
            'item_count': 5,
            'visibility': 'public',
            'uploaded_at': '2025-01-01T00:00:00.000Z',
          },
        ],
      };

      final result = await service.fetchGearSets();

      expect(result.success, true);
      expect(result.data, isA<List<GearSet>>());
      expect(result.data!.length, 1);
    });

    test('uploadGearSet returns uploaded GearSet', () async {
      mockClient.expectedResponseData = {
        'gear_set': {
          'uuid': 'new_uuid',
          'title': 'New Set',
          'author': 'User',
          'total_weight': 100,
          'item_count': 1,
          'visibility': 'public',
          'uploaded_at': '2025-01-01T00:00:00.000Z',
        },
      };

      final items = [GearItem(name: 'Item', weight: 100, category: 'Misc')];

      final result = await service.uploadGearSet(
        tripId: 'trip1',
        title: 'New Set',
        author: 'User',
        visibility: GearSetVisibility.public,
        items: items,
      );

      expect(result.success, true);
      expect(result.data!.uuid, 'new_uuid');
    });

    test('uploadGearSet requires 4-digit key for protected sets', () async {
      final items = [GearItem(name: 'Item', weight: 100, category: 'Misc')];

      final result = await service.uploadGearSet(
        tripId: 'trip1',
        title: 'Protected Set',
        author: 'User',
        visibility: GearSetVisibility.protected,
        items: items,
        key: '123', // Invalid key length
      );

      expect(result.success, false);
      expect(result.errorMessage, contains('4 位數 Key'));
    });

    test('downloadGearSet returns GearSet with items', () async {
      mockClient.expectedResponseData = {
        'gear_set': {
          'uuid': 'uuid1',
          'title': 'Set 1',
          'author': 'User',
          'total_weight': 1000,
          'item_count': 5,
          'visibility': 'public',
          'uploaded_at': '2025-01-01T00:00:00.000Z',
          'items': [],
        },
      };

      final result = await service.downloadGearSet('uuid1');

      expect(result.success, true);
      expect(result.data, isNotNull);
    });
  });
}
