// ignore_for_file: prefer_initializing_formals

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/sync/outbox_writer.dart';
import '../domain/meal_logic.dart';

/// The signed-in person's own meal plan for a trip. Plan days are created on demand when the first
/// item of a day is added, so the UI never has to manage them.
class MealRepository {
  MealRepository(this._db, this._outbox, {Uuid uuid = const Uuid()}) : _uuid = uuid;
  final AppDatabase _db;
  final OutboxWriter _outbox;
  final Uuid _uuid;

  Stream<List<MealEntry>> watch(String tripId) {
    final query = _db.select(_db.mealItems).join([innerJoin(_db.mealPlanDays, _db.mealPlanDays.id.equalsExp(_db.mealItems.mealPlanDayId))])
      ..where(_db.mealItems.tripId.equals(tripId));
    return query.watch().map(
      (rows) => [for (final r in rows) MealEntry(r.readTable(_db.mealItems), r.readTable(_db.mealPlanDays).dayIndex)],
    );
  }

  /// [weight] is in grams, [calories] in kcal (both per unit).
  Future<String> add(
    String tripId, {
    required int dayIndex,
    required String name,
    String mealType = 'other',
    double weight = 0,
    double calories = 0,
    int quantity = 1,
    String note = '',
  }) async {
    final id = _uuid.v7();
    await _db.transaction(() async {
      final dayId = await _dayFor(tripId, dayIndex);
      await _db.into(_db.mealItems).insert(
        MealItemsCompanion.insert(
          id: id,
          tripId: tripId,
          mealPlanDayId: dayId,
          mealType: Value(mealType),
          name: Value(name),
          weight: Value(weight),
          calories: Value(calories),
          quantity: Value(quantity),
          note: Value(note),
        ),
      );
      await _outbox.upsert(
        'meal_items',
        id,
        {'trip_id': tripId, 'meal_plan_day_id': dayId, 'meal_type': mealType, 'name': name, 'weight': weight, 'calories': calories, 'quantity': quantity, 'note': note},
        isCreate: true,
      );
    });
    return id;
  }

  Future<String> _dayFor(String tripId, int dayIndex) async {
    final existing = await (_db.select(_db.mealPlanDays)..where((d) => d.tripId.equals(tripId) & d.dayIndex.equals(dayIndex))).getSingleOrNull();
    if (existing != null) return existing.id;
    final id = _uuid.v7();
    await _db.into(_db.mealPlanDays).insert(MealPlanDaysCompanion.insert(id: id, tripId: tripId, name: Value('D$dayIndex'), dayIndex: Value(dayIndex)));
    await _outbox.upsert('meal_plan_days', id, {'trip_id': tripId, 'name': 'D$dayIndex', 'day_index': dayIndex}, isCreate: true);
    return id;
  }

  Future<void> update(String id, {String? name, String? mealType, double? weight, double? calories, int? quantity, String? note}) async {
    final patch = <String, Object?>{
      'name': ?name,
      'meal_type': ?mealType,
      'weight': ?weight,
      'calories': ?calories,
      'quantity': ?quantity,
      'note': ?note,
    };
    if (patch.isEmpty) return;
    await _db.transaction(() async {
      await (_db.update(_db.mealItems)..where((m) => m.id.equals(id))).write(
        MealItemsCompanion(
          name: Value.absentIfNull(name),
          mealType: Value.absentIfNull(mealType),
          weight: Value.absentIfNull(weight),
          calories: Value.absentIfNull(calories),
          quantity: Value.absentIfNull(quantity),
          note: Value.absentIfNull(note),
        ),
      );
      await _outbox.upsert('meal_items', id, patch);
    });
  }

  Future<void> delete(String id) => _db.transaction(() async {
    await _outbox.delete('meal_items', id);
    await (_db.delete(_db.mealItems)..where((m) => m.id.equals(id))).go();
  });
}
