import 'package:equatable/equatable.dart';

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
class TutorialActive extends TutorialState {
  /// 當前的教學章節 (如 'QuickTour', 'TripDetail')
  final String chapterId;

  /// 當前正在顯示的步驟索引
  final int currentStepIndex;

  /// 是否為 Quick Tour 模式
  final bool isQuickTour;

  const TutorialActive({
    required this.chapterId,
    this.currentStepIndex = 0,
    this.isQuickTour = false,
  });

  TutorialActive copyWith({
    String? chapterId,
    int? currentStepIndex,
    bool? isQuickTour,
  }) {
    return TutorialActive(
      chapterId: chapterId ?? this.chapterId,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      isQuickTour: isQuickTour ?? this.isQuickTour,
    );
  }

  @override
  List<Object?> get props => [chapterId, currentStepIndex, isQuickTour];
}

/// 發生錯誤
class TutorialError extends TutorialState {
  final String message;

  const TutorialError(this.message);

  @override
  List<Object?> get props => [message];
}
