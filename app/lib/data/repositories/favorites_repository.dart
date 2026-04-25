import 'package:injectable/injectable.dart';
import '../models/favorite.dart';
import '../../data/models/enums/favorite_type.dart';
import '../../core/error/result.dart';
import 'interfaces/i_favorites_repository.dart';
import '../../domain/interfaces/i_auth_service.dart';
import '../../data/datasources/interfaces/i_favorites_remote_data_source.dart';
import '../../data/datasources/interfaces/i_favorites_local_data_source.dart';
import '../../infrastructure/tools/log_service.dart';

/// 最愛 (Favorites) 的 Repository 實作
/// 負責在本地 (Hive) 與遠端之間進行同步
@LazySingleton(as: IFavoritesRepository)
class FavoritesRepository implements IFavoritesRepository {
  final IFavoritesLocalDataSource _localDataSource;
  final IFavoritesRemoteDataSource _remoteDataSource;
  final IAuthService _authService;

  FavoritesRepository({
    required IFavoritesLocalDataSource localDataSource,
    required IFavoritesRemoteDataSource remoteDataSource,
    required IAuthService authService,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource,
       _authService = authService;

  @override
  Future<Result<List<Favorite>, Exception>> getFavorites() async {
    try {
      // 1. 優先從本地 Hive 取得 (快速)
      final localFavorites = await _localDataSource.getFavorites();

      // 2. 從遠端獲取
      // 觸發背景同步 (Fire and forget)
      // 雖然沒有 await，但在這裡是用於觸發副作用更新本地快取
      _syncFromRemote();

      return Success(localFavorites);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<void> _syncFromRemote() async {
    final result = await _remoteDataSource.getFavorites();
    if (result is Success<List<Favorite>, Exception>) {
      await _localDataSource.saveFavorites(result.value);
      LogService.info('從遠端同步了最愛列表: ${result.value.length} 筆', source: 'FavoritesRepository');
    }
  }

  @override
  Future<Result<void, Exception>> toggleFavorite(String id, FavoriteType type, bool isFavorite) async {
    try {
      // 1. 立即更新本地 Hive (樂觀 UI 更新)
      final userId = _authService.currentUserId ?? '';
      await _localDataSource.toggleFavorite(id, type, isFavorite, userId: userId);

      // 2. 更新遠端
      if (await _authService.isLoggedIn()) {
        final remoteResult = await _remoteDataSource.updateFavorite(id, type, isFavorite);
        if (remoteResult is Failure) {
          LogService.warning('同步最愛狀態至遠端失敗', source: 'FavoritesRepository');
        }
      }

      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }
}
