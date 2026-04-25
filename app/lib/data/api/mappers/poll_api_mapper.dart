import '../../models/poll.dart';
import '../models/poll_api_models.dart';

/// Poll API Model ↔ Domain Model 轉換
class PollApiMapper {
  /// PollResponse → Poll (domain model)
  static Poll fromResponse(PollResponse response) {
    return Poll(
      id: response.id,
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

  /// PollOptionResponse → PollOption (domain model)
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
}
