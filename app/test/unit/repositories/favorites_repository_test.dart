import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/core/error/result.dart';
import 'package:summitmate/core/models/paginated_list.dart';
import 'package:summitmate/data/datasources/interfaces/i_favorites_local_data_source.dart';
import 'package:summitmate/data/datasources/interfaces/i_favorites_remote_data_source.dart';

import 'package:summitmate/data/models/favorite_model.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/data/repositories/favorites_repository.dart';


class MockFavoritesLocalDataSource extends Mock implements IFavoritesLocalDataSource {}

class MockFavoritesRemoteDataSource extends Mock implements IFavoritesRemoteDataSource {}

class MockAuthService extends Mock implements IAuthService {}

void main() {
  late FavoritesRepository repository;
  late MockFavoritesLocalDataSource mockLocalDataSource;
  late MockFavoritesRemoteDataSource mockRemoteDataSource;
  late MockAuthService mockAuthService;

  setUpAll(() {
    registerFallbackValue(FavoriteType.mountain);
    registerFallbackValue(
      FavoriteModel(
        id: 'dummy',
        targetId: 'dummy',
        type: FavoriteType.mountain,
        createdAt: DateTime.now(),
        createdBy: 'dummy',
        updatedAt: DateTime.now(),
        updatedBy: 'dummy',
      ),
    );
  });

  setUp(() {
    mockLocalDataSource = MockFavoritesLocalDataSource();
    mockRemoteDataSource = MockFavoritesRemoteDataSource();
    mockAuthService = MockAuthService();
    repository = FavoritesRepository(
      localDataSource: mockLocalDataSource,
      remoteDataSource: mockRemoteDataSource,
      authService: mockAuthService,
    );
  });

  group('FavoritesRepository', () {
    final tFavorite = Favorite(
      id: 'fav1',
      targetId: 'target1',
      type: FavoriteType.mountain,
      createdAt: DateTime.now(),
      createdBy: 'user1',
      updatedAt: DateTime.now(),
      updatedBy: 'user1',
    );
    final tFavoriteModel = FavoriteModel.fromDomain(tFavorite);
    final tException = Exception('Test Error');

    group('getFavorites', () {
      test('should return local favorites immediately and trigger remote sync', () async {
        // Arrange
        when(() => mockLocalDataSource.getFavorites()).thenAnswer((_) async => [tFavoriteModel]);
        when(
          () => mockRemoteDataSource.getFavorites(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer(
          (_) async => Success<PaginatedList<Favorite>, Exception>(
            const PaginatedList(items: [], page: 1, total: 0, hasMore: false),
          ),
        );
        when(() => mockLocalDataSource.saveFavorites(any())).thenAnswer((_) async {});

        // Act
        final result = await repository.getFavorites();

        // Assert
        expect(result, isA<Success<PaginatedList<Favorite>, Exception>>());
        final paginated = (result as Success<PaginatedList<Favorite>, Exception>).value;
        expect(paginated.items, [tFavorite]);

        verify(() => mockLocalDataSource.getFavorites()).called(1);
        verify(
          () => mockRemoteDataSource.getFavorites(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          ),
        ).called(1);
      });

      test('should return Failure when local fetch fails', () async {
        // Arrange
        when(() => mockLocalDataSource.getFavorites()).thenThrow(tException);

        // Act
        final result = await repository.getFavorites();

        // Assert
        expect(result, isA<Failure<PaginatedList<Favorite>, Exception>>());
        expect((result as Failure).exception, tException);
      });
    });

    group('toggleFavorite', () {
      const tId = 'target1';
      const tType = FavoriteType.mountain;

      test('should toggle local and remote if logged in', () async {
        // Arrange
        when(() => mockAuthService.currentUserId).thenReturn('user1');
        when(() => mockAuthService.isLoggedIn()).thenAnswer((_) async => true);
        when(
          () => mockLocalDataSource.toggleFavorite(any(), any(), any(), userId: any(named: 'userId')),
        ).thenAnswer((_) async {});
        when(
          () => mockRemoteDataSource.updateFavorite(any(), any(), any()),
        ).thenAnswer((_) async => const Success(null));

        // Act
        final result = await repository.toggleFavorite(tId, tType, true);

        // Assert
        expect(result, isA<Success<void, Exception>>());
        verify(() => mockLocalDataSource.toggleFavorite(tId, tType, true, userId: 'user1')).called(1);
        verify(() => mockRemoteDataSource.updateFavorite(tId, tType, true)).called(1);
      });

      test('should only toggle local if not logged in', () async {
        // Arrange
        when(() => mockAuthService.currentUserId).thenReturn('user1');
        when(() => mockAuthService.isLoggedIn()).thenAnswer((_) async => false);
        when(
          () => mockLocalDataSource.toggleFavorite(any(), any(), any(), userId: any(named: 'userId')),
        ).thenAnswer((_) async {});

        // Act
        final result = await repository.toggleFavorite(tId, tType, true);

        // Assert
        expect(result, isA<Success<void, Exception>>());
        verify(() => mockLocalDataSource.toggleFavorite(tId, tType, true, userId: 'user1')).called(1);
        verifyNever(() => mockRemoteDataSource.updateFavorite(any(), any(), any()));
      });
    });
  });
}
