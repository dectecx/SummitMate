import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/datasources/remote/favorites_remote_data_source.dart';
import 'package:summitmate/data/models/enums/favorite_type.dart';
import 'package:summitmate/infrastructure/clients/network_aware_client.dart';
import 'package:summitmate/core/error/result.dart';

class MockNetworkAwareClient extends Mock implements NetworkAwareClient {}

void main() {
  late FavoritesRemoteDataSource dataSource;
  late MockNetworkAwareClient mockApiClient;

  setUp(() {
    mockApiClient = MockNetworkAwareClient();
    dataSource = FavoritesRemoteDataSource(apiClient: mockApiClient);
  });

  group('FavoritesRemoteDataSource.getFavorites', () {
    test('returns success with list of maps on success', () async {
      final responseData = [
        {'target_id': '1', 'type': 'trip'},
      ];

      when(() => mockApiClient.get('/favorites')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/favorites'),
          data: responseData,
          statusCode: 200,
        ),
      );

      final result = await dataSource.getFavorites();

      expect(result, isA<Success>());
      expect((result as Success).value.length, 1);
    });

    test('returns failure on non-200 status', () async {
      when(
        () => mockApiClient.get('/favorites'),
      ).thenAnswer((_) async => Response(requestOptions: RequestOptions(path: '/favorites'), statusCode: 500));

      final result = await dataSource.getFavorites();
      expect(result, isA<Failure>());
    });
  });

  group('FavoritesRemoteDataSource.updateFavorite', () {
    test('returns success on valid update', () async {
      when(
        () => mockApiClient.post('/favorites', data: any(named: 'data')),
      ).thenAnswer((_) async => Response(requestOptions: RequestOptions(path: '/favorites'), statusCode: 200));

      final result = await dataSource.updateFavorite('t1', FavoriteType.route, true);

      expect(result, isA<Success>());
      verify(
        () => mockApiClient.post('/favorites', data: {'target_id': 't1', 'type': 'route', 'is_favorite': true}),
      ).called(1);
    });
  });
}
