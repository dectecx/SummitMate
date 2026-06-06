import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/core/constants.dart';
import 'package:summitmate/presentation/utils/gear_utils.dart';
import 'package:mocktail/mocktail.dart';

class MockBuildContext extends Mock implements BuildContext {}

void main() {
  final mockContext = MockBuildContext();

  group('GearCategoryHelper Tests', () {
    test('Given GearCategoryHelper Tests, When executing, Then allCategories constant contains expected values', () {
      expect(
        GearCategory.all,
        containsAll([GearCategory.sleep, GearCategory.cook, GearCategory.wear, GearCategory.other]),
      );
      expect(GearCategory.all.length, 4);
    });

    test('Given each category, When calling GearCategoryHelper Tests, Then getIcon returns correct icon', () {
      expect(GearCategoryHelper.getIcon(GearCategory.sleep), Icons.bed);
      expect(GearCategoryHelper.getIcon(GearCategory.cook), Icons.restaurant);
      expect(GearCategoryHelper.getIcon(GearCategory.wear), Icons.checkroom);
      expect(GearCategoryHelper.getIcon(GearCategory.other), Icons.category);
      expect(GearCategoryHelper.getIcon('Unknown'), Icons.inventory_2);
    });

    test('Given each category, When calling GearCategoryHelper Tests, Then getName returns correct name', () {
      expect(GearCategoryHelper.getName(GearCategory.sleep), '睡眠系統');
      expect(GearCategoryHelper.getName(GearCategory.cook), '炊具與飲食');
      expect(GearCategoryHelper.getName(GearCategory.wear), '穿著');
      expect(GearCategoryHelper.getName(GearCategory.other), '其他');
      expect(GearCategoryHelper.getName('Unknown'), 'Unknown');
    });

    test('Given each category, When calling GearCategoryHelper Tests, Then getColor returns correct color', () {
      expect(GearCategoryHelper.getColor(GearCategory.sleep, mockContext), Colors.indigo);
      expect(GearCategoryHelper.getColor(GearCategory.cook, mockContext), Colors.orange);
      expect(GearCategoryHelper.getColor(GearCategory.wear, mockContext), Colors.teal);
      expect(GearCategoryHelper.getColor(GearCategory.other, mockContext), Colors.grey);
      expect(GearCategoryHelper.getColor('Unknown', mockContext), Colors.grey);
    });

    test('Given GearCategoryHelper Tests, When executing, Then compareCategories sorts categories correctly', () {
      final categories = [GearCategory.other, GearCategory.sleep, GearCategory.wear, GearCategory.cook];

      categories.sort(GearCategoryHelper.compareCategories);

      expect(categories, [GearCategory.sleep, GearCategory.cook, GearCategory.wear, GearCategory.other]);
    });
  });

  group('WeightFormatter Tests', () {
    test('Given weight < 1000, When calling WeightFormatter Tests, Then format returns grams', () {
      expect(WeightFormatter.format(500), '500 g');
      expect(WeightFormatter.format(999), '999 g');
      expect(WeightFormatter.format(0), '0 g');
    });

    test('Given weight >= 1000, When calling WeightFormatter Tests, Then format returns kg', () {
      expect(WeightFormatter.format(1000), '1.0 kg');
      expect(WeightFormatter.format(1500), '1.5 kg');
      expect(WeightFormatter.format(2000), '2.0 kg');
    });

    test('Given WeightFormatter Tests, When executing, Then format respects decimals parameter', () {
      expect(WeightFormatter.format(1234, decimals: 2), '1.23 kg');
      expect(WeightFormatter.format(1234, decimals: 0), '1 kg');
    });

    test('Given WeightFormatter Tests, When executing, Then formatPrecise returns correct format', () {
      expect(WeightFormatter.formatPrecise(500), '500 g');
      expect(WeightFormatter.formatPrecise(1550), '1.55 kg');
    });
  });
}
