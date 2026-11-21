import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/core/error/result.dart';
import 'package:summitmate/core/models/paginated_list.dart';
import 'package:summitmate/data/datasources/interfaces/i_favorites_local_data_source.dart';

import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/data/repositories/favorites_repository.dart';

class MockFavoritesLocalDataSource extends Mock implements IFavoritesLocalDataSource {}

class MockAuthService extends Mock implements IAuthService {}

class FakeFavorite extends Fake implements Favorite {}

void main() {
  late FavoritesRepository repository;
  late MockFavoritesLocalDataSource mockLocalDataSource;
  late MockAuthService mockAuthService;

  setUpAll(() {
    registerFallbackValue(FavoriteType.mountain);
    registerFallbackValue(FakeFavorite());
  });

  setUp(() {
    mockLocalDataSource = MockFavoritesLocalDataSource();
    mockAuthService = MockAuthService();
    repository = FavoritesRepository(localDataSource: mockLocalDataSource, authService: mockAuthService);
  });

  group('FavoritesRepository (C 模式)', () {
    final tFavorite = Favorite(
      id: 'mountain_target1',
      targetId: 'target1',
      type: FavoriteType.mountain,
      createdAt: DateTime.now(),
      createdBy: 'user1',
      updatedAt: DateTime.now(),
      updatedBy: 'user1',
    );
    final tException = Exception('Test Error');

    group('getFavorites', () {
      test('Given local favorites, When getFavorites, Then it returns them from local only', () async {
        when(() => mockLocalDataSource.getFavorites()).thenAnswer((_) async => [tFavorite]);

        final result = await repository.getFavorites();

        expect(result, isA<Success<PaginatedList<Favorite>, Exception>>());
        expect((result as Success<PaginatedList<Favorite>, Exception>).value.items, [tFavorite]);
        verify(() => mockLocalDataSource.getFavorites()).called(1);
      });

      test('Given local fetch fails, When getFavorites, Then it returns Failure', () async {
        when(() => mockLocalDataSource.getFavorites()).thenThrow(tException);

        final result = await repository.getFavorites();

        expect(result, isA<Failure<PaginatedList<Favorite>, Exception>>());
        expect((result as Failure).exception, tException);
      });
    });

    group('toggleFavorite', () {
      const tId = 'target1';
      const tType = FavoriteType.mountain;

      test('Given a toggle, When toggleFavorite, Then it only writes local (pending queue)', () async {
        when(() => mockAuthService.currentUserId).thenReturn('user1');
        when(
          () => mockLocalDataSource.toggleFavorite(any(), any(), any(), userId: any(named: 'userId')),
        ).thenAnswer((_) async {});

        final result = await repository.toggleFavorite(tId, tType, true);

        expect(result, isA<Success<void, Exception>>());
        verify(() => mockLocalDataSource.toggleFavorite(tId, tType, true, userId: 'user1')).called(1);
      });
    });
  });
}
