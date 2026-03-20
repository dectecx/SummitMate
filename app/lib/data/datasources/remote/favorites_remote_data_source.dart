import '../../../core/error/result.dart';
import '../../models/enums/favorite_type.dart';
import '../../../infrastructure/tools/log_service.dart';
import '../../../core/di.dart';
import '../../../infrastructure/clients/network_aware_client.dart';
import '../../datasources/interfaces/i_favorites_remote_data_source.dart';

/// 最愛 (Favorites) 的遠端資料來源實作
class FavoritesRemoteDataSource implements IFavoritesRemoteDataSource {
  static const String _source = 'FavoritesRemoteDataSource';
  final NetworkAwareClient _apiClient;

  FavoritesRemoteDataSource({NetworkAwareClient? apiClient}) : _apiClient = apiClient ?? getIt<NetworkAwareClient>();

  /// 從雲端獲取所有最愛列表
  ///
  /// 回傳: 最愛資料的列表 (Map 格式)
  @override
  Future<Result<List<Map<String, dynamic>>, Exception>> getFavorites() async {
    try {
      LogService.info('獲取雲端最愛列表...', source: _source);
      final response = await _apiClient.get('/favorites');

      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        return Success(data.cast<Map<String, dynamic>>());
      } else {
        return Failure(GeneralException('無法獲取最愛列表: HTTP ${response.statusCode}'));
      }
    } catch (e) {
      LogService.error('獲取最愛列表失敗: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  /// 在雲端更新最愛狀態
  ///
  /// [id] 目標物件 ID (如行程 ID, 揪團 ID)
  /// [type] 最愛類型 (參考 FavoriteType)
  /// [isFavorite] 是否設定為最愛
  @override
  Future<Result<void, Exception>> updateFavorite(String id, FavoriteType type, bool isFavorite) async {
    try {
      LogService.info('更新最愛狀態: $id (${type.value}) -> $isFavorite', source: _source);

      // TODO: 待優化 - 目前採單次切換狀態。若有大量同步需求，建議後端提供批次更新介面。
      final response = await _apiClient.post(
        '/favorites',
        data: {'target_id': id, 'type': type.value, 'is_favorite': isFavorite},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw GeneralException('更新失敗: HTTP ${response.statusCode}');
      }

      LogService.info('遠端更新成功', source: _source);
      return const Success(null);
    } catch (e) {
      LogService.error('更新最愛狀態失敗: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }
}
