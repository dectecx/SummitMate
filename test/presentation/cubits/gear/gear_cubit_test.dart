import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/models/gear_item.dart';
import 'package:summitmate/data/repositories/interfaces/i_gear_repository.dart';
import 'package:summitmate/presentation/cubits/gear/gear_cubit.dart';
import 'package:summitmate/presentation/cubits/gear/gear_state.dart';

class MockGearRepository extends Mock implements IGearRepository {}

class FakeGearItem extends Fake implements GearItem {}

void main() {
  group('GearCubit', () {
    late IGearRepository mockGearRepository;
    late GearCubit cubit;

    final testItem1 = GearItem(uuid: 'item_1', name: 'Tent', tripId: 'trip_1', weight: 2000, category: 'Sleep');
    final testItem2 = GearItem(uuid: 'item_2', name: 'Stove', tripId: 'trip_1', weight: 500, category: 'Cook');
    final otherTripItem = GearItem(uuid: 'item_3', name: 'Boots', tripId: 'trip_2', weight: 1000, category: 'Wear');

    setUpAll(() {
      registerFallbackValue(FakeGearItem());
    });

    setUp(() {
      mockGearRepository = MockGearRepository();
      cubit = GearCubit(repository: mockGearRepository);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is GearInitial', () {
      expect(cubit.state, const GearInitial());
    });

    blocTest<GearCubit, GearState>(
      'loadGear emits [GearLoading, GearLoaded] with filtered items',
      setUp: () {
        when(() => mockGearRepository.getAllItems()).thenReturn([testItem1, testItem2, otherTripItem]);
      },
      build: () => cubit,
      act: (cubit) => cubit.loadGear('trip_1'),
      expect: () => [
        const GearLoading(),
        isA<GearLoaded>().having((s) => s.items, 'items', [testItem1, testItem2]),
      ],
      verify: (_) {
        verify(() => mockGearRepository.getAllItems()).called(1);
      },
    );

    blocTest<GearCubit, GearState>(
      'addItem calls repository and reloads',
      setUp: () {
        when(() => mockGearRepository.addItem(any())).thenAnswer((_) async => 1);
        when(() => mockGearRepository.getAllItems()).thenReturn([testItem1]);
      },
      build: () => cubit,
      act: (cubit) async {
        await cubit.loadGear('trip_1'); // Pre-load
        await cubit.addItem(name: 'Tent', weight: 2000, category: 'Sleep');
      },
      expect: () => [const GearLoading(), isA<GearLoaded>()],
      verify: (_) {
        verify(() => mockGearRepository.addItem(any())).called(1);
        verify(() => mockGearRepository.getAllItems()).called(2);
      },
    );

    blocTest<GearCubit, GearState>(
      'filters work correctly',
      setUp: () {
        when(() => mockGearRepository.getAllItems()).thenReturn([testItem1, testItem2]);
      },
      build: () => cubit,
      act: (cubit) async {
        await cubit.loadGear('trip_1');
        cubit.selectCategory('Sleep');
        cubit.setSearchQuery('Tent');
      },
      expect: () => [
        const GearLoading(),
        isA<GearLoaded>(),
        isA<GearLoaded>().having((s) => s.selectedCategory, 'category', 'Sleep'),
        isA<GearLoaded>()
            .having((s) => s.selectedCategory, 'category', 'Sleep')
            .having((s) => s.searchQuery, 'query', 'Tent'),
      ],
    );

    blocTest<GearCubit, GearState>(
      'computed properties in state are correct',
      setUp: () {
        when(() => mockGearRepository.getAllItems()).thenReturn([testItem1, testItem2]);
      },
      build: () => cubit,
      act: (cubit) => cubit.loadGear('trip_1'),
      verify: (cubit) {
        final state = cubit.state as GearLoaded;
        expect(state.totalWeight, 2500);
        expect(state.itemsByCategory['Sleep']!.length, 1);
        expect(state.itemsByCategory['Cook']!.length, 1);
      },
    );
  });
}
