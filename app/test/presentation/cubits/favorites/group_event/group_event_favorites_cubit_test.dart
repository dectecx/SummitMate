import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/core/error/result.dart';
import 'package:summitmate/core/models/paginated_list.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/presentation/cubits/favorites/group_event/group_event_favorites_cubit.dart';
import 'package:summitmate/presentation/cubits/favorites/group_event/group_event_favorites_state.dart';

class MockFavoritesRepository extends Mock implements IFavoritesRepository {}

void main() {
  late MockFavoritesRepository mockRepo;

  final tFavoriteGroupEvent = Favorite(
    id: 'fav-1',
    targetId: 'event-1',
    type: FavoriteType.groupEvent,
    createdAt: DateTime(2024, 1, 1),
    createdBy: 'user-1',
    updatedAt: DateTime(2024, 1, 1),
    updatedBy: 'user-1',
  );

  final tFavoriteMountain = Favorite(
    id: 'fav-2',
    targetId: 'mountain-1',
    type: FavoriteType.mountain,
    createdAt: DateTime(2024, 1, 1),
    createdBy: 'user-1',
    updatedAt: DateTime(2024, 1, 1),
    updatedBy: 'user-1',
  );

  setUpAll(() {
    registerFallbackValue(FavoriteType.groupEvent);
  });

  setUp(() {
    mockRepo = MockFavoritesRepository();
  });

  group('GroupEventFavoritesCubit', () {
    test(
      'Given GroupEventFavoritesCubit, When initialized, Then initial state is GroupEventFavoritesInitial',
      () {
        expect(
          GroupEventFavoritesCubit(mockRepo).state,
          isA<GroupEventFavoritesInitial>(),
        );
      },
    );

    // ─── loadFavorites ────────────────────────────────────────────────────────

    blocTest<GroupEventFavoritesCubit, GroupEventFavoritesState>(
      'Given favorites list, When loadFavorites, Then emits [Loading, Loaded] with only group_event IDs',
      build: () {
        when(() => mockRepo.getFavorites()).thenAnswer(
          (_) async => Success(
            PaginatedList(
              items: [tFavoriteGroupEvent, tFavoriteMountain],
              total: 2,
              page: 1,
              hasMore: false,
            ),
          ),
        );
        return GroupEventFavoritesCubit(mockRepo);
      },
      act: (cubit) => cubit.loadFavorites(),
      expect: () => [
        isA<GroupEventFavoritesLoading>(),
        isA<GroupEventFavoritesLoaded>().having(
          (s) => s.favoriteIds,
          'favoriteIds',
          ['event-1'],
        ),
      ],
    );

    blocTest<GroupEventFavoritesCubit, GroupEventFavoritesState>(
      'Given API failure, When loadFavorites, Then emits [Loading, Error]',
      build: () {
        when(
          () => mockRepo.getFavorites(),
        ).thenAnswer((_) async => Failure(Exception('network error')));
        return GroupEventFavoritesCubit(mockRepo);
      },
      act: (cubit) => cubit.loadFavorites(),
      expect: () => [
        isA<GroupEventFavoritesLoading>(),
        isA<GroupEventFavoritesError>(),
      ],
    );

    // ─── toggleFavorite ───────────────────────────────────────────────────────

    blocTest<GroupEventFavoritesCubit, GroupEventFavoritesState>(
      'Given loaded state without id, When toggleFavorite, Then emits Loaded with id added',
      build: () {
        when(
          () => mockRepo.toggleFavorite(
            'event-new',
            FavoriteType.groupEvent,
            true,
          ),
        ).thenAnswer((_) async => const Success(null));
        return GroupEventFavoritesCubit(mockRepo);
      },
      seed: () => const GroupEventFavoritesLoaded([]),
      act: (cubit) => cubit.toggleFavorite('event-new'),
      expect: () => [
        isA<GroupEventFavoritesLoaded>().having(
          (s) => s.favoriteIds,
          'favoriteIds',
          contains('event-new'),
        ),
      ],
    );

    blocTest<GroupEventFavoritesCubit, GroupEventFavoritesState>(
      'Given loaded state with id, When toggleFavorite, Then emits Loaded with id removed',
      build: () {
        when(
          () => mockRepo.toggleFavorite(
            'event-1',
            FavoriteType.groupEvent,
            false,
          ),
        ).thenAnswer((_) async => const Success(null));
        return GroupEventFavoritesCubit(mockRepo);
      },
      seed: () => const GroupEventFavoritesLoaded(['event-1']),
      act: (cubit) => cubit.toggleFavorite('event-1'),
      expect: () => [
        isA<GroupEventFavoritesLoaded>().having(
          (s) => s.favoriteIds,
          'favoriteIds',
          isNot(contains('event-1')),
        ),
      ],
    );

    blocTest<GroupEventFavoritesCubit, GroupEventFavoritesState>(
      'Given not in Loaded state, When toggleFavorite, Then emits nothing',
      build: () => GroupEventFavoritesCubit(mockRepo),
      act: (cubit) => cubit.toggleFavorite('event-1'),
      expect: () => [],
    );

    blocTest<GroupEventFavoritesCubit, GroupEventFavoritesState>(
      'Given toggle failure, When toggleFavorite, Then emits Error then re-loads',
      build: () {
        when(
          () => mockRepo.toggleFavorite(
            'event-1',
            FavoriteType.groupEvent,
            false,
          ),
        ).thenAnswer((_) async => Failure(Exception('server error')));
        when(() => mockRepo.getFavorites()).thenAnswer(
          (_) async => Success(
            PaginatedList(
              items: [tFavoriteGroupEvent],
              total: 1,
              page: 1,
              hasMore: false,
            ),
          ),
        );
        return GroupEventFavoritesCubit(mockRepo);
      },
      seed: () => const GroupEventFavoritesLoaded(['event-1']),
      act: (cubit) => cubit.toggleFavorite('event-1'),
      expect: () => [
        isA<GroupEventFavoritesError>(),
        isA<GroupEventFavoritesLoading>(),
        isA<GroupEventFavoritesLoaded>(),
      ],
    );

    // ─── isFavorite ───────────────────────────────────────────────────────────

    test(
      'Given Loaded state with id, When calling isFavorite, Then it returns true',
      () {
        final cubit = GroupEventFavoritesCubit(mockRepo)
          ..emit(const GroupEventFavoritesLoaded(['event-1']));
        expect(cubit.isFavorite('event-1'), isTrue);
        expect(cubit.isFavorite('event-other'), isFalse);
      },
    );

    test(
      'Given non-Loaded state, When calling isFavorite, Then it returns false',
      () {
        final cubit = GroupEventFavoritesCubit(mockRepo);
        expect(cubit.isFavorite('event-1'), isFalse);
      },
    );

    // ─── reset ────────────────────────────────────────────────────────────────

    blocTest<GroupEventFavoritesCubit, GroupEventFavoritesState>(
      'Given any state, When calling reset, Then emits Initial',
      build: () => GroupEventFavoritesCubit(mockRepo),
      seed: () => const GroupEventFavoritesLoaded(['event-1']),
      act: (cubit) => cubit.reset(),
      expect: () => [isA<GroupEventFavoritesInitial>()],
    );
  });
}
