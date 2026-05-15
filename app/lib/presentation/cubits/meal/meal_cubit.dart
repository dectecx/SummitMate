import 'package:injectable/injectable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/result.dart';
import '../../cubits/meal/meal_state.dart';
import '../../../domain/domain.dart';
import '../../../domain/entities/meal_plan_day.dart';

@injectable
class MealCubit extends Cubit<MealState> {
  final ITripRepository _tripRepository;
  String? _currentTripId;

  MealCubit(this._tripRepository) : super(const MealInitial());

  /// 載入行程的糧食計畫
  Future<void> loadMealPlans(String tripId) async {
    _currentTripId = tripId;
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
    _currentTripId = null;
    emit(const MealInitial());
  }

  /// 新增餐點項目
  void addMealItem(String dayId, MealType type, String name, double weight, double calories) {
    if (state is! MealLoaded) return;
    final loadedState = state as MealLoaded;
    if (loadedState.isMockMode) return;

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
    if (loadedState.isMockMode) return;

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
    if (loadedState.isMockMode) return;
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
    if (state is! MealLoaded || _currentTripId == null) return;
    final loadedState = state as MealLoaded;
    if (loadedState.isMockMode) return;

    final result = await _tripRepository.addMealPlanDay(_currentTripId!, name);

    if (result is Success<MealPlanDay, Exception>) {
      final newDay = result.value;
      final currentPlans = List<DailyMealPlan>.from(loadedState.dailyPlans);
      currentPlans.add(DailyMealPlan(dayInfo: newDay));

      emit(loadedState.copyWith(dailyPlans: currentPlans));
    } else if (result is Failure<MealPlanDay, Exception>) {
      emit(MealError('新增天數失敗: ${result.exception.toString()}'));
      emit(loadedState); // 回復狀態
    }
  }

  /// 重新命名未綁定的天數
  Future<void> renameMealPlanDay(String dayId, String newName) async {
    if (state is! MealLoaded || _currentTripId == null) return;
    final loadedState = state as MealLoaded;
    if (loadedState.isMockMode) return;

    final currentPlans = List<DailyMealPlan>.from(loadedState.dailyPlans);
    final planIndex = currentPlans.indexWhere((p) => p.dayInfo.id == dayId);

    if (planIndex != -1) {
      final oldDay = currentPlans[planIndex].dayInfo;
      if (oldDay.linkedItineraryDay != null) return; // 綁定的天數不可改名

      final result = await _tripRepository.updateMealPlanDay(
        _currentTripId!,
        dayId,
        newName,
        linkedItineraryDay: oldDay.linkedItineraryDay,
      );

      if (result is Success<MealPlanDay, Exception>) {
        final newDay = result.value;
        currentPlans[planIndex] = currentPlans[planIndex].copyWith(dayInfo: newDay);
        emit(loadedState.copyWith(dailyPlans: currentPlans));
      } else if (result is Failure<MealPlanDay, Exception>) {
        emit(MealError('重新命名天數失敗: ${result.exception.toString()}'));
        emit(loadedState);
      }
    }
  }

  /// 綁定天數到行程天數
  Future<void> linkMealPlanDay(String dayId, String itineraryDay) async {
    if (state is! MealLoaded || _currentTripId == null) return;
    final loadedState = state as MealLoaded;
    if (loadedState.isMockMode) return;

    final currentPlans = List<DailyMealPlan>.from(loadedState.dailyPlans);
    final planIndex = currentPlans.indexWhere((p) => p.dayInfo.id == dayId);

    if (planIndex != -1) {
      // 綁定時，名稱強制覆蓋為行程天數名稱
      final result = await _tripRepository.updateMealPlanDay(
        _currentTripId!,
        dayId,
        itineraryDay,
        linkedItineraryDay: itineraryDay,
      );

      if (result is Success<MealPlanDay, Exception>) {
        final newDay = result.value;
        currentPlans[planIndex] = currentPlans[planIndex].copyWith(dayInfo: newDay);
        emit(loadedState.copyWith(dailyPlans: currentPlans));
      } else if (result is Failure<MealPlanDay, Exception>) {
        emit(MealError('綁定天數失敗: ${result.exception.toString()}'));
        emit(loadedState);
      }
    }
  }

  /// 取消綁定
  Future<void> unlinkMealPlanDay(String dayId) async {
    if (state is! MealLoaded || _currentTripId == null) return;
    final loadedState = state as MealLoaded;
    if (loadedState.isMockMode) return;

    final currentPlans = List<DailyMealPlan>.from(loadedState.dailyPlans);
    final planIndex = currentPlans.indexWhere((p) => p.dayInfo.id == dayId);

    if (planIndex != -1) {
      final oldDay = currentPlans[planIndex].dayInfo;

      final result = await _tripRepository.updateMealPlanDay(
        _currentTripId!,
        dayId,
        oldDay.name,
        linkedItineraryDay: null,
      );

      if (result is Success<MealPlanDay, Exception>) {
        final newDay = result.value;
        currentPlans[planIndex] = currentPlans[planIndex].copyWith(dayInfo: newDay);
        emit(loadedState.copyWith(dailyPlans: currentPlans));
      } else if (result is Failure<MealPlanDay, Exception>) {
        emit(MealError('解除綁定天數失敗: ${result.exception.toString()}'));
        emit(loadedState);
      }
    }
  }

  /// 刪除天數
  Future<void> deleteMealPlanDay(String dayId) async {
    if (state is! MealLoaded || _currentTripId == null) return;
    final loadedState = state as MealLoaded;
    if (loadedState.isMockMode) return;

    final currentPlans = List<DailyMealPlan>.from(loadedState.dailyPlans);
    final planIndex = currentPlans.indexWhere((p) => p.dayInfo.id == dayId);

    if (planIndex != -1) {
      final result = await _tripRepository.deleteMealPlanDay(_currentTripId!, dayId);

      if (result is Success<void, Exception>) {
        currentPlans.removeAt(planIndex);
        emit(loadedState.copyWith(dailyPlans: currentPlans));
      } else if (result is Failure<void, Exception>) {
        emit(MealError('刪除天數失敗: ${result.exception.toString()}'));
        emit(loadedState);
      }
    }
  }

  // ─────────────────────────────────────────────
  // 教學導覽的 Mock 資料注入
  // ─────────────────────────────────────────────

  void injectMockData(List<DailyMealPlan> mockPlans) {
    if (state is MealLoaded) {
      final current = state as MealLoaded;
      emit(current.copyWith(dailyPlans: mockPlans, isMockMode: true));
    } else {
      emit(MealLoaded(dailyPlans: mockPlans, isMockMode: true));
    }
  }

  Future<void> clearMockData() async {
    if (state is MealLoaded && (state as MealLoaded).isMockMode) {
      if (_currentTripId != null) {
        await loadMealPlans(_currentTripId!);
      } else {
        emit(const MealInitial());
      }
    }
  }
}
