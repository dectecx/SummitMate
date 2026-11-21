import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/core/db/app_database.dart';
import 'package:summitmate/core/sync/local_store.dart';
import 'package:summitmate/core/sync/outbox_writer.dart';
import 'package:summitmate/core/sync/pull_applier.dart';
import 'package:summitmate/core/sync/sync_api.dart';
import 'package:summitmate/core/sync/sync_entity.dart';

import 'support.dart';

PullPage page(Map<String, List<Map<String, Object?>>> changes, {String next = '2026-01-01T12:00:10.123456Z'}) =>
    PullPage(serverTime: next, nextSince: next, hasMore: false, changes: changes);

void main() {
  late AppDatabase db;
  late OutboxWriter writer;
  late LocalStore store;
  late PullApplier applier;

  setUp(() {
    db = memoryDb();
    writer = OutboxWriter(db);
    store = LocalStore(db);
    applier = PullApplier(db);
  });
  tearDown(() => db.close());

  test('inserts rows parents first and stores the cursor verbatim', () async {
    await applier.applyPage(page({
      'itinerary_items': [itemRow('i1', 't1')],
      'trips': [tripRow('t1', ownerId: 'u1')],
    }, next: '2026-01-01T12:00:10.123456Z'));

    expect(await select(db, 'SELECT id, owner_id FROM trips'), [
      {'id': 't1', 'owner_id': 'u1'},
    ]);
    expect(await select(db, 'SELECT id FROM itinerary_items'), hasLength(1));
    expect((await db.select(db.appMeta).getSingle()).syncCursor, '2026-01-01T12:00:10.123456Z');
  });

  test('server rows may carry extra columns and the local-only flag survives an update', () async {
    await db.into(db.trips).insert(TripsCompanion.insert(id: 't1', name: 'x', startDate: '2026-01-01', isSample: const Value(true)));
    await applier.applyPage(page({
      'trips': [
        {...tripRow('t1', name: 'From server'), 'created_by': 'u9', 'updated_at': '2026-01-01T00:00:00Z', 'deleted_at': null},
      ],
    }));
    expect(await select(db, 'SELECT name, is_sample FROM trips'), [
      {'name': 'From server', 'is_sample': 1},
    ]);
  });

  test('pending local edits stay on top of server data; other fields update', () async {
    await store.upsertFromServer(tripsEntity, tripRow('t1', name: 'Old'));
    await localEdit(db, writer, tripsEntity, 't1', {'name': 'Local name'});

    await applier.applyPage(page({
      'trips': [
        {...tripRow('t1', name: 'Server name'), 'description': 'Server description'},
      ],
    }));

    expect(await select(db, 'SELECT name, description FROM trips'), [
      {'name': 'Local name', 'description': 'Server description'},
    ]);
  });

  test('an entity queued for deletion is not resurrected', () async {
    await store.upsertFromServer(tripsEntity, tripRow('t1'));
    await store.upsertFromServer(itineraryItemsEntity, itemRow('i1', 't1'));
    await localDelete(db, writer, itineraryItemsEntity, 'i1');

    await applier.applyPage(page({'itinerary_items': [itemRow('i1', 't1', name: 'back again')]}));

    expect(await select(db, 'SELECT id FROM itinerary_items'), isEmpty);
  });

  test('tombstones delete the row, and a trip tombstone takes its content along', () async {
    await store.upsertFromServer(tripsEntity, tripRow('t1'));
    await store.upsertFromServer(itineraryItemsEntity, itemRow('i1', 't1'));
    await store.upsertFromServer(gearItemsEntity, gearRow('g1', 't1'));

    await applier.applyPage(page({
      'itinerary_items': [{...itemRow('i1', 't1'), 'deleted_at': '2026-01-01T12:00:05Z'}],
    }));
    expect(await select(db, 'SELECT id FROM itinerary_items'), isEmpty);
    expect(await select(db, 'SELECT id FROM gear_items'), hasLength(1));

    await applier.applyPage(page({
      'trips': [{...tripRow('t1'), 'deleted_at': '2026-01-01T12:00:06Z'}],
    }));
    expect(await select(db, 'SELECT id FROM trips'), isEmpty);
    expect(await select(db, 'SELECT id FROM gear_items'), isEmpty);
  });

  test('being removed from a trip deletes it locally, removal of someone else does not', () async {
    await db.update(db.appMeta).write(const AppMetaCompanion(accountId: Value('me')));
    await store.upsertFromServer(tripsEntity, tripRow('t1'));
    await store.upsertFromServer(gearItemsEntity, gearRow('g1', 't1'));
    Map<String, Object?> member(String id, String user, {String? deleted}) => {
      'id': id, 'trip_id': 't1', 'user_id': user, 'role': 'member', 'display_name': user, 'avatar': '', 'deleted_at': deleted,
    };

    await applier.applyPage(page({'trip_members': [member('m-other', 'someone', deleted: '2026-01-01T12:00:05Z')]}));
    expect(await select(db, 'SELECT id FROM trips'), hasLength(1));

    await applier.applyPage(page({'trip_members': [member('m-me', 'me', deleted: '2026-01-01T12:00:06Z')]}));
    expect(await select(db, 'SELECT id FROM trips'), isEmpty);
    expect(await select(db, 'SELECT id FROM gear_items'), isEmpty);
  });

  test('rows whose parent is missing are skipped without error', () async {
    await applier.applyPage(page({
      'itinerary_items': [itemRow('i1', 'unknown-trip')],
      'gear_items': [gearRow('g1', 'unknown-trip')],
    }));
    expect(await select(db, 'SELECT id FROM itinerary_items'), isEmpty);
    expect(await select(db, 'SELECT id FROM gear_items'), isEmpty);
  });

  test('a bad value from the server aborts the page and leaves nothing half applied', () async {
    final bad = tripRow('t2')..['name'] = null;
    await expectLater(
      applier.applyPage(page({'trips': [tripRow('t1'), bad]}, next: 'NEW')),
      throwsFormatException,
    );
    expect(await select(db, 'SELECT id FROM trips'), isEmpty);
    expect((await db.select(db.appMeta).getSingle()).syncCursor, isNull);
  });

  test('stream queries see rows removed by cascade', () async {
    await store.upsertFromServer(tripsEntity, tripRow('t1'));
    await store.upsertFromServer(itineraryItemsEntity, itemRow('i1', 't1'));
    final seen = <int>[];
    final sub = db.select(db.itineraryItems).watch().listen((rows) => seen.add(rows.length));
    await pumpEventQueue();

    await applier.applyPage(page({'trips': [{...tripRow('t1'), 'deleted_at': '2026-01-01T12:00:06Z'}]}));
    await pumpEventQueue();
    await sub.cancel();

    expect(seen, [1, 0]);
  });
}
