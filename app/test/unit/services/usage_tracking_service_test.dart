import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/infrastructure/tools/usage_tracking_service.dart';
import 'package:summitmate/infrastructure/clients/gas_api_client.dart';

// Mock Dio
class MockDio extends Mock implements Dio {}

void main() {
  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
  });

  group('UsageTrackingService 測試', () {
    test('start() with userId should send member heartbeat', () async {
      // 安排
      final mockDio = MockDio();

      // Capture the sent data
      Map<String, dynamic>? capturedData;

      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((invocation) async {
        capturedData = invocation.namedArguments[#data] as Map<String, dynamic>;
        return Response(
          requestOptions: RequestOptions(path: ''),
          data: {'code': '0000', 'message': 'Success'},
          statusCode: 200,
        );
      });

      final apiClient = GasApiClient(dio: mockDio, baseUrl: 'https://mock.api');
      final service = UsageTrackingService(apiClient: apiClient, forceWeb: true);

      // 執行 - 啟動追蹤 (Member)
      service.start('MemberUser', userId: 'user-123');

      // 驗證
      expect(capturedData, isNotNull);
      expect(capturedData!['user_name'], 'MemberUser');
      expect(capturedData!['user_id'], 'user-123');
      expect(capturedData!['user_type'], 'member');

      service.dispose();
    });

    test('start() without userId should send guest heartbeat', () async {
      // 安排
      final mockDio = MockDio();

      Map<String, dynamic>? capturedData;

      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((invocation) async {
        capturedData = invocation.namedArguments[#data] as Map<String, dynamic>;
        return Response(
          requestOptions: RequestOptions(path: ''),
          data: {'code': '0000', 'message': 'Success'},
          statusCode: 200,
        );
      });

      final apiClient = GasApiClient(dio: mockDio, baseUrl: 'https://mock.api');
      final service = UsageTrackingService(apiClient: apiClient, forceWeb: true);

      // 執行 - 啟動追蹤 (Guest)
      service.start('GuestUser');

      // 驗證
      expect(capturedData, isNotNull);
      expect(capturedData!['user_name'], 'GuestUser');
      expect(capturedData!['user_id'], isNull); // ID is explicitly null for guests in flutter, GAS handles logic
      expect(capturedData!['user_type'], 'guest');

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
