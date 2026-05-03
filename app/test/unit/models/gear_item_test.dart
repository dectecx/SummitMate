import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/domain/domain.dart';

void main() {
  group('GearItem Domain Entity Tests', () {
    test('should create with required values', () {
      const item = GearItem(id: '1', tripId: 't1', name: 'Tent', weight: 2000, category: 'Sleep');

      expect(item.name, equals('Tent'));
      expect(item.weight, equals(2000));
      expect(item.category, equals('Sleep'));
      expect(item.isChecked, isFalse); // Default value
    });

    test('should handle copyWith', () {
      const item = GearItem(id: '1', tripId: 't1', name: 'Tent', weight: 2000, category: 'Sleep');

      final updatedItem = item.copyWith(isChecked: true);
      expect(updatedItem.isChecked, isTrue);
      expect(updatedItem.name, equals('Tent'));
    });

    test('should calculate totalWeight correctly', () {
      const item = GearItem(id: '1', tripId: 't1', name: 'Tent', weight: 2000, category: 'Sleep', quantity: 2);

      expect(item.totalWeight, equals(4000));
    });

    test('should calculate weightInKg correctly', () {
      const item = GearItem(id: '1', tripId: 't1', name: 'Tent', weight: 1500, category: 'Sleep');

      expect(item.weightInKg, equals(1.5));
    });

    test('should convert to/from JSON', () {
      // Note: This requires the generated code to be present
      final item = GearItem(
        id: '1',
        tripId: 't1',
        name: 'Tent',
        weight: 1200,
        category: 'Sleep',
        isChecked: true,
        createdAt: DateTime(2023, 1, 1),
      );

      final json = item.toJson();
      final restored = GearItem.fromJson(json);

      expect(restored.name, equals(item.name));
      expect(restored.weight, equals(item.weight));
      expect(restored.category, equals(item.category));
      expect(restored.isChecked, equals(item.isChecked));
    });
  });
}
