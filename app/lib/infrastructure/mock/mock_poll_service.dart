import '../../domain/interfaces/i_poll_service.dart';
import '../../data/models/poll.dart';
import '../../core/error/result.dart';

class MockPollService implements IPollService {
  @override
  Future<Result<List<Poll>, Exception>> getPolls({required String userId}) async => const Success([]);

  @override
  Future<Result<void, Exception>> createPoll({
    required String title,
    String description = '',
    required String creatorId,
    DateTime? deadline,
    bool isAllowAddOption = false,
    int maxOptionLimit = 20,
    bool allowMultipleVotes = false,
    List<String> initialOptions = const [],
  }) async => const Success(null);

  @override
  Future<Result<void, Exception>> votePoll({
    required String pollId,
    required List<String> optionIds,
    required String userId,
    String userName = 'Anonymous',
  }) async => const Success(null);

  @override
  Future<Result<void, Exception>> addOption({
    required String pollId,
    required String text,
    required String creatorId,
  }) async => const Success(null);

  @override
  Future<Result<void, Exception>> closePoll({required String pollId, required String userId}) async =>
      const Success(null);

  @override
  Future<Result<void, Exception>> deletePoll({required String pollId, required String userId}) async =>
      const Success(null);

  @override
  Future<Result<void, Exception>> deleteOption({required String optionId, required String userId}) async =>
      const Success(null);
}
