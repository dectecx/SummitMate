import 'package:dio/dio.dart';
import '../../../core/constants.dart';
import '../../../core/error/result.dart';
import '../../models/enums/favorite_type.dart';
import '../../../infrastructure/tools/log_service.dart';

import '../../../core/di.dart';
import '../../../infrastructure/clients/network_aware_client.dart';
import '../../../infrastructure/clients/gas_api_client.dart';

import '../../datasources/interfaces/i_favorites_remote_data_source.dart';

/// 最愛 (Favorites) 的遠端資料來源實作
/// 處理與 GAS 後端的通訊
class FavoritesRemoteDataSource implements IFavoritesRemoteDataSource {
  final NetworkAwareClient _apiClient;

  FavoritesRemoteDataSource({NetworkAwareClient? apiClient}) : _apiClient = apiClient ?? getIt<NetworkAwareClient>();

  /// 從後端獲取所有最愛列表
  @override
  Future<Result<List<Map<String, dynamic>>, Exception>> getFavorites() async {
    try {
      final response = await _apiClient.get('', queryParameters: {'action': ApiConfig.actionFavoritesGet});

      if (response.statusCode == 200) {
        final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);

        if (gasResponse.isSuccess) {
          final favorites = gasResponse.data['favorites'] as List?;
          return Success(favorites?.cast<Map<String, dynamic>>() ?? []);
        } else {
          return Failure(GeneralException('無法獲取最愛列表: ${gasResponse.message} (${gasResponse.code})'));
        }
      } else {
        return Failure(GeneralException('無法獲取最愛列表: HTTP ${response.statusCode}'));
      }
    } catch (e) {
      LogService.error('獲取最愛列表失敗: $e', source: 'FavoritesRemoteDataSource');
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  /// 在後端切換最愛狀態
  @override
  Future<Result<void, Exception>> updateFavorite(String id, FavoriteType type, bool isFavorite) async {
    try {
      final response = await _apiClient.post(
        '',
        data: {
          'action': ApiConfig.actionFavoritesUpdate,
          'target_id': id,
          'type': type.value,
          'is_favorite': isFavorite,
        },
        options: Options(extra: {'requiresAuth': true}),
      );

      final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
      if (!gasResponse.isSuccess) {
        throw GeneralException('更新失敗: ${gasResponse.message}');
      }

      LogService.info('遠端: 更新最愛狀態 $id (${type.value}) 為 $isFavorite', source: 'FavoritesRemoteDataSource');

      return const Success(null);
    } catch (e) {
      LogService.error('更新最愛狀態失敗: $e', source: 'FavoritesRemoteDataSource');
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }
}
