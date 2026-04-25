import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/itinerary_api_models.dart';

part 'itinerary_api_service.g.dart';

/// Itinerary API Service
///
/// Retrofit 介面，對應後端 `/trips/{tripId}/itinerary` 相關的 API endpoint。
@RestApi()
abstract class ItineraryApiService {
  factory ItineraryApiService(Dio dio, {String baseUrl}) = _ItineraryApiService;

  @GET('/trips/{tripId}/itinerary')
  Future<List<ItineraryItemResponse>> listItinerary(@Path('tripId') String tripId);

  @POST('/trips/{tripId}/itinerary')
  Future<ItineraryItemResponse> addItem(@Path('tripId') String tripId, @Body() ItineraryItemRequest request);

  @PATCH('/trips/{tripId}/itinerary/{itemId}')
  Future<ItineraryItemResponse> updateItem(
    @Path('tripId') String tripId,
    @Path('itemId') String itemId,
    @Body() ItineraryItemRequest request,
  );

  @DELETE('/trips/{tripId}/itinerary/{itemId}')
  Future<void> deleteItem(@Path('tripId') String tripId, @Path('itemId') String itemId);
}
