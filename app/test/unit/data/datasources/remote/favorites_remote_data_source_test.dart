import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/datasources/remote/favorites_remote_data_source.dart';
import 'package:summitmate/data/models/enums/favorite_type.dart';
import 'package:summitmate/core/error/result.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late FavoritesRemoteDataSource dataSource;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    dataSource = FavoritesRemoteDataSource(mockDio);
  });

  group('FavoritesRemoteDataSource.getFavorites', () {
    test('returns success with list of maps on success', () async {
      final responseData = [
        {
          'id': 'fav-1',
          'target_id': '1',
          'type': 'trip',
          'created_at': DateTime.now().toIso8601String(),
          'created_by': 'user-1',
          'updated_at': DateTime.now().toIso8601String(),
          'updated_by': 'user-1',
        },
      ];

      when(() => mockDio.get('/favorites')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/favorites'),
          data: responseData,
          statusCode: 200,
        ),
      );

      final result = await dataSource.getFavorites();

      expect(result, isA<Success>());
      final list = (result as Success).value as List;
      expect(list.length, 1);
      expect(list[0]['target_id'], '1');
    });

    test('returns failure on exception', () async {
      when(() => mockDio.get('/favorites')).thenThrow(Exception('Fail'));

      final result = await dataSource.getFavorites();
      expect(result, isA<Failure>());
    });
  });

  group('FavoritesRemoteDataSource.updateFavorite', () {
    test('calls POST when isFavorite is true', () async {
      final responseData = {
        'id': 'fav-1',
        'target_id': 't1',
        'type': 'route',
        'created_at': DateTime.now().toIso8601String(),
        'created_by': 'u1',
        'updated_at': DateTime.now().toIso8601String(),
        'updated_by': 'u1',
      };
      
      when(() => mockDio.post('/favorites', data: any(named: 'data'))).thenAnswer(
        (_) async => Response(requestOptions: RequestOptions(path: '/favorites'), data: responseData, statusCode: 201),
      );

      final result = await dataSource.updateFavorite('t1', FavoriteType.route, true);

      expect(result, isA<Success>());
      verify(() => mockDio.post('/favorites', data: {'target_id': 't1', 'type': 'route'})).called(1);
    });

    test('calls DELETE when isFavorite is false', () async {
      when(() => mockDio.delete('/favorites/t1')).thenAnswer(
        (_) async => Response(requestOptions: RequestOptions(path: '/favorites/t1'), statusCode: 200),
      );

      final result = await dataSource.updateFavorite('t1', FavoriteType.route, false);

      expect(result, isA<Success>());
      verify(() => mockDio.delete('/favorites/t1')).called(1);
    });
  });
}
