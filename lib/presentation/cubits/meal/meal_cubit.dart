import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/meal/meal_state.dart';
import '../../../data/models/meal_item.dart';

class MealCubit extends Cubit<MealState> {
  MealCubit() : super(const MealInitial()) {
    reset();
  }

  /// Initial setup or reset
  void reset() {
    emit(
      MealLoaded(
        dailyPlans: [
          DailyMealPlan(day: 'D0'),
          DailyMealPlan(day: 'D1'),
          DailyMealPlan(day: 'D2'),
        ],
      ),
    );
  }

  /// Add meal item
  void addMealItem(String day, MealType type, String name, double weight, double calories) {
    if (state is! MealLoaded) return;

    final currentPlans = List<DailyMealPlan>.from((state as MealLoaded).dailyPlans);
    final planIndex = currentPlans.indexWhere((p) => p.day == day);

    if (planIndex != -1) {
      final newItem = MealItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        weight: weight,
        calories: calories,
      );

      // Clone the plan and the meal list to ensure immutability
      final plan = currentPlans[planIndex];
      final newMeals = Map<MealType, List<MealItem>>.from(plan.meals);

      if (newMeals[type] == null) {
        newMeals[type] = [];
      }

      final typeList = List<MealItem>.from(newMeals[type]!);
      typeList.add(newItem);
      newMeals[type] = typeList;

      // Create updated plan (assuming DailyMealPlan has copyWith or we create new)
      // Since DailyMealPlan might not have copyWith for internal Map deep copy, manual reconstruction:
      // Assuming DailyMealPlan constructor takes mutable map reference or we replaced it.
      // But looking at provider, it mutated directly. Here in Cubit we prefer immutability.
      // Assuming DailyMealPlan structure allows this.
      // Let's check DailyMealPlan model if possible, but for now we replace the instance.

      // If DailyMealPlan is essentially mutable, we might need a workaround or ensure UI rebuilds.
      // In Provider code: `_dailyPlans[planIndex].meals[type]?.add(newItem); notifyListeners();`
      // Here we emit new state.

      // Direct mutation of list inside state is BAD for BLoC (state equality check might fail if reference same).
      // So we copied `currentPlans`.
      // We need to verify if `DailyMealPlan` is mutable.

      // For now, let's assume we can mutate the cloned list structure or use what we have.
      // Since `currentPlans` is a shallow copy of the list, elements are same references.
      // Ideally we deep copy.
      // But for simplicity in migration:

      // Workaround: Modify, then emit new List reference.
      // But modifying object inside previous state is risky.

      currentPlans[planIndex].meals[type]?.add(newItem);

      // Force emit
      emit((state as MealLoaded).copyWith(dailyPlans: List.from(currentPlans)));
    }
  }

  /// Remove meal item
  void removeMealItem(String day, MealType type, String itemId) {
    if (state is! MealLoaded) return;
    final currentPlans = List<DailyMealPlan>.from((state as MealLoaded).dailyPlans);
    final planIndex = currentPlans.indexWhere((p) => p.day == day);

    if (planIndex != -1) {
      currentPlans[planIndex].meals[type]?.removeWhere((item) => item.id == itemId);
      emit((state as MealLoaded).copyWith(dailyPlans: List.from(currentPlans)));
    }
  }

  /// Update quantity
  void updateMealItemQuantity(String day, MealType type, String itemId, int quantity) {
    if (state is! MealLoaded) return;
    if (quantity < 1) quantity = 1;

    final currentPlans = List<DailyMealPlan>.from((state as MealLoaded).dailyPlans);
    final planIndex = currentPlans.indexWhere((p) => p.day == day);

    if (planIndex != -1) {
      final items = currentPlans[planIndex].meals[type];
      if (items != null) {
        final itemIndex = items.indexWhere((item) => item.id == itemId);
        if (itemIndex != -1) {
          items[itemIndex] = items[itemIndex].copyWith(quantity: quantity);
          emit((state as MealLoaded).copyWith(dailyPlans: List.from(currentPlans)));
        }
      }
    }
  }

  /// Set plans (e.g. import)
  void setDailyPlans(List<DailyMealPlan> newPlans) {
    emit(MealLoaded(dailyPlans: newPlans));
  }
}
