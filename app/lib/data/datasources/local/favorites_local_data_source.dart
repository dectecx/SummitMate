import 'package:injectable/injectable.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../models/favorite_model.dart';
import '../../models/enums/favorite_type.dart';
import '../../../core/constants.dart';
import '../../../infrastructure/tools/hive_service.dart';
import '../../datasources/interfaces/i_favorites_local_data_source.dart';

/// 最愛 (Favorites) 的本地資料來源實作 (使用 Hive)
@LazySingleton(as: IFavoritesLocalDataSource)
class FavoritesLocalDataSource implements IFavoritesLocalDataSource {
  final Box<FavoriteModel> box;

  FavoritesLocalDataSource({required HiveService hiveService})
    : box = hiveService.getBox<FavoriteModel>(HiveBoxNames.mountainFavorites);

  @override
  Future<List<FavoriteModel>> getFavorites() async {
    return box.values.toList();
  }

  @override
  Future<void> toggleFavorite(String id, FavoriteType type, bool isFavorite, {String userId = ''}) async {
    final now = DateTime.now();
    // 為了獲取 extension/helper 還是先建立物件
    // 其實 compositeKey 就是 '${type.value}_$id'

    if (isFavorite) {
      final newRow = FavoriteModel(
        id: '', // 本地暫存 ID 為空，等待同步回寫
        targetId: id,
        type: type,
        createdAt: now,
        createdBy: userId,
        updatedAt: now,
        updatedBy: userId,
      );
      await box.put(newRow.compositeKey, newRow);
    } else {
      await box.delete('${type.value}_$id');
    }
  }

  @override
  Future<void> saveFavorites(List<FavoriteModel> rows) async {
    await box.clear();

    final Map<String, FavoriteModel> entries = {};
    for (var row in rows) {
      entries[row.compositeKey] = row;
    }

    await box.putAll(entries);
  }
}
