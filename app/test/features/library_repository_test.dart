import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/core/db/app_database.dart';
import 'package:summitmate/core/sync/outbox_writer.dart';
import 'package:summitmate/features/gear/data/gear_repository.dart';
import 'package:summitmate/features/library/data/library_repository.dart';
import 'package:summitmate/features/library/data/template_repository.dart';
import 'package:summitmate/features/library/domain/set_item.dart';
import 'package:summitmate/features/meals/data/meal_repository.dart';
import 'package:summitmate/features/trips/data/trip_repository.dart';

import '../core/support.dart';

void main() {
  late AppDatabase db;
  late LibraryRepository library;
  late TemplateRepository templates;
  late TripRepository trips;
  late GearRepository gear;
  late MealRepository meals;

  setUp(() {
    db = memoryDb();
    final w = OutboxWriter(db);
    library = LibraryRepository(db, w);
    gear = GearRepository(db, w);
    meals = MealRepository(db, w);
    templates = TemplateRepository(db, w, gear, meals);
    trips = TripRepository(db, w);
  });
  tearDown(() => db.close());

  group('set items', () {
    test('survive encoding, and broken or unknown entries are skipped', () {
      const items = [
        SetItem(kind: 'gear', name: '睡袋', category: 'sleep', weight: 900),
        SetItem(kind: 'meal', name: '飯糰', category: 'lunch', weight: 180, calories: 320, quantity: 2, day: 2, note: '加梅子'),
      ];
      final back = decodeSetItems(encodeSetItems(items));
      expect(back.map((i) => [i.kind, i.name, i.category, i.weight, i.quantity, i.calories, i.day, i.note]), [
        ['gear', '睡袋', 'sleep', 900.0, 1, 0.0, 1, ''],
        ['meal', '飯糰', 'lunch', 180.0, 2, 320.0, 2, '加梅子'],
      ]);
      expect(decodeSetItems('[{"kind":"gear","name":"A"},{"kind":"tent","name":"B"},{"kind":"gear"},3,{"kind":"gear","name":"  "}]').map((i) => i.name), ['A']);
      expect(decodeSetItems('not json'), isEmpty);
      expect(decodeSetItems('{"a":1}'), isEmpty);
      expect(decodeSetItems(null), isEmpty);
    });

    test('negative or odd numbers are cleaned, the count is capped, and totals count quantities', () {
      final odd = decodeSetItems('[{"kind":"gear","name":"A","weight":-5,"quantity":-1},{"kind":"meal","name":"M","day":0}]');
      expect([odd[0].weight, odd[0].quantity, odd[1].day], [0.0, 1, 1]);
      final many = [for (var i = 0; i < 400; i++) SetItem(kind: 'gear', name: 'g$i')];
      expect(decodeSetItems(encodeSetItems(many)).length, maxSetItems);
      const mixed = [SetItem(kind: 'gear', name: 'a', weight: 100, quantity: 2), SetItem(kind: 'gear', name: 'b', weight: 50), SetItem(kind: 'meal', name: 'm', weight: 999)];
      expect([gearWeightOf(mixed), gearCountOf(mixed), mealCountOf(mixed)], [250.0, 2, 1]);
    });
  });

  group('library', () {
    test('adding queues an upload; editing sends only what changed; deleting removes it', () async {
      final id = await library.add(kind: 'gear', name: '頭燈', category: 'electronics', weight: 90);
      expect(await opSummary(db), ['upsert:library_items/$id']);
      await db.delete(db.outbox).go();
      await library.update(id, weight: 100);
      expect(patchOf((await db.select(db.outbox).get()).single), {'weight': 100.0});
      await library.delete(id);
      expect(await db.select(db.libraryItems).get(), isEmpty);
    });

    test('remember adds an unknown name once (ignoring case) and leaves an existing entry alone', () async {
      expect(await library.remember(kind: 'gear', name: '睡袋', category: 'sleep', weight: 900), isTrue);
      expect(await library.remember(kind: 'gear', name: ' 睡袋 ', category: 'sleep', weight: 1000), isFalse);
      expect(await library.remember(kind: 'meal', name: '睡袋'), isTrue, reason: 'gear and food libraries are separate');
      expect(await library.remember(kind: 'gear', name: '   '), isFalse);
      final gearItems = await library.watch('gear').first;
      expect(gearItems.map((i) => [i.name, i.weight]), [['睡袋', 900.0]]);
    });
  });

  group('templates', () {
    test('a trip is saved as a template with its gear and meals, and applied to another trip', () async {
      final a = await trips.create(name: 'A', start: DateTime(2026, 5, 1), end: DateTime(2026, 5, 2));
      await gear.add(a, name: '睡袋', weight: 900, category: 'sleep');
      await gear.add(a, name: '爐頭', weight: 380, category: 'cook', quantity: 2);
      await meals.add(a, dayIndex: 1, name: '飯糰', mealType: 'lunch', weight: 180, calories: 320, quantity: 2);
      await meals.add(a, dayIndex: 2, name: '燕麥粥', mealType: 'breakfast', weight: 80, calories: 300);

      final id = await templates.saveTripAs(a, title: '兩天一夜');
      final saved = decodeSetItems((await db.select(db.templates).getSingle()).items);
      expect(saved.map((i) => '${i.kind}:${i.name}:${i.day}'), ['gear:睡袋:1', 'gear:爐頭:1', 'meal:飯糰:1', 'meal:燕麥粥:2']);

      final b = await trips.create(name: 'B', start: DateTime(2026, 6, 1), end: DateTime(2026, 6, 2));
      await gear.add(b, name: '睡袋', weight: 1200, category: 'sleep'); // already there
      final r = await templates.applyToTrip(b, saved);
      expect([r.gearAdded, r.gearSkipped, r.mealsAdded], [1, 1, 2]);
      final bGear = await (db.select(db.gearItems)..where((g) => g.tripId.equals(b))).get();
      expect(bGear.map((g) => [g.name, g.weight]), [['睡袋', 1200.0], ['爐頭', 380.0]], reason: 'the existing item is untouched');
      final bMeals = await meals.watch(b).first;
      expect(bMeals.map((m) => [m.item.name, m.dayIndex]), unorderedEquals([['飯糰', 1], ['燕麥粥', 2]]));

      await templates.update(id, title: '改名');
      expect((await db.select(db.templates).getSingle()).title, '改名');
      await templates.delete(id);
      expect(await db.select(db.templates).get(), isEmpty);
    });

    test('applying twice never duplicates gear', () async {
      final t = await trips.create(name: 'T', start: DateTime(2026, 5, 1));
      const items = [SetItem(kind: 'gear', name: '帳篷', category: 'sleep', weight: 1500)];
      await templates.applyToTrip(t, items);
      final again = await templates.applyToTrip(t, items);
      expect([again.gearAdded, again.gearSkipped], [0, 1]);
      expect((await db.select(db.gearItems).get()).length, 1);
    });
  });
}
