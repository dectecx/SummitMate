import 'package:drift/drift.dart';
import '../../../domain/enums/meal_type.dart';

/// Maps [MealType] to its JSON-value string for SQLite storage.
class MealTypeConverter extends TypeConverter<MealType, String> {
  const MealTypeConverter();

  static const _map = {
    MealType.preBreakfast: 'pre_breakfast',
    MealType.breakfast: 'breakfast',
    MealType.lunch: 'lunch',
    MealType.teatime: 'teatime',
    MealType.dinner: 'dinner',
    MealType.action: 'action',
    MealType.emergency: 'emergency',
  };

  @override
  MealType fromSql(String fromDb) {
    return _map.entries.firstWhere((e) => e.value == fromDb, orElse: () => _map.entries.first).key;
  }

  @override
  String toSql(MealType value) => _map[value]!;
}
