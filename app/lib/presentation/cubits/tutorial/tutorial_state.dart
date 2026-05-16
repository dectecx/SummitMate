import 'package:equatable/equatable.dart';
import '../../../domain/entities/itinerary_item.dart';
import '../../../domain/entities/gear_item.dart';
import '../../../domain/entities/trip.dart';
import '../../../domain/entities/daily_meal_plan.dart';

abstract class TutorialState extends Equatable {
  const TutorialState();

  @override
  List<Object?> get props => [];
}

/// 初始狀態，未開啟任何教學
class TutorialInitial extends TutorialState {
  const TutorialInitial();
}

/// 正在載入教學資料 (可供擴充使用)
class TutorialLoading extends TutorialState {
  const TutorialLoading();
}

/// 教學執行中狀態
///
/// 持有完整的 Mock 資料快照，供 UI 層直接讀取，
/// 無需將資料推送至各業務 Cubit。
class TutorialActive extends TutorialState {
  /// 當前的教學章節 (如 'itinerary', 'gear', 'meal')
  final String chapterId;

  /// 當前正在顯示的步驟索引
  final int currentStepIndex;

  /// 是否為 Quick Tour 模式
  final bool isQuickTour;

  // ─── Mock 資料快照 ────────────────────────────────────────────
  // 教學期間的顯示資料來源，由 TutorialCubit 在 startTutorial 時建立。
  // UI 層 (TutorialAwareBuilder) 讀取這些資料而非從 Cubit 讀取。

  /// Mock 行程
  final Trip? mockTrip;

  /// Mock 行程項目
  final List<ItineraryItem> mockItineraryItems;

  /// Mock 天數名稱列表
  final List<String> mockDayNames;

  /// Mock 裝備列表
  final List<GearItem> mockGearItems;

  /// Mock 糧食計畫列表
  final List<DailyMealPlan> mockMealPlans;

  const TutorialActive({
    required this.chapterId,
    this.currentStepIndex = 0,
    this.isQuickTour = false,
    this.mockTrip,
    this.mockItineraryItems = const [],
    this.mockDayNames = const [],
    this.mockGearItems = const [],
    this.mockMealPlans = const [],
  });

  TutorialActive copyWith({
    String? chapterId,
    int? currentStepIndex,
    bool? isQuickTour,
    Trip? mockTrip,
    List<ItineraryItem>? mockItineraryItems,
    List<String>? mockDayNames,
    List<GearItem>? mockGearItems,
    List<DailyMealPlan>? mockMealPlans,
  }) {
    return TutorialActive(
      chapterId: chapterId ?? this.chapterId,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      isQuickTour: isQuickTour ?? this.isQuickTour,
      mockTrip: mockTrip ?? this.mockTrip,
      mockItineraryItems: mockItineraryItems ?? this.mockItineraryItems,
      mockDayNames: mockDayNames ?? this.mockDayNames,
      mockGearItems: mockGearItems ?? this.mockGearItems,
      mockMealPlans: mockMealPlans ?? this.mockMealPlans,
    );
  }

  @override
  List<Object?> get props => [
    chapterId,
    currentStepIndex,
    isQuickTour,
    mockTrip,
    mockItineraryItems,
    mockDayNames,
    mockGearItems,
    mockMealPlans,
  ];
}

/// 發生錯誤
class TutorialError extends TutorialState {
  final String message;

  const TutorialError(this.message);

  @override
  List<Object?> get props => [message];
}
