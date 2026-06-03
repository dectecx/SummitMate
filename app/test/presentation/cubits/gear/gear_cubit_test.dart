import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/domain/domain.dart';

import 'package:summitmate/presentation/cubits/gear/gear_cubit.dart';
import 'package:summitmate/presentation/cubits/gear/gear_state.dart';
import 'package:summitmate/core/error/result.dart';
import 'package:get_it/get_it.dart';

class MockGearRepository extends Mock implements IGearRepository {}

class MockTripRepository extends Mock implements ITripRepository {}

void main() {
  late MockGearRepository mockGearRepository;
  late MockTripRepository mockTripRepository;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Fallback registration
    registerFallbackValue(
      const GearItem(id: 'fallback', tripId: 'fallback', name: 'fallback', weight: 0, category: 'Other'),
    );
  });

  setUp(() {
    mockGearRepository = MockGearRepository();
    mockTripRepository = MockTripRepository();

    when(() => mockTripRepository.markTripAsPendingUpdate(any())).thenAnswer((_) async => const Success(null));

    GetIt.I.reset();
    GetIt.I.registerSingleton<IGearRepository>(mockGearRepository);
    GetIt.I.registerSingleton<ITripRepository>(mockTripRepository);
  });

  group('GearCubit', () {
    final gearItem1 = GearItem(id: 'item1', tripId: 'trip1', name: 'Tent', weight: 2000, category: 'Sleep');

    final gearItem2 = GearItem(id: 'item2', tripId: 'trip2', name: 'Stove', weight: 500, category: 'Cook');

    test('initial state is GearInitial', () {
      expect(GearCubit(mockGearRepository, mockTripRepository).state, const GearInitial());
    });

    blocTest<GearCubit, GearState>(
      'loadGear emits [GearLoading, GearLoaded] with filtered items',
      build: () {
        when(() => mockGearRepository.getAllItems()).thenAnswer((_) async => [gearItem1, gearItem2]);
        return GearCubit(mockGearRepository, mockTripRepository);
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
        var callCount = 0;
        when(() => mockGearRepository.getAllItems()).thenAnswer((_) async {
          if (callCount == 0) {
            callCount++;
            return [];
          }
          return [gearItem1];
        });

        when(() => mockGearRepository.addItem(any())).thenAnswer((_) async => const Success(null));
        return GearCubit(mockGearRepository, mockTripRepository);
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
        final captured = verify(() => mockGearRepository.addItem(captureAny())).captured;
        final item = captured.first as GearItem;
        expect(item.id[14], '7', reason: 'UUID must be version 7');
      },
    );

    blocTest<GearCubit, GearState>(
      'deleteItem calls repo and reloads',
      build: () {
        var callCount = 0;
        when(() => mockGearRepository.getAllItems()).thenAnswer((_) async {
          if (callCount == 0) {
            callCount++;
            return [gearItem1];
          }
          return [];
        });
        when(() => mockGearRepository.deleteItem(any())).thenAnswer((_) async => const Success(null));
        return GearCubit(mockGearRepository, mockTripRepository);
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
        const uncheckedItem = GearItem(
          id: 'item1',
          tripId: 'trip1',
          name: 'Tent',
          isChecked: false,
          weight: 1000,
          category: 'Sleep',
        );
        const checkedItem = GearItem(
          id: 'item1',
          tripId: 'trip1',
          name: 'Tent',
          isChecked: true,
          weight: 1000,
          category: 'Sleep',
        );

        var callCount = 0;
        when(() => mockGearRepository.getAllItems()).thenAnswer((_) async {
          if (callCount == 0) {
            callCount++;
            return [uncheckedItem];
          }
          return [checkedItem];
        });
        when(() => mockGearRepository.toggleChecked(any())).thenAnswer((_) async => const Success(null));
        return GearCubit(mockGearRepository, mockTripRepository);
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

      final cubit = GearCubit(mockGearRepository, mockTripRepository);

      expectLater(
        cubit.stream,
        emitsInOrder([const GearLoading(), isA<GearError>().having((e) => e.message, 'message', contains('DB Error'))]),
      );

      await cubit.loadGear('trip1');
    });

    test('addItem fails gracefully', () async {
      when(() => mockGearRepository.addItem(any())).thenAnswer((_) async => Failure(Exception('Add Failed')));
      when(() => mockGearRepository.getAllItems()).thenAnswer((_) async => []);

      final cubit = GearCubit(mockGearRepository, mockTripRepository);
      await cubit.loadGear('trip1'); // Prepare tripId

      expectLater(cubit.stream, emits(isA<GearError>().having((e) => e.message, 'message', contains('Add Failed'))));

      await cubit.addItem(name: 'Fail', weight: 0, category: 'Other');
    });
  });
}
