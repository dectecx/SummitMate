import '../../models/poll_model.dart';
import '../models/poll_api_models.dart';

/// Poll API Model ↔ Persistence Model 轉換
class PollApiMapper {
  /// PollResponse → PollModel
  static PollModel fromResponse(PollResponse response, {String tripId = ''}) {
    return PollModel(
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

  /// PollOptionResponse → PollOptionModel
  static PollOptionModel fromOptionResponse(PollOptionResponse response) {
    return PollOptionModel(
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
