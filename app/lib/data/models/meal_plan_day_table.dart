import 'package:drift/drift.dart';
import 'package:summitmate/domain/entities/meal_plan_day.dart';
import 'package:summitmate/infrastructure/database/app_database.dart';

import 'trip_table.dart';

@DataClassName('MealPlanDayEntity')
class MealPlanDaysTable extends Table {
  TextColumn get id => text()();
  TextColumn get tripId => text().references(TripsTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get linkedItineraryDay => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

extension MealPlanDayMapping on MealPlanDay {
  MealPlanDaysTableCompanion toCompanion(String tripId) {
    return MealPlanDaysTableCompanion.insert(
      id: id,
      tripId: tripId,
      name: name,
      linkedItineraryDay: Value(linkedItineraryDay),
      // createdAt & updatedAt will be handled by defaults/update logic if not explicitly provided here
    );
  }
}
