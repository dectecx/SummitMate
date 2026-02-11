import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/models/gear_item.dart';
import 'package:summitmate/data/repositories/interfaces/i_gear_repository.dart';
import 'package:summitmate/presentation/cubits/gear/gear_cubit.dart';
import 'package:summitmate/presentation/cubits/gear/gear_state.dart';
import 'package:get_it/get_it.dart';

class MockGearRepository extends Mock implements IGearRepository {}

void main() {
  late MockGearRepository mockGearRepository;

  setUp(() {
    mockGearRepository = MockGearRepository();
    GetIt.I.reset();
    GetIt.I.registerSingleton<IGearRepository>(mockGearRepository);

    // Fallback registration
    registerFallbackValue(GearItem(uuid: 'fallback', tripId: 'fallback', name: 'fallback'));
  });

  group('GearCubit', () {
    final gearItem1 = GearItem(uuid: 'item1', tripId: 'trip1', name: 'Tent', weight: 2000, category: 'Sleep');

    final gearItem2 = GearItem(uuid: 'item2', tripId: 'trip2', name: 'Stove', weight: 500, category: 'Cook');

    test('initial state is GearInitial', () {
      expect(GearCubit(repository: mockGearRepository).state, const GearInitial());
    });

    blocTest<GearCubit, GearState>(
      'loadGear emits [GearLoading, GearLoaded] with filtered items',
      build: () {
        when(() => mockGearRepository.getAllItems()).thenReturn([gearItem1, gearItem2]);
        return GearCubit(repository: mockGearRepository);
      },
      act: (cubit) => cubit.loadGear('trip1'),
      expect: () => [
        const GearLoading(),
        isA<GearLoaded>()
            .having((state) => state.items.length, 'items count', 1)
            .having((state) => state.items.first.name, 'item name', 'Tent'),
      ],
    );

    blocTest<GearCubit, GearState>(
      'addItem calls repo and reloads',
      build: () {
        // First call (loadGear) -> empty
        // Second call (reload after add) -> [gearItem1]
        when(() => mockGearRepository.getAllItems()).thenReturn([]);
        // Note: mocktail returns last value for subsequent calls, so we need to be careful.
        // Actually usually it's .thenReturn(A).thenReturn(B).
        // However, blocTest build runs ONCE.
        // Let's use a side effect if needed or just return the final state as loadGear also reads it.
        // If loadGear reads [gearItem1], then state is already [gearItem1].
        // Then addItem runs, reload reads [gearItem1], state is [gearItem1].
        // The transition is: Loading -> Loaded([gearItem1]) -> Loaded([gearItem1]) (no change?)
        // If state is distinct, strict equality might filter it out? Equatable props items are same list instance?
        // Let's force a change.

        var callCount = 0;
        when(() => mockGearRepository.getAllItems()).thenAnswer((_) {
          if (callCount == 0) {
            callCount++;
            return [];
          }
          return [gearItem1];
        });

        when(() => mockGearRepository.addItem(any())).thenAnswer((_) async => 1);
        return GearCubit(repository: mockGearRepository);
      },
      act: (cubit) async {
        await cubit.loadGear('trip1');
        await cubit.addItem(name: 'New Item', weight: 100, category: 'Other');
      },
      expect: () => [
        const GearLoading(),
        isA<GearLoaded>().having((s) => s.items.isEmpty, 'empty first', true),
        isA<GearLoaded>().having((s) => s.items.length, 'items count', 1),
      ],
      verify: (_) {
        verify(() => mockGearRepository.addItem(any())).called(1);
      },
    );

    blocTest<GearCubit, GearState>(
      'deleteItem calls repo and reloads',
      build: () {
        // 1. loadGear -> [gearItem1]
        // 2. reload -> []
        var callCount = 0;
        when(() => mockGearRepository.getAllItems()).thenAnswer((_) {
          if (callCount == 0) {
            callCount++;
            return [gearItem1];
          }
          return [];
        });
        when(() => mockGearRepository.deleteItem(any())).thenAnswer((_) async {});
        return GearCubit(repository: mockGearRepository);
      },
      act: (cubit) async {
        await cubit.loadGear('trip1');
        await cubit.deleteItem('item1');
      },
      expect: () => [
        const GearLoading(),
        isA<GearLoaded>().having((state) => state.items.isNotEmpty, 'items not empty', true),
        isA<GearLoaded>().having((state) => state.items.isEmpty, 'items empty', true),
      ],
      verify: (_) {
        verify(() => mockGearRepository.deleteItem('item1')).called(1);
      },
    );

    blocTest<GearCubit, GearState>(
      'toggleChecked calls repo and reloads',
      build: () {
        final uncheckedItem = GearItem(uuid: 'item1', tripId: 'trip1', name: 'Tent', isChecked: false);
        final checkedItem = GearItem(uuid: 'item1', tripId: 'trip1', name: 'Tent', isChecked: true);

        var callCount = 0;
        when(() => mockGearRepository.getAllItems()).thenAnswer((_) {
          if (callCount == 0) {
            callCount++;
            return [uncheckedItem];
          }
          return [checkedItem];
        });
        when(() => mockGearRepository.toggleChecked(any())).thenAnswer((_) async {});
        return GearCubit(repository: mockGearRepository);
      },
      act: (cubit) async {
        await cubit.loadGear('trip1');
        await cubit.toggleChecked('item1');
      },
      expect: () => [
        const GearLoading(),
        isA<GearLoaded>().having((state) => state.items.first.isChecked, 'isChecked false', false),
        isA<GearLoaded>().having((state) => state.items.first.isChecked, 'isChecked true', true),
      ],
      verify: (_) {
        verify(() => mockGearRepository.toggleChecked('item1')).called(1);
      },
    );

    test('loadGear emits GearError on failure', () async {
      when(() => mockGearRepository.getAllItems()).thenThrow(Exception('DB Error'));

      final cubit = GearCubit(repository: mockGearRepository);

      expectLater(
        cubit.stream,
        emitsInOrder([const GearLoading(), isA<GearError>().having((e) => e.message, 'message', contains('DB Error'))]),
      );

      await cubit.loadGear('trip1');
    });

    test('addItem fails gracefully', () async {
      when(() => mockGearRepository.addItem(any())).thenThrow(Exception('Add Failed'));
      when(() => mockGearRepository.getAllItems()).thenReturn([]);

      final cubit = GearCubit(repository: mockGearRepository);
      await cubit.loadGear('trip1'); // Prepare tripId

      expectLater(cubit.stream, emits(isA<GearError>().having((e) => e.message, 'message', contains('Add Failed'))));

      await cubit.addItem(name: 'Fail', weight: 0, category: 'Other');
    });
  });
}
