import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/trip_gear_api_models.dart';

part 'trip_gear_api_service.g.dart';

/// TripGear API Service
///
/// Retrofit 介面，對應後端 `/trips/{tripId}/gear` 相關的 API endpoint。
@RestApi()
abstract class TripGearApiService {
  factory TripGearApiService(Dio dio, {String baseUrl}) = _TripGearApiService;

  @GET('/trips/{tripId}/gear')
  Future<List<TripGearItemResponse>> listGear(@Path('tripId') String tripId);

  @POST('/trips/{tripId}/gear')
  Future<TripGearItemResponse> addGear(
    @Path('tripId') String tripId,
    @Body() TripGearItemRequest request,
  );

  @PUT('/trips/{tripId}/gear/{itemId}')
  Future<TripGearItemResponse> updateGear(
    @Path('tripId') String tripId,
    @Path('itemId') String itemId,
    @Body() TripGearItemRequest request,
  );

  @DELETE('/trips/{tripId}/gear/{itemId}')
  Future<void> deleteGear(
    @Path('tripId') String tripId,
    @Path('itemId') String itemId,
  );

  @PUT('/trips/{tripId}/gear')
  Future<void> replaceAllGear(
    @Path('tripId') String tripId,
    @Body() List<TripGearItemRequest> items,
  );
}
