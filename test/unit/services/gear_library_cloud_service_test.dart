import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:summitmate/data/models/gear_library_item.dart';
import 'package:summitmate/services/gear_library_cloud_service.dart';
import 'package:summitmate/services/gas_api_client.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

@GenerateMocks([GasApiClient])
import 'gear_library_cloud_service_test.mocks.dart';

void main() {
  late MockGasApiClient mockClient;
  late GearLibraryCloudService service;

  setUp(() {
    mockClient = MockGasApiClient();
    service = GearLibraryCloudService(apiClient: mockClient);
  });

  group('GearLibraryCloudService Tests', () {
    group('uploadLibrary', () {
      test('驗證 owner_key 必須為 4 位數', () async {
        final result = await service.uploadLibrary(ownerKey: '123', items: []);
        expect(result.isSuccess, isFalse);
        expect(result.error, contains('4 位數字'));
      });

      test('owner_key 為非數字時應失敗', () async {
        final result = await service.uploadLibrary(ownerKey: 'abcd', items: []);
        expect(result.isSuccess, isFalse);
        expect(result.error, contains('4 位數字'));
      });

      test('成功上傳返回項目數量', () async {
        final items = [GearLibraryItem(name: 'Test Item', weight: 100, category: 'Other')];

        when(
          mockClient.post(any),
        ).thenAnswer((_) async => http.Response(jsonEncode({'success': true, 'count': 1}), 200));

        final result = await service.uploadLibrary(ownerKey: '1234', items: items);
        expect(result.isSuccess, isTrue);
        expect(result.data, 1);
      });

      test('API 失敗時返回錯誤訊息', () async {
        when(
          mockClient.post(any),
        ).thenAnswer((_) async => http.Response(jsonEncode({'success': false, 'error': '伺服器錯誤'}), 200));

        final result = await service.uploadLibrary(
          ownerKey: '1234',
          items: [GearLibraryItem(name: 'Test', weight: 100, category: 'Other')],
        );
        expect(result.isSuccess, isFalse);
        expect(result.error, contains('伺服器錯誤'));
      });
    });

    group('downloadLibrary', () {
      test('驗證 owner_key 必須為 4 位數', () async {
        final result = await service.downloadLibrary(ownerKey: '12');
        expect(result.isSuccess, isFalse);
        expect(result.error, contains('4 位數字'));
      });

      test('成功下載返回項目列表', () async {
        when(mockClient.post(any)).thenAnswer(
          (_) async => http.Response(
            jsonEncode({
              'success': true,
              'items': [
                {'uuid': 'test-uuid', 'name': 'Downloaded Item', 'weight': 200.0, 'category': 'Sleep'},
              ],
            }),
            200,
          ),
        );

        final result = await service.downloadLibrary(ownerKey: '5678');
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.length, 1);
        expect(result.data!.first.name, 'Downloaded Item');
      });

      test('下載空列表時返回空 List', () async {
        when(
          mockClient.post(any),
        ).thenAnswer((_) async => http.Response(jsonEncode({'success': true, 'items': []}), 200));

        final result = await service.downloadLibrary(ownerKey: '0000');
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });
    });
  });
}
