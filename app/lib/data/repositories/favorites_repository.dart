import 'package:injectable/injectable.dart';
import '../../../core/models/paginated_list.dart';
import '../models/favorite_model.dart';
import '../../domain/entities/favorite.dart';
import '../../data/models/enums/favorite_type.dart';
import '../../core/error/result.dart';
import '../../domain/repositories/i_favorites_repository.dart';
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
  Future<Result<PaginatedList<Favorite>, Exception>> getFavorites({int? page, int? limit}) async {
    try {
      // 1. 如果是第一頁且沒有搜尋條件，優先從本地 Hive 取得 (快速)
      if (page == null || page <= 1) {
        final localFavorites = await _localDataSource.getFavorites();
        final domainItems = localFavorites.map((f) => f.toDomain()).toList();

        // 觸發背景同步 (Fire and forget)
        _syncFromRemote();

        return Success(PaginatedList(items: domainItems, page: 1, total: domainItems.length, hasMore: false));
      }

      // 2. 從遠端獲取分頁資料
      final remoteResult = await _remoteDataSource.getFavorites(page: page, limit: limit);

      return remoteResult;
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<void> _syncFromRemote() async {
    final result = await _remoteDataSource.getFavorites();
    if (result is Success<PaginatedList<Favorite>, Exception>) {
      final models = result.value.items.map((f) => FavoriteModel.fromDomain(f)).toList();
      await _localDataSource.saveFavorites(models);
      LogService.info('從遠端同步了最愛列表: ${result.value.items.length} 筆', source: 'FavoritesRepository');
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
