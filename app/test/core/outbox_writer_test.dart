import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/core/db/app_database.dart';
import 'package:summitmate/core/sync/local_store.dart';
import 'package:summitmate/core/sync/outbox_writer.dart';
import 'package:summitmate/core/sync/sync_entity.dart';

import 'support.dart';

void main() {
  late AppDatabase db;
  late OutboxWriter writer;
  late LocalStore store;

  setUp(() {
    db = memoryDb();
    writer = OutboxWriter(db);
    store = LocalStore(db);
  });
  tearDown(() => db.close());

  test('a local write and its outbox entry commit or roll back together', () async {
    await expectLater(
      db.transaction(() async {
        await store.upsertFromServer(tripsEntity, tripRow('t1'));
        await writer.upsert('trips', 't1', {'name': 'Trip', 'start_date': '2026-05-01'}, isCreate: true);
        throw StateError('boom');
      }),
      throwsStateError,
    );
    expect(await select(db, 'SELECT id FROM trips'), isEmpty);
    expect(await opSummary(db), isEmpty);

    await localCreate(db, writer, tripsEntity, tripRow('t1'));
    expect(await select(db, 'SELECT id FROM trips'), hasLength(1));
    expect(await opSummary(db), ['upsert:trips/t1']);
  });

  test('consecutive edits of one entity merge into a single op', () async {
    await localCreate(db, writer, tripsEntity, tripRow('t1'));
    final first = (await db.select(db.outbox).get()).single;

    await localEdit(db, writer, tripsEntity, 't1', {'name': 'Renamed'});
    await localEdit(db, writer, tripsEntity, 't1', {'description': 'x', 'name': 'Renamed again'});

    final ops = await db.select(db.outbox).get();
    expect(ops, hasLength(1));
    expect(ops.single.seq, first.seq);
    expect(ops.single.opId, first.opId, reason: 'unsent ops keep their idempotency key');
    expect(ops.single.isCreate, isTrue);
    expect(patchOf(ops.single), containsPair('name', 'Renamed again'));
    expect(patchOf(ops.single), containsPair('description', 'x'));
    expect(patchOf(ops.single), containsPair('start_date', '2026-05-01'), reason: 'creation fields survive');
  });

  test('editing an op that was already sent gives it a new op id', () async {
    await localCreate(db, writer, tripsEntity, tripRow('t1'));
    await (db.update(db.outbox)).write(const OutboxCompanion(sent: Value(true)));
    final before = (await db.select(db.outbox).get()).single;

    await localEdit(db, writer, tripsEntity, 't1', {'name': 'Edited while in flight'});

    final after = (await db.select(db.outbox).get()).single;
    expect(after.opId, isNot(before.opId));
    expect(after.sent, isTrue);
  });

  test('creating and deleting before any upload sends nothing', () async {
    await localCreate(db, writer, tripsEntity, tripRow('t1'));
    await localCreate(db, writer, itineraryItemsEntity, itemRow('i1', 't1'));
    await localDelete(db, writer, itineraryItemsEntity, 'i1');
    expect(await opSummary(db), ['upsert:trips/t1']);

    await localDelete(db, writer, tripsEntity, 't1');
    expect(await opSummary(db), isEmpty);
  });

  test('deleting something the server already has replaces its pending edit with a delete', () async {
    await store.upsertFromServer(tripsEntity, tripRow('t1'));
    await store.upsertFromServer(itineraryItemsEntity, itemRow('i1', 't1'));
    await localEdit(db, writer, itineraryItemsEntity, 'i1', {'name': 'edited'});
    expect(await opSummary(db), ['upsert:itinerary_items/i1']);

    await localDelete(db, writer, itineraryItemsEntity, 'i1');
    expect(await opSummary(db), ['delete:itinerary_items/i1']);

    // A second delete does not queue another.
    await writer.delete('itinerary_items', 'i1');
    expect(await opSummary(db), ['delete:itinerary_items/i1']);
  });

  test('deleting a creation that may already have reached the server still queues a delete', () async {
    await localCreate(db, writer, tripsEntity, tripRow('t1'));
    await (db.update(db.outbox)).write(const OutboxCompanion(sent: Value(true)));
    await localDelete(db, writer, tripsEntity, 't1');
    expect(await opSummary(db), ['delete:trips/t1']);
  });

  test('deleting a trip drops the pending work of its content', () async {
    await store.upsertFromServer(tripsEntity, tripRow('t1'));
    await store.upsertFromServer(itineraryItemsEntity, itemRow('i1', 't1'));
    await store.upsertFromServer(gearItemsEntity, gearRow('g1', 't1'));
    await localEdit(db, writer, itineraryItemsEntity, 'i1', {'name': 'x'});
    await localEdit(db, writer, gearItemsEntity, 'g1', {'name': 'y'});
    await localCreate(db, writer, itineraryItemsEntity, itemRow('i2', 't1'));

    await localDelete(db, writer, tripsEntity, 't1');

    expect(await opSummary(db), ['delete:trips/t1']);
    expect(await select(db, 'SELECT id FROM itinerary_items'), isEmpty, reason: 'cascade');
  });

  test('deleting a meal plan day also deletes its meal items on the server', () async {
    await store.upsertFromServer(tripsEntity, tripRow('t1'));
    await store.upsertFromServer(mealPlanDaysEntity, {'id': 'd1', 'trip_id': 't1', 'name': 'D1', 'day_index': 1});
    for (final id in ['m1', 'm2']) {
      await store.upsertFromServer(mealItemsEntity, {
        'id': id, 'trip_id': 't1', 'meal_plan_day_id': 'd1', 'meal_type': 'lunch', 'name': id,
        'weight': 0.1, 'calories': 100.0, 'quantity': 1, 'note': '',
      });
    }
    await localDelete(db, writer, mealPlanDaysEntity, 'd1');
    expect(await opSummary(db), unorderedEquals(['delete:meal_items/m1', 'delete:meal_items/m2', 'delete:meal_plan_days/d1']));
  });

  test('the sample trip and its content never enter the outbox', () async {
    await db.into(db.trips).insert(TripsCompanion.insert(id: 's1', name: 'Sample', startDate: '2026-01-01', isSample: const Value(true)));
    await store.upsertFromServer(itineraryItemsEntity, itemRow('i1', 's1'));
    await writer.upsert('trips', 's1', {'name': 'Edited sample'});
    await writer.upsert('itinerary_items', 'i1', {'name': 'x'});
    await writer.delete('itinerary_items', 'i1');
    await writer.delete('trips', 's1');
    expect(await opSummary(db), isEmpty);
  });

  test('programming mistakes are rejected loudly', () async {
    await expectLater(writer.upsert('trips', 't1', {'nope': 1}), throwsArgumentError);
    await expectLater(writer.upsert('unknown', 'x', {}), throwsArgumentError);
    await store.upsertFromServer(tripsEntity, tripRow('t1'));
    await writer.delete('trips', 't1');
    await expectLater(writer.upsert('trips', 't1', {'name': 'late'}), throwsStateError);
  });

  test('editing a failed op retries it; discarding a failed creation removes it with its content', () async {
    await localCreate(db, writer, tripsEntity, tripRow('t1'));
    await localCreate(db, writer, itineraryItemsEntity, itemRow('i1', 't1'));
    final tripOp = (await db.select(db.outbox).get()).firstWhere((o) => o.entity == 'trips');
    await (db.update(db.outbox)..where((o) => o.seq.equals(tripOp.seq))).write(const OutboxCompanion(state: Value('failed'), lastError: Value('invalid')));

    await localEdit(db, writer, tripsEntity, 't1', {'name': 'fixed'});
    var op = (await db.select(db.outbox).get()).firstWhere((o) => o.entity == 'trips');
    expect(op.state, 'pending');
    expect(op.lastError, isNull);

    await (db.update(db.outbox)..where((o) => o.seq.equals(op.seq))).write(const OutboxCompanion(state: Value('failed')));
    await writer.discardFailed(op.seq);
    expect(await opSummary(db), isEmpty);
    expect(await select(db, 'SELECT id FROM trips'), isEmpty);
    expect(await select(db, 'SELECT id FROM itinerary_items'), isEmpty);
  });

  test('discarding a failed edit resets the cursor so the server version comes back', () async {
    await store.upsertFromServer(tripsEntity, tripRow('t1'));
    await (db.update(db.appMeta)).write(const AppMetaCompanion(syncCursor: Value('2026-01-01T00:00:00Z')));
    await localEdit(db, writer, tripsEntity, 't1', {'name': 'bad edit'});
    final op = (await db.select(db.outbox).get()).single;
    await (db.update(db.outbox)).write(const OutboxCompanion(state: Value('failed')));

    await writer.discardFailed(op.seq);

    expect(await opSummary(db), isEmpty);
    expect((await db.select(db.appMeta).getSingle()).syncCursor, isNull);
  });

  test('retryFailed puts the op back in the queue', () async {
    await localCreate(db, writer, tripsEntity, tripRow('t1'));
    final op = (await db.select(db.outbox).get()).single;
    await (db.update(db.outbox)).write(const OutboxCompanion(state: Value('failed'), attempts: Value(3), lastError: Value('x')));
    await writer.retryFailed(op.seq);
    final after = (await db.select(db.outbox).get()).single;
    expect([after.state, after.attempts, after.lastError], ['pending', 0, null]);
  });
}
