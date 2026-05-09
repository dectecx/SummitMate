import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/gear_set_api_models.dart';

part 'gear_set_api_service.g.dart';

/// GearSet API Service
///
/// Retrofit 介面，對應後端 `/gear-sets` 相關的 API endpoint。
@RestApi()
abstract class GearSetApiService {
  factory GearSetApiService(Dio dio, {String baseUrl}) = _GearSetApiService;

  /// 取得雲端裝備庫列表 (public / protected)
  @GET('/gear-sets')
  Future<GearSetListResponse> listGearSets({
    @Query('page') int? page,
    @Query('limit') int? limit,
    @Query('search') String? search,
    @Query('my_uploaded') bool? myUploaded,
  });

  /// 上傳新的裝備組合
  @POST('/gear-sets')
  Future<GearSetResponse> createGearSet(@Body() GearSetCreateRequest request);

  /// 取得單一裝備組合 (含 key 驗證)
  @GET('/gear-sets/{id}')
  Future<GearSetResponse> getGearSet(@Path('id') String id, {@Query('key') String? key});

  /// 刪除裝備組合
  @DELETE('/gear-sets/{id}')
  Future<void> deleteGearSet(@Path('id') String id);

  /// 更新裝備組合
  @PUT('/gear-sets/{id}')
  Future<GearSetResponse> updateGearSet(
    @Path('id') String id,
    @Body() GearSetCreateRequest request,
  );
}
