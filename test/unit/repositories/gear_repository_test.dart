import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/datasources/interfaces/i_gear_local_data_source.dart';
import 'package:summitmate/data/models/gear_item.dart';
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
    repository = GearRepository(localDataSource: mockLocalDataSource);

    testItem1 = GearItem(uuid: 'item_1', name: 'Tent', category: 'Shelter', weight: 2000, quantity: 1, orderIndex: 0);

    testItem2 = GearItem(
      uuid: 'item_2',
      name: 'Sleeping Bag',
      category: 'Sleep',
      weight: 1000,
      quantity: 1,
      orderIndex: 1,
    );

    registerFallbackValue(testItem1);
  });

  group('GearRepository', () {
    test('init delegates to localDataSource', () async {
      when(() => mockLocalDataSource.init()).thenAnswer((_) async {});
      await repository.init();
      verify(() => mockLocalDataSource.init()).called(1);
    });

    group('getAllItems', () {
      test('returns sorted items', () {
        // Arrange: return unsorted list (by index)
        testItem1.orderIndex = 1;
        testItem2.orderIndex = 0;
        when(() => mockLocalDataSource.getAll()).thenReturn([testItem1, testItem2]);

        // Act
        final result = repository.getAllItems();

        // Assert
        expect(result.length, 2);
        expect(result[0].uuid, testItem2.uuid); // Should be first
        expect(result[1].uuid, testItem1.uuid);
      });

      test('handles null orderIndex sorting (pushes to end)', () {
        testItem1.orderIndex = null;
        testItem2.orderIndex = 0;
        when(() => mockLocalDataSource.getAll()).thenReturn([testItem1, testItem2]);

        final result = repository.getAllItems();

        expect(result[0].uuid, testItem2.uuid);
        expect(result[1].uuid, testItem1.uuid);
      });
    });

    group('addItem', () {
      test('calculates max orderIndex', () async {
        when(() => mockLocalDataSource.getAll()).thenReturn([testItem2]); // item2 has index 1
        when(() => mockLocalDataSource.add(any())).thenAnswer((_) async => 0); // returns key (int)

        final newItem = GearItem(uuid: 'new', name: 'New', category: 'Misc', weight: 100);
        await repository.addItem(newItem);

        verify(() => mockLocalDataSource.getAll()).called(1);
        expect(newItem.orderIndex, 2); // 1 + 1
        verify(() => mockLocalDataSource.add(newItem)).called(1);
      });

      test('delegates add call', () async {
        when(() => mockLocalDataSource.getAll()).thenReturn([]);
        when(() => mockLocalDataSource.add(any())).thenAnswer((_) async => 0);

        await repository.addItem(testItem1);
        verify(() => mockLocalDataSource.add(testItem1)).called(1);
      });
    });

    test('getTotalWeight calculates correctly', () {
      when(() => mockLocalDataSource.getAll()).thenReturn([testItem1, testItem2]); // 2000 + 1000
      final result = repository.getTotalWeight();
      expect(result, 3000.0);
    });

    test('getCheckedWeight calculates correctly', () {
      testItem1.isChecked = true; // 2000
      testItem2.isChecked = false; // 1000
      when(() => mockLocalDataSource.getAll()).thenReturn([testItem1, testItem2]);

      final result = repository.getCheckedWeight();
      expect(result, 2000.0);
    });

    test('resetAllChecked updates all items', () async {
      testItem1.isChecked = true;
      testItem2.isChecked = true;
      when(() => mockLocalDataSource.getAll()).thenReturn([testItem1, testItem2]);
      when(() => mockLocalDataSource.update(any())).thenAnswer((_) async {});

      await repository.resetAllChecked();

      expect(testItem1.isChecked, false);
      expect(testItem2.isChecked, false);
      verify(() => mockLocalDataSource.update(any())).called(2);
    });
  });
}
