import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import '../../infrastructure/database/app_database.dart';
import '../datasources/interfaces/i_poll_local_data_source.dart';
import '../models/poll_table.dart';
import '../../domain/entities/poll.dart';

part 'poll_dao.g.dart';

@LazySingleton(as: IPollLocalDataSource)
@DriftAccessor(tables: [PollsTable, PollOptionsTable])
class PollDao extends DatabaseAccessor<AppDatabase> with _$PollDaoMixin implements IPollLocalDataSource {
  PollDao(AppDatabase db) : super(db);

  @override
  Future<List<Poll>> getAllPolls() async {
    final pollRows = await select(pollsTable).get();
    final polls = <Poll>[];

    for (final pollRow in pollRows) {
      final options = await _getOptionsForPoll(pollRow.id);
      polls.add(_mapToDomain(pollRow, options));
    }
    return polls;
  }

  @override
  Future<Poll?> getPollById(String id) async {
    final query = select(pollsTable)..where((t) => t.id.equals(id));
    final pollRow = await query.getSingleOrNull();
    if (pollRow == null) return null;

    final options = await _getOptionsForPoll(id);
    return _mapToDomain(pollRow, options);
  }

  @override
  Future<void> savePolls(List<Poll> polls) async {
    await batch((batch) {
      for (final poll in polls) {
        batch.insertAllOnConflictUpdate(pollsTable, [poll.toCompanion()]);
        batch.insertAllOnConflictUpdate(pollOptionsTable, poll.options.map((o) => o.toCompanion()).toList());
      }
    });
  }

  @override
  Future<void> savePoll(Poll poll) async {
    await transaction(() async {
      await into(pollsTable).insertOnConflictUpdate(poll.toCompanion());
      // 先刪除舊的選項再插入新的，確保選項一致
      await (delete(pollOptionsTable)..where((t) => t.pollId.equals(poll.id))).go();
      for (final option in poll.options) {
        await into(pollOptionsTable).insertOnConflictUpdate(option.toCompanion());
      }
    });
  }

  @override
  Future<void> deletePoll(String id) async {
    await transaction(() async {
      await (delete(pollOptionsTable)..where((t) => t.pollId.equals(id))).go();
      await (delete(pollsTable)..where((t) => t.id.equals(id))).go();
    });
  }

  @override
  Future<void> clear() async {
    await transaction(() async {
      await delete(pollOptionsTable).go();
      await delete(pollsTable).go();
    });
  }

  Future<List<PollOption>> _getOptionsForPoll(String pollId) async {
    final query = select(pollOptionsTable)..where((t) => t.pollId.equals(pollId));
    final rows = await query.get();
    return rows.map((row) => _mapOptionToDomain(row)).toList();
  }

  Poll _mapToDomain(PollsTableData row, List<PollOption> options) {
    return Poll(
      id: row.id,
      tripId: row.tripId,
      title: row.title,
      description: row.description,
      creatorId: row.creatorId,
      deadline: row.deadline,
      isAllowAddOption: row.isAllowAddOption,
      maxOptionLimit: row.maxOptionLimit,
      allowMultipleVotes: row.allowMultipleVotes,
      resultDisplayType: row.resultDisplayType,
      status: row.status,
      options: options,
      myVotes: row.myVotes,
      totalVotes: row.totalVotes,
      createdAt: row.createdAt,
      createdBy: row.createdBy,
      updatedAt: row.updatedAt,
      updatedBy: row.updatedBy,
    );
  }

  PollOption _mapOptionToDomain(PollOptionsTableData row) {
    return PollOption(
      id: row.id,
      pollId: row.pollId,
      text: row.textContent,
      creatorId: row.creatorId,
      voteCount: row.voteCount,
      voters: row.voters,
      createdAt: row.createdAt,
      createdBy: row.createdBy,
      updatedAt: row.updatedAt,
      updatedBy: row.updatedBy,
    );
  }
}
