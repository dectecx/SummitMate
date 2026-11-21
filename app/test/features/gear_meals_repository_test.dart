import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/core/db/app_database.dart';
import 'package:summitmate/core/sync/outbox_writer.dart';
import 'package:summitmate/features/gear/data/gear_repository.dart';
import 'package:summitmate/features/meals/data/meal_repository.dart';
import 'package:summitmate/features/trips/data/trip_repository.dart';

import '../core/support.dart';

void main() {
  late AppDatabase db;
  late TripRepository trips;
  late GearRepository gear;
  late MealRepository meals;
  late String trip;

  setUp(() async {
    db = memoryDb();
    final writer = OutboxWriter(db);
    trips = TripRepository(db, writer);
    gear = GearRepository(db, writer);
    meals = MealRepository(db, writer);
    trip = await trips.create(name: 't', start: DateTime(2026, 5, 1), end: DateTime(2026, 5, 2));
    await db.delete(db.outbox).go(); // pretend the trip was uploaded
  });
  tearDown(() => db.close());

  group('gear', () {
    test('adding gear numbers items in the order they were added and queues the creation', () async {
      final a = await gear.add(trip, name: '睡袋', weight: 900, category: 'sleep');
      final b = await gear.add(trip, name: '爐頭', weight: 380, category: 'cook', quantity: 2);

      final rows = await db.select(db.gearItems).get();
      expect(rows.map((r) => [r.name, r.sortOrder, r.quantity, r.isChecked]), [['睡袋', 0, 1, false], ['爐頭', 1, 2, false]]);
      expect(await opSummary(db), ['upsert:gear_items/$a', 'upsert:gear_items/$b']);
      final op = (await db.select(db.outbox).get()).first;
      expect(op.isCreate, isTrue);
      expect(patchOf(op), {'trip_id': trip, 'name': '睡袋', 'weight': 900.0, 'category': 'sleep', 'quantity': 1, 'is_checked': false, 'sort_order': 0});
    });

    test('ticking, editing and deleting', () async {
      final id = await gear.add(trip, name: 'x', weight: 10);
      await db.delete(db.outbox).go();

      await gear.update(id, isChecked: true);
      await gear.update(id, name: 'y', quantity: 3);
      expect((await db.select(db.gearItems).get()).single.isChecked, isTrue);
      final op = (await db.select(db.outbox).get()).single; // merged into one op
      expect(patchOf(op), {'is_checked': true, 'name': 'y', 'quantity': 3});

      await db.delete(db.outbox).go();
      await gear.delete(id);
      expect(await select(db, 'SELECT id FROM gear_items'), isEmpty);
      expect(await opSummary(db), ['delete:gear_items/$id']);
    });

    test('gear of the sample trip is never queued', () async {
      final sample = await trips.createSample(today: DateTime(2026, 5, 1));
      expect(await select(db, "SELECT id FROM gear_items WHERE trip_id = '$sample'"), isNotEmpty, reason: 'the sample comes with a packing list');
      await gear.add(sample, name: 'extra');
      expect(await opSummary(db), isEmpty);
    });
  });

  group('meals', () {
    test('the first meal of a day creates the plan day before the meal; later meals reuse it', () async {
      final a = await meals.add(trip, dayIndex: 1, name: '飯糰', mealType: 'lunch', weight: 180, calories: 320, quantity: 2);
      final ops = await opSummary(db);
      expect(ops, hasLength(2));
      expect(ops[0], startsWith('upsert:meal_plan_days/'));
      expect(ops[1], 'upsert:meal_items/$a');

      await meals.add(trip, dayIndex: 1, name: '泡麵');
      await meals.add(trip, dayIndex: 2, name: '燕麥');
      expect(await select(db, 'SELECT day_index FROM meal_plan_days ORDER BY day_index'), [{'day_index': 1}, {'day_index': 2}]);

      final item = (await db.select(db.outbox).get()).firstWhere((o) => o.entityId == a);
      final dayId = (await db.select(db.mealPlanDays).get()).firstWhere((d) => d.dayIndex == 1).id;
      expect(patchOf(item), containsPair('meal_plan_day_id', dayId));
    });

    test('watching returns each meal with its day', () async {
      await meals.add(trip, dayIndex: 1, name: 'a', calories: 100, quantity: 2);
      await meals.add(trip, dayIndex: 2, name: 'b');
      final entries = await meals.watch(trip).first;
      expect(entries.map((e) => [e.item.name, e.dayIndex]), unorderedEquals([['a', 1], ['b', 2]]));
      expect(entries.firstWhere((e) => e.item.name == 'a').calories, 200);
    });

    test('editing and deleting a meal', () async {
      final id = await meals.add(trip, dayIndex: 1, name: 'x');
      await db.delete(db.outbox).go();
      await meals.update(id, name: 'y', calories: 50);
      expect(patchOf((await db.select(db.outbox).get()).single), {'name': 'y', 'calories': 50.0});
      await db.delete(db.outbox).go();
      await meals.delete(id);
      expect(await opSummary(db), ['delete:meal_items/$id']);
    });

    test('deleting the trip removes the whole plan and uploads only the trip deletion', () async {
      await meals.add(trip, dayIndex: 1, name: 'x');
      await gear.add(trip, name: 'g');
      await db.delete(db.outbox).go();
      await trips.delete(trip);
      expect(await select(db, 'SELECT id FROM meal_items'), isEmpty);
      expect(await select(db, 'SELECT id FROM meal_plan_days'), isEmpty);
      expect(await select(db, 'SELECT id FROM gear_items'), isEmpty);
      expect(await opSummary(db), ['delete:trips/$trip']);
    });
  });
}
