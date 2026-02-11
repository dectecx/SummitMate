import 'package:hive_flutter/hive_flutter.dart';
import '../../models/favorite.dart';
import '../../models/enums/favorite_type.dart';
import '../../../core/constants.dart';
import '../../../infrastructure/tools/hive_service.dart';
import '../../datasources/interfaces/i_favorites_local_data_source.dart';

/// 最愛 (Favorites) 的本地資料來源實作 (使用 Hive)
class FavoritesLocalDataSource implements IFavoritesLocalDataSource {
  final HiveService _hiveService;
  Box<Favorite>? _box;

  FavoritesLocalDataSource({required HiveService hiveService}) : _hiveService = hiveService;

  @override
  Future<void> init() async {
    // 使用獨立的 Box 儲存最愛項目
    if (_box == null || !_box!.isOpen) {
      _box = await _hiveService.openBox<Favorite>(HiveBoxNames.mountainFavorites);
    }
  }

  Box<Favorite> get box {
    if (_box == null || !_box!.isOpen) {
      throw StateError('FavoritesLocalDataSource not initialized. Call init() first.');
    }
    return _box!;
  }

  @override
  Future<List<Favorite>> getFavorites() async {
    return box.values.toList();
  }

  @override
  Future<void> toggleFavorite(String id, FavoriteType type, bool isFavorite, {String userId = ''}) async {
    final now = DateTime.now();
    // 為了獲取 extension/helper 還是先建立物件
    // 其實 compositeKey 就是 '${type.value}_$id'

    if (isFavorite) {
      final newRow = Favorite(
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
  Future<void> saveFavorites(List<Favorite> rows) async {
    await box.clear();

    final Map<String, Favorite> entries = {};
    for (var row in rows) {
      entries[row.compositeKey] = row;
    }

    await box.putAll(entries);
  }
}
