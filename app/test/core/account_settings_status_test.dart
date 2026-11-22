import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/core/auth/auth_state.dart';
import 'package:summitmate/core/db/app_database.dart';
import 'package:summitmate/core/db/local_account.dart';
import 'package:summitmate/core/settings/app_settings.dart';
import 'package:summitmate/core/sync/local_store.dart';
import 'package:summitmate/core/sync/outbox_counts.dart';
import 'package:summitmate/core/sync/outbox_writer.dart';
import 'package:summitmate/core/sync/sync_entity.dart';
import 'package:summitmate/core/sync/sync_status.dart';
import 'package:summitmate/core/sync/vote_id.dart';

import 'support.dart';

const alice = AuthUser(id: 'alice', email: 'a@x.co', displayName: 'Alice', avatar: '🐻');
const bob = AuthUser(id: 'bob', email: 'b@x.co', displayName: 'Bob', avatar: '🦊');

void main() {
  late AppDatabase db;
  late OutboxWriter writer;
  late LocalAccountStore account;

  setUp(() {
    db = memoryDb();
    writer = OutboxWriter(db);
    account = LocalAccountStore(db);
  });
  tearDown(() => db.close());

  group('account', () {
    test('a fresh database is a guest', () async {
      expect((await account.read()).accountId, isNull);
    });

    test('signing in as a guest keeps the guest data and its pending uploads', () async {
      await localCreate(db, writer, tripsEntity, tripRow('t1'));

      final wiped = await account.onSignedIn(alice);

      expect(wiped, isFalse);
      expect((await account.read()).accountId, 'alice');
      expect(await select(db, 'SELECT id FROM trips'), hasLength(1));
      expect(await opSummary(db), ['upsert:trips/t1']);
    });

    test('signing in adopts what a guest wrote: messages get the author, votes are re-keyed with their upload', () async {
      final store = LocalStore(db);
      await store.upsertFromServer(tripsEntity, tripRow('t1'));
      await store.upsertFromServer(tripMessagesEntity, {'id': 'm1', 'trip_id': 't1', 'user_id': null, 'parent_id': null, 'body': 'hi', 'created_at': '2026-05-01T00:00:00Z'});
      await store.upsertFromServer(pollsEntity, {'id': 'p1', 'trip_id': 't1', 'title': 'P', 'description': '', 'deadline': null, 'allow_multiple': false, 'allow_add_option': false, 'blind': false, 'status': 'open', 'created_at': '2026-05-01T00:00:00Z'});
      await store.upsertFromServer(pollOptionsEntity, {'id': 'o1', 'poll_id': 'p1', 'trip_id': 't1', 'text': 'A', 'sort_order': 0, 'created_by': null});
      final guestVote = voteIdFor('o1', guestVoterId);
      await localCreate(db, writer, pollVotesEntity, {'id': guestVote, 'poll_id': 'p1', 'option_id': 'o1', 'trip_id': 't1', 'user_id': null, 'updated_at': '2026-05-01T00:00:00Z'});

      await account.onSignedIn(alice);

      final newId = voteIdFor('o1', 'alice');
      expect((await db.select(db.tripMessages).getSingle()).userId, 'alice');
      final vote = await db.select(db.pollVotes).getSingle();
      expect([vote.id, vote.userId], [newId, 'alice']);
      expect(await opSummary(db), ['upsert:poll_votes/$newId']);
    });

    test('signing in again as the same account changes nothing', () async {
      await account.onSignedIn(alice);
      await localCreate(db, writer, tripsEntity, tripRow('t1'));
      expect(await account.onSignedIn(alice), isFalse);
      expect(await select(db, 'SELECT id FROM trips'), hasLength(1));
    });

    test('signing in as someone else wipes the previous account\'s data first', () async {
      await account.onSignedIn(alice);
      await localCreate(db, writer, tripsEntity, tripRow('t1'));
      await LocalStore(db).upsertFromServer(itineraryItemsEntity, itemRow('i1', 't1'));
      await db.update(db.appMeta).write(const AppMetaCompanion(syncCursor: Value('2026-01-01T00:00:00Z')));

      expect(await account.onSignedIn(bob), isTrue);

      expect(await select(db, 'SELECT id FROM trips'), isEmpty);
      expect(await select(db, 'SELECT id FROM itinerary_items'), isEmpty);
      expect(await opSummary(db), isEmpty);
      final meta = await account.read();
      expect([meta.accountId, meta.syncCursor, meta.email], ['bob', null, 'b@x.co']);
    });

    test('resetting also clears messages, polls, votes and favorites', () async {
      final store = LocalStore(db);
      await store.upsertFromServer(tripsEntity, tripRow('t1'));
      await store.upsertFromServer(tripMessagesEntity, {'id': 'm1', 'trip_id': 't1', 'user_id': 'u', 'parent_id': null, 'body': 'hi', 'created_at': '2026-05-01T00:00:00Z'});
      await store.upsertFromServer(favoritesEntity, {'id': 'f1', 'kind': 'mountain', 'target_id': 'beidawu'});

      await account.resetLocalData();

      expect(await db.select(db.tripMessages).get(), isEmpty);
      expect(await db.select(db.favorites).get(), isEmpty);
    });

    test('resetting keeps app settings and returns the device to guest mode', () async {
      final settings = SettingsStore(db);
      await settings.setBool(SettingsStore.welcomeSeen, true);
      await account.onSignedIn(alice);
      await localCreate(db, writer, tripsEntity, tripRow('t1'));

      await account.resetLocalData();

      expect((await account.read()).accountId, isNull);
      expect(await select(db, 'SELECT id FROM trips'), isEmpty);
      expect(await settings.getBool(SettingsStore.welcomeSeen), isTrue);
      expect(await account.unsyncedCount(), 0);
    });
  });

  group('settings', () {
    test('values round-trip and hints are remembered once', () async {
      final s = SettingsStore(db);
      expect(await s.get('x'), isNull);
      await s.set('x', '1');
      await s.set('x', '2');
      expect(await s.get('x'), '2');
      await s.remove('x');
      expect(await s.get('x'), isNull);

      expect(await s.hasSeenHint('first-trip'), isFalse);
      await s.markHintSeen('first-trip');
      await s.markHintSeen('first-trip');
      await s.markHintSeen('gear');
      expect(await s.hasSeenHint('first-trip'), isTrue);
      expect(await s.hasSeenHint('gear'), isTrue);
      expect(await s.hasSeenHint('offline-map'), isFalse);

      await s.resetHints();
      expect(await s.hasSeenHint('first-trip'), isFalse);
    });
  });

  group('outbox counts', () {
    test('follow the outbox as it changes', () async {
      final seen = <OutboxCounts>[];
      final sub = watchOutboxCounts(db).listen(seen.add);
      await pumpEventQueue();

      await localCreate(db, writer, tripsEntity, tripRow('t1'));
      await localCreate(db, writer, tripsEntity, tripRow('t2'));
      await pumpEventQueue();
      final first = (await db.select(db.outbox).get()).first;
      await (db.update(db.outbox)..where((o) => o.seq.equals(first.seq))).write(const OutboxCompanion(state: Value('failed')));
      await pumpEventQueue();
      await sub.cancel();

      expect(seen.first, (pending: 0, failed: 0));
      expect(seen.last, (pending: 1, failed: 1));
    });
  });

  group('sync status', () {
    SyncStatus status({AuthState auth = const SignedIn(alice), int pending = 0, int failed = 0, bool syncing = false, bool online = true}) =>
        computeSyncStatus(auth: auth, pending: pending, failed: failed, syncing: syncing, online: online);

    test('guests only ever see local-only, whatever is queued', () {
      expect(status(auth: const Guest(), pending: 3, syncing: true), isA<GuestLocalOnly>());
    });

    test('an expired session shows up even when everything is synced', () {
      expect(status(auth: const NeedsReauth(alice)), isA<SessionExpired>());
    });

    test('signed-in states', () {
      expect(status(), isA<Synced>());
      expect(status(syncing: true, pending: 2), isA<Syncing>());
      expect((status(pending: 2) as Pending).count, 2);
      expect((status(pending: 2, online: false) as Offline).pending, 2);
      expect((status(failed: 1, pending: 4) as Failed).count, 1);
      expect(status(online: false), isA<Synced>(), reason: 'nothing to upload, so being offline is not news');
    });
  });
}
