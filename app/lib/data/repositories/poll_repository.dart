import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/error/result.dart';
import '../../core/di/injection.dart';
import '../../infrastructure/tools/log_service.dart';
import 'interfaces/i_poll_repository.dart';
import '../datasources/interfaces/i_poll_local_data_source.dart';
import '../datasources/interfaces/i_poll_remote_data_source.dart';
import '../models/poll.dart';

/// 投票 Repository (支援 Offline-First)
///
/// 協調 LocalDataSource (Hive) 與 RemoteDataSource (API) 的資料存取。
@LazySingleton(as: IPollRepository)
class PollRepository implements IPollRepository {
  static const String _source = 'PollRepository';
  static const String _lastSyncKey = 'poll_last_sync_time';

  final IPollLocalDataSource _localDataSource;
  final IPollRemoteDataSource _remoteDataSource;

  PollRepository({required IPollLocalDataSource localDataSource, required IPollRemoteDataSource remoteDataSource})
    : _localDataSource = localDataSource,
      _remoteDataSource = remoteDataSource;

  // ========== Init ==========

  @override
  Future<Result<void, Exception>> init() async {
    return const Success(null);
  }

  // ========== Data Operations ==========

  @override
  List<Poll> getAll() => _localDataSource.getAllPolls();

  @override
  Poll? getById(String id) => _localDataSource.getPollById(id);

  @override
  Future<void> saveAll(List<Poll> polls) => _localDataSource.savePolls(polls);

  @override
  Future<void> save(Poll poll) => _localDataSource.savePoll(poll);

  @override
  Future<void> delete(String id) => _localDataSource.deletePoll(id);

  @override
  Future<Result<void, Exception>> clearAll() async {
    try {
      LogService.info('Clearing all polls (Local)', source: _source);
      await _localDataSource.clear();
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  // ========== Sync Operations ==========

  @override
  Future<Result<void, Exception>> sync({required String tripId}) async {
    try {
      LogService.info('Syncing polls for trip: $tripId', source: _source);
      final polls = await _remoteDataSource.getPolls(tripId);
      await _localDataSource.savePolls(polls);
      await _saveLastSyncTime(DateTime.now());
      LogService.info('Synced ${polls.length} polls', source: _source);
      return const Success(null);
    } catch (e) {
      LogService.error('Sync failed: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  DateTime? getLastSyncTime() {
    final prefs = getIt<SharedPreferences>();
    final str = prefs.getString(_lastSyncKey);
    if (str == null) return null;
    return DateTime.tryParse(str);
  }

  Future<void> _saveLastSyncTime(DateTime time) async {
    final prefs = getIt<SharedPreferences>();
    await prefs.setString(_lastSyncKey, time.toIso8601String());
  }

  // ========== Remote Write Operations ==========

  @override
  Future<Result<String, Exception>> create({
    required String tripId,
    required String title,
    String description = '',
    DateTime? deadline,
    bool isAllowAddOption = false,
    int maxOptionLimit = 20,
    bool allowMultipleVotes = false,
    List<String> initialOptions = const [],
  }) async {
    try {
      final id = await _remoteDataSource.createPoll(
        tripId: tripId,
        title: title,
        description: description,
        deadline: deadline,
        isAllowAddOption: isAllowAddOption,
        maxOptionLimit: maxOptionLimit,
        allowMultipleVotes: allowMultipleVotes,
        initialOptions: initialOptions,
      );
      LogService.info('Created poll: $id', source: _source);
      return Success(id);
    } catch (e) {
      LogService.error('Create poll failed: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> vote({
    required String tripId,
    required String pollId,
    required String optionId,
  }) async {
    try {
      await _remoteDataSource.voteOption(tripId: tripId, pollId: pollId, optionId: optionId);
      return const Success(null);
    } catch (e) {
      LogService.error('Vote failed: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> addOption({
    required String tripId,
    required String pollId,
    required String text,
  }) async {
    try {
      await _remoteDataSource.addOption(tripId: tripId, pollId: pollId, text: text);
      return const Success(null);
    } catch (e) {
      LogService.error('Add option failed: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> remove({required String tripId, required String pollId}) async {
    try {
      await _remoteDataSource.deletePoll(tripId: tripId, pollId: pollId);
      await _localDataSource.deletePoll(pollId);
      LogService.info('Removed poll: $pollId', source: _source);
      return const Success(null);
    } catch (e) {
      LogService.error('Remove poll failed: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> removeOption({
    required String tripId,
    required String pollId,
    required String optionId,
  }) async {
    try {
      await _remoteDataSource.deleteOption(tripId: tripId, pollId: pollId, optionId: optionId);
      return const Success(null);
    } catch (e) {
      LogService.error('Remove option failed: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }
}
