// End-to-end check of the sync stack against a running backend.
// Skipped unless E2E_BASE_URL (e.g. http://localhost:8080/api/v1) and E2E_TOKEN (a valid access
// token) are set. See backend/README.md for how to start the backend.
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/core/db/app_database.dart';
import 'package:summitmate/core/sync/dio_sync_api.dart';
import 'package:summitmate/core/sync/outbox_writer.dart';
import 'package:summitmate/core/sync/sync_engine.dart';
import 'package:summitmate/core/sync/sync_entity.dart';
import 'package:summitmate/features/events/data/events_api.dart';
import 'package:summitmate/features/library/data/shared_sets_api.dart';
import 'package:summitmate/features/library/domain/set_item.dart';
import 'package:uuid/uuid.dart';

import '../core/support.dart';

void main() {
  final baseUrl = Platform.environment['E2E_BASE_URL'];
  final token = Platform.environment['E2E_TOKEN'];
  final enabled = baseUrl != null && token != null;

  late AppDatabase dbA, dbB;
  late OutboxWriter writerA, writerB;
  late SyncEngine engineA, engineB;

  setUp(() {
    if (!enabled) return;
    final dio = Dio(BaseOptions(baseUrl: baseUrl, headers: {'Authorization': 'Bearer $token'}, validateStatus: (s) => s != null && s < 400));
    dbA = memoryDb();
    dbB = memoryDb();
    writerA = OutboxWriter(dbA);
    writerB = OutboxWriter(dbB);
    engineA = SyncEngine(db: dbA, api: DioSyncApi(dio), gate: FakeGate());
    engineB = SyncEngine(db: dbB, api: DioSyncApi(dio), gate: FakeGate());
  });
  tearDown(() async {
    if (!enabled) return;
    await engineA.dispose();
    await engineB.dispose();
    await dbA.close();
    await dbB.close();
  });

  test('two devices converge through the real server', () async {
    const uuid = Uuid();
    final trip = uuid.v7(), item = uuid.v7(), gear = uuid.v7();

    // Device A creates a trip offline and syncs.
    await localCreate(dbA, writerA, tripsEntity, tripRow(trip, name: 'E2E trip'));
    await localCreate(dbA, writerA, itineraryItemsEntity, itemRow(item, trip, name: 'Start'));
    await localCreate(dbA, writerA, gearItemsEntity, gearRow(gear, trip, name: 'Tent'));
    expect(await engineA.sync(), SyncOutcome.success);
    expect(await opSummary(dbA), isEmpty);
    expect((await select(dbA, 'SELECT owner_id FROM trips')).single['owner_id'], isNotNull);

    // Device B (same account) pulls everything, including the owner membership row.
    expect(await engineB.sync(), SyncOutcome.success);
    expect((await select(dbB, 'SELECT name FROM trips')).single['name'], 'E2E trip');
    expect((await select(dbB, 'SELECT name FROM itinerary_items')).single['name'], 'Start');
    expect((await select(dbB, 'SELECT role FROM trip_members')).single['role'], 'owner');
    expect((await select(dbB, 'SELECT name FROM gear_items')).single['name'], 'Tent');

    // Both devices edit different fields of the same item while apart.
    await localEdit(dbA, writerA, itineraryItemsEntity, item, {'name': 'Trailhead'});
    await localEdit(dbB, writerB, itineraryItemsEntity, item, {'altitude': 2300});
    await engineA.sync();
    await engineB.sync();
    await engineA.sync();
    for (final db in [dbA, dbB]) {
      expect((await select(db, 'SELECT name, altitude FROM itinerary_items')).single, {'name': 'Trailhead', 'altitude': 2300});
    }

    // A deletes the item; B learns about it.
    await localDelete(dbA, writerA, itineraryItemsEntity, item);
    await engineA.sync();
    await engineB.sync();
    expect(await select(dbB, 'SELECT id FROM itinerary_items'), isEmpty);

    // Deleting the trip removes it everywhere.
    await localDelete(dbA, writerA, tripsEntity, trip);
    await engineA.sync();
    await engineB.sync();
    expect(await select(dbB, 'SELECT id FROM trips'), isEmpty);
    expect(await select(dbB, 'SELECT id FROM gear_items'), isEmpty);
    expect(await opSummary(dbA), isEmpty);
  }, skip: enabled ? false : 'set E2E_BASE_URL and E2E_TOKEN');

  test('library items and templates converge through the real server', () async {
    const uuid = Uuid();
    final lib = uuid.v7(), tpl = uuid.v7();
    final items = encodeSetItems(const [SetItem(kind: 'gear', name: '睡袋', category: 'sleep', weight: 900), SetItem(kind: 'meal', name: '飯糰', category: 'lunch', weight: 180, calories: 320)]);

    await localCreate(dbA, writerA, libraryItemsEntity, {'id': lib, 'kind': 'gear', 'name': '頭燈', 'category': 'electronics', 'weight': 90.0, 'calories': 0.0, 'note': ''});
    await localCreate(dbA, writerA, templatesEntity, {'id': tpl, 'title': '兩天一夜', 'note': '', 'items': items});
    expect(await engineA.sync(), SyncOutcome.success);
    expect(await opSummary(dbA), isEmpty);

    expect(await engineB.sync(), SyncOutcome.success);
    expect((await select(dbB, 'SELECT name, weight FROM library_items')).single, {'name': '頭燈', 'weight': 90.0});
    final pulled = (await select(dbB, 'SELECT title, items FROM templates')).single;
    expect(pulled['title'], '兩天一夜');
    expect(decodeSetItems(pulled['items'] as String).map((i) => i.name), ['睡袋', '飯糰']);

    await localEdit(dbB, writerB, libraryItemsEntity, lib, {'weight': 95.0});
    await engineB.sync();
    await engineA.sync();
    expect((await select(dbA, 'SELECT weight FROM library_items')).single['weight'], 95.0);

    await localDelete(dbA, writerA, libraryItemsEntity, lib);
    await localDelete(dbA, writerA, templatesEntity, tpl);
    await engineA.sync();
    await engineB.sync();
    expect(await select(dbB, 'SELECT id FROM library_items'), isEmpty);
    expect(await select(dbB, 'SELECT id FROM templates'), isEmpty);
  }, skip: enabled ? false : 'set E2E_BASE_URL and E2E_TOKEN');

  test('a set is shared, listed, opened with its Key, and taken back through the real server', () async {
    final dio = Dio(BaseOptions(baseUrl: baseUrl!, headers: {'Authorization': 'Bearer $token'}, validateStatus: (s) => s != null && s < 400));
    final api = DioSharedSetsApi(dio);
    const items = [SetItem(kind: 'gear', name: '睡袋', category: 'sleep', weight: 900, quantity: 2), SetItem(kind: 'meal', name: '飯糰', category: 'lunch', weight: 180, calories: 320, day: 2)];
    final created = await api.create(title: 'E2E 組合', visibility: SharedVisibility.protected, key: 'e2ekey', items: items);
    try {
      expect([created.gearCount, created.mealCount, created.totalWeight, created.mine], [1, 1, 1800.0, true]);

      final mine = await api.list(scope: 'mine');
      expect(mine.items.map((s) => s.id), contains(created.id));
      final publicList = await api.list(scope: 'public');
      expect(publicList.items.map((s) => s.id), contains(created.id), reason: 'protected sets are listed');

      final owner = await api.get(created.id); // the owner needs no Key
      expect(owner.items.map((i) => i.name), ['睡袋', '飯糰']);
      expect(owner.items.last.day, 2);

      // Another person (no token) needs the Key.
      final anon = DioSharedSetsApi(Dio(BaseOptions(baseUrl: baseUrl, validateStatus: (s) => s != null && s < 400)));
      await expectLater(anon.get(created.id), throwsA(isA<SharedSetsException>().having((e) => e.needsKey, 'needsKey', isTrue)));
      await expectLater(anon.get(created.id, key: 'wrong'), throwsA(isA<SharedSetsException>().having((e) => e.wrongKey, 'wrongKey', isTrue)));
      expect((await anon.get(created.id, key: 'e2ekey')).summary.mine, isFalse);
    } finally {
      await api.delete(created.id);
    }
    await expectLater(api.get(created.id), throwsA(isA<SharedSetsException>().having((e) => e.code, 'code', 'shared_set_not_found')));
  }, skip: enabled ? false : 'set E2E_BASE_URL and E2E_TOKEN');

  test('group events: approval adds the applicant to the linked trip, removal takes them out again', () async {
    final token2 = Platform.environment['E2E_TOKEN_2']!;
    Dio dioFor(String tk) => Dio(BaseOptions(baseUrl: baseUrl!, headers: {'Authorization': 'Bearer $tk'}, validateStatus: (s) => s != null && s < 400));
    final apiA = DioEventsApi(dioFor(token!)), apiB = DioEventsApi(dioFor(token2));
    final dbOther = memoryDb();
    final engineOther = SyncEngine(db: dbOther, api: DioSyncApi(dioFor(token2)), gate: FakeGate());
    // The other device knows whose data it holds (the app sets this at sign-in); removal from a trip relies on it.
    final me = (await dioFor(token2).get<Map<String, dynamic>>('/auth/me')).data!;
    await dbOther.customStatement('UPDATE app_meta SET account_id = ? WHERE id = 1', [me['id']]);
    const uuid = Uuid();
    final trip = uuid.v7();
    String? eventId;
    try {
      await localCreate(dbA, writerA, tripsEntity, tripRow(trip, name: '揪團行程'));
      await localCreate(dbA, writerA, itineraryItemsEntity, itemRow(uuid.v7(), trip, name: '登山口'));
      expect(await engineA.sync(), SyncOutcome.success);

      final created = await apiA.create(
        EventInput(title: 'E2E 揪團', category: EventCategory.hiking, startDate: '2099-01-10', maxMembers: 3, privateMessage: '集合：車站 06:00', linkedTripId: trip),
      );
      eventId = created.id;
      expect(created.isHost, isTrue);
      expect(created.privateMessageLocked, isFalse);

      // The other person sees the event but not the secret, and does not have the trip yet.
      final seen = await apiB.get(created.id);
      expect([seen.privateMessageLocked, seen.privateMessage, seen.linkedTripId], [true, null, null]);
      expect(await engineOther.sync(), SyncOutcome.success);
      expect(await select(dbOther, 'SELECT id FROM trips'), isEmpty);

      expect(await apiB.apply(created.id, message: '我想參加'), ApplicationStatus.pending);
      final pending = await apiA.applications(created.id, status: ApplicationStatus.pending);
      expect(pending.single.message, '我想參加');
      await apiA.review(created.id, pending.single.id, approve: true);

      // Now the secret is unlocked and the trip arrives through the normal sync.
      expect((await apiB.get(created.id)).privateMessage, '集合：車站 06:00');
      expect(await engineOther.sync(), SyncOutcome.success);
      expect((await select(dbOther, 'SELECT name FROM trips')).single['name'], '揪團行程');
      expect((await select(dbOther, "SELECT role FROM trip_members WHERE role = 'member'")).length, 1);

      // Removing the member takes the trip away from them again.
      await apiA.removeMember(created.id, pending.single.id);
      expect(await engineOther.sync(), SyncOutcome.success);
      expect(await select(dbOther, 'SELECT id FROM trips'), isEmpty);
      expect((await apiB.get(created.id)).privateMessageLocked, isTrue);
    } finally {
      if (eventId != null) await apiA.cancel(eventId);
      await localDelete(dbA, writerA, tripsEntity, trip);
      await engineA.sync();
      await engineOther.dispose();
      await dbOther.close();
    }
  }, skip: enabled && Platform.environment['E2E_TOKEN_2'] != null ? false : 'set E2E_BASE_URL, E2E_TOKEN and E2E_TOKEN_2');
}
