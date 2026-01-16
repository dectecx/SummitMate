import 'package:shared_preferences/shared_preferences.dart';
import '../../core/error/result.dart';
import '../../core/di.dart';
import '../../infrastructure/tools/log_service.dart';
import 'interfaces/i_poll_repository.dart';
import '../datasources/interfaces/i_poll_local_data_source.dart';
import '../datasources/interfaces/i_poll_remote_data_source.dart';
import '../models/poll.dart';

/// 投票 Repository (支援 Offline-First)
///
/// 協調 LocalDataSource (Hive) 與 RemoteDataSource (API) 的資料存取。
class PollRepository implements IPollRepository {
  static const String _source = 'PollRepository';
  static const String _lastSyncKey = 'poll_last_sync_time';

  final IPollLocalDataSource _localDataSource;
  final IPollRemoteDataSource _remoteDataSource;

  PollRepository({
    required IPollLocalDataSource localDataSource,
    required IPollRemoteDataSource remoteDataSource,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource;

  // ========== Init ==========

  @override
  Future<Result<void, Exception>> init() async {
    try {
      await _localDataSource.init();
      return const Success(null);
    } catch (e) {
      LogService.error('Init failed: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
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
  Future<Result<void, Exception>> sync({required String userId}) async {
    try {
      LogService.info('Syncing polls for user: $userId', source: _source);
      final polls = await _remoteDataSource.getPolls(userId: userId);
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
    required String title,
    String description = '',
    required String creatorId,
    DateTime? deadline,
    bool isAllowAddOption = false,
    int maxOptionLimit = 20,
    bool allowMultipleVotes = false,
    List<String> initialOptions = const [],
  }) async {
    try {
      final id = await _remoteDataSource.createPoll(
        title: title,
        description: description,
        creatorId: creatorId,
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
    required String pollId,
    required List<String> optionIds,
    required String userId,
    String userName = 'Anonymous',
  }) async {
    try {
      await _remoteDataSource.votePoll(
        pollId: pollId,
        optionIds: optionIds,
        userId: userId,
        userName: userName,
      );
      return const Success(null);
    } catch (e) {
      LogService.error('Vote failed: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> addOption({
    required String pollId,
    required String text,
    required String creatorId,
  }) async {
    try {
      await _remoteDataSource.addOption(pollId: pollId, text: text, creatorId: creatorId);
      return const Success(null);
    } catch (e) {
      LogService.error('Add option failed: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> close({required String pollId, required String userId}) async {
    try {
      await _remoteDataSource.closePoll(pollId: pollId, userId: userId);
      return const Success(null);
    } catch (e) {
      LogService.error('Close poll failed: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> remove({required String pollId, required String userId}) async {
    try {
      await _remoteDataSource.deletePoll(pollId: pollId, userId: userId);
      await _localDataSource.deletePoll(pollId);
      LogService.info('Removed poll: $pollId', source: _source);
      return const Success(null);
    } catch (e) {
      LogService.error('Remove poll failed: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> removeOption({required String optionId, required String userId}) async {
    try {
      await _remoteDataSource.deleteOption(optionId: optionId, userId: userId);
      return const Success(null);
    } catch (e) {
      LogService.error('Remove option failed: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }
}
