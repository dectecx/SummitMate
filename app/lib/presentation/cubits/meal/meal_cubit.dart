import 'package:injectable/injectable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/result.dart';
import '../../cubits/meal/meal_state.dart';
import '../../../domain/domain.dart';
import '../../../domain/entities/meal_plan_day.dart';

@injectable
class MealCubit extends Cubit<MealState> {
  final ITripRepository _tripRepository;

  MealCubit(this._tripRepository) : super(const MealInitial());

  /// 載入行程的糧食計畫
  Future<void> loadMealPlans(String tripId) async {
    final result = await _tripRepository.getMealPlanDays(tripId);
    if (result is Success<List<MealPlanDay>, Exception>) {
      final days = result.value;
      final dailyPlans = days.map((day) => DailyMealPlan(dayInfo: day)).toList();
      emit(MealLoaded(dailyPlans: dailyPlans));
    } else {
      emit(const MealError('載入糧食計畫失敗'));
    }
  }

  /// 初始化或重置
  void reset() {
    emit(const MealInitial());
  }

  /// 根據行程天數同步計畫
  void syncWithTripDays(List<String> dayNames) {
    // TODO: 這裡可能需要呼叫 API，此為 placeholder 邏輯。具體同步行為需在後續實作。
  }

  /// 新增餐點項目
  void addMealItem(String dayId, MealType type, String name, double weight, double calories) {
    if (state is! MealLoaded) return;
    final loadedState = state as MealLoaded;

    final currentPlans = List<DailyMealPlan>.from(loadedState.dailyPlans);
    final planIndex = currentPlans.indexWhere((p) => p.dayInfo.id == dayId);

    if (planIndex != -1) {
      final oldPlan = currentPlans[planIndex];
      final newItem = MealItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        weight: weight,
        calories: calories,
      );

      final newMeals = Map<MealType, List<MealItem>>.from(oldPlan.meals);
      final itemList = List<MealItem>.from(newMeals[type] ?? []);
      itemList.add(newItem);
      newMeals[type] = itemList;

      currentPlans[planIndex] = oldPlan.copyWith(meals: newMeals);
      emit(loadedState.copyWith(dailyPlans: currentPlans));
    }
  }

  /// 移除餐點項目
  void removeMealItem(String dayId, MealType type, String itemId) {
    if (state is! MealLoaded) return;
    final loadedState = state as MealLoaded;

    final currentPlans = List<DailyMealPlan>.from(loadedState.dailyPlans);
    final planIndex = currentPlans.indexWhere((p) => p.dayInfo.id == dayId);

    if (planIndex != -1) {
      final oldPlan = currentPlans[planIndex];
      final newMeals = Map<MealType, List<MealItem>>.from(oldPlan.meals);
      final itemList = List<MealItem>.from(newMeals[type] ?? []);
      itemList.removeWhere((item) => item.id == itemId);
      newMeals[type] = itemList;

      currentPlans[planIndex] = oldPlan.copyWith(meals: newMeals);
      emit(loadedState.copyWith(dailyPlans: currentPlans));
    }
  }

  /// 更新餐點數量
  void updateMealItemQuantity(String dayId, MealType type, String itemId, int quantity) {
    if (state is! MealLoaded) return;
    final loadedState = state as MealLoaded;
    if (quantity < 1) quantity = 1;

    final currentPlans = List<DailyMealPlan>.from(loadedState.dailyPlans);
    final planIndex = currentPlans.indexWhere((p) => p.dayInfo.id == dayId);

    if (planIndex != -1) {
      final oldPlan = currentPlans[planIndex];
      final newMeals = Map<MealType, List<MealItem>>.from(oldPlan.meals);
      final itemList = List<MealItem>.from(newMeals[type] ?? []);
      final itemIndex = itemList.indexWhere((item) => item.id == itemId);

      if (itemIndex != -1) {
        itemList[itemIndex] = itemList[itemIndex].copyWith(quantity: quantity);
        newMeals[type] = itemList;
        currentPlans[planIndex] = oldPlan.copyWith(meals: newMeals);
        emit(loadedState.copyWith(dailyPlans: currentPlans));
      }
    }
  }

  /// 設定計畫 (例如匯入)
  void setDailyPlans(List<DailyMealPlan> newPlans) {
    emit(MealLoaded(dailyPlans: newPlans));
  }

  // ==========================================
  // 天數管理 (Meal Plan Day Management)
  // ==========================================

  /// 新增獨立的天數
  Future<void> addMealPlanDay(String name) async {
    if (state is! MealLoaded) return;
    final loadedState = state as MealLoaded;

    final newDay = MealPlanDay(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // TODO: use UUID
      name: name,
    );

    // TODO: Call Repository here (not fully implemented in backend yet, doing local state for now)
    // await _tripRepository.addMealPlanDay(tripId, newDay);

    final currentPlans = List<DailyMealPlan>.from(loadedState.dailyPlans);
    currentPlans.add(DailyMealPlan(dayInfo: newDay));

    emit(loadedState.copyWith(dailyPlans: currentPlans));
  }

  /// 重新命名未綁定的天數
  Future<void> renameMealPlanDay(String dayId, String newName) async {
    if (state is! MealLoaded) return;
    final loadedState = state as MealLoaded;

    final currentPlans = List<DailyMealPlan>.from(loadedState.dailyPlans);
    final planIndex = currentPlans.indexWhere((p) => p.dayInfo.id == dayId);

    if (planIndex != -1) {
      final oldDay = currentPlans[planIndex].dayInfo;
      if (oldDay.linkedItineraryDay != null) return; // 綁定的天數不可改名

      final newDay = oldDay.copyWith(name: newName);

      // TODO: await _tripRepository.updateMealPlanDay(tripId, newDay);

      currentPlans[planIndex] = currentPlans[planIndex].copyWith(dayInfo: newDay);
      emit(loadedState.copyWith(dailyPlans: currentPlans));
    }
  }

  /// 綁定天數到行程天數
  Future<void> linkMealPlanDay(String dayId, String itineraryDay) async {
    if (state is! MealLoaded) return;
    final loadedState = state as MealLoaded;

    final currentPlans = List<DailyMealPlan>.from(loadedState.dailyPlans);
    final planIndex = currentPlans.indexWhere((p) => p.dayInfo.id == dayId);

    if (planIndex != -1) {
      final oldDay = currentPlans[planIndex].dayInfo;
      final newDay = oldDay.copyWith(linkedItineraryDay: itineraryDay);

      // TODO: await _tripRepository.updateMealPlanDay(tripId, newDay);

      currentPlans[planIndex] = currentPlans[planIndex].copyWith(dayInfo: newDay);
      emit(loadedState.copyWith(dailyPlans: currentPlans));
    }
  }

  /// 取消綁定
  Future<void> unlinkMealPlanDay(String dayId) async {
    if (state is! MealLoaded) return;
    final loadedState = state as MealLoaded;

    final currentPlans = List<DailyMealPlan>.from(loadedState.dailyPlans);
    final planIndex = currentPlans.indexWhere((p) => p.dayInfo.id == dayId);

    if (planIndex != -1) {
      final oldDay = currentPlans[planIndex].dayInfo;
      final newDay = oldDay.copyWith(linkedItineraryDay: null);

      // TODO: await _tripRepository.updateMealPlanDay(tripId, newDay);

      currentPlans[planIndex] = currentPlans[planIndex].copyWith(dayInfo: newDay);
      emit(loadedState.copyWith(dailyPlans: currentPlans));
    }
  }

  /// 刪除天數
  Future<void> deleteMealPlanDay(String dayId) async {
    if (state is! MealLoaded) return;
    final loadedState = state as MealLoaded;

    final currentPlans = List<DailyMealPlan>.from(loadedState.dailyPlans);
    currentPlans.removeWhere((p) => p.dayInfo.id == dayId);

    // TODO: await _tripRepository.deleteMealPlanDay(tripId, dayId);

    emit(loadedState.copyWith(dailyPlans: currentPlans));
  }
}
