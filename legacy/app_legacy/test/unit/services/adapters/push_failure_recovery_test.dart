import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/core/error/result.dart';
import 'package:summitmate/data/datasources/interfaces/i_trip_remote_data_source.dart';
import 'package:summitmate/data/datasources/local/trip_dao.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/infrastructure/database/app_database.dart';
import 'package:summitmate/infrastructure/services/adapters/trip_sync_adapter.dart';

class _MockTripRemoteDataSource extends Mock implements ITripRemoteDataSource {}

/// 以真實的記憶體資料庫與真實的 TripSyncAdapter 驗證「推送失敗後重試」的流程。
///
/// 回歸情境：推送失敗過一次的資料，下一輪曾被直接標成 synced 而從未上傳。
void main() {
  late AppDatabase db;
  late TripDao localDataSource;
  late _MockTripRemoteDataSource remote;
  late TripSyncAdapter adapter;

  Trip newTrip(String id, {SyncStatus status = SyncStatus.pendingCreate, DateTime? cloudSyncedAt}) {
    final now = DateTime.utc(2026, 11, 21);
    return Trip(
      id: id,
      userId: 'u1',
      name: 'Trip $id',
      startDate: now,
      syncStatus: status,
      cloudSyncedAt: cloudSyncedAt,
      createdAt: now,
      createdBy: 'u1',
      updatedAt: now,
      updatedBy: 'u1',
    );
  }

  setUpAll(() => registerFallbackValue(newTrip('fallback')));

  Future<SyncStatus> statusOf(String id) async => (await localDataSource.getTripById(id))!.syncStatus;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    localDataSource = TripDao(db);
    remote = _MockTripRemoteDataSource();
    adapter = TripSyncAdapter(localDataSource, remote, db);
  });

  tearDown(() => db.close());

  group('TripSyncAdapter - push failure recovery (real database)', () {
    test(
      'Given an upload that fails then succeeds, When pushing twice, Then the trip is uploaded and then synced',
      () async {
        await localDataSource.addTrip(newTrip('t1'));
        var attempts = 0;
        when(() => remote.uploadTrip(any())).thenAnswer((_) async {
          attempts++;
          return attempts == 1 ? Failure(Exception('network down')) : const Success('t1');
        });

        final first = await adapter.pushPending();

        expect(first.isSuccess, isFalse);
        expect(await statusOf('t1'), SyncStatus.pendingCreate, reason: 'a failed push must keep the pending intent');

        final second = await adapter.pushPending();

        expect(second.isSuccess, isTrue);
        verify(() => remote.uploadTrip(any())).called(2);
        expect(await statusOf('t1'), SyncStatus.synced);
      },
    );

    test('Given repeated failures, When pushing several times, Then the item never becomes synced', () async {
      await localDataSource.addTrip(newTrip('t1'));
      when(() => remote.uploadTrip(any())).thenAnswer((_) async => Failure(Exception('server error')));

      for (var i = 0; i < 3; i++) {
        await adapter.pushPending();
      }

      expect(await statusOf('t1'), SyncStatus.pendingCreate);
      verify(() => remote.uploadTrip(any())).called(3);
    });

    test('Given a failed update, When pushing again, Then the update is retried rather than skipped', () async {
      final uploadedAt = DateTime.utc(2026, 11, 20);
      await localDataSource.addTrip(newTrip('t1', status: SyncStatus.pendingUpdate, cloudSyncedAt: uploadedAt));
      var attempts = 0;
      when(() => remote.uploadTrip(any())).thenAnswer((_) async {
        attempts++;
        return attempts == 1 ? Failure(Exception('timeout')) : const Success('t1');
      });

      await adapter.pushPending();
      expect(await statusOf('t1'), SyncStatus.pendingUpdate);

      await adapter.pushPending();
      expect(await statusOf('t1'), SyncStatus.synced);
      verify(() => remote.uploadTrip(any())).called(2);
    });

    test(
      'Given a trip deleted before it was ever uploaded, When pushing, Then it is removed locally without a remote call',
      () async {
        await localDataSource.addTrip(newTrip('t1', status: SyncStatus.pendingDelete));

        final result = await adapter.pushPending();

        expect(result.isSuccess, isTrue);
        expect(await localDataSource.getTripById('t1'), isNull);
        verifyNever(() => remote.deleteTrip(any()));
      },
    );

    test(
      'Given a trip deleted after upload, When the remote delete fails, Then it stays pending for the next cycle',
      () async {
        await localDataSource.addTrip(
          newTrip('t1', status: SyncStatus.pendingDelete, cloudSyncedAt: DateTime.utc(2026, 11, 20)),
        );
        when(() => remote.deleteTrip('t1')).thenAnswer((_) async => Failure(Exception('network down')));

        final result = await adapter.pushPending();

        expect(result.isSuccess, isFalse);
        expect(await statusOf('t1'), SyncStatus.pendingDelete);
      },
    );

    test(
      'Given a leftover item in an impossible state, When pushing, Then it fails loudly and is neither uploaded nor marked synced',
      () async {
        await db.customStatement(
          'INSERT INTO trips_table (id, user_id, name, start_date, is_active, created_at, created_by, updated_at, updated_by, sync_status) '
          "VALUES ('legacy', 'u1', 'Legacy', 1775563200, 0, 1775563200, 'u1', 1775563200, 'u1', 'error')",
        );

        final result = await adapter.pushPending();

        expect(result.isSuccess, isFalse);
        verifyNever(() => remote.uploadTrip(any()));
        expect(await statusOf('legacy'), SyncStatus.error);
      },
    );
  });
}
