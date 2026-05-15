import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'tutorial_state.dart';
import '../trip/trip_cubit.dart';
import '../itinerary/itinerary_cubit.dart';
import '../gear/gear_cubit.dart';
import '../meal/meal_cubit.dart';
import '../../../infrastructure/tools/tutorial_mock_data.dart';

@injectable
class TutorialCubit extends Cubit<TutorialState> {
  final TripCubit _tripCubit;
  final ItineraryCubit _itineraryCubit;
  final GearCubit _gearCubit;
  final MealCubit _mealCubit;

  TutorialCubit(
    this._tripCubit,
    this._itineraryCubit,
    this._gearCubit,
    this._mealCubit,
  ) : super(const TutorialInitial());

  /// 開啟教學模式 (Quick Tour 或一般章節教學)
  Future<void> startTutorial({
    required String chapterId,
    bool isQuickTour = false,
  }) async {
    // 進入教學前，先注入 Mock 資料
    _injectMockData();
    
    emit(TutorialActive(
      chapterId: chapterId,
      currentStepIndex: 0,
      isQuickTour: isQuickTour,
    ));
  }

  /// 關閉教學模式
  Future<void> endTutorial() async {
    emit(const TutorialLoading());

    // 清除 Mock 資料，恢復原狀
    await _clearMockData();

    emit(const TutorialInitial());
  }

  /// 切換到上一個步驟
  void previousStep() {
    if (state is TutorialActive) {
      final activeState = state as TutorialActive;
      if (activeState.currentStepIndex > 0) {
        emit(activeState.copyWith(
          currentStepIndex: activeState.currentStepIndex - 1,
        ));
      }
    }
  }

  /// 切換到下一個步驟
  void nextStep() {
    if (state is TutorialActive) {
      final activeState = state as TutorialActive;
      emit(activeState.copyWith(
        currentStepIndex: activeState.currentStepIndex + 1,
      ));
    }
  }
  
  /// 跳到特定步驟
  void goToStep(int index) {
    if (state is TutorialActive) {
      final activeState = state as TutorialActive;
      if (index >= 0) {
        emit(activeState.copyWith(
          currentStepIndex: index,
        ));
      }
    }
  }

  /// 注入四大功能模組的 Mock 資料
  void _injectMockData() {
    final mockTrip = TutorialMockData.createMockTrip();
    _tripCubit.injectMockTrip(mockTrip);

    final mockItinerary = TutorialMockData.createMockItineraryItems();
    _itineraryCubit.injectMockData(mockItinerary, mockTrip.dayNames);

    final mockGear = TutorialMockData.createMockGearItems();
    _gearCubit.injectMockData(mockGear);

    final mockMeals = TutorialMockData.createMockDailyMealPlans();
    _mealCubit.injectMockData(mockMeals);
  }

  /// 清除四大功能模組的 Mock 資料
  Future<void> _clearMockData() async {
    await _tripCubit.clearMockTrip();
    await _itineraryCubit.clearMockData();
    await _gearCubit.clearMockData();
    await _mealCubit.clearMockData();
  }
}
