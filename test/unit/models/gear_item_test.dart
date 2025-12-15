import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/data/models/gear_item.dart';

void main() {
  group('GearItem Model Tests', () {
    test('should create gear item with required fields', () {
      final item = GearItem()
        ..name = '羽絨睡袋'
        ..weight = 800
        ..category = 'Sleep'
        ..isChecked = false;

      expect(item.name, '羽絨睡袋');
      expect(item.weight, 800);
      expect(item.category, 'Sleep');
      expect(item.isChecked, isFalse);
    });

    test('should toggle isChecked state', () {
      final item = GearItem()
        ..name = '睡墊'
        ..weight = 400
        ..category = 'Sleep'
        ..isChecked = false;

      item.isChecked = true;

      expect(item.isChecked, isTrue);
    });

    test('should validate category values', () {
      final validCategories = ['Sleep', 'Cook', 'Wear', 'Other'];

      final item = GearItem()
        ..name = '測試裝備'
        ..weight = 100
        ..category = 'Sleep'
        ..isChecked = false;

      expect(validCategories.contains(item.category), isTrue);

      item.category = 'InvalidCategory';
      expect(validCategories.contains(item.category), isFalse);
    });

    test('should handle decimal weights', () {
      final item = GearItem()
        ..name = '鈦杯'
        ..weight = 150.5
        ..category = 'Cook'
        ..isChecked = false;

      expect(item.weight, 150.5);
    });

    test('should calculate weight in kg', () {
      final item = GearItem()
        ..name = '大背包'
        ..weight = 1500
        ..category = 'Other'
        ..isChecked = false;

      // weight 是 grams，除以 1000 得到 kg
      expect(item.weight / 1000, 1.5);
    });

    test('should support all gear categories', () {
      final categories = ['Sleep', 'Cook', 'Wear', 'Other'];

      for (final cat in categories) {
        final item = GearItem()
          ..name = 'Test Item'
          ..weight = 100
          ..category = cat
          ..isChecked = false;

        expect(item.category, cat);
      }
    });
  });
}
