import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import '../../infrastructure/database/app_database.dart';
import '../datasources/interfaces/i_favorites_local_data_source.dart';
import '../models/favorite_table.dart';
import '../../domain/entities/favorite.dart';

part 'favorite_dao.g.dart';

@LazySingleton(as: IFavoritesLocalDataSource)
@DriftAccessor(tables: [FavoritesTable])
class FavoriteDao extends DatabaseAccessor<AppDatabase> with _$FavoriteDaoMixin implements IFavoritesLocalDataSource {
  FavoriteDao(AppDatabase db) : super(db);

  @override
  Future<List<Favorite>> getFavorites() async {
    final rows = await select(favoritesTable).get();
    return rows.map((row) => _mapToDomain(row)).toList();
  }

  @override
  Future<void> toggleFavorite(String id, FavoriteType type, bool isFavorite, {String userId = ''}) async {
    if (isFavorite) {
      // 假設 id 為 targetId，若需要 UUID 則在此生成
      // TODO: 確認是否需要在此生成 UUID
      final companion = FavoritesTableCompanion.insert(
        id: id,
        targetId: id,
        type: type,
        createdAt: DateTime.now(),
        createdBy: Value(userId),
      );
      await into(favoritesTable).insertOnConflictUpdate(companion);
    } else {
      await (delete(favoritesTable)..where((t) => t.targetId.equals(id) & t.type.equals(type.index))).go();
    }
  }

  @override
  Future<void> saveFavorites(List<Favorite> rows) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(favoritesTable, rows.map((e) => e.toCompanion()).toList());
    });
  }

  Favorite _mapToDomain(FavoritesTableData row) {
    return Favorite(
      id: row.id,
      targetId: row.targetId,
      type: row.type,
      createdAt: row.createdAt,
      createdBy: row.createdBy,
      updatedAt: row.updatedAt,
      updatedBy: row.updatedBy,
    );
  }
}
