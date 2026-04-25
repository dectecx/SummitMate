import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/trip_meal_api_models.dart';

part 'trip_meal_api_service.g.dart';

/// TripMeal API Service
///
/// Retrofit 介面，對應後端 `/trips/{tripId}/meals` 相關的 API endpoint。
@RestApi()
abstract class TripMealApiService {
  factory TripMealApiService(Dio dio, {String baseUrl}) = _TripMealApiService;

  @GET('/trips/{tripId}/meals')
  Future<List<TripMealItemResponse>> listMeals(@Path('tripId') String tripId);

  @POST('/trips/{tripId}/meals')
  Future<TripMealItemResponse> addMeal(@Path('tripId') String tripId, @Body() TripMealItemRequest request);

  @PUT('/trips/{tripId}/meals/{itemId}')
  Future<TripMealItemResponse> updateMeal(
    @Path('tripId') String tripId,
    @Path('itemId') String itemId,
    @Body() TripMealItemRequest request,
  );

  @DELETE('/trips/{tripId}/meals/{itemId}')
  Future<void> deleteMeal(@Path('tripId') String tripId, @Path('itemId') String itemId);

  @PUT('/trips/{tripId}/meals')
  Future<void> replaceAllMeals(@Path('tripId') String tripId, @Body() List<TripMealItemRequest> items);
}
