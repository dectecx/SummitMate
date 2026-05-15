import 'package:equatable/equatable.dart';
import '../../../domain/domain.dart';

abstract class MealState extends Equatable {
  const MealState();

  @override
  List<Object> get props => [];
}

class MealInitial extends MealState {
  const MealInitial();
}

class MealLoaded extends MealState {
  final List<DailyMealPlan> dailyPlans;
  final bool isMockMode;

  /// 建構子
  ///
  /// [dailyPlans] 每日餐食計畫列表
  /// [isMockMode] 是否為教學展示模式
  const MealLoaded({
    required this.dailyPlans,
    this.isMockMode = false,
  });

  /// Get total weight in kg
  double get totalWeightKg {
    double totalGrams = 0;
    for (var plan in dailyPlans) {
      totalGrams += plan.totalWeight;
    }
    return totalGrams / 1000.0;
  }

  MealLoaded copyWith({
    List<DailyMealPlan>? dailyPlans,
    bool? isMockMode,
  }) {
    return MealLoaded(
      dailyPlans: dailyPlans ?? this.dailyPlans,
      isMockMode: isMockMode ?? this.isMockMode,
    );
  }

  @override
  List<Object> get props => [dailyPlans, isMockMode];
}

class MealError extends MealState {
  final String message;

  const MealError(this.message);

  @override
  List<Object> get props => [message];
}
