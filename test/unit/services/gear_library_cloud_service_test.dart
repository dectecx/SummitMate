import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:summitmate/data/models/gear_library_item.dart';
import 'package:summitmate/infrastructure/services/gear_library_cloud_service.dart';
import 'package:summitmate/infrastructure/clients/network_aware_client.dart';

// Mock NetworkAwareClient
class MockNetworkAwareClient extends Mock implements NetworkAwareClient {}

void main() {
  late MockNetworkAwareClient mockApiClient;
  late GearLibraryCloudService service;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
  });

  setUp(() {
    mockApiClient = MockNetworkAwareClient();
    service = GearLibraryCloudService(apiClient: mockApiClient);
  });

  group('GearLibraryCloudService', () {
    final testItems = [
      GearLibraryItem(
        id: '1',
        userId: 'u1',
        name: 'Tent',
        weight: 1500,
        category: 'Shelter',
        notes: 'Lightweight',
        createdAt: DateTime.now(),
        createdBy: 'u1',
        updatedAt: DateTime.now(),
        updatedBy: 'u1',
      ),
    ];

    test('syncLibrary success should return count', () async {
      // Arrange
      when(() => mockApiClient.post(any(), requiresAuth: true)).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: {
            'code': '0000',
            'message': 'Success',
            'data': {'count': 1},
          },
        ),
      );

      // Act
      final result = await service.syncLibrary(testItems);

      // Assert
      expect(result.isSuccess, true);
      expect(result.data, 1);
    });

    test('syncLibrary failure should return error message', () async {
      // Arrange
      when(() => mockApiClient.post(any(), requiresAuth: true)).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: {'code': '9999', 'message': 'Database error'},
        ),
      );

      // Act
      final result = await service.syncLibrary(testItems);

      // Assert
      expect(result.isSuccess, false);
      expect(result.errorMessage, contains('Database error'));
    });

    test('getLibrary success should return items', () async {
      // Arrange
      when(() => mockApiClient.post(any(), requiresAuth: true)).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: {
            'code': '0000',
            'message': 'Success',
            'data': {
              'items': [testItems[0].toJson()],
            },
          },
        ),
      );

      // Act
      final result = await service.getLibrary();

      // Assert
      expect(result.isSuccess, true);
      expect(result.data!.length, 1);
      expect(result.data![0].name, 'Tent');
    });

    test('getLibrary failure should return error', () async {
      // Arrange
      when(() => mockApiClient.post(any(), requiresAuth: true)).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 500,
          data: {},
        ),
      );

      // Act
      final result = await service.getLibrary();

      // Assert
      expect(result.isSuccess, false);
      expect(result.errorMessage, contains('HTTP 500'));
    });
  });
}
