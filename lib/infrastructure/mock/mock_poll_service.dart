import '../../domain/interfaces/i_poll_service.dart';
import '../../data/models/poll.dart';

class MockPollService implements IPollService {
  @override
  Future<List<Poll>> getPolls({required String userId}) async => [];

  @override
  Future<void> createPoll({
    required String title,
    String description = '',
    required String creatorId,
    DateTime? deadline,
    bool isAllowAddOption = false,
    int maxOptionLimit = 20,
    bool allowMultipleVotes = false,
    List<String> initialOptions = const [],
  }) async {}

  @override
  Future<void> votePoll({
    required String pollId,
    required List<String> optionIds,
    required String userId,
    String userName = 'Anonymous',
  }) async {}

  @override
  Future<void> addOption({required String pollId, required String text, required String creatorId}) async {}

  @override
  Future<void> closePoll({required String pollId, required String userId}) async {}

  @override
  Future<void> deletePoll({required String pollId, required String userId}) async {}

  @override
  Future<void> deleteOption({required String optionId, required String userId}) async {}
}
