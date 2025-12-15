import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/data/models/gear_item.dart';

void main() {
  group('GearItem Model Tests', () {
    test('should create with default values', () {
      final item = GearItem();

      expect(item.name, isEmpty);
      expect(item.weight, equals(0));
      expect(item.category, isEmpty);
      expect(item.isChecked, isFalse);
    });

    test('should create with named parameters', () {
      final item = GearItem(
        name: '睡袋',
        weight: 1200,
        category: 'Sleep',
        isChecked: false,
      );

      expect(item.name, equals('睡袋'));
      expect(item.weight, equals(1200));
      expect(item.category, equals('Sleep'));
      expect(item.isChecked, isFalse);
    });

    test('should toggle isChecked', () {
      final item = GearItem(isChecked: false);

      item.isChecked = true;
      expect(item.isChecked, isTrue);

      item.isChecked = false;
      expect(item.isChecked, isFalse);
    });

    test('should calculate weightInKg correctly', () {
      final item = GearItem(weight: 1500);

      expect(item.weightInKg, equals(1.5));
    });

    test('should validate category values', () {
      final validCategories = ['Sleep', 'Cook', 'Wear', 'Other'];

      for (final cat in validCategories) {
        final item = GearItem(category: cat);
        expect(validCategories.contains(item.category), isTrue);
      }
    });

    test('should calculate total weight for multiple items', () {
      final items = [
        GearItem(weight: 1200),
        GearItem(weight: 800),
        GearItem(weight: 500),
      ];

      final total = items.fold<double>(0, (sum, item) => sum + item.weight);
      expect(total, equals(2500));
    });

    test('should convert to/from JSON', () {
      final item = GearItem(
        name: '睡袋',
        weight: 1200,
        category: 'Sleep',
        isChecked: true,
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
