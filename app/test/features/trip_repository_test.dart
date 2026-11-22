import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/core/db/app_database.dart';
import 'package:summitmate/core/sync/outbox_writer.dart';
import 'package:summitmate/features/trips/data/itinerary_repository.dart';
import 'package:summitmate/features/trips/data/trip_repository.dart';

import '../core/support.dart';

void main() {
  late AppDatabase db;
  late TripRepository trips;
  late ItineraryRepository items;

  setUp(() {
    db = memoryDb();
    final writer = OutboxWriter(db);
    trips = TripRepository(db, writer);
    items = ItineraryRepository(db, writer);
  });
  tearDown(() => db.close());

  test('creating a trip stores it and queues one upload', () async {
    final id = await trips.create(name: '嘉明湖', start: DateTime(2026, 5, 1), end: DateTime(2026, 5, 3), description: 'x');
    final t = (await db.select(db.trips).get()).single;
    expect([t.id, t.name, t.startDate, t.endDate, t.description, t.isSample], [id, '嘉明湖', '2026-05-01', '2026-05-03', 'x', false]);
    expect(await opSummary(db), ['upsert:trips/$id']);
    final op = (await db.select(db.outbox).get()).single;
    expect(op.isCreate, isTrue);
    expect(patchOf(op), {'name': '嘉明湖', 'description': 'x', 'start_date': '2026-05-01', 'end_date': '2026-05-03'});
  });

  test('the main mountain is stored, uploaded, and can be cleared', () async {
    final id = await trips.create(name: 'a', start: DateTime(2026, 5, 1), mountainId: 'yushan-main');
    expect((await db.select(db.trips).getSingle()).mountainId, 'yushan-main');
    expect(patchOf((await db.select(db.outbox).get()).single)['mountain_id'], 'yushan-main');

    await db.delete(db.outbox).go();
    await trips.update(id, mountainId: const Value(null));
    expect((await db.select(db.trips).getSingle()).mountainId, isNull);
    expect(patchOf((await db.select(db.outbox).get()).single), {'mountain_id': null});
  });

  test('an end date that is not after the start means a one-day trip', () async {
    await trips.create(name: 'a', start: DateTime(2026, 5, 1), end: DateTime(2026, 5, 1));
    await trips.create(name: 'b', start: DateTime(2026, 5, 1), end: DateTime(2026, 4, 1));
    expect((await db.select(db.trips).get()).map((t) => t.endDate), [null, null]);
  });

  test('updating changes only what was given, locally and in the upload', () async {
    final id = await trips.create(name: 'old', start: DateTime(2026, 5, 1), end: DateTime(2026, 5, 3));
    await trips.update(id, name: 'new', end: const Value(null));

    final t = (await db.select(db.trips).get()).single;
    expect([t.name, t.startDate, t.endDate], ['new', '2026-05-01', null]);
    // Merged into the pending creation: still one op, creation fields intact, end date cleared.
    final op = (await db.select(db.outbox).get()).single;
    expect(patchOf(op), containsPair('name', 'new'));
    expect(patchOf(op), containsPair('end_date', null));
    expect(patchOf(op), containsPair('start_date', '2026-05-01'));

    await trips.update(id); // nothing to change
    expect(await opSummary(db), hasLength(1));
  });

  test('deleting a trip that never reached the server leaves nothing to upload', () async {
    final id = await trips.create(name: 'a', start: DateTime(2026, 5, 1));
    await items.add(id, dayIndex: 1, name: 'start');
    await trips.delete(id);
    expect(await select(db, 'SELECT id FROM trips'), isEmpty);
    expect(await select(db, 'SELECT id FROM itinerary_items'), isEmpty);
    expect(await opSummary(db), isEmpty);
  });

  test('deleting a trip the server already has queues a single delete', () async {
    final id = await trips.create(name: 'a', start: DateTime(2026, 5, 1));
    await items.add(id, dayIndex: 1, name: 'start');
    await db.delete(db.outbox).go(); // pretend everything was uploaded
    await trips.delete(id);
    expect(await opSummary(db), ['delete:trips/$id']);
  });

  test('itinerary items are stored with the trip and queued', () async {
    final trip = await trips.create(name: 'a', start: DateTime(2026, 5, 1), end: DateTime(2026, 5, 2));
    final id = await items.add(trip, dayIndex: 1, name: '黑水塘', estMinutes: 570, altitude: 2700, distance: 2.1, note: 'n');

    final i = (await db.select(db.itineraryItems).get()).single;
    expect([i.name, i.dayIndex, i.estMinutes, i.altitude, i.distance, i.note], ['黑水塘', 1, 570, 2700, 2.1, 'n']);
    expect(await opSummary(db), containsAll(['upsert:trips/$trip', 'upsert:itinerary_items/$id']));
  });

  test('updating an item, clearing its time and checking in', () async {
    final trip = await trips.create(name: 'a', start: DateTime(2026, 5, 1));
    final id = await items.add(trip, dayIndex: 1, name: 'x', estMinutes: 60);
    await db.delete(db.outbox).go();

    await items.update(id, name: 'y', estMinutes: const Value(null), altitude: 100);
    var i = (await db.select(db.itineraryItems).get()).single;
    expect([i.name, i.estMinutes, i.altitude], ['y', null, 100]);
    expect(patchOf((await db.select(db.outbox).get()).single), {'name': 'y', 'est_minutes': null, 'altitude': 100});

    final when = DateTime.utc(2026, 5, 1, 7, 5);
    await items.update(id, checkedInAt: Value(when));
    i = (await db.select(db.itineraryItems).get()).single;
    expect(i.checkedInAt, when);
    expect(patchOf((await db.select(db.outbox).get()).single), containsPair('checked_in_at', '2026-05-01T07:05:00.000Z'));
  });

  test('deleting an item', () async {
    final trip = await trips.create(name: 'a', start: DateTime(2026, 5, 1));
    final id = await items.add(trip, dayIndex: 1, name: 'x');
    await db.delete(db.outbox).go();
    await items.delete(id);
    expect(await select(db, 'SELECT id FROM itinerary_items'), isEmpty);
    expect(await opSummary(db), ['delete:itinerary_items/$id']);
  });

  test('the sample trip is complete and never queued', () async {
    final id = await trips.createSample(today: DateTime(2026, 5, 1));
    final t = (await db.select(db.trips).get()).single;
    expect([t.isSample, t.startDate, t.endDate], [true, '2026-05-15', '2026-05-16']);
    expect((await db.select(db.itineraryItems).get()).length, 5);
    expect(await opSummary(db), isEmpty);

    // Editing it stays local too.
    final first = (await db.select(db.itineraryItems).get()).first;
    await items.update(first.id, name: 'edited');
    await trips.update(id, name: 'renamed');
    await items.add(id, dayIndex: 1, name: 'new');
    expect(await opSummary(db), isEmpty);
  });

  test('streams update when data changes', () async {
    final seen = <int>[];
    final sub = trips.watchAll().listen((l) => seen.add(l.length));
    await pumpEventQueue();
    final id = await trips.create(name: 'a', start: DateTime(2026, 5, 1));
    await pumpEventQueue();
    await trips.delete(id);
    await pumpEventQueue();
    await sub.cancel();
    expect(seen, [0, 1, 0]);
  });
}
