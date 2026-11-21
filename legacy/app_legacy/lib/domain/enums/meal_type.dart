import 'package:json_annotation/json_annotation.dart';

/// 餐食類型 (早/午/晚/行動糧...)
enum MealType {
  /// 早早餐 (攻頂前)
  @JsonValue('pre_breakfast')
  preBreakfast,

  /// 早餐
  @JsonValue('breakfast')
  breakfast,

  /// 午餐
  @JsonValue('lunch')
  lunch,

  /// 下午點心
  @JsonValue('teatime')
  teatime,

  /// 晚餐
  @JsonValue('dinner')
  dinner,

  /// 行動糧
  @JsonValue('action')
  action,

  /// 緊急/備用糧
  @JsonValue('emergency')
  emergency;

  String get label {
    switch (this) {
      case MealType.preBreakfast:
        return '早早餐';
      case MealType.breakfast:
        return '早餐';
      case MealType.lunch:
        return '午餐';
      case MealType.teatime:
        return '下午點心';
      case MealType.dinner:
        return '晚餐';
      case MealType.action:
        return '行動糧';
      case MealType.emergency:
        return '緊急/備用糧';
    }
  }
}
