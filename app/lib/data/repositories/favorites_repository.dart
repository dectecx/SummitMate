import 'package:injectable/injectable.dart';
import '../../../core/models/paginated_list.dart';
import '../../domain/entities/favorite.dart';
import '../../domain/enums/favorite_type.dart';
import '../../core/error/result.dart';
import '../../domain/repositories/i_favorites_repository.dart';
import '../../domain/interfaces/i_auth_service.dart';
import '../../data/datasources/interfaces/i_favorites_remote_data_source.dart';
import '../../data/datasources/interfaces/i_favorites_local_data_source.dart';
import '../../infrastructure/tools/log_service.dart';

/// 最愛 (Favorites) 的 Repository 實作
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
      if (page == null || page <= 1) {
        final localFavorites = await _localDataSource.getFavorites();

        // 觸發背景同步
        _syncFromRemote();

        return Success(PaginatedList(items: localFavorites, page: 1, total: localFavorites.length, hasMore: false));
      }

      return await _remoteDataSource.getFavorites(page: page, limit: limit);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<void> _syncFromRemote() async {
    try {
      final result = await _remoteDataSource.getFavorites();
      if (result is Success<PaginatedList<Favorite>, Exception>) {
        await _localDataSource.saveFavorites(result.value.items);
        LogService.info('已同步遠端最愛列表: ${result.value.items.length} 筆', source: 'FavoritesRepository');
      }
    } catch (e) {
      LogService.error('背景同步最愛列表失敗: $e', source: 'FavoritesRepository');
    }
  }

  @override
  Future<Result<void, Exception>> toggleFavorite(String id, FavoriteType type, bool isFavorite) async {
    try {
      final userId = _authService.currentUserId ?? '';
      await _localDataSource.toggleFavorite(id, type, isFavorite, userId: userId);

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
