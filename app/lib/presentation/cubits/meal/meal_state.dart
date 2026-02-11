import 'package:equatable/equatable.dart';
import '../../../data/models/meal_item.dart';

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

  /// 建構子
  ///
  /// [dailyPlans] 每日餐食計畫列表
  const MealLoaded({required this.dailyPlans});

  /// Get total weight in kg
  double get totalWeightKg {
    double totalGrams = 0;
    for (var plan in dailyPlans) {
      totalGrams += plan.totalWeight;
    }
    return totalGrams / 1000.0;
  }

  MealLoaded copyWith({List<DailyMealPlan>? dailyPlans}) {
    return MealLoaded(dailyPlans: dailyPlans ?? this.dailyPlans);
  }

  @override
  List<Object> get props => [dailyPlans];
}

class MealError extends MealState {
  final String message;

  const MealError(this.message);

  @override
  List<Object> get props => [message];
}
