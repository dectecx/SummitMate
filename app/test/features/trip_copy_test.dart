import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:summitmate/core/db/app_database.dart';
import 'package:summitmate/core/sync/outbox_writer.dart';
import 'package:summitmate/features/gear/data/gear_repository.dart';
import 'package:summitmate/features/library/data/template_repository.dart';
import 'package:summitmate/features/meals/data/meal_repository.dart';
import 'package:summitmate/features/trips/data/itinerary_repository.dart';
import 'package:summitmate/features/trips/data/trip_copier.dart';
import 'package:summitmate/features/trips/data/trip_repository.dart';
import 'package:summitmate/features/trips/providers.dart';

import '../core/support.dart';
import 'harness.dart';

void main() {
  group('copier', () {
    late AppDatabase db;
    late TripRepository trips;
    late ItineraryRepository items;
    late GearRepository gear;
    late MealRepository meals;
    late TripCopier copier;

    setUp(() {
      db = memoryDb();
      final w = OutboxWriter(db);
      trips = TripRepository(db, w);
      items = ItineraryRepository(db, w);
      gear = GearRepository(db, w);
      meals = MealRepository(db, w);
      copier = TripCopier(trips, items, TemplateRepository(db, w, gear, meals));
    });
    tearDown(() => db.close());

    test('copies the plan with shifted dates, plus the gear and meals, and leaves the original alone', () async {
      final a = await trips.create(name: '嘉明湖', start: DateTime(2026, 5, 1), end: DateTime(2026, 5, 3), description: '備註', mountainId: 'jiaming', track: '[[23.3,121.0,2300]]');
      final node = await items.add(a, dayIndex: 1, name: '登山口', estMinutes: 420, altitude: 2300, distance: 0, lat: 23.3, lng: 121.0, note: '集合');
      await items.add(a, dayIndex: 2, name: '山屋', altitude: 2850, distance: 4.5);
      await items.update(node, checkedInAt: Value(DateTime(2026, 5, 1, 7)));
      await gear.add(a, name: '睡袋', weight: 900, category: 'sleep');
      final g = await (db.select(db.gearItems)).getSingle();
      await gear.update(g.id, isChecked: true);
      await meals.add(a, dayIndex: 2, name: '飯糰', mealType: 'lunch', weight: 180, calories: 320);

      final src = await (db.select(db.trips)..where((t) => t.id.equals(a))).getSingle();
      final b = await copier.copy(src, name: '嘉明湖（複製）', start: DateTime(2026, 9, 10));

      final copy = await (db.select(db.trips)..where((t) => t.id.equals(b))).getSingle();
      expect([copy.name, copy.startDate, copy.endDate, copy.description, copy.mountainId, copy.track], ['嘉明湖（複製）', '2026-09-10', '2026-09-12', '備註', 'jiaming', '[[23.3,121.0,2300]]']);
      final nodes = await (db.select(db.itineraryItems)..where((i) => i.tripId.equals(b))).get();
      expect(nodes.map((n) => [n.dayIndex, n.name, n.estMinutes, n.altitude, n.distance, n.note, n.checkedInAt]), unorderedEquals([[1, '登山口', 420, 2300, 0.0, '集合', null], [2, '山屋', null, 2850, 4.5, '', null]]));
      final copiedGear = await (db.select(db.gearItems)..where((x) => x.tripId.equals(b))).get();
      expect(copiedGear.map((x) => [x.name, x.isChecked]), [['睡袋', false]], reason: 'packed ticks start over');
      expect((await meals.watch(b).first).map((m) => [m.item.name, m.dayIndex]), [['飯糰', 2]]);

      expect((await (db.select(db.itineraryItems)..where((i) => i.tripId.equals(a))).get()).length, 2);
      expect((await (db.select(db.gearItems)..where((x) => x.tripId.equals(a))).get()).single.isChecked, isTrue, reason: 'the original keeps its ticks');
      expect((await db.select(db.tripMembers).get()), isEmpty, reason: 'members are not copied');
    });

    test('a one-day trip stays a one-day trip', () async {
      final a = await trips.create(name: '單日', start: DateTime(2026, 5, 1));
      final src = await (db.select(db.trips)..where((t) => t.id.equals(a))).getSingle();
      final b = await copier.copy(src, name: '單日 2', start: DateTime(2026, 6, 1));
      expect((await (db.select(db.trips)..where((t) => t.id.equals(b))).getSingle()).endDate, isNull);
    });
  });

  testWidgets('long-pressing a trip copies it from the dialog and opens the copy', (tester) async {
    final app = await AppHarness.start(tester, welcomeSeen: true, overrides: [clockProvider.overrideWithValue(() => DateTime(2026, 5, 10, 9))]);
    await act(tester, () => app.container.read(tripRepositoryProvider).create(name: '原行程', start: DateTime(2026, 6, 1), end: DateTime(2026, 6, 2)));
    await settle(tester);
    await tester.longPress(find.text('原行程'));
    await settle(tester);
    expect(find.text('複製行程'), findsOneWidget);
    expect(find.byKey(const ValueKey('copy-name')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('copy-confirm')));
    await settleUntil(tester, find.textContaining('已複製為'));
    final all = await real(tester, () => app.db.select(app.db.trips).get());
    expect(all.map((t) => t.name), unorderedEquals(['原行程', '原行程（複製）']));
    expect(all.firstWhere((t) => t.name == '原行程（複製）').startDate, '2026-06-01', reason: 'a future trip keeps its date');
    await app.dispose(tester);
  });

  testWidgets('the trip menu has the copy entry for a team member too', (tester) async {
    final app = await AppHarness.start(tester, welcomeSeen: true, overrides: [clockProvider.overrideWithValue(() => DateTime(2026, 5, 10, 9))]);
    await act(tester, () => app.container.read(tripRepositoryProvider).create(name: '選單', start: DateTime(2026, 6, 1)));
    await settle(tester);
    await tapText(tester, '選單');
    await tester.tap(find.byType(PopupMenuButton<String>));
    await settle(tester);
    expect(find.text('複製行程'), findsOneWidget);
    await app.dispose(tester);
  });
}
