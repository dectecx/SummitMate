import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/models/gear_item.dart';
import 'package:summitmate/data/models/gear_library_item.dart';
import 'package:summitmate/data/models/trip.dart';
import 'package:summitmate/data/repositories/interfaces/i_gear_library_repository.dart';
import 'package:summitmate/data/repositories/interfaces/i_gear_repository.dart';
import 'package:summitmate/data/repositories/interfaces/i_trip_repository.dart';
import 'package:summitmate/presentation/cubits/gear_library/gear_library_cubit.dart';
import 'package:summitmate/presentation/cubits/gear_library/gear_library_state.dart';

class MockGearLibraryRepository extends Mock implements IGearLibraryRepository {}

class MockGearRepository extends Mock implements IGearRepository {}

class MockTripRepository extends Mock implements ITripRepository {}

class FakeGearLibraryItem extends Fake implements GearLibraryItem {}

class FakeGearItem extends Fake implements GearItem {}

void main() {
  group('GearLibraryCubit', () {
    late IGearLibraryRepository mockRepo;
    late IGearRepository mockGearRepo;
    late ITripRepository mockTripRepo;
    late GearLibraryCubit cubit;

    final libItem1 = GearLibraryItem(uuid: 'lib1', name: 'Tent', weight: 2000, category: 'Sleep');
    final libItem2 = GearLibraryItem(uuid: 'lib2', name: 'Stove', weight: 500, category: 'Cook');

    setUpAll(() {
      registerFallbackValue(FakeGearLibraryItem());
      registerFallbackValue(FakeGearItem());
    });

    setUp(() {
      mockRepo = MockGearLibraryRepository();
      mockGearRepo = MockGearRepository();
      mockTripRepo = MockTripRepository();

      cubit = GearLibraryCubit(repository: mockRepo, gearRepository: mockGearRepo, tripRepository: mockTripRepo);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is GearLibraryInitial', () {
      expect(cubit.state, const GearLibraryInitial());
    });

    blocTest<GearLibraryCubit, GearLibraryState>(
      'loadItems emits [GearLibraryLoading, GearLibraryLoaded]',
      setUp: () {
        when(() => mockRepo.getAllItems()).thenReturn([libItem1, libItem2]);
      },
      build: () => cubit,
      act: (cubit) => cubit.loadItems(),
      expect: () => [
        const GearLibraryLoading(),
        isA<GearLibraryLoaded>().having((s) => s.items, 'items', [libItem1, libItem2]),
      ],
    );

    blocTest<GearLibraryCubit, GearLibraryState>(
      'addItem calls repository and reloads',
      setUp: () {
        when(() => mockRepo.addItem(any())).thenAnswer((_) async {});
        when(() => mockRepo.getAllItems()).thenReturn([libItem1]);
      },
      build: () => cubit,
      act: (cubit) => cubit.addItem(name: 'Tent', weight: 2000, category: 'Sleep'),
      expect: () => [isA<GearLibraryLoaded>()],
      verify: (_) {
        verify(() => mockRepo.addItem(any())).called(1);
        verify(() => mockRepo.getAllItems()).called(1); // reload
      },
    );

    blocTest<GearLibraryCubit, GearLibraryState>(
      'updateItem calls repository and syncs linked gear',
      setUp: () {
        when(() => mockRepo.updateItem(any())).thenAnswer((_) async {});
        when(() => mockRepo.getAllItems()).thenReturn([libItem1]);

        // Mock sync logic
        final linkedGear = GearItem(uuid: 'g1', name: 'OldName', libraryItemId: 'lib1', tripId: 't1');
        when(() => mockGearRepo.getAllItems()).thenReturn([linkedGear]);
        when(
          () => mockTripRepo.getTripById('t1'),
        ).thenReturn(Trip(id: 't1', name: 'T1', startDate: DateTime.now(), isActive: true, createdAt: DateTime.now()));
        when(() => mockGearRepo.updateItem(any())).thenAnswer((_) async {});
      },
      build: () => cubit,
      act: (cubit) => cubit.updateItem(libItem1),
      expect: () => [isA<GearLibraryLoaded>()],
      verify: (_) {
        verify(() => mockRepo.updateItem(libItem1)).called(1);
        verify(() => mockGearRepo.updateItem(any())).called(1); // Should update linked gear
      },
    );
  });
}
