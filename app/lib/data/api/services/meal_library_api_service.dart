import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/meal_library_api_models.dart';

part 'meal_library_api_service.g.dart';

/// MealLibrary API Service
///
/// Retrofit 介面，對應後端 `/meal-library` 相關的 API endpoint。
@RestApi()
abstract class MealLibraryApiService {
  factory MealLibraryApiService(Dio dio, {String baseUrl}) = _MealLibraryApiService;

  @GET('/meal-library')
  Future<MealLibraryPaginationResponse> listItems({
    @Query('include_archived') bool? includeArchived,
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
    @Query('search') String? search,
  });

  @POST('/meal-library')
  Future<MealLibraryItem> addItem(@Body() MealLibraryItemRequest request);

  @PUT('/meal-library/{itemId}')
  Future<MealLibraryItem> updateItem(@Path('itemId') String itemId, @Body() MealLibraryItemRequest request);

  @DELETE('/meal-library/{itemId}')
  Future<void> deleteItem(@Path('itemId') String itemId);

  @PUT('/meal-library')
  Future<void> replaceAll(@Body() List<MealLibraryItemRequest> items);
}
