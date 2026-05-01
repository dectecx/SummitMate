import 'package:injectable/injectable.dart';
import 'package:hive_ce/hive.dart';
import '../../models/poll_model.dart';
import '../../../core/constants.dart';
import '../../../infrastructure/tools/hive_service.dart';
import '../interfaces/i_poll_local_data_source.dart';

/// 投票本地資料來源實作 (Hive)
@LazySingleton(as: IPollLocalDataSource)
class PollLocalDataSource implements IPollLocalDataSource {
  final Box<PollModel> _polls;

  PollLocalDataSource({required HiveService hiveService}) : _polls = hiveService.getBox<PollModel>(HiveBoxNames.polls);

  @override
  List<PollModel> getAllPolls() => _polls.values.toList();

  @override
  PollModel? getPollById(String id) {
    try {
      return _polls.values.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> savePolls(List<PollModel> polls) async {
    await _polls.clear();
    final Map<String, PollModel> entries = {for (var poll in polls) poll.id: poll};
    await _polls.putAll(entries);
  }

  @override
  Future<void> savePoll(PollModel poll) async {
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
