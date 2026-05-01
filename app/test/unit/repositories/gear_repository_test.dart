import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/datasources/interfaces/i_gear_local_data_source.dart';
import 'package:summitmate/data/models/gear_item_model.dart';
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

    testItem1 = const GearItem(id: 'item_1', tripId: 'trip_1', name: 'Tent', category: 'Shelter', weight: 2000, quantity: 1, orderIndex: 0);

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
    registerFallbackValue(GearItemModel.fromDomain(testItem1));
  });

  group('GearRepository', () {
    group('getAllItems', () {
      test('returns sorted items', () {
        // Arrange
        final item1 = testItem1.copyWith(orderIndex: 1);
        final item2 = testItem2.copyWith(orderIndex: 0);
        
        when(() => mockLocalDataSource.getAll()).thenReturn([
          GearItemModel.fromDomain(item1),
          GearItemModel.fromDomain(item2),
        ]);

        // Act
        final result = repository.getAllItems();

        // Assert
        expect(result.length, 2);
        expect(result[0].id, item2.id); // Should be first
        expect(result[1].id, item1.id);
      });

      test('handles fallback orderIndex sorting', () {
        final item1 = testItem1.copyWith(orderIndex: 999);
        final item2 = testItem2.copyWith(orderIndex: 0);
        
        when(() => mockLocalDataSource.getAll()).thenReturn([
          GearItemModel.fromDomain(item1),
          GearItemModel.fromDomain(item2),
        ]);

        final result = repository.getAllItems();

        expect(result[0].id, item2.id);
        expect(result[1].id, item1.id);
      });
    });

    group('addItem', () {
      test('calculates max orderIndex', () async {
        when(() => mockLocalDataSource.getAll()).thenReturn([GearItemModel.fromDomain(testItem2)]); // item2 has index 1
        when(() => mockLocalDataSource.add(any())).thenAnswer((_) async => 0); // returns key (int)

        const newItem = GearItem(id: 'new', tripId: 'trip_1', name: 'New', category: 'Misc', weight: 100);
        await repository.addItem(newItem);

        verify(() => mockLocalDataSource.getAll()).called(1);
        // Repository internally maps and increments orderIndex
        verify(() => mockLocalDataSource.add(any())).called(1);
      });

      test('delegates add call', () async {
        when(() => mockLocalDataSource.getAll()).thenReturn([]);
        when(() => mockLocalDataSource.add(any())).thenAnswer((_) async => 0);

        await repository.addItem(testItem1);
        verify(() => mockLocalDataSource.add(any())).called(1);
      });
    });

    test('getTotalWeight calculates correctly', () {
      when(() => mockLocalDataSource.getAll()).thenReturn([
        GearItemModel.fromDomain(testItem1),
        GearItemModel.fromDomain(testItem2),
      ]); // 2000 + 1000
      final result = repository.getAllItems();
      final total = result.fold<double>(0, (sum, item) => sum + (item.weight * item.quantity));
      expect(total, 3000.0);
    });

    test('resetAllChecked updates all items', () async {
      final item1 = testItem1.copyWith(isChecked: true);
      final item2 = testItem2.copyWith(isChecked: true);
      
      when(() => mockLocalDataSource.getAll()).thenReturn([
        GearItemModel.fromDomain(item1),
        GearItemModel.fromDomain(item2),
      ]);
      when(() => mockLocalDataSource.update(any())).thenAnswer((_) async {});

      await repository.resetAllChecked();

      verify(() => mockLocalDataSource.update(any())).called(2);
    });
  });
}
