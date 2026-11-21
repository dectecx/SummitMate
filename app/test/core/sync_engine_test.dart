import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/core/db/app_database.dart';
import 'package:summitmate/core/sync/local_store.dart';
import 'package:summitmate/core/sync/outbox_writer.dart';
import 'package:summitmate/core/sync/sync_api.dart';
import 'package:summitmate/core/sync/sync_engine.dart';
import 'package:summitmate/core/sync/sync_entity.dart';

import 'support.dart';

void main() {
  late AppDatabase db;
  late OutboxWriter writer;
  late LocalStore store;
  late FakeServer server;
  late FakeGate gate;
  late SyncEngine engine;
  var authFailures = 0;

  setUp(() {
    db = memoryDb();
    writer = OutboxWriter(db);
    store = LocalStore(db);
    server = FakeServer();
    gate = FakeGate();
    authFailures = 0;
    engine = SyncEngine(db: db, api: server, gate: gate, pullLimit: 200, onAuthFailure: () => authFailures++);
  });
  tearDown(() async {
    await engine.dispose();
    await db.close();
  });

  test('guests are not synced and nothing is attempted', () async {
    gate.canSync = false;
    await localCreate(db, writer, tripsEntity, tripRow('t1'));

    expect(await engine.sync(), SyncOutcome.skipped);

    expect(server.pushLog, isEmpty);
    expect(server.pullCalls, 0);
    expect(await opSummary(db), ['upsert:trips/t1'], reason: 'the guest data waits in the outbox');
  });

  test('guest data created before signing in is uploaded afterwards', () async {
    gate.canSync = false;
    await localCreate(db, writer, tripsEntity, tripRow('t1', name: 'Made offline'));
    await localCreate(db, writer, itineraryItemsEntity, itemRow('i1', 't1'));

    gate.canSync = true;
    expect(await engine.sync(), SyncOutcome.success);

    expect(await opSummary(db), isEmpty);
    expect(server.row('trips', 't1')!['name'], 'Made offline');
    expect(server.row('itinerary_items', 'i1'), isNotNull);
    expect(await select(db, 'SELECT owner_id FROM trips'), [
      {'owner_id': 'u1'},
    ], reason: 'the server confirmed the owner');
  });

  test('operations are sent in the order they were made', () async {
    await localCreate(db, writer, tripsEntity, tripRow('t1'));
    await localCreate(db, writer, itineraryItemsEntity, itemRow('i1', 't1'));
    await localCreate(db, writer, gearItemsEntity, gearRow('g1', 't1'));
    await engine.sync();
    expect(server.pushLog.single.map((o) => '${o.entity}/${o.entityId}'), ['trips/t1', 'itinerary_items/i1', 'gear_items/g1']);
  });

  test('a lost response is retried with the same op id and is applied only once', () async {
    await localCreate(db, writer, tripsEntity, tripRow('t1'));
    final opId = (await db.select(db.outbox).get()).single.opId;
    server.failNextPush = const SyncNetworkException('connection reset');

    expect(await engine.sync(), SyncOutcome.retryLater);
    final afterFailure = (await db.select(db.outbox).get()).single;
    expect(afterFailure.state, 'pending');
    expect(afterFailure.sent, isTrue);
    expect(afterFailure.attempts, 1);
    expect(engine.consecutiveFailures, 1);
    expect(engine.retryDelay, const Duration(seconds: 1));

    expect(await engine.sync(), SyncOutcome.success);
    expect(await opSummary(db), isEmpty);
    expect(server.pushLog.map((b) => b.single.opId), [opId, opId]);
    expect(server.rows['trips']!.length, 1);
    expect(engine.consecutiveFailures, 0);
  });

  test('a rejected op is marked failed and does not block the others', () async {
    await localCreate(db, writer, tripsEntity, tripRow('t1'));
    await localCreate(db, writer, gearItemsEntity, gearRow('g1', 't1'));
    server.forbiddenEntities.add('gear_items');

    expect(await engine.sync(), SyncOutcome.success);

    expect(await opSummary(db), ['upsert:gear_items/g1:failed']);
    final failed = (await db.select(db.outbox).get()).single;
    expect(failed.lastError, contains('forbidden'));
    expect(server.row('trips', 't1'), isNotNull);

    // Failed ops are not retried automatically.
    server.pushLog.clear();
    await engine.sync();
    expect(server.pushLog, isEmpty);
  });

  test('a 401 asks the auth layer to sign in again and keeps the data', () async {
    await localCreate(db, writer, tripsEntity, tripRow('t1'));
    server.failNextPush = const SyncAuthException();

    expect(await engine.sync(), SyncOutcome.needsReauth);

    expect(authFailures, 1);
    expect(await opSummary(db), ['upsert:trips/t1']);
    expect(await select(db, 'SELECT id FROM trips'), hasLength(1));
  });

  test('server errors back off; client errors fail the batch instead of looping', () async {
    await localCreate(db, writer, tripsEntity, tripRow('t1'));
    server.failNextPush = const SyncServerException(503);
    expect(await engine.sync(), SyncOutcome.retryLater);
    expect(await opSummary(db), ['upsert:trips/t1']);

    server.failNextPush = const SyncServerException(400, message: 'bad');
    await expectLater(engine.sync(), throwsA(isA<SyncServerException>()));
    expect(await opSummary(db), ['upsert:trips/t1:failed']);
  });

  test('backoff doubles and is capped at five minutes', () {
    expect([for (var i = 0; i <= 4; i++) SyncEngine.backoffFor(i).inSeconds], [0, 1, 2, 4, 8]);
    expect(SyncEngine.backoffFor(20), const Duration(minutes: 5));
  });

  test('an edit made while a request is in flight is not lost', () async {
    await localCreate(db, writer, tripsEntity, tripRow('t1', name: 'v1'));
    server.onPushApplied = () => localEdit(db, writer, tripsEntity, 't1', {'name': 'v2'});

    await engine.sync();

    // The first request carried v1; the edit was queued under a new op id and sent in the next batch
    // of the same run, so the server ends up with v2 and nothing is left over.
    expect(server.pushLog, hasLength(2));
    expect(server.pushLog[0].single.patch!['name'], 'v1');
    expect(server.pushLog[1].single.patch!['name'], 'v2');
    expect(server.pushLog[1].single.opId, isNot(server.pushLog[0].single.opId));
    expect(await opSummary(db), isEmpty);
    expect(server.row('trips', 't1')!['name'], 'v2');
    expect((await select(db, 'SELECT name FROM trips')).single['name'], 'v2');
  });

  test('changes from other devices are pulled, including tombstones', () async {
    server.serverEdit('trips', 't1', tripRow('t1', ownerId: 'u2', name: 'Shared trip'));
    server.serverEdit('itinerary_items', 'i1', itemRow('i1', 't1'));
    server.serverEdit('itinerary_items', 'i2', itemRow('i2', 't1'));
    await engine.sync();
    expect(await select(db, 'SELECT id FROM itinerary_items ORDER BY id'), [
      {'id': 'i1'},
      {'id': 'i2'},
    ]);

    server.serverDelete('itinerary_items', 'i1');
    await engine.sync();
    expect(await select(db, 'SELECT id FROM itinerary_items'), [
      {'id': 'i2'},
    ]);
  });

  test('a delete of something already gone on the server just cleans up', () async {
    await store.upsertFromServer(tripsEntity, tripRow('t1'));
    await store.upsertFromServer(itineraryItemsEntity, itemRow('i1', 't1'));
    await localDelete(db, writer, itineraryItemsEntity, 'i1');
    // The server never heard of i1.
    await engine.sync();
    expect(await opSummary(db), isEmpty);
  });

  test('an edit to something deleted elsewhere removes it locally', () async {
    server.serverEdit('trips', 't1', tripRow('t1', ownerId: 'u1'));
    server.serverEdit('itinerary_items', 'i1', itemRow('i1', 't1'));
    await engine.sync();
    await localEdit(db, writer, itineraryItemsEntity, 'i1', {'name': 'edit offline'});
    server.serverDelete('itinerary_items', 'i1');

    await engine.sync();

    expect(await opSummary(db), isEmpty);
    expect(await select(db, 'SELECT id FROM itinerary_items'), isEmpty);
  });

  test('pagination pulls everything and the cursor is the server string', () async {
    final small = SyncEngine(db: db, api: server, gate: gate, pullLimit: 2);
    server.serverEdit('trips', 't1', tripRow('t1', ownerId: 'u1'));
    for (var i = 0; i < 5; i++) {
      server.serverEdit('itinerary_items', 'i$i', itemRow('i$i', 't1'));
    }

    await small.sync();

    expect(await select(db, 'SELECT id FROM itinerary_items'), hasLength(5));
    expect(server.pullCalls, greaterThan(1));
    expect((await db.select(db.appMeta).getSingle()).syncCursor, server.clock.toIso8601String());
    await small.dispose();
  });

  test('the first pull of a run starts slightly before the stored cursor', () async {
    server.serverEdit('trips', 't1', tripRow('t1', ownerId: 'u1'));
    await engine.sync();
    final cursor = DateTime.parse((await db.select(db.appMeta).getSingle()).syncCursor!);

    server.pullSinceLog.clear();
    await engine.sync();

    expect(DateTime.parse(server.pullSinceLog.first!), cursor.subtract(const Duration(seconds: 5)));
  });

  test('concurrent sync calls share one run', () async {
    await localCreate(db, writer, tripsEntity, tripRow('t1'));
    final a = engine.sync();
    final b = engine.sync();
    expect(identical(a, b), isTrue);
    await Future.wait([a, b]);
    expect(server.pushLog, hasLength(1));
    expect(server.pullCalls, 1);
    expect(engine.isRunning, isFalse);
  });

  test('running state is announced', () async {
    final events = <bool>[];
    final sub = engine.running.listen(events.add);
    await engine.sync();
    await pumpEventQueue();
    await sub.cancel();
    expect(events, [true, false]);
  });

  test('last sync time is recorded only after a full successful run', () async {
    server.failNextPull = const SyncNetworkException();
    await engine.sync();
    expect((await db.select(db.appMeta).getSingle()).lastSyncedAt, isNull);
    await engine.sync();
    expect((await db.select(db.appMeta).getSingle()).lastSyncedAt, isNotNull);
  });

  test('a push edit does not overwrite a newer pending edit when the server row comes back', () async {
    await localCreate(db, writer, tripsEntity, tripRow('t1', name: 'A'));
    server.onPushApplied = () => localEdit(db, writer, tripsEntity, 't1', {'description': 'typed meanwhile'});
    await engine.sync();
    expect((await select(db, 'SELECT name, description FROM trips')).single, {'name': 'A', 'description': 'typed meanwhile'});
  });
}
