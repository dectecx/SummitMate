import 'package:injectable/injectable.dart';
import '../../../core/models/paginated_list.dart';
import '../../domain/entities/favorite.dart';
import '../../domain/enums/favorite_type.dart';
import '../../core/error/result.dart';
import '../../domain/repositories/i_favorites_repository.dart';
import '../../domain/interfaces/i_auth_service.dart';
import '../../data/datasources/interfaces/i_favorites_local_data_source.dart';

/// 最愛 (Favorites) 的 Repository 實作（C 模式：離線可寫，pending 佇列）
///
/// 讀寫皆只動本地；遠端推拉由 `FavoritesSyncAdapter` 透過 `SyncEngine` 背景處理。
@LazySingleton(as: IFavoritesRepository)
class FavoritesRepository implements IFavoritesRepository {
  final IFavoritesLocalDataSource _localDataSource;
  final IAuthService _authService;

  FavoritesRepository({
    required IFavoritesLocalDataSource localDataSource,
    required IAuthService authService,
  }) : _localDataSource = localDataSource,
       _authService = authService;

  @override
  Future<Result<PaginatedList<Favorite>, Exception>> getFavorites({int? page, int? limit}) async {
    try {
      final favorites = await _localDataSource.getFavorites();
      return Success(PaginatedList(items: favorites, page: 1, total: favorites.length, hasMore: false));
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> toggleFavorite(String id, FavoriteType type, bool isFavorite) async {
    try {
      final userId = _authService.currentUserId ?? '';
      await _localDataSource.toggleFavorite(id, type, isFavorite, userId: userId);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }
}
