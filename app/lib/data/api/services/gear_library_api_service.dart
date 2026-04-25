import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/gear_library_api_models.dart';

part 'gear_library_api_service.g.dart';

/// GearLibrary API Service
///
/// Retrofit 介面，對應後端 `/gear-library` 相關的 API endpoint。
@RestApi()
abstract class GearLibraryApiService {
  factory GearLibraryApiService(Dio dio, {String baseUrl}) = _GearLibraryApiService;

  @GET('/gear-library')
  Future<GearLibraryPaginationResponse> listItems({
    @Query('include_archived') bool? includeArchived,
    @Query('page') int? page,
    @Query('limit') int? limit,
    @Query('search') String? search,
  });

  @POST('/gear-library')
  Future<GearLibraryItemResponse> addItem(@Body() GearLibraryItemRequest request);

  @PUT('/gear-library/{itemId}')
  Future<GearLibraryItemResponse> updateItem(@Path('itemId') String itemId, @Body() GearLibraryItemRequest request);

  @DELETE('/gear-library/{itemId}')
  Future<void> deleteItem(@Path('itemId') String itemId);

  @PUT('/gear-library')
  Future<void> replaceAll(@Body() List<GearLibraryItemRequest> items);
}
