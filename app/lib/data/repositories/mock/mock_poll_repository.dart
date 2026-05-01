import '../../../core/error/result.dart';
import '../../../core/models/paginated_list.dart';
import 'package:summitmate/domain/domain.dart';
import '../../../domain/repositories/i_poll_repository.dart';

/// 模擬投票資料倉庫
class MockPollRepository implements IPollRepository {
  @override
  Future<Result<void, Exception>> init() async {
    return const Success(null);
  }

  @override
  List<Poll> getByTripId(String tripId) {
    return [];
  }

  @override
  Future<Result<PaginatedList<Poll>, Exception>> syncPolls(String tripId, {int? page, int? limit}) async {
    return Success(PaginatedList(items: [], page: 1, total: 0, hasMore: false));
  }

  @override
  Future<Result<String, Exception>> create({
    required String tripId,
    required String title,
    required List<String> options,
    bool allowMultiple = false,
  }) async {
    return const Success('mock-poll-id');
  }

  @override
  Future<Result<void, Exception>> vote({
    required String tripId,
    required String pollId,
    required List<String> optionIds,
  }) async {
    return const Success(null);
  }

  @override
  Future<Result<void, Exception>> addOption({
    required String tripId,
    required String pollId,
    required String optionText,
  }) async {
    return const Success(null);
  }

  @override
  Future<Result<void, Exception>> delete(String tripId, String pollId) async {
    return const Success(null);
  }
}
