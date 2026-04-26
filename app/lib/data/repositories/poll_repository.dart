import 'package:injectable/injectable.dart';
import '../../../core/models/paginated_list.dart';
import '../../core/error/result.dart';
import '../datasources/interfaces/i_poll_local_data_source.dart';
import '../datasources/interfaces/i_poll_remote_data_source.dart';
import '../models/poll.dart';
import 'interfaces/i_poll_repository.dart';

/// 投票 Repository
@LazySingleton(as: IPollRepository)
class PollRepository implements IPollRepository {
  final IPollLocalDataSource _localDataSource;
  final IPollRemoteDataSource _remoteDataSource;

  PollRepository(this._localDataSource, this._remoteDataSource);

  @override
  Future<Result<void, Exception>> init() async {
    return const Success(null);
  }

  @override
  List<Poll> getByTripId(String tripId) => _localDataSource.getAllPolls().where((p) => p.tripId == tripId).toList();

  @override
  Future<Result<PaginatedList<Poll>, Exception>> syncPolls(String tripId, {int? page, int? limit}) async {
    try {
      final result = await _remoteDataSource.getPolls(tripId, page: page, limit: limit);
      if (result is Success<PaginatedList<Poll>, Exception>) {
        await _localDataSource.savePolls(result.value.items);
      }
      return result;
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<String, Exception>> create({
    required String tripId,
    required String title,
    required List<String> options,
    bool allowMultiple = false,
  }) async {
    try {
      final result = await _remoteDataSource.createPoll(
        tripId: tripId,
        title: title,
        options: options,
        allowMultiple: allowMultiple,
      );
      if (result is Success<String, Exception>) {
        await syncPolls(tripId);
      }
      return result;
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> vote({
    required String tripId,
    required String pollId,
    required List<String> optionIds,
  }) async {
    try {
      final result = await _remoteDataSource.vote(tripId, pollId, optionIds);
      if (result is Success) {
        await syncPolls(tripId);
      }
      return result;
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> addOption({
    required String tripId,
    required String pollId,
    required String optionText,
  }) async {
    try {
      final result = await _remoteDataSource.addOption(tripId, pollId, optionText);
      if (result is Success) {
        await syncPolls(tripId);
      }
      return result;
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> delete(String tripId, String pollId) async {
    try {
      final result = await _remoteDataSource.deletePoll(tripId, pollId);
      if (result is Success) {
        await _localDataSource.deletePoll(pollId);
      }
      return result;
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }
}
