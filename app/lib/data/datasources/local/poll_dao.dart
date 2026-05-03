import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import '../../../infrastructure/database/app_database.dart';
import '../../../domain/entities/poll.dart';
import '../interfaces/i_poll_local_data_source.dart';
import '../../models/poll_table.dart';
import '../../models/sync_meta_data_table.dart';

part 'poll_dao.g.dart';

@DriftAccessor(tables: [PollsTable, PollOptionsTable, SyncMetaDataTable])
@LazySingleton(as: IPollLocalDataSource)
class PollDao extends DatabaseAccessor<AppDatabase> with _$PollDaoMixin implements IPollLocalDataSource {
  PollDao(AppDatabase db) : super(db);

  @override
  Future<List<Poll>> getAllPolls() async {
    final polls = await select(pollsTable).get();
    final results = <Poll>[];
    for (final pollRow in polls) {
      final options = await (select(pollOptionsTable)..where((o) => o.pollId.equals(pollRow.id))).get();
      results.add(_mapToDomain(pollRow, options));
    }
    return results;
  }

  @override
  Future<Poll?> getPollById(String id) async {
    final pollRow = await (select(pollsTable)..where((p) => p.id.equals(id))).getSingleOrNull();
    if (pollRow == null) return null;
    final options = await (select(pollOptionsTable)..where((o) => o.pollId.equals(id))).get();
    return _mapToDomain(pollRow, options);
  }

  @override
  Future<void> savePolls(List<Poll> polls) async {
    await transaction(() async {
      await delete(pollsTable).go();
      await delete(pollOptionsTable).go();
      for (final poll in polls) {
        await savePoll(poll);
      }
    });
  }

  @override
  Future<void> savePoll(Poll poll) async {
    await transaction(() async {
      await into(pollsTable).insertOnConflictUpdate(poll.toCompanion());
      // 先刪除舊選項，再插入新選項 (或使用 upsert)
      await (delete(pollOptionsTable)..where((o) => o.pollId.equals(poll.id))).go();
      for (final option in poll.options) {
        await into(pollOptionsTable).insert(option.toCompanion());
      }
    });
  }

  @override
  Future<void> deletePoll(String id) async {
    await transaction(() async {
      await (delete(pollOptionsTable)..where((o) => o.pollId.equals(id))).go();
      await (delete(pollsTable)..where((p) => p.id.equals(id))).go();
    });
  }

  @override
  Future<void> clear() async {
    await transaction(() async {
      await delete(pollOptionsTable).go();
      await delete(pollsTable).go();
    });
  }

  @override
  Future<void> saveLastSyncTime(DateTime time) async {
    await into(syncMetaDataTable).insertOnConflictUpdate(
      SyncMetaDataTableCompanion.insert(
        key: 'polls',
        lastSyncTime: Value(time),
      ),
    );
  }

  @override
  Future<DateTime?> getLastSyncTime() async {
    final query = select(syncMetaDataTable)..where((t) => t.key.equals('polls'));
    final row = await query.getSingleOrNull();
    return row?.lastSyncTime;
  }

  Poll _mapToDomain(PollsTableData row, List<PollOptionsTableData> optionsRows) {
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
      options: optionsRows.map((o) => _mapOptionToDomain(o)).toList(),
      myVotes: row.myVotes,
      totalVotes: row.totalVotes,
      createdAt: row.createdAt ?? DateTime.now(),
      createdBy: row.createdBy ?? '',
      updatedAt: row.updatedAt ?? DateTime.now(),
      updatedBy: row.updatedBy ?? '',
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
      createdAt: row.createdAt ?? DateTime.now(),
      createdBy: row.createdBy ?? '',
      updatedAt: row.updatedAt ?? DateTime.now(),
      updatedBy: row.updatedBy ?? '',
    );
  }
}
