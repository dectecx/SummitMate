import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/favorites_api_models.dart';

part 'favorites_api_service.g.dart';

/// Favorites API Service
///
/// Retrofit 介面，對應後端 `/favorites` 相關的 API endpoint。
@RestApi()
abstract class FavoritesApiService {
  factory FavoritesApiService(Dio dio, {String baseUrl}) = _FavoritesApiService;

  @GET('/favorites')
  Future<FavoritePaginationResponse> listFavorites({
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  });

  @POST('/favorites')
  Future<FavoriteResponse> addFavorite(@Body() FavoriteAddRequest request);

  @POST('/favorites/batch')
  Future<void> batchUpdate(@Body() List<BatchFavoriteItem> items);

  @DELETE('/favorites/{targetId}')
  Future<void> removeFavorite(@Path('targetId') String targetId);
}
