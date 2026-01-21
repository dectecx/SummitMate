import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/core/constants.dart';
import 'package:summitmate/core/gear_helpers.dart';

void main() {
  group('GearCategoryHelper Tests', () {
    test('allCategories constant contains expected values', () {
      expect(
        GearCategory.all,
        containsAll([GearCategory.sleep, GearCategory.cook, GearCategory.wear, GearCategory.other]),
      );
      expect(GearCategory.all.length, 4);
    });

    test('getIcon returns correct icon for each category', () {
      expect(GearCategoryHelper.getIcon(GearCategory.sleep), Icons.bed);
      expect(GearCategoryHelper.getIcon(GearCategory.cook), Icons.restaurant);
      expect(GearCategoryHelper.getIcon(GearCategory.wear), Icons.checkroom);
      expect(GearCategoryHelper.getIcon(GearCategory.other), Icons.category);
      expect(GearCategoryHelper.getIcon('Unknown'), Icons.inventory_2);
    });

    test('getName returns correct name for each category', () {
      expect(GearCategoryHelper.getName(GearCategory.sleep), '睡眠系統');
      expect(GearCategoryHelper.getName(GearCategory.cook), '炊具與飲食');
      expect(GearCategoryHelper.getName(GearCategory.wear), '穿著');
      expect(GearCategoryHelper.getName(GearCategory.other), '其他');
      expect(GearCategoryHelper.getName('Unknown'), 'Unknown');
    });

    test('getColor returns correct color for each category', () {
      expect(GearCategoryHelper.getColor(GearCategory.sleep), Colors.indigo);
      expect(GearCategoryHelper.getColor(GearCategory.cook), Colors.orange);
      expect(GearCategoryHelper.getColor(GearCategory.wear), Colors.teal);
      expect(GearCategoryHelper.getColor(GearCategory.other), Colors.grey);
      expect(GearCategoryHelper.getColor('Unknown'), Colors.grey);
    });

    test('compareCategories sorts categories correctly', () {
      final categories = [GearCategory.other, GearCategory.sleep, GearCategory.wear, GearCategory.cook];

      categories.sort(GearCategoryHelper.compareCategories);

      expect(categories, [GearCategory.sleep, GearCategory.cook, GearCategory.wear, GearCategory.other]);
    });
  });

  group('WeightFormatter Tests', () {
    test('format returns grams for weight < 1000', () {
      expect(WeightFormatter.format(500), '500 g');
      expect(WeightFormatter.format(999), '999 g');
      expect(WeightFormatter.format(0), '0 g');
    });

    test('format returns kg for weight >= 1000', () {
      expect(WeightFormatter.format(1000), '1.0 kg');
      expect(WeightFormatter.format(1500), '1.5 kg');
      expect(WeightFormatter.format(2000), '2.0 kg');
    });

    test('format respects decimals parameter', () {
      expect(WeightFormatter.format(1234, decimals: 2), '1.23 kg');
      expect(WeightFormatter.format(1234, decimals: 0), '1 kg');
    });

    test('formatPrecise returns correct format', () {
      expect(WeightFormatter.formatPrecise(500), '500 g');
      expect(WeightFormatter.formatPrecise(1550), '1.55 kg');
    });
  });
}
