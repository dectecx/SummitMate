import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import '../../infrastructure/database/app_database.dart';
import '../datasources/interfaces/i_group_event_local_data_source.dart';
import '../models/group_event_table.dart';
import '../../domain/entities/group_event.dart';

part 'group_event_dao.g.dart';

@LazySingleton(as: IGroupEventLocalDataSource)
@DriftAccessor(tables: [GroupEventsTable, GroupEventApplicationsTable])
class GroupEventDao extends DatabaseAccessor<AppDatabase>
    with _$GroupEventDaoMixin
    implements IGroupEventLocalDataSource {
  GroupEventDao(AppDatabase db) : super(db);

  @override
  Future<List<GroupEvent>> getAllEvents() async {
    final rows = await select(groupEventsTable).get();
    return rows.map((row) => _mapToDomain(row)).toList();
  }

  @override
  Future<GroupEvent?> getEventById(String id) async {
    final query = select(groupEventsTable)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _mapToDomain(row) : null;
  }

  @override
  Future<void> saveEvents(List<GroupEvent> events) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(groupEventsTable, events.map((e) => e.toCompanion()).toList());
    });
  }

  @override
  Future<void> saveEvent(GroupEvent event) async {
    await into(groupEventsTable).insertOnConflictUpdate(event.toCompanion());
  }

  @override
  Future<void> deleteEvent(String id) async {
    await (delete(groupEventsTable)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<List<GroupEventApplication>> getAllApplications() async {
    final rows = await select(groupEventApplicationsTable).get();
    return rows.map((row) => _mapApplicationToDomain(row)).toList();
  }

  @override
  Future<void> saveApplications(List<GroupEventApplication> applications) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(groupEventApplicationsTable, applications.map((a) => a.toCompanion()).toList());
    });
  }

  @override
  Future<void> clear() async {
    await delete(groupEventsTable).go();
    await delete(groupEventApplicationsTable).go();
  }

  GroupEvent _mapToDomain(GroupEventsTableData row) {
    return GroupEvent(
      id: row.id,
      creatorId: row.creatorId,
      title: row.title,
      description: row.description,
      category: row.category,
      location: row.location,
      startDate: row.startDate,
      endDate: row.endDate,
      status: row.status,
      maxMembers: row.maxMembers,
      applicationCount: row.applicationCount,
      totalApplicationCount: row.totalApplicationCount,
      approvalRequired: row.approvalRequired,
      privateMessage: row.privateMessage,
      linkedTripId: row.linkedTripId,
      snapshotUpdatedAt: row.snapshotUpdatedAt,
      likeCount: row.likeCount,
      commentCount: row.commentCount,
      isLiked: row.isLiked,
      myApplicationStatus: row.myApplicationStatus,
      creatorName: row.creatorName,
      creatorAvatar: row.creatorAvatar,
      createdAt: row.createdAt,
      createdBy: row.createdBy,
      updatedAt: row.updatedAt,
      updatedBy: row.updatedBy,
    );
  }

  GroupEventApplication _mapApplicationToDomain(GroupEventApplicationsTableData row) {
    return GroupEventApplication(
      id: row.id,
      eventId: row.eventId,
      userId: row.userId,
      status: row.status,
      message: row.message,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      updatedBy: row.updatedBy,
      userName: row.userName,
      userAvatar: row.userAvatar,
    );
  }
}
