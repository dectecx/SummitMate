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
}
