import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/trip_api_models.dart';

part 'trip_api_service.g.dart';

/// Trip API Service
///
/// Retrofit 介面，對應後端 `/trips` 相關的所有 API endpoint。
@RestApi()
abstract class TripApiService {
  factory TripApiService(Dio dio, {String baseUrl}) = _TripApiService;

  // ── Trip CRUD ──

  @GET('/trips')
  Future<List<TripResponse>> listTrips();

  @POST('/trips')
  Future<TripResponse> createTrip(@Body() TripCreateRequest request);

  @GET('/trips/{tripId}')
  Future<TripResponse> getTrip(@Path('tripId') String tripId);

  @PATCH('/trips/{tripId}')
  Future<TripResponse> updateTrip(
    @Path('tripId') String tripId,
    @Body() TripUpdateRequest request,
  );

  @DELETE('/trips/{tripId}')
  Future<void> deleteTrip(@Path('tripId') String tripId);

  // ── Trip Members ──

  @GET('/trips/{tripId}/members')
  Future<List<TripMemberResponse>> getMembers(@Path('tripId') String tripId);

  @POST('/trips/{tripId}/members')
  Future<void> addMember(
    @Path('tripId') String tripId,
    @Body() AddMemberRequest request,
  );

  @PUT('/trips/{tripId}/members/{userId}')
  Future<void> updateMemberRole(
    @Path('tripId') String tripId,
    @Path('userId') String userId,
    @Body() UpdateMemberRoleRequest request,
  );

  @DELETE('/trips/{tripId}/members/{userId}')
  Future<void> removeMember(
    @Path('tripId') String tripId,
    @Path('userId') String userId,
  );
}
