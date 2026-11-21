import 'package:injectable/injectable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:summitmate/presentation/cubits/base/safe_emit_mixin.dart';
import 'package:summitmate/presentation/cubits/base/trip_dirty_marker_mixin.dart';
import '../../../core/error/result.dart';
import '../../cubits/meal/meal_state.dart';
import '../../../domain/domain.dart';

@injectable
class MealCubit extends Cubit<MealState> with SafeEmitMixin<MealState>, TripDirtyMarkerMixin<MealState> {
  final ITripRepository _tripRepository;
  String? _currentTripId;

  MealCubit(this._tripRepository) : super(const MealInitial());

  @override
  ITripRepository get tripRepository => _tripRepository;

  @override
  String? get currentTripId => _currentTripId;

  /// 載入行程的糧食計畫（含各天的餐點項目）
  Future<void> loadMealPlans(String tripId) async {
    _currentTripId = tripId;
    final result = await _tripRepository.getDailyMealPlans(tripId);
    if (result is Success<List<DailyMealPlan>, Exception>) {
      safeEmit(MealLoaded(dailyPlans: result.value));
    } else {
      safeEmit(const MealError('載入糧食計畫失敗'));
    }
  }

  /// 初始化或重置
  void reset() {
    _currentTripId = null;
    safeEmit(const MealInitial());
  }

  /// 新增餐點項目
  Future<void> addMealItem(
    String dayId,
    MealType type,
    String name,
    double weight,
    double calories, {
    String? note,
  }) async {
    if (state is! MealLoaded || _currentTripId == null) return;
    final loadedState = state as MealLoaded;

    final result = await _tripRepository.addMealItem(dayId, type, name, weight, calories, note: note);

    if (result is Success<MealItem, Exception>) {
      final newItem = result.value;
      final currentPlans = List<DailyMealPlan>.from(loadedState.dailyPlans);
      final planIndex = currentPlans.indexWhere((p) => p.dayInfo.id == dayId);

      if (planIndex != -1) {
        final oldPlan = currentPlans[planIndex];
        final newMeals = Map<MealType, List<MealItem>>.from(oldPlan.meals);
        newMeals[type] = [...(newMeals[type] ?? []), newItem];
        currentPlans[planIndex] = oldPlan.copyWith(meals: newMeals);
        await markCurrentTripDirty();
        safeEmit(loadedState.copyWith(dailyPlans: currentPlans));
      }
    } else if (result is Failure<MealItem, Exception>) {
      safeEmit(MealError('新增餐點失敗: ${result.exception}'));
      safeEmit(loadedState);
    }
  }

  /// 移除餐點項目
  Future<void> removeMealItem(String dayId, MealType type, String itemId) async {
    if (state is! MealLoaded || _currentTripId == null) return;
    final loadedState = state as MealLoaded;

    final result = await _tripRepository.removeMealItem(itemId);

    if (result is Success<void, Exception>) {
      final currentPlans = List<DailyMealPlan>.from(loadedState.dailyPlans);
      final planIndex = currentPlans.indexWhere((p) => p.dayInfo.id == dayId);

      if (planIndex != -1) {
        final oldPlan = currentPlans[planIndex];
        final newMeals = Map<MealType, List<MealItem>>.from(oldPlan.meals);
        newMeals[type] = (newMeals[type] ?? []).where((item) => item.id != itemId).toList();
        currentPlans[planIndex] = oldPlan.copyWith(meals: newMeals);
        await markCurrentTripDirty();
        safeEmit(loadedState.copyWith(dailyPlans: currentPlans));
      }
    } else if (result is Failure<void, Exception>) {
      safeEmit(MealError('刪除餐點失敗: ${result.exception}'));
      safeEmit(loadedState);
    }
  }

  /// 更新餐點數量
  Future<void> updateMealItemQuantity(String dayId, MealType type, String itemId, int quantity) async {
    if (state is! MealLoaded || _currentTripId == null) return;
    final loadedState = state as MealLoaded;
    if (quantity < 1) quantity = 1;

    final result = await _tripRepository.updateMealItemQuantity(itemId, quantity);

    if (result is Success<void, Exception>) {
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
          await markCurrentTripDirty();
          safeEmit(loadedState.copyWith(dailyPlans: currentPlans));
        }
      }
    } else if (result is Failure<void, Exception>) {
      safeEmit(MealError('更新餐點數量失敗: ${result.exception}'));
      safeEmit(loadedState);
    }
  }

  /// 設定計畫 (例如匯入)
  void setDailyPlans(List<DailyMealPlan> newPlans) {
    safeEmit(MealLoaded(dailyPlans: newPlans));
  }

  // ==========================================
  // 天數管理 (Meal Plan Day Management)
  // ==========================================

  /// 新增獨立的天數
  Future<void> addMealPlanDay(String name) async {
    if (state is! MealLoaded || _currentTripId == null) return;
    final loadedState = state as MealLoaded;

    final result = await _tripRepository.addMealPlanDay(_currentTripId!, name);

    if (result is Success<MealPlanDay, Exception>) {
      final newDay = result.value;
      final currentPlans = List<DailyMealPlan>.from(loadedState.dailyPlans);
      currentPlans.add(DailyMealPlan(dayInfo: newDay));

      await markCurrentTripDirty();
      safeEmit(loadedState.copyWith(dailyPlans: currentPlans));
    } else if (result is Failure<MealPlanDay, Exception>) {
      safeEmit(MealError('新增天數失敗: ${result.exception.toString()}'));
      safeEmit(loadedState); // 回復狀態
    }
  }

  /// 重新命名未綁定的天數
  Future<void> renameMealPlanDay(String dayId, String newName) async {
    if (state is! MealLoaded || _currentTripId == null) return;
    final loadedState = state as MealLoaded;

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
        await markCurrentTripDirty();
        safeEmit(loadedState.copyWith(dailyPlans: currentPlans));
      } else if (result is Failure<MealPlanDay, Exception>) {
        safeEmit(MealError('重新命名天數失敗: ${result.exception.toString()}'));
        safeEmit(loadedState);
      }
    }
  }

  /// 綁定天數到行程天數
  Future<void> linkMealPlanDay(String dayId, String itineraryDay) async {
    if (state is! MealLoaded || _currentTripId == null) return;
    final loadedState = state as MealLoaded;

    final currentPlans = List<DailyMealPlan>.from(loadedState.dailyPlans);
    final planIndex = currentPlans.indexWhere((p) => p.dayInfo.id == dayId);

    if (planIndex != -1) {
      final result = await _tripRepository.updateMealPlanDay(
        _currentTripId!,
        dayId,
        itineraryDay,
        linkedItineraryDay: itineraryDay,
      );

      if (result is Success<MealPlanDay, Exception>) {
        final newDay = result.value;
        currentPlans[planIndex] = currentPlans[planIndex].copyWith(dayInfo: newDay);
        await markCurrentTripDirty();
        safeEmit(loadedState.copyWith(dailyPlans: currentPlans));
      } else if (result is Failure<MealPlanDay, Exception>) {
        safeEmit(MealError('綁定天數失敗: ${result.exception.toString()}'));
        safeEmit(loadedState);
      }
    }
  }

  /// 取消綁定
  Future<void> unlinkMealPlanDay(String dayId) async {
    if (state is! MealLoaded || _currentTripId == null) return;
    final loadedState = state as MealLoaded;

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
        await markCurrentTripDirty();
        safeEmit(loadedState.copyWith(dailyPlans: currentPlans));
      } else if (result is Failure<MealPlanDay, Exception>) {
        safeEmit(MealError('解除綁定天數失敗: ${result.exception.toString()}'));
        safeEmit(loadedState);
      }
    }
  }

  /// 刪除天數
  Future<void> deleteMealPlanDay(String dayId) async {
    if (state is! MealLoaded || _currentTripId == null) return;
    final loadedState = state as MealLoaded;

    final currentPlans = List<DailyMealPlan>.from(loadedState.dailyPlans);
    final planIndex = currentPlans.indexWhere((p) => p.dayInfo.id == dayId);

    if (planIndex != -1) {
      final result = await _tripRepository.deleteMealPlanDay(_currentTripId!, dayId);

      if (result is Success<void, Exception>) {
        currentPlans.removeAt(planIndex);
        await markCurrentTripDirty();
        safeEmit(loadedState.copyWith(dailyPlans: currentPlans));
      } else if (result is Failure<void, Exception>) {
        safeEmit(MealError('刪除天數失敗: ${result.exception.toString()}'));
        safeEmit(loadedState);
      }
    }
  }
}
