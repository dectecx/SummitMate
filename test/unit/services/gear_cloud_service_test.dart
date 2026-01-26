import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:summitmate/data/models/gear_set.dart';
import 'package:summitmate/data/models/gear_item.dart';
import 'package:summitmate/infrastructure/clients/gas_api_client.dart';
import 'package:summitmate/infrastructure/services/gear_cloud_service.dart';
import 'package:summitmate/infrastructure/clients/network_aware_client.dart';
import 'package:summitmate/domain/interfaces/i_connectivity_service.dart';

// Mock GasApiClient (Reused pattern)
class MockGasApiClient extends GasApiClient {
  MockGasApiClient() : super(baseUrl: 'https://mock.url');

  Map<String, dynamic>? expectedResponseData;
  bool shouldFail = false;
  int statusCode = 200;

  @override
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    if (shouldFail) {
      return Response(
        requestOptions: RequestOptions(path: path),
        statusCode: 500,
        statusMessage: 'Error',
      );
    }

    final responseBody = {
      'code': statusCode == 200 ? '0000' : '9999',
      'message': 'Mock Message',
      'data': expectedResponseData ?? {},
    };

    return Response(
      requestOptions: RequestOptions(path: path),
      data: responseBody,
      statusCode: statusCode,
    );
  }
}

class MockConnectivityService extends Mock implements IConnectivityService {}

void main() {
  late GearCloudService service;
  late MockGasApiClient mockClient;
  late MockConnectivityService mockConnectivity;

  setUp(() {
    mockClient = MockGasApiClient();
    mockConnectivity = MockConnectivityService();
    when(() => mockConnectivity.isOffline).thenReturn(false);

    final networkClient = NetworkAwareClient(apiClient: mockClient, connectivity: mockConnectivity);
    service = GearCloudService(apiClient: networkClient);
  });

  group('GearCloudService', () {
    test('getGearSets returns list of GearSets', () async {
      mockClient.expectedResponseData = {
        'gear_sets': [
          {
            'id': 'uuid1',
            'title': 'Set 1',
            'author': 'User',
            'total_weight': 1000,
            'item_count': 5,
            'visibility': 'public',
            'uploaded_at': '2025-01-01T00:00:00.000Z',
            'created_at': '2025-01-01T00:00:00.000Z',
            'created_by': 'User',
            'updated_at': '2025-01-01T00:00:00.000Z',
            'updated_by': 'User',
          },
        ],
      };

      final result = await service.getGearSets();
      // 驗證
      expect(result.isSuccess, isTrue);
      expect(result.data, hasLength(1));
      expect(result.data!.first.title, 'Set 1');
    });

    test('uploadGearSet returns uploaded GearSet', () async {
      mockClient.expectedResponseData = {
        'gear_set': {
          'id': 'new_uuid',
          'title': 'New Set',
          'author': 'User',
          'total_weight': 100,
          'item_count': 1,
          'visibility': 'public',
          'uploaded_at': '2025-01-01T00:00:00.000Z',
          'created_at': '2025-01-01T00:00:00.000Z',
          'created_by': 'User',
          'updated_at': '2025-01-01T00:00:00.000Z',
          'updated_by': 'User',
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

      expect(result.isSuccess, true);
      expect(result.data!.id, 'new_uuid');
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

      expect(result.isSuccess, false);
      expect(result.errorMessage, contains('4 位數 Key'));
    });

    test('downloadGearSet returns GearSet with items', () async {
      mockClient.expectedResponseData = {
        'gear_set': {
          'id': 'uuid1',
          'title': 'Set 1',
          'author': 'User',
          'total_weight': 1000,
          'item_count': 5,
          'visibility': 'public',
          'uploaded_at': '2025-01-01T00:00:00.000Z',
          'created_at': '2025-01-01T00:00:00.000Z',
          'created_by': 'User',
          'updated_at': '2025-01-01T00:00:00.000Z',
          'updated_by': 'User',
          'items': [],
        },
      };

      final result = await service.downloadGearSet('uuid1');

      expect(result.isSuccess, true);
      expect(result.data, isNotNull);
    });
  });
}
