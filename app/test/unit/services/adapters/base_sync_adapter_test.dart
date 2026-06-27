import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/domain/enums/sync_status.dart';
import 'package:summitmate/domain/interfaces/i_sync_adapter.dart';
import 'package:summitmate/domain/interfaces/i_syncable_entity.dart';
import 'package:summitmate/infrastructure/database/app_database.dart';
import 'package:summitmate/infrastructure/services/adapters/base_sync_adapter.dart';

class MockAppDatabase extends Mock implements AppDatabase {}

/// 測試用的可同步實體。
class _Entity implements SyncableEntity {
  @override
  final String id;
  @override
  final SyncStatus syncStatus;
  @override
  final DateTime? updatedAt;

  const _Entity(this.id, this.syncStatus, [this.updatedAt]);
}

/// 測試用的具體 adapter：記錄被推送/標記的項目，並以 hook 模擬遠端行為。
class _TestAdapter extends BaseSyncAdapter<_Entity> {
  @override
  final AppDatabase db;

  final List<_Entity> local;

  /// 回傳每個 id 對應的 ID 遷移（模擬後端配發永久 ID）。
  final Map<String, String> idMigrations;

  /// 推送時應拋錯的 id 集合。
  final Set<String> failingIds;

  final List<String> pushedOrder = [];
  final List<String> deletedLocally = [];

  _TestAdapter(
    this.db, {
    required this.local,
    this.idMigrations = const {},
    this.failingIds = const {},
  });

  @override
  String get tableName => 'test_table';

  @override
  Future<List<_Entity>> getLocalItems() async => local;

  @override
  Future<IdMigration?> pushOne(_Entity item) async {
    pushedOrder.add(item.id);
    if (failingIds.contains(item.id)) {
      throw Exception('push failed for ${item.id}');
    }
    if (item.syncStatus == SyncStatus.pendingDelete) {
      deletedLocally.add(item.id);
      return null;
    }
    final permanent = idMigrations[item.id];
    if (permanent != null) {
      return IdMigration(tempId: item.id, permanentId: permanent);
    }
    return null;
  }

  @override
  Future<void> migrateLocalId(String oldId, String newId) async {}

  // Pull hooks (unused in these tests)
  @override
  Future<List<String>> resolveScopes() async => const [];
  @override
  Future<List<_Entity>> fetchRemote(String scope) async => const [];
  @override
  Future<List<_Entity>> getLocalItemsForScope(String scope) async => const [];
  @override
  Future<_Entity?> getLocalById(String id) async => null;
  @override
  Future<void> upsertLocalSynced(_Entity remote, _Entity? localItem) async {}
  @override
  Future<void> markLocalConflict(_Entity localItem) async {}
  @override
  Future<void> deleteLocal(String id) async {}
}

void main() {
  late MockAppDatabase mockDb;

  setUp(() {
    mockDb = MockAppDatabase();
    when(() => mockDb.markAsSynced(any(), any())).thenAnswer((_) async {});
    when(() => mockDb.markAsError(any(), any())).thenAnswer((_) async {});
  });

  group('BaseSyncAdapter - pushPending', () {
    test('Given mixed pending items, When pushPending, Then it skips synced and marks the rest synced', () async {
      final adapter = _TestAdapter(
        mockDb,
        local: [
          const _Entity('a', SyncStatus.synced),
          const _Entity('b', SyncStatus.pendingCreate),
          const _Entity('c', SyncStatus.pendingUpdate),
        ],
      );

      final result = await adapter.pushPending();

      expect(result.pushedCount, 2);
      expect(result.isSuccess, isTrue);
      expect(adapter.pushedOrder, containsAll(['b', 'c']));
      expect(adapter.pushedOrder, isNot(contains('a')));
      verify(() => mockDb.markAsSynced('test_table', 'b')).called(1);
      verify(() => mockDb.markAsSynced('test_table', 'c')).called(1);
    });

    // 註：ID 遷移會將 migrateLocalId + markAsSynced 包在 db.transaction 內，
    // 該 transaction 內部寫入屬整合測試範疇；adapter 回傳 IdMigration 的對應邏輯
    // 已在各 adapter 的 pushOne 測試中覆蓋。

    test('Given a delete, When pushPending, Then it does not mark synced', () async {
      final adapter = _TestAdapter(
        mockDb,
        local: [const _Entity('d', SyncStatus.pendingDelete)],
      );

      final result = await adapter.pushPending();

      expect(result.pushedCount, 1);
      expect(adapter.deletedLocally, contains('d'));
      verifyNever(() => mockDb.markAsSynced('test_table', 'd'));
    });

    test('Given a failing push, When pushPending, Then it records error and marks as error', () async {
      final adapter = _TestAdapter(
        mockDb,
        local: [const _Entity('x', SyncStatus.pendingUpdate)],
        failingIds: {'x'},
      );

      final result = await adapter.pushPending();

      expect(result.isSuccess, isFalse);
      expect(result.errors, isNotEmpty);
      verify(() => mockDb.markAsError('test_table', 'x')).called(1);
    });

    test('Given deletes mixed with creates, When pushPending, Then deletes are pushed last', () async {
      final adapter = _TestAdapter(
        mockDb,
        local: [
          const _Entity('del', SyncStatus.pendingDelete),
          const _Entity('new', SyncStatus.pendingCreate),
        ],
      );

      await adapter.pushPending();

      expect(adapter.pushedOrder, ['new', 'del']);
    });
  });
}
