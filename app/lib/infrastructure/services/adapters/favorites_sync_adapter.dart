import 'package:injectable/injectable.dart';
import '../../../core/error/result.dart';
import '../../../core/models/paginated_list.dart';
import '../../../domain/entities/favorite.dart';
import '../../../domain/enums/sync_status.dart';
import '../../../domain/interfaces/i_sync_adapter.dart';
import '../../../data/datasources/interfaces/i_favorites_local_data_source.dart';
import '../../../data/datasources/interfaces/i_favorites_remote_data_source.dart';
import '../../database/app_database.dart';
import 'base_sync_adapter.dart';

/// 最愛（C 模式）同步適配器。
///
/// 最愛以 `(targetId, type)` 為決定性身分（本地主鍵 `${type.name}_$targetId`），
/// 故不需 ID 遷移。取消最愛以墓碑（pendingDelete）表示，推送 unfavorite 後硬刪。
@lazySingleton
class FavoritesSyncAdapter extends BaseSyncAdapter<Favorite> {
  static const String _userScope = '__all_favorites__';

  final IFavoritesLocalDataSource _local;
  final IFavoritesRemoteDataSource _remote;

  @override
  final AppDatabase db;

  FavoritesSyncAdapter(this._local, this._remote, this.db);

  @override
  String get tableName => 'favorites_table';

  // ── Push ──
  @override
  Future<List<Favorite>> getLocalItems() => _local.getAllIncludingPending();

  @override
  Future<IdMigration?> pushOne(Favorite item) async {
    if (item.syncStatus == SyncStatus.pendingDelete) {
      final result = await _remote.updateFavorite(item.targetId, item.type, false);
      if (result is Failure<void, Exception>) throw result.exception;
      await _local.deleteById(item.id);
      return null;
    }
    final result = await _remote.updateFavorite(item.targetId, item.type, true);
    if (result is Failure<void, Exception>) throw result.exception;
    return null;
  }

  @override
  Future<void> migrateLocalId(String oldId, String newId) async {
    // 最愛主鍵為決定性，無 ID 遷移
  }

  // ── Pull ──
  @override
  Future<List<String>> resolveScopes() async => const [_userScope];

  @override
  Future<List<Favorite>> fetchRemote(String scope) async {
    final result = await _remote.getFavorites();
    if (result is Success<PaginatedList<Favorite>, Exception>) {
      // 正規化 id 為決定性主鍵，使 id-keyed 合併與本地一致
      return result.value.items.map((f) => f.copyWith(id: '${f.type.name}_${f.targetId}')).toList();
    }
    throw (result as Failure<PaginatedList<Favorite>, Exception>).exception;
  }

  @override
  Future<List<Favorite>> getLocalItemsForScope(String scope) => _local.getAllIncludingPending();

  @override
  Future<Favorite?> getLocalById(String id) => _local.getById(id);

  @override
  Future<void> upsertLocalSynced(Favorite remote, Favorite? local) =>
      _local.upsert(remote.copyWith(syncStatus: SyncStatus.synced));

  @override
  Future<void> markLocalConflict(Favorite local) => _local.upsert(local.copyWith(syncStatus: SyncStatus.conflict));

  @override
  Future<void> deleteLocal(String id) => _local.deleteById(id);
}
