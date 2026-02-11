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
import 'package:summitmate/domain/interfaces/i_auth_service.dart';
import 'package:summitmate/core/error/result.dart';

class MockGearLibraryRepository extends Mock implements IGearLibraryRepository {}

class MockGearRepository extends Mock implements IGearRepository {}

class MockTripRepository extends Mock implements ITripRepository {}

class MockAuthService extends Mock implements IAuthService {}

class FakeGearLibraryItem extends Fake implements GearLibraryItem {}

class FakeGearItem extends Fake implements GearItem {}

class FakeTrip extends Fake implements Trip {}

void main() {
  group('GearLibraryCubit', () {
    late IGearLibraryRepository mockRepo;
    late IGearRepository mockGearRepo;
    late ITripRepository mockTripRepo;
    late IAuthService mockAuthService;
    late GearLibraryCubit cubit;

    final libItem1 = GearLibraryItem(
      id: 'lib1',
      userId: 'u1',
      name: 'Tent',
      weight: 2000,
      category: 'Sleep',
      createdAt: DateTime.now(),
      createdBy: 'u1',
      updatedAt: DateTime.now(),
      updatedBy: 'u1',
    );
    final libItem2 = GearLibraryItem(
      id: 'lib2',
      userId: 'u1',
      name: 'Stove',
      weight: 500,
      category: 'Cook',
      createdAt: DateTime.now(),
      createdBy: 'u1',
      updatedAt: DateTime.now(),
      updatedBy: 'u1',
    );

    setUpAll(() {
      registerFallbackValue(FakeGearLibraryItem());
      registerFallbackValue(FakeGearItem());
      registerFallbackValue(FakeTrip());
    });

    setUp(() {
      mockRepo = MockGearLibraryRepository();
      mockGearRepo = MockGearRepository();
      mockAuthService = MockAuthService();
      mockTripRepo = MockTripRepository();

      when(() => mockAuthService.currentUserId).thenReturn('u1');
      when(() => mockAuthService.currentUserEmail).thenReturn('u1@test.com');

      cubit = GearLibraryCubit(
        repository: mockRepo,
        gearRepository: mockGearRepo,
        tripRepository: mockTripRepo,
        authService: mockAuthService,
      );
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
        when(() => mockRepo.getAll(any())).thenReturn([libItem1, libItem2]);
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
        when(() => mockRepo.add(any())).thenAnswer((_) async {});
        when(() => mockRepo.getAll(any())).thenReturn([libItem1]);
      },
      build: () => cubit,
      act: (cubit) => cubit.addItem(name: 'Tent', weight: 2000, category: 'Sleep'),
      expect: () => [isA<GearLibraryLoaded>()],
      verify: (_) {
        verify(() => mockRepo.add(any())).called(1);
        verify(() => mockRepo.getAll(any())).called(1); // reload
      },
    );

    blocTest<GearLibraryCubit, GearLibraryState>(
      'updateItem calls repository and syncs linked gear',
      setUp: () {
        when(() => mockRepo.update(any())).thenAnswer((_) async {});
        when(() => mockRepo.getAll(any())).thenReturn([libItem1]);

        // Mock sync logic
        final linkedGear = GearItem(uuid: 'g1', name: 'OldName', libraryItemId: 'lib1', tripId: 't1');
        when(() => mockGearRepo.getAllItems()).thenReturn([linkedGear]);
        when(() => mockTripRepo.getTripById('t1')).thenAnswer(
          (_) async => Success(
            Trip(
              id: 't1',
              userId: 'u1',
              name: 'T1',
              startDate: DateTime.now(),
              isActive: true,
              createdAt: DateTime.now(),
              createdBy: 'u1',
              updatedAt: DateTime.now(),
              updatedBy: 'u1',
            ),
          ),
        );
        when(() => mockGearRepo.updateItem(any())).thenAnswer((_) async {});
      },
      build: () => cubit,
      act: (cubit) => cubit.updateItem(libItem1),
      expect: () => [isA<GearLibraryLoaded>()],
      verify: (_) {
        verify(() => mockRepo.update(libItem1)).called(1);
        verify(() => mockGearRepo.updateItem(any())).called(1); // Should update linked gear
      },
    );
  });
}
