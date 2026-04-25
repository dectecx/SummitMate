import 'package:injectable/injectable.dart';
import '../../../core/models/paginated_list.dart';
import '../../../core/error/result.dart';
import '../../models/favorite.dart';
import '../../models/enums/favorite_type.dart';
import '../../api/models/favorites_api_models.dart';
import '../../api/mappers/favorites_api_mapper.dart';
import '../../api/services/favorites_api_service.dart';
import '../../../infrastructure/tools/log_service.dart';
import '../interfaces/i_favorites_remote_data_source.dart';

/// 最愛 (Favorites) 的遠端資料來源實作
@LazySingleton(as: IFavoritesRemoteDataSource)
class FavoritesRemoteDataSource implements IFavoritesRemoteDataSource {
  static const String _source = 'FavoritesRemoteDataSource';

  final FavoritesApiService _favoritesApi;

  FavoritesRemoteDataSource(this._favoritesApi);

  @override
  Future<Result<PaginatedList<Favorite>, Exception>> getFavorites({String? cursor, int? limit}) async {
    try {
      LogService.info('獲取雲端最愛列表 (cursor: $cursor, limit: $limit)...', source: _source);
      final response = await _favoritesApi.listFavorites(cursor: cursor, limit: limit);
      final list = PaginatedList<Favorite>(
        items: response.items.map(FavoritesApiMapper.fromResponse).toList(),
        nextCursor: response.pagination.nextCursor,
        hasMore: response.pagination.hasMore,
      );
      return Success(list);
    } catch (e) {
      LogService.error('獲取最愛列表失敗: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> updateFavorite(String id, FavoriteType type, bool isFavorite) async {
    try {
      LogService.info('更新最愛狀態: $id (${type.value}) -> $isFavorite', source: _source);
      if (isFavorite) {
        await _favoritesApi.addFavorite(FavoriteAddRequest(targetId: id, type: type.value));
      } else {
        await _favoritesApi.removeFavorite(id);
      }
      return const Success(null);
    } catch (e) {
      LogService.error('更新最愛狀態失敗: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> batchUpdateFavorites(List<Map<String, dynamic>> items) async {
    try {
      LogService.info('批量更新最愛狀態: 數量 ${items.length}', source: _source);
      final requests = items
          .map(
            (m) => BatchFavoriteItem(
              targetId: m['target_id'] as String,
              type: m['type'] as String,
              isFavorite: m['is_favorite'] as bool,
            ),
          )
          .toList();
      await _favoritesApi.batchUpdate(requests);
      return const Success(null);
    } catch (e) {
      LogService.error('批次更新最愛狀態失敗: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }
}
