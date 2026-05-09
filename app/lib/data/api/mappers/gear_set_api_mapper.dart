import '../../../domain/entities/gear_set.dart';
import '../../../domain/entities/gear_item.dart';
import '../../../domain/entities/daily_meal_plan.dart';
import '../../../domain/enums/gear_set_visibility.dart';
import '../models/gear_set_api_models.dart';

/// GearSet API Model ↔ Domain Model 轉換
class GearSetApiMapper {
  /// GearSetResponse → GearSet (Domain Entity)
  static GearSet fromResponse(GearSetResponse response) {
    // Map DTO items to GearItem domain entities
    final items = response.items.map((dto) {
      return GearItem(
        id: dto.id,
        tripId: '', // cloud sets are not trip-bound
        name: dto.name,
        category: dto.category,
        weight: dto.weight,
        quantity: dto.quantity,
        orderIndex: dto.orderIndex,
      );
    }).toList();

    // DailyMealPlan from meal DTOs — keep as flat list mapped by day
    // (domain model organises by day/mealType, so we produce one plan per unique day)
    final List<DailyMealPlan>? meals = response.meals != null
        ? _groupMeals(response.meals!)
        : null;

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
    final itemMaps = items.asMap().entries.map((e) {
      final item = e.value;
      return <String, dynamic>{
        'name': item.name,
        'category': item.category,
        'weight': item.weight,
        'quantity': item.quantity,
        'order_index': e.key,
      };
    }).toList();

    final mealMaps = meals?.expand((plan) {
      return plan.meals.entries.expand((entry) {
        return entry.value.map((mealItem) => <String, dynamic>{
          'day': plan.day,
          'meal_type': entry.key.name,
          'name': mealItem.name,
          'calories': mealItem.calories,
          'note': null,
        });
      });
    }).toList();

    return GearSetCreateRequest(
      title: title,
      author: author,
      visibility: visibility.name,
      downloadKey: downloadKey,
      totalWeight: items.fold(0.0, (sum, i) => sum + i.totalWeight),
      itemCount: items.length,
      items: itemMaps,
      meals: mealMaps,
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

  /// Group flat meal DTOs into DailyMealPlan domain entities.
  /// Since DailyMealPlan uses MealItem internally (with weight etc), and cloud data
  /// only stores minimal info, we use empty MealItems for display purposes.
  static List<DailyMealPlan> _groupMeals(List<GearSetMealDto> dtos) {
    // Group by day
    final Map<String, DailyMealPlan> byDay = {};
    for (final dto in dtos) {
      byDay.putIfAbsent(dto.day, () => DailyMealPlan(day: dto.day));
    }
    return byDay.values.toList();
  }
}
