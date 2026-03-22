import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/infrastructure/tools/usage_tracking_service.dart';
import 'package:summitmate/infrastructure/clients/network_aware_client.dart';

// Mock NetworkAwareClient
class MockNetworkAwareClient extends Mock implements NetworkAwareClient {}

void main() {
  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
  });

  group('UsageTrackingService 測試', () {
    late MockNetworkAwareClient mockApiClient;
    late UsageTrackingService service;

    setUp(() {
      mockApiClient = MockNetworkAwareClient();
      service = UsageTrackingService(mockApiClient, forceWeb: true);
    });

    tearDown(() {
      service.dispose();
    });

    test('start() with userId should send member heartbeat', () async {
      // 安排
      Map<String, dynamic>? capturedData;

      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((invocation) async {
        capturedData = invocation.namedArguments[#data] as Map<String, dynamic>;
        return Response(
          requestOptions: RequestOptions(path: '/system/heartbeat'),
          data: {'status': 'ok'},
          statusCode: 200,
        );
      });

      // 執行 - 啟動追蹤 (Member)
      service.start('MemberUser', userId: 'user-123');

      // 驗證
      expect(capturedData, isNotNull);
      expect(capturedData!['user_name'], 'MemberUser');
      expect(capturedData!['user_id'], 'user-123');
      expect(capturedData!['user_type'], 'member');
    });

    test('start() without userId should send guest heartbeat', () async {
      // 安排
      Map<String, dynamic>? capturedData;

      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((invocation) async {
        capturedData = invocation.namedArguments[#data] as Map<String, dynamic>;
        return Response(
          requestOptions: RequestOptions(path: '/system/heartbeat'),
          data: {'status': 'ok'},
          statusCode: 200,
        );
      });

      // 執行 - 啟動追蹤 (Guest)
      service.start('GuestUser');

      // 驗證
      expect(capturedData, isNotNull);
      expect(capturedData!['user_name'], 'GuestUser');
      expect(capturedData!['user_id'], isNull);
      expect(capturedData!['user_type'], 'guest');
    });

    test('stop() 應取消定時器', () {
      // 執行 & 驗證 - 不應拋出異常
      expect(() => service.stop(), returnsNormally);
      expect(() => service.stop(), returnsNormally);
    });

    test('dispose() 應釋放資源', () {
      // 執行 & 驗證
      expect(() => service.dispose(), returnsNormally);
    });

    test('建構子應接受自訂 ApiClient', () {
      // 執行
      final customService = UsageTrackingService(mockApiClient);

      // 驗證
      expect(customService, isNotNull);
      customService.dispose();
    });
  });
}
