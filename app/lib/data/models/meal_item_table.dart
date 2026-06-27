import 'package:drift/drift.dart';
import 'converters/meal_type_converter.dart';
import 'meal_plan_day_table.dart';

@DataClassName('MealItemEntity')
class MealItemsTable extends Table {
  TextColumn get id => text()();
  TextColumn get dayId => text().references(MealPlanDaysTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get mealType => text().map(const MealTypeConverter())();
  TextColumn get name => text()();
  RealColumn get weight => real()();
  RealColumn get calories => real()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
