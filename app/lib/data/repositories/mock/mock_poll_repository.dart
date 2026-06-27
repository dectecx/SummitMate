import '../../../core/error/result.dart';
import '../../../core/models/paginated_list.dart';
import 'package:summitmate/domain/domain.dart';

/// 模擬投票資料倉庫
class MockPollRepository implements IPollRepository {
  @override
  Future<Result<void, Exception>> init() async => const Success(null);

  @override
  Future<List<Poll>> getByTripId(String tripId) async => [];

  @override
  Future<Result<PaginatedList<Poll>, Exception>> refresh(String tripId, {int? page, int? limit}) async =>
      const Success(PaginatedList(items: [], page: 1, total: 0, hasMore: false));

  @override
  Future<Result<String, Exception>> create({
    required String tripId,
    required String title,
    required List<String> options,
    bool allowMultiple = false,
  }) async => const Success('');

  @override
  Future<Result<void, Exception>> vote({
    required String tripId,
    required String pollId,
    required List<String> optionIds,
  }) async => const Success(null);

  @override
  Future<Result<void, Exception>> addOption({
    required String tripId,
    required String pollId,
    required String optionText,
  }) async => const Success(null);

  @override
  Future<Result<void, Exception>> delete(String tripId, String pollId) async => const Success(null);
}
