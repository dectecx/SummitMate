import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import '../../../infrastructure/database/app_database.dart';
import '../interfaces/i_favorites_local_data_source.dart';
import '../../models/favorite_table.dart';
import '../../../domain/entities/favorite.dart';
import '../../../domain/enums/sync_status.dart';

part 'favorite_dao.g.dart';

@LazySingleton(as: IFavoritesLocalDataSource)
@DriftAccessor(tables: [FavoritesTable])
class FavoriteDao extends DatabaseAccessor<AppDatabase> with _$FavoriteDaoMixin implements IFavoritesLocalDataSource {
  FavoriteDao(super.db);

  /// 本地最愛的決定性主鍵：`${type.name}_$targetId`
  String _rowId(String targetId, FavoriteType type) => '${type.name}_$targetId';

  @override
  Future<List<Favorite>> getFavorites() async {
    final rows = await (select(favoritesTable)..where((t) => t.syncStatus.equals(SyncStatus.pendingDelete.name).not()))
        .get();
    return rows.map(_mapToDomain).toList();
  }

  @override
  Future<List<Favorite>> getAllIncludingPending() async {
    final rows = await select(favoritesTable).get();
    return rows.map(_mapToDomain).toList();
  }

  @override
  Future<Favorite?> getById(String id) async {
    final row = await (select(favoritesTable)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapToDomain(row);
  }

  @override
  Future<void> toggleFavorite(String id, FavoriteType type, bool isFavorite, {String userId = ''}) async {
    final rowId = _rowId(id, type);
    final existing = await (select(favoritesTable)..where((t) => t.id.equals(rowId))).getSingleOrNull();

    if (isFavorite) {
      // 加入最愛：新增／復活墓碑，標記為待推送
      await into(favoritesTable).insertOnConflictUpdate(
        FavoritesTableCompanion.insert(
          id: rowId,
          targetId: id,
          type: type,
          syncStatus: const Value(SyncStatus.pendingCreate),
          createdAt: existing?.createdAt ?? DateTime.now(),
          createdBy: Value(userId),
          updatedAt: Value(DateTime.now()),
        ),
      );
    } else {
      // 取消最愛
      if (existing == null) return;
      if (existing.syncStatus == SyncStatus.pendingCreate) {
        // 從未成功推送過，直接硬刪
        await (delete(favoritesTable)..where((t) => t.id.equals(rowId))).go();
      } else {
        // 已同步過，保留墓碑等待推送 unfavorite
        await (update(favoritesTable)..where((t) => t.id.equals(rowId))).write(
          FavoritesTableCompanion(syncStatus: const Value(SyncStatus.pendingDelete), updatedAt: Value(DateTime.now())),
        );
      }
    }
  }

  @override
  Future<void> upsert(Favorite favorite) async {
    await into(favoritesTable).insertOnConflictUpdate(favorite.toCompanion());
  }

  @override
  Future<void> deleteById(String id) async {
    await (delete(favoritesTable)..where((t) => t.id.equals(id))).go();
  }

  Favorite _mapToDomain(FavoritesTableData row) {
    return Favorite(
      id: row.id,
      targetId: row.targetId,
      type: row.type,
      syncStatus: row.syncStatus,
      createdAt: row.createdAt,
      createdBy: row.createdBy,
      updatedAt: row.updatedAt ?? row.createdAt,
      updatedBy: row.updatedBy,
    );
  }
}
