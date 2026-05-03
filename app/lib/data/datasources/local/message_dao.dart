import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import '../../../infrastructure/database/app_database.dart';
import '../../../domain/entities/message.dart';
import '../interfaces/i_message_local_data_source.dart';
import '../../models/message_table.dart';
import '../../models/sync_meta_data_table.dart';

part 'message_dao.g.dart';

@DriftAccessor(tables: [MessagesTable, SyncMetaDataTable])
@LazySingleton(as: IMessageLocalDataSource)
class MessageDao extends DatabaseAccessor<AppDatabase> with _$MessageDaoMixin implements IMessageLocalDataSource {
  MessageDao(AppDatabase db) : super(db);

  @override
  Future<List<Message>> getAll() async {
    final rows = await select(messagesTable).get();
    return rows.map((row) => _mapToDomain(row)).toList();
  }

  @override
  Future<Message?> getById(String id) async {
    final query = select(messagesTable)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _mapToDomain(row) : null;
  }

  @override
  Future<void> add(Message message) async {
    await into(messagesTable).insertOnConflictUpdate(message.toCompanion());
  }

  @override
  Future<void> deleteById(String id) async {
    await (delete(messagesTable)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> clear() async {
    await delete(messagesTable).go();
  }

  @override
  Stream<List<Message>> watch() {
    return select(messagesTable).watch().map((rows) => rows.map((row) => _mapToDomain(row)).toList());
  }

  @override
  Future<void> saveLastSyncTime(DateTime time) async {
    await into(syncMetaDataTable).insertOnConflictUpdate(
      SyncMetaDataTableCompanion.insert(
        key: 'messages',
        lastSyncTime: Value(time),
      ),
    );
  }

  @override
  Future<DateTime?> getLastSyncTime() async {
    final query = select(syncMetaDataTable)..where((t) => t.key.equals('messages'));
    final row = await query.getSingleOrNull();
    return row?.lastSyncTime;
  }

  Message _mapToDomain(MessagesTableData row) {
    return Message(
      id: row.id,
      tripId: row.tripId,
      parentId: row.parentId,
      userId: row.userId,
      user: row.user,
      avatar: row.avatar,
      category: row.category,
      content: row.content,
      timestamp: row.timestamp,
      createdAt: row.createdAt ?? DateTime.now(),
      createdBy: row.createdBy ?? '',
      updatedAt: row.updatedAt ?? DateTime.now(),
      updatedBy: row.updatedBy ?? '',
    );
  }
}
