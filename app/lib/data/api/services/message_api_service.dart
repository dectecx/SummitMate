import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/message_api_models.dart';

part 'message_api_service.g.dart';

/// Message API Service
///
/// Retrofit 介面，對應後端 `/trips/{tripId}/messages` 相關的 API endpoint。
@RestApi()
abstract class MessageApiService {
  factory MessageApiService(Dio dio, {String baseUrl}) = _MessageApiService;

  @GET('/trips/{tripId}/messages')
  Future<MessagePaginationResponse> listTripMessages(
    @Path('tripId') String tripId, {
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  });

  @POST('/trips/{tripId}/messages')
  Future<MessageResponse> addMessage(@Path('tripId') String tripId, @Body() MessageCreateRequest request);

  @DELETE('/trips/{tripId}/messages/{messageId}')
  Future<void> deleteMessage(@Path('tripId') String tripId, @Path('messageId') String messageId);
}
