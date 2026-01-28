import 'package:hive/hive.dart';
import '../../models/poll.dart';
import '../../../core/constants.dart';
import '../../../infrastructure/tools/hive_service.dart';
import '../interfaces/i_poll_local_data_source.dart';

/// 投票本地資料來源實作 (Hive)
class PollLocalDataSource implements IPollLocalDataSource {
  final HiveService _hiveService;
  Box<Poll>? _box;

  PollLocalDataSource({required HiveService hiveService}) : _hiveService = hiveService;

  @override
  Future<void> init() async {
    _box = await _hiveService.openBox<Poll>(HiveBoxNames.polls);
  }

  Box<Poll> get _polls {
    if (_box == null || !_box!.isOpen) {
      throw StateError('PollLocalDataSource not initialized. Call init() first.');
    }
    return _box!;
  }

  @override
  List<Poll> getAllPolls() => _polls.values.toList();

  @override
  Poll? getPollById(String id) {
    try {
      return _polls.values.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> savePolls(List<Poll> polls) async {
    await _polls.clear();
    final Map<String, Poll> entries = {for (var poll in polls) poll.id: poll};
    await _polls.putAll(entries);
  }

  @override
  Future<void> savePoll(Poll poll) async {
    await _polls.put(poll.id, poll);
  }

  @override
  Future<void> deletePoll(String id) async {
    await _polls.delete(id);
  }

  @override
  Future<void> clear() async {
    await _polls.clear();
  }
}
