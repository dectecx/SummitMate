import 'package:summitmate/domain/domain.dart';
import '../models/poll_api_models.dart';

/// Poll API Model ↔ Persistence Model 轉換
class PollApiMapper {
  /// PollResponse → Poll (domain entity)
  static Poll fromResponse(PollResponse response, {String tripId = ''}) {
    return Poll(
      id: response.id,
      tripId: tripId,
      title: response.title,
      description: response.description,
      creatorId: response.creatorId,
      deadline: response.deadline?.toLocal(),
      isAllowAddOption: response.isAllowAddOption,
      maxOptionLimit: response.maxOptionLimit,
      allowMultipleVotes: response.allowMultipleVotes,
      resultDisplayType: response.resultDisplayType,
      status: response.status,
      options: response.options.map(fromOptionResponse).toList(),
      myVotes: response.myVotes,
      totalVotes: response.totalVotes,
      createdAt: response.createdAt.toLocal(),
      createdBy: response.createdBy,
      updatedAt: response.updatedAt.toLocal(),
      updatedBy: response.updatedBy,
    );
  }

  /// PollOptionResponse → PollOption (domain entity)
  static PollOption fromOptionResponse(PollOptionResponse response) {
    return PollOption(
      id: response.id,
      pollId: response.pollId,
      text: response.text,
      creatorId: response.creatorId,
      voteCount: response.voteCount,
      voters: response.voters,
      createdAt: response.createdAt.toLocal(),
      createdBy: response.createdBy,
      updatedAt: response.updatedAt.toLocal(),
      updatedBy: response.updatedBy,
    );
  }

  /// Parameters to CreateRequest
  static PollCreateRequest toCreateRequest({
    required String title,
    required List<String> options,
    bool allowMultiple = false,
    String description = '',
    DateTime? deadline,
    bool isAllowAddOption = false,
    int maxOptionLimit = 20,
    String resultDisplayType = 'realtime',
  }) {
    return PollCreateRequest(
      title: title,
      initialOptions: options,
      allowMultipleVotes: allowMultiple,
      description: description,
      deadline: deadline,
      isAllowAddOption: isAllowAddOption,
      maxOptionLimit: maxOptionLimit,
      resultDisplayType: resultDisplayType,
    );
  }

  /// Option text to Request
  static PollOptionRequest toOptionRequest(String text) {
    return PollOptionRequest(text: text);
  }
}
