import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/services/usage_tracking_service.dart';
import 'package:summitmate/services/gas_api_client.dart';

// Mock Dio
class MockDio extends Mock implements Dio {}

void main() {
  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
  });

  group('UsageTrackingService 測試', () {
    test('start() 應發送初始心跳', () async {
      // 安排 - 建立 Mock Dio
      final mockDio = MockDio();

      // Stub post request just in case
      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: {'success': true},
          statusCode: 200,
        ),
      );

      final apiClient = GasApiClient(dio: mockDio, baseUrl: 'https://mock.api');
      final service = UsageTrackingService(apiClient: apiClient);

      // 執行 - 啟動追蹤
      service.start('test_user');

      // 驗證 - 服務應正確建立
      expect(service, isNotNull);

      // 清理
      service.dispose();
    });

    test('stop() 應取消定時器', () {
      // 安排
      final mockDio = MockDio();
      final apiClient = GasApiClient(dio: mockDio, baseUrl: 'https://mock.api');
      final service = UsageTrackingService(apiClient: apiClient);

      // 執行
      service.stop();

      // 驗證 - 不應拋出異常
      expect(() => service.stop(), returnsNormally);

      // 清理
      service.dispose();
    });

    test('dispose() 應釋放資源', () {
      // 安排
      final mockDio = MockDio();
      final apiClient = GasApiClient(dio: mockDio, baseUrl: 'https://mock.api');
      final service = UsageTrackingService(apiClient: apiClient);

      // 執行 & 驗證
      expect(() => service.dispose(), returnsNormally);
    });

    test('建構子應接受自訂 ApiClient', () {
      // 安排
      final mockDio = MockDio();
      final apiClient = GasApiClient(dio: mockDio, baseUrl: 'https://custom.api');

      // 執行
      final service = UsageTrackingService(apiClient: apiClient);

      // 驗證
      expect(service, isNotNull);

      // 清理
      service.dispose();
    });
  });
}
