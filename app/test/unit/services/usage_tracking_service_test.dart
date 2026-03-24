import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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

  group('UsageTrackingService Tests', () {
    late MockNetworkAwareClient mockApiClient;
    late UsageTrackingService service;

    setUp(() {
      mockApiClient = MockNetworkAwareClient();
      service = UsageTrackingService(mockApiClient);
    });

    tearDown(() {
      service.dispose();
    });

    test('start() should send heartbeat on Web and skip on non-Web', () async {
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

      // 執行
      service.start('MemberUser', userId: 'user-123');

      // 驗證
      if (kIsWeb) {
        expect(capturedData, isNotNull);
        expect(capturedData!['user_name'], 'MemberUser');
      } else {
        expect(capturedData, isNull);
        verifyNever(() => mockApiClient.post(any(), data: any(named: 'data')));
      }
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
      if (kIsWeb) {
        expect(capturedData, isNotNull);
        expect(capturedData!['user_name'], 'GuestUser');
        expect(capturedData!['user_id'], isNull);
        expect(capturedData!['user_type'], 'guest');
      } else {
        expect(capturedData, isNull);
        verifyNever(() => mockApiClient.post(any(), data: any(named: 'data')));
      }
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
