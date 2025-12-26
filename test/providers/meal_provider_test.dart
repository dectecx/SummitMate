import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/data/models/meal_item.dart';
import 'package:summitmate/presentation/providers/meal_provider.dart';

void main() {
  group('MealProvider Tests', () {
    late MealProvider provider;

    setUp(() {
      provider = MealProvider();
    });

    test('初始狀態有 3 天行程 (D0, D1, D2)', () {
      expect(provider.dailyPlans.length, 3);
      expect(provider.dailyPlans[0].day, 'D0');
      expect(provider.dailyPlans[1].day, 'D1');
      expect(provider.dailyPlans[2].day, 'D2');
    });

    test('初始狀態總重量為 0', () {
      expect(provider.totalWeightKg, 0.0);
    });

    test('新增餐點後總重量增加', () {
      provider.addMealItem('D0', MealType.breakfast, '麵包', 100.0, 250.0);

      expect(provider.totalWeightKg, 0.1); // 100g = 0.1kg
    });

    test('新增多個餐點後總重量正確計算', () {
      provider.addMealItem('D0', MealType.breakfast, '麵包', 100.0, 250.0);
      provider.addMealItem('D0', MealType.lunch, '飯糰', 200.0, 400.0);
      provider.addMealItem('D1', MealType.dinner, '乾燥飯', 150.0, 500.0);

      expect(provider.totalWeightKg, 0.45); // 450g = 0.45kg
    });

    test('刪除餐點後總重量減少', () {
      provider.addMealItem('D0', MealType.breakfast, '麵包', 100.0, 250.0);

      // 取得新增的 item id
      final addedItem = provider.dailyPlans[0].meals[MealType.breakfast]!.first;

      provider.removeMealItem('D0', MealType.breakfast, addedItem.id);

      expect(provider.totalWeightKg, 0.0);
    });

    test('addMealItem 會 notifyListeners', () {
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.addMealItem('D0', MealType.breakfast, '麵包', 100.0, 250.0);

      expect(notifyCount, 1);
    });

    test('removeMealItem 會 notifyListeners', () {
      provider.addMealItem('D0', MealType.breakfast, '麵包', 100.0, 250.0);
      final addedItem = provider.dailyPlans[0].meals[MealType.breakfast]!.first;

      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.removeMealItem('D0', MealType.breakfast, addedItem.id);

      expect(notifyCount, 1);
    });

    test('DailyMealPlan totalWeight 計算正確', () {
      provider.addMealItem('D0', MealType.breakfast, '麵包', 100.0, 250.0);
      provider.addMealItem('D0', MealType.lunch, '飯糰', 200.0, 400.0);

      final d0Plan = provider.dailyPlans[0];
      expect(d0Plan.totalWeight, 300.0);
    });

    test('DailyMealPlan totalCalories 計算正確', () {
      provider.addMealItem('D0', MealType.breakfast, '麵包', 100.0, 250.0);
      provider.addMealItem('D0', MealType.lunch, '飯糰', 200.0, 400.0);

      final d0Plan = provider.dailyPlans[0];
      expect(d0Plan.totalCalories, 650.0);
    });

    test('對不存在的 day 操作不會拋出異常', () {
      // 不應該拋出異常
      expect(() => provider.addMealItem('D99', MealType.breakfast, '麵包', 100.0, 250.0), returnsNormally);

      expect(() => provider.removeMealItem('D99', MealType.breakfast, 'someId'), returnsNormally);
    });

    test('各 MealType 獨立儲存', () {
      provider.addMealItem('D0', MealType.breakfast, '早餐', 100.0, 200.0);
      provider.addMealItem('D0', MealType.lunch, '午餐', 150.0, 300.0);
      provider.addMealItem('D0', MealType.dinner, '晚餐', 200.0, 400.0);

      final d0 = provider.dailyPlans[0];
      expect(d0.meals[MealType.breakfast]!.length, 1);
      expect(d0.meals[MealType.lunch]!.length, 1);
      expect(d0.meals[MealType.dinner]!.length, 1);
    });
  });

  group('MealItem Tests', () {
    test('MealItem copyWith 正確複製', () {
      final item = MealItem(id: '1', name: '麵包', weight: 100.0, calories: 250.0);
      final copied = item.copyWith(name: '吐司', calories: 300.0);

      expect(copied.id, '1'); // ID 不變
      expect(copied.name, '吐司');
      expect(copied.weight, 100.0); // 未指定的保持原值
      expect(copied.calories, 300.0);
    });

    test('MealItem 預設 quantity 為 1', () {
      final item = MealItem(id: '1', name: '麵包', weight: 100.0, calories: 250.0);
      expect(item.quantity, 1);
    });
  });

  group('MealType Tests', () {
    test('MealType 有正確的標籤', () {
      expect(MealType.breakfast.label, '早餐');
      expect(MealType.lunch.label, '午餐');
      expect(MealType.dinner.label, '晚餐');
      expect(MealType.action.label, '行動糧');
      expect(MealType.emergency.label, '緊急/備用糧');
    });

    test('MealType 有 7 種類型', () {
      expect(MealType.values.length, 7);
    });
  });
}
