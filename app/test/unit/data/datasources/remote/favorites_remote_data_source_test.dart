import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/api/models/favorites_api_models.dart';
import 'package:summitmate/data/api/services/favorites_api_service.dart';
import 'package:summitmate/data/datasources/remote/favorites_remote_data_source.dart';
import 'package:summitmate/domain/enums/favorite_type.dart';
import 'package:summitmate/core/error/result.dart';

class MockFavoritesApiService extends Mock implements FavoritesApiService {}

class FakeFavoriteAddRequest extends Fake implements FavoriteAddRequest {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeFavoriteAddRequest());
  });

  late FavoritesRemoteDataSource dataSource;
  late MockFavoritesApiService mockApi;

  setUp(() {
    mockApi = MockFavoritesApiService();
    dataSource = FavoritesRemoteDataSource(mockApi);
  });

  final testResponse = FavoriteResponse.fromJson({
    'id': 'fav-1',
    'target_id': '1',
    'type': 'trip',
    'created_at': '2024-01-01T00:00:00Z',
    'created_by': 'user-1',
    'updated_at': '2024-01-01T00:00:00Z',
    'updated_by': 'user-1',
  });

  group('FavoritesRemoteDataSource.getFavorites', () {
    test(
      'Given success, When calling FavoritesRemoteDataSource.getFavorites, Then returns success with list',
      () async {
        final paginationResponse = FavoritePaginationResponse.fromJson({
          'items': [
            {
              'id': 'fav-1',
              'target_id': '1',
              'type': 'trip',
              'created_at': '2024-01-01T00:00:00Z',
              'created_by': 'user-1',
              'updated_at': '2024-01-01T00:00:00Z',
              'updated_by': 'user-1',
            },
          ],
          'pagination': {'next_cursor': null, 'has_more': false, 'page': 1, 'limit': 20, 'total': 1},
        });
        when(
          () => mockApi.listFavorites(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => paginationResponse);

        final result = await dataSource.getFavorites();

        expect(result, isA<Success>());
        final paginated = (result as Success).value;
        expect(paginated.items.length, 1);
        expect(paginated.page, 1);
        expect(paginated.total, 1);
      },
    );

    test('Given exception, When calling FavoritesRemoteDataSource.getFavorites, Then returns failure', () async {
      when(
        () => mockApi.listFavorites(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenThrow(Exception('Error'));

      final result = await dataSource.getFavorites();

      expect(result, isA<Failure>());
    });
  });

  group('FavoritesRemoteDataSource.updateFavorite', () {
    test(
      'Given isFavorite is true, When calling FavoritesRemoteDataSource.updateFavorite, Then calls addFavorite',
      () async {
        when(() => mockApi.addFavorite(any())).thenAnswer((_) async => testResponse);

        final result = await dataSource.updateFavorite('1', FavoriteType.mountain, true);

        expect(result, isA<Success>());
        verify(() => mockApi.addFavorite(any())).called(1);
      },
    );

    test(
      'Given isFavorite is false, When calling FavoritesRemoteDataSource.updateFavorite, Then calls removeFavorite',
      () async {
        when(() => mockApi.removeFavorite('1', type: any(named: 'type'))).thenAnswer((_) async {});

        final result = await dataSource.updateFavorite('1', FavoriteType.mountain, false);

        expect(result, isA<Success>());
        verify(() => mockApi.removeFavorite('1', type: FavoriteType.mountain.value)).called(1);
      },
    );
  });
}
