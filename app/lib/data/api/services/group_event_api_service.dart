import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/group_event_api_models.dart';

part 'group_event_api_service.g.dart';

/// GroupEvent API Service
///
/// Retrofit 介面，對應後端 `/group-events` 相關的 API endpoint。
@RestApi()
abstract class GroupEventApiService {
  factory GroupEventApiService(Dio dio, {String baseUrl}) = _GroupEventApiService;

  // ── Events ──

  @GET('/group-events')
  Future<List<GroupEventResponse>> listEvents(
    @Query('status') String? status,
  );

  @GET('/group-events/my')
  Future<List<GroupEventResponse>> listMyEvents(@Query('type') String type);

  @GET('/group-events/{eventId}')
  Future<GroupEventResponse> getEvent(@Path('eventId') String eventId);

  @POST('/group-events')
  Future<GroupEventResponse> createEvent(@Body() GroupEventCreateRequest request);

  @PUT('/group-events/{eventId}')
  Future<GroupEventResponse> updateEvent(
    @Path('eventId') String eventId,
    @Body() GroupEventUpdateRequest request,
  );

  @PUT('/group-events/{eventId}/status')
  Future<void> updateEventStatus(
    @Path('eventId') String eventId,
    @Body() GroupEventStatusRequest request,
  );

  @DELETE('/group-events/{eventId}')
  Future<void> deleteEvent(@Path('eventId') String eventId);

  // ── Applications ──

  @GET('/group-events/{eventId}/applications')
  Future<List<GroupEventApplicationResponse>> listApplications(
    @Path('eventId') String eventId,
  );

  @POST('/group-events/{eventId}/apply')
  Future<GroupEventApplicationResponse> applyEvent(
    @Path('eventId') String eventId,
    @Body() GroupEventApplyRequest request,
  );

  @DELETE('/group-events/applications/{applicationId}')
  Future<void> cancelApplication(@Path('applicationId') String applicationId);

  @PUT('/group-events/applications/{applicationId}')
  Future<void> reviewApplication(
    @Path('applicationId') String applicationId,
    @Body() GroupEventReviewRequest request,
  );

  // ── Likes ──

  @POST('/group-events/{eventId}/like')
  Future<void> likeEvent(@Path('eventId') String eventId);

  @DELETE('/group-events/{eventId}/like')
  Future<void> unlikeEvent(@Path('eventId') String eventId);

  // ── Comments ──

  @GET('/group-events/{eventId}/comments')
  Future<List<GroupEventCommentResponse>> listComments(@Path('eventId') String eventId);

  @POST('/group-events/{eventId}/comments')
  Future<GroupEventCommentResponse> addComment(
    @Path('eventId') String eventId,
    @Body() GroupEventCommentRequest request,
  );

  @DELETE('/group-events/comments/{commentId}')
  Future<void> deleteComment(@Path('commentId') String commentId);
}
