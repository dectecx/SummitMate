import 'package:injectable/injectable.dart';
import 'package:summitmate/domain/domain.dart';
import '../../core/error/result.dart';
import '../../core/models/paginated_list.dart';
import '../datasources/interfaces/i_poll_local_data_source.dart';
import '../datasources/interfaces/i_poll_remote_data_source.dart';
import 'base/repository_remote_access.dart';

/// 投票 Repository 實作（B 模式：讀快取／寫線上）
///
/// 讀取回傳本地快取；[refresh] 與寫入操作經 [RepositoryRemoteAccess.online]
/// 守門（離線→`OfflineException`），成功後更新本地快取。
@LazySingleton(as: IPollRepository)
class PollRepository with RepositoryRemoteAccess implements IPollRepository {
  final IPollLocalDataSource _local;
  final IPollRemoteDataSource _remote;

  @override
  final IConnectivityService connectivity;

  PollRepository(this._local, this._remote, this.connectivity);

  @override
  Future<Result<void, Exception>> init() async => const Success(null);

  @override
  Future<List<Poll>> getByTripId(String tripId) async {
    final polls = await _local.getAllPolls();
    return polls.where((p) => p.tripId == tripId).toList();
  }

  @override
  Future<Result<PaginatedList<Poll>, Exception>> refresh(String tripId, {int? page, int? limit}) {
    return online(
      'fetchPolls',
      () => _remote.getPolls(tripId, page: page, limit: limit),
      cache: (paginated) => _local.savePolls(paginated.items),
    );
  }

  @override
  Future<Result<String, Exception>> create({
    required String tripId,
    required String title,
    required List<String> options,
    bool allowMultiple = false,
  }) {
    return online(
      'createPoll',
      () => _remote.createPoll(tripId: tripId, title: title, options: options, allowMultiple: allowMultiple),
    );
  }

  @override
  Future<Result<void, Exception>> vote({
    required String tripId,
    required String pollId,
    required List<String> optionIds,
  }) {
    return online('votePoll', () => _remote.vote(tripId, pollId, optionIds));
  }

  @override
  Future<Result<void, Exception>> addOption({
    required String tripId,
    required String pollId,
    required String optionText,
  }) {
    return online('addOption', () => _remote.addOption(tripId, pollId, optionText));
  }

  @override
  Future<Result<void, Exception>> delete(String tripId, String pollId) {
    return online(
      'deletePoll',
      () => _remote.deletePoll(tripId, pollId),
      cache: (_) => _local.deletePoll(pollId),
    );
  }
}
