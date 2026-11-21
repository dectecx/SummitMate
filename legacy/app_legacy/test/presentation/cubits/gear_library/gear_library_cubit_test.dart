import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/presentation/cubits/gear_library/gear_library_cubit.dart';
import 'package:summitmate/presentation/cubits/gear_library/gear_library_state.dart';

class MockGearLibraryRepository extends Mock implements IGearLibraryRepository {}

class MockGearRepository extends Mock implements IGearRepository {}

class MockTripRepository extends Mock implements ITripRepository {}

class MockAuthService extends Mock implements IAuthService {}

class MockGearLibrarySyncService extends Mock implements IGearLibrarySyncService {}

class FakeGearLibraryItem extends Fake implements GearLibraryItem {}

class FakeGearItem extends Fake implements GearItem {}

class FakeTrip extends Fake implements Trip {}

void main() {
  group('GearLibraryCubit', () {
    late IGearLibraryRepository mockRepo;
    late IGearRepository mockGearRepo;
    late MockAuthService mockAuthService;
    late MockGearLibrarySyncService mockSyncService;
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
      mockSyncService = MockGearLibrarySyncService();

      when(() => mockAuthService.currentUserId).thenReturn('u1');
      when(() => mockAuthService.currentUserEmail).thenReturn('u1@test.com');

      cubit = GearLibraryCubit(mockRepo, mockGearRepo, mockAuthService, mockSyncService);
    });

    tearDown(() {
      cubit.close();
    });

    test('Given GearLibraryCubit, When executing, Then initial state is GearLibraryInitial', () {
      expect(cubit.state, isA<GearLibraryInitial>());
    });

    blocTest<GearLibraryCubit, GearLibraryState>(
      'loadItems emits [GearLibraryLoading, GearLibraryLoaded]',
      setUp: () {
        when(() => mockRepo.getAll(any())).thenAnswer((_) async => [libItem1, libItem2]);
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
        when(() => mockRepo.getAll(any())).thenAnswer((_) async => [libItem1]);
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
        when(() => mockRepo.getAll(any())).thenAnswer((_) async => [libItem1]);

        // Mock sync logic
        when(() => mockSyncService.syncLinkedGear(any())).thenAnswer((_) async {});
      },
      build: () => cubit,
      act: (cubit) => cubit.updateItem(libItem1),
      expect: () => [isA<GearLibraryLoaded>()],
      verify: (_) {
        verify(() => mockRepo.update(any())).called(1);
        verify(() => mockSyncService.syncLinkedGear(any())).called(1); // Should update linked gear
      },
    );
  });
}
