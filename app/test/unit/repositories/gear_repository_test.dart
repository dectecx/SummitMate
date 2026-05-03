import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/datasources/interfaces/i_gear_local_data_source.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/data/repositories/gear_repository.dart';

// Mocks
class MockGearLocalDataSource extends Mock implements IGearLocalDataSource {}

void main() {
  late GearRepository repository;
  late MockGearLocalDataSource mockLocalDataSource;
  late GearItem testItem1;
  late GearItem testItem2;

  setUp(() {
    mockLocalDataSource = MockGearLocalDataSource();
    repository = GearRepository(mockLocalDataSource);

    testItem1 = const GearItem(
      id: 'item_1',
      tripId: 'trip_1',
      name: 'Tent',
      category: 'Shelter',
      weight: 2000,
      quantity: 1,
      orderIndex: 0,
    );

    testItem2 = const GearItem(
      id: 'item_2',
      tripId: 'trip_1',
      name: 'Sleeping Bag',
      category: 'Sleep',
      weight: 1000,
      quantity: 1,
      orderIndex: 1,
    );

    registerFallbackValue(testItem1);
  });

  group('GearRepository', () {
    group('getAllItems', () {
      test('returns sorted items', () async {
        // Arrange
        final item1 = testItem1.copyWith(orderIndex: 1);
        final item2 = testItem2.copyWith(orderIndex: 0);

        when(
          () => mockLocalDataSource.getAll(),
        ).thenAnswer((_) async => [item1, item2]);

        // Act
        final result = await repository.getAllItems();

        // Assert
        expect(result.length, 2);
        expect(result[0].id, item2.id); // Should be first
        expect(result[1].id, item1.id);
      });

      test('handles fallback orderIndex sorting', () async {
        final item1 = testItem1.copyWith(orderIndex: 999);
        final item2 = testItem2.copyWith(orderIndex: 0);

        when(
          () => mockLocalDataSource.getAll(),
        ).thenAnswer((_) async => [item1, item2]);

        final result = await repository.getAllItems();

        expect(result[0].id, item2.id);
        expect(result[1].id, item1.id);
      });
    });

    group('addItem', () {
      test('calculates max orderIndex', () async {
        when(() => mockLocalDataSource.getAll()).thenAnswer((_) async => [testItem2]); // item2 has index 1
        when(() => mockLocalDataSource.addItem(any())).thenAnswer((_) async => 0);

        const newItem = GearItem(id: 'new', tripId: 'trip_1', name: 'New', category: 'Misc', weight: 100);
        await repository.addItem(newItem);

        verify(() => mockLocalDataSource.getAll()).called(1);
        verify(() => mockLocalDataSource.addItem(any())).called(1);
      });

      test('delegates add call', () async {
        when(() => mockLocalDataSource.getAll()).thenAnswer((_) async => []);
        when(() => mockLocalDataSource.addItem(any())).thenAnswer((_) async => 0);

        await repository.addItem(testItem1);
        verify(() => mockLocalDataSource.addItem(any())).called(1);
      });
    });

    test('getTotalWeight calculates correctly', () async {
      when(
        () => mockLocalDataSource.getAll(),
      ).thenAnswer((_) async => [testItem1, testItem2]); // 2000 + 1000
      final result = await repository.getAllItems();
      final total = result.fold<double>(0, (sum, item) => sum + (item.weight * item.quantity));
      expect(total, 3000.0);
    });

    test('resetAllChecked updates all items', () async {
      final item1 = testItem1.copyWith(isChecked: true);
      final item2 = testItem2.copyWith(isChecked: true);

      when(
        () => mockLocalDataSource.getAll(),
      ).thenAnswer((_) async => [item1, item2]);
      when(() => mockLocalDataSource.updateItem(any())).thenAnswer((_) async => {});

      await repository.resetAllChecked();

      verify(() => mockLocalDataSource.updateItem(any())).called(2);
    });
  });
}
