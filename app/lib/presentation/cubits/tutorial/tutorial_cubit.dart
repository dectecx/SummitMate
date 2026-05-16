import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'tutorial_state.dart';
import '../../../infrastructure/tools/tutorial_mock_data.dart';

@injectable
class TutorialCubit extends Cubit<TutorialState> {
  TutorialCubit() : super(const TutorialInitial());

  /// 開啟教學模式 (Quick Tour 或一般章節教學)
  ///
  /// 建立完整的 Mock 資料快照並放入 [TutorialActive] state，
  /// UI 層的 TutorialAwareBuilder 將從此處讀取資料，
  /// 業務 Cubit 完全不受影響。
  Future<void> startTutorial({required String chapterId, bool isQuickTour = false}) async {
    final snapshot = TutorialMockData.createSnapshot();
    emit(
      TutorialActive(
        chapterId: chapterId,
        isQuickTour: isQuickTour,
        mockTrip: snapshot.trip,
        mockItineraryItems: snapshot.itineraryItems,
        mockDayNames: snapshot.dayNames,
        mockGearItems: snapshot.gearItems,
        mockMealPlans: snapshot.mealPlans,
      ),
    );
  }

  /// 關閉教學模式
  ///
  /// 恢復至初始狀態。UI 層的 TutorialAwareBuilder 將自動
  /// 切換回讀取各業務 Cubit 的真實資料。
  Future<void> endTutorial() async {
    emit(const TutorialInitial());
  }

  /// 切換到上一個步驟
  void previousStep() {
    if (state is TutorialActive) {
      final activeState = state as TutorialActive;
      if (activeState.currentStepIndex > 0) {
        emit(activeState.copyWith(currentStepIndex: activeState.currentStepIndex - 1));
      }
    }
  }

  /// 切換到下一個步驟
  void nextStep() {
    if (state is TutorialActive) {
      final activeState = state as TutorialActive;
      emit(activeState.copyWith(currentStepIndex: activeState.currentStepIndex + 1));
    }
  }

  /// 跳到特定步驟
  void goToStep(int index) {
    if (state is TutorialActive) {
      final activeState = state as TutorialActive;
      if (index >= 0) {
        emit(activeState.copyWith(currentStepIndex: index));
      }
    }
  }
}
