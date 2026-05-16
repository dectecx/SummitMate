import '../../../domain/entities/gear_set.dart';
import '../../../domain/entities/gear_item.dart';
import '../../../domain/entities/daily_meal_plan.dart';
import '../../../domain/entities/meal_item.dart';
import '../../../domain/entities/meal_plan_day.dart';
import '../../../domain/enums/gear_set_visibility.dart';
import '../../../domain/enums/meal_type.dart';
import '../models/gear_set_api_models.dart';

/// GearSet API Model ↔ Domain Model 轉換
class GearSetApiMapper {
  /// GearSetResponse → GearSet (Domain Entity)
  static GearSet fromResponse(GearSetResponse response) {
    final items = response.items.map((dto) {
      return GearItem(
        id: dto.id,
        tripId: '',
        name: dto.name,
        category: dto.category,
        weight: dto.weight,
        quantity: dto.quantity,
        orderIndex: dto.orderIndex,
      );
    }).toList();

    final List<DailyMealPlan>? meals = response.meals != null ? _groupMeals(response.meals!) : null;

    return GearSet(
      id: response.id,
      title: response.title,
      author: response.author,
      totalWeight: response.totalWeight,
      itemCount: response.itemCount,
      visibility: _mapVisibility(response.visibility),
      items: items,
      meals: meals,
      createdAt: response.createdAt.toLocal(),
      createdBy: response.createdBy,
      uploadedAt: response.createdAt.toLocal(),
      updatedAt: response.updatedAt.toLocal(),
      updatedBy: response.updatedBy,
    );
  }

  /// Build GearSetCreateRequest from domain parameters
  static GearSetCreateRequest toCreateRequest({
    required String title,
    required String author,
    required GearSetVisibility visibility,
    required List<GearItem> items,
    List<DailyMealPlan>? meals,
    String? downloadKey,
  }) {
    final itemRequests = items.asMap().entries.map((e) {
      final item = e.value;
      return GearSetItemRequest(
        name: item.name,
        category: item.category,
        weight: item.weight,
        quantity: item.quantity,
        orderIndex: e.key,
      );
    }).toList();

    final mealRequests = meals?.expand((plan) {
      return plan.meals.entries.expand((entry) {
        return entry.value.map(
          (mealItem) => GearSetMealRequest(
            day: plan.dayInfo.name,
            mealType: entry.key.name,
            name: mealItem.name,
            calories: mealItem.calories,
            note: mealItem.note,
          ),
        );
      });
    }).toList();

    return GearSetCreateRequest(
      title: title,
      author: author,
      visibility: visibility.name,
      downloadKey: downloadKey,
      totalWeight: items.fold(0.0, (sum, i) => sum + i.totalWeight),
      itemCount: items.length,
      items: itemRequests,
      meals: mealRequests,
    );
  }

  // ── Private Helpers ──

  static GearSetVisibility _mapVisibility(String raw) {
    switch (raw) {
      case 'protected':
        return GearSetVisibility.protected;
      case 'private':
        return GearSetVisibility.private;
      default:
        return GearSetVisibility.public;
    }
  }

  static List<DailyMealPlan> _groupMeals(List<GearSetMealDto> dtos) {
    final Map<String, DailyMealPlan> byDay = {};
    for (final dto in dtos) {
      final plan = byDay.putIfAbsent(
        dto.day,
        () => DailyMealPlan(
          dayInfo: MealPlanDay(id: dto.day, name: dto.day),
        ),
      );
      final mealType = MealType.values.firstWhere((t) => t.name == dto.mealType, orElse: () => MealType.breakfast);

      final mealItem = MealItem(id: dto.id, name: dto.name, calories: dto.calories, weight: 0, note: dto.note);

      final meals = Map<MealType, List<MealItem>>.from(plan.meals);
      meals.putIfAbsent(mealType, () => []).add(mealItem);

      byDay[dto.day] = plan.copyWith(meals: meals);
    }
    return byDay.values.toList();
  }
}
