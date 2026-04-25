import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../models/poll.dart';
import '../models/poll_api_models.dart';

part 'poll_api_service.g.dart';

/// Poll API Service
///
/// Retrofit 介面，對應後端 `/trips/{tripId}/polls` 相關的 API endpoint。
@RestApi()
abstract class PollApiService {
  factory PollApiService(Dio dio, {String baseUrl}) = _PollApiService;

  @GET('/trips/{tripId}/polls')
  Future<List<Poll>> listPolls(@Path('tripId') String tripId);

  @POST('/trips/{tripId}/polls')
  Future<Poll> createPoll(
    @Path('tripId') String tripId,
    @Body() PollCreateRequest request,
  );

  @DELETE('/trips/{tripId}/polls/{pollId}')
  Future<void> deletePoll(
    @Path('tripId') String tripId,
    @Path('pollId') String pollId,
  );

  // ── Options ──

  @POST('/trips/{tripId}/polls/{pollId}/options')
  Future<PollOption> addOption(
    @Path('tripId') String tripId,
    @Path('pollId') String pollId,
    @Body() PollOptionRequest request,
  );

  @DELETE('/trips/{tripId}/polls/{pollId}/options/{optionId}')
  Future<void> deleteOption(
    @Path('tripId') String tripId,
    @Path('pollId') String pollId,
    @Path('optionId') String optionId,
  );

  // ── Votes ──

  @POST('/trips/{tripId}/polls/{pollId}/options/{optionId}/vote')
  Future<void> voteOption(
    @Path('tripId') String tripId,
    @Path('pollId') String pollId,
    @Path('optionId') String optionId,
  );
}
