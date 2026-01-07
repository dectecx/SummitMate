import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:summitmate/data/models/gear_library_item.dart';
import 'package:summitmate/services/gas_api_client.dart';
import 'package:summitmate/services/gear_library_cloud_service.dart';

// Mock GasApiClient
class MockGasApiClient extends GasApiClient {
  MockGasApiClient() : super(baseUrl: 'https://mock.url');

  Map<String, dynamic>? expectedResponseData;
  bool shouldFail = false;
  int statusCode = 200;

  @override
  Future<Response> post(Map<String, dynamic> body, {bool requiresAuth = false}) async {
    if (shouldFail) {
      return Response(
        requestOptions: RequestOptions(path: ''),
        statusCode: 500,
        statusMessage: 'Error',
      );
    }

    // Default success response
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
  late MockGasApiClient mockClient;
  late GearLibraryCloudService service;

  setUp(() {
    mockClient = MockGasApiClient();
    service = GearLibraryCloudService(apiClient: mockClient);
  });

  group('GearLibraryCloudService Tests', () {
    group('syncLibrary', () {
      test('成功同步返回項目數量', () async {
        final items = [GearLibraryItem(name: 'Test Item', weight: 100, category: 'Other')];
        mockClient.expectedResponseData = {'count': 1};

        final result = await service.syncLibrary(items);
        expect(result.isSuccess, isTrue);
        expect(result.data, 1);
      });

      test('API 成功時返回 count', () async {
        mockClient.expectedResponseData = {'count': 5};

        final result = await service.syncLibrary([GearLibraryItem(name: 'Test', weight: 100, category: 'Other')]);
        // 驗證
        expect(result.isSuccess, isTrue);
        expect(result.data, equals(5));
      });

      test('API 失敗時返回錯誤訊息', () async {
        mockClient.shouldFail = true;

        final result = await service.syncLibrary([GearLibraryItem(name: 'Test', weight: 100, category: 'Other')]);
        // 驗證
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('HTTP 500'));
      });
    });

    group('fetchLibrary', () {
      test('成功下載返回項目列表', () async {
        mockClient.expectedResponseData = {
          'items': [
            {'uuid': 'test-uuid', 'name': 'Downloaded Item', 'weight': 200.0, 'category': 'Sleep'},
          ],
        };

        final result = await service.fetchLibrary();
        // 驗證
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data, hasLength(1));

        expect(result.data!.first.name, 'Downloaded Item');
      });

      test('下載空列表時返回空 List', () async {
        mockClient.expectedResponseData = {'items': []};

        final result = await service.fetchLibrary();
        // 驗證
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });
    });
  });
}
