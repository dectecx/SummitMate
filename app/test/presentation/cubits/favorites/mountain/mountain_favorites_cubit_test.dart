import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/core/error/result.dart';
import 'package:summitmate/core/models/paginated_list.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/presentation/cubits/favorites/mountain/mountain_favorites_cubit.dart';
import 'package:summitmate/presentation/cubits/favorites/mountain/mountain_favorites_state.dart';

class MockFavoritesRepository extends Mock implements IFavoritesRepository {}

void main() {
  late MockFavoritesRepository mockRepo;

  final tFavoriteMountain = Favorite(
    id: 'fav-1',
    targetId: 'mountain-1',
    type: FavoriteType.mountain,
    createdAt: DateTime(2024, 1, 1),
    createdBy: 'user-1',
    updatedAt: DateTime(2024, 1, 1),
    updatedBy: 'user-1',
  );

  final tFavoriteGroupEvent = Favorite(
    id: 'fav-2',
    targetId: 'event-1',
    type: FavoriteType.groupEvent,
    createdAt: DateTime(2024, 1, 1),
    createdBy: 'user-1',
    updatedAt: DateTime(2024, 1, 1),
    updatedBy: 'user-1',
  );

  setUpAll(() {
    registerFallbackValue(FavoriteType.mountain);
  });

  setUp(() {
    mockRepo = MockFavoritesRepository();
  });

  group('MountainFavoritesCubit', () {
    test(
      'Given MountainFavoritesCubit, When initialized, Then initial state is MountainFavoritesInitial',
      () {
        expect(
          MountainFavoritesCubit(mockRepo).state,
          isA<MountainFavoritesInitial>(),
        );
      },
    );

    // ─── loadFavorites ────────────────────────────────────────────────────────

    blocTest<MountainFavoritesCubit, MountainFavoritesState>(
      'Given favorites list, When loadFavorites, Then emits [Loading, Loaded] with only mountain IDs',
      build: () {
        when(() => mockRepo.getFavorites()).thenAnswer(
          (_) async => Success(
            PaginatedList(
              items: [tFavoriteMountain, tFavoriteGroupEvent],
              total: 2,
              page: 1,
              hasMore: false,
            ),
          ),
        );
        return MountainFavoritesCubit(mockRepo);
      },
      act: (cubit) => cubit.loadFavorites(),
      expect: () => [
        isA<MountainFavoritesLoading>(),
        isA<MountainFavoritesLoaded>().having(
          (s) => s.favoriteIds,
          'favoriteIds',
          ['mountain-1'],
        ),
      ],
    );

    blocTest<MountainFavoritesCubit, MountainFavoritesState>(
      'Given API failure, When loadFavorites, Then emits [Loading, Error]',
      build: () {
        when(
          () => mockRepo.getFavorites(),
        ).thenAnswer((_) async => Failure(Exception('network error')));
        return MountainFavoritesCubit(mockRepo);
      },
      act: (cubit) => cubit.loadFavorites(),
      expect: () => [
        isA<MountainFavoritesLoading>(),
        isA<MountainFavoritesError>(),
      ],
    );

    // ─── toggleFavorite ───────────────────────────────────────────────────────

    blocTest<MountainFavoritesCubit, MountainFavoritesState>(
      'Given loaded state without id, When toggleFavorite, Then emits Loaded with id added',
      build: () {
        when(
          () => mockRepo.toggleFavorite(
            'mountain-new',
            FavoriteType.mountain,
            true,
          ),
        ).thenAnswer((_) async => const Success(null));
        return MountainFavoritesCubit(mockRepo);
      },
      seed: () => const MountainFavoritesLoaded([]),
      act: (cubit) => cubit.toggleFavorite('mountain-new'),
      expect: () => [
        isA<MountainFavoritesLoaded>().having(
          (s) => s.favoriteIds,
          'favoriteIds',
          contains('mountain-new'),
        ),
      ],
    );

    blocTest<MountainFavoritesCubit, MountainFavoritesState>(
      'Given loaded state with id, When toggleFavorite, Then emits Loaded with id removed',
      build: () {
        when(
          () => mockRepo.toggleFavorite(
            'mountain-1',
            FavoriteType.mountain,
            false,
          ),
        ).thenAnswer((_) async => const Success(null));
        return MountainFavoritesCubit(mockRepo);
      },
      seed: () => const MountainFavoritesLoaded(['mountain-1']),
      act: (cubit) => cubit.toggleFavorite('mountain-1'),
      expect: () => [
        isA<MountainFavoritesLoaded>().having(
          (s) => s.favoriteIds,
          'favoriteIds',
          isNot(contains('mountain-1')),
        ),
      ],
    );

    blocTest<MountainFavoritesCubit, MountainFavoritesState>(
      'Given not in Loaded state, When toggleFavorite, Then emits nothing',
      build: () => MountainFavoritesCubit(mockRepo),
      act: (cubit) => cubit.toggleFavorite('mountain-1'),
      expect: () => [],
    );

    blocTest<MountainFavoritesCubit, MountainFavoritesState>(
      'Given toggle failure, When toggleFavorite, Then emits Error then re-loads',
      build: () {
        when(
          () => mockRepo.toggleFavorite(
            'mountain-1',
            FavoriteType.mountain,
            false,
          ),
        ).thenAnswer((_) async => Failure(Exception('server error')));
        when(() => mockRepo.getFavorites()).thenAnswer(
          (_) async => Success(
            PaginatedList(
              items: [tFavoriteMountain],
              total: 1,
              page: 1,
              hasMore: false,
            ),
          ),
        );
        return MountainFavoritesCubit(mockRepo);
      },
      seed: () => const MountainFavoritesLoaded(['mountain-1']),
      act: (cubit) => cubit.toggleFavorite('mountain-1'),
      expect: () => [
        isA<MountainFavoritesError>(),
        isA<MountainFavoritesLoading>(),
        isA<MountainFavoritesLoaded>(),
      ],
    );

    // ─── isFavorite ───────────────────────────────────────────────────────────

    test(
      'Given Loaded state with id, When calling isFavorite, Then it returns true',
      () {
        final cubit = MountainFavoritesCubit(mockRepo)
          ..emit(const MountainFavoritesLoaded(['mountain-1']));
        expect(cubit.isFavorite('mountain-1'), isTrue);
        expect(cubit.isFavorite('mountain-other'), isFalse);
      },
    );

    test(
      'Given non-Loaded state, When calling isFavorite, Then it returns false',
      () {
        final cubit = MountainFavoritesCubit(mockRepo);
        expect(cubit.isFavorite('mountain-1'), isFalse);
      },
    );

    // ─── reset ────────────────────────────────────────────────────────────────

    blocTest<MountainFavoritesCubit, MountainFavoritesState>(
      'Given any state, When calling reset, Then emits Initial',
      build: () => MountainFavoritesCubit(mockRepo),
      seed: () => const MountainFavoritesLoaded(['mountain-1']),
      act: (cubit) => cubit.reset(),
      expect: () => [isA<MountainFavoritesInitial>()],
    );
  });
}
