import 'package:drift/drift.dart';
import 'package:summitmate/infrastructure/database/app_database.dart';
import '../../domain/entities/group_event.dart';
import '../../domain/enums/group_event_status.dart';
import '../../domain/enums/group_event_application_status.dart';
import '../../domain/enums/group_event_category.dart';

class GroupEventsTable extends Table {
  TextColumn get id => text()();
  TextColumn get creatorId => text()();
  TextColumn get title => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get category => text().map(const GroupEventCategoryConverter()).withDefault(const Constant('other'))();
  TextColumn get location => text().withDefault(const Constant(''))();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get status => text().map(const GroupEventStatusConverter()).withDefault(const Constant('open'))();
  IntColumn get maxMembers => integer().withDefault(const Constant(10))();
  IntColumn get applicationCount => integer().withDefault(const Constant(0))();
  IntColumn get totalApplicationCount => integer().withDefault(const Constant(0))();
  BoolColumn get approvalRequired => boolean().withDefault(const Constant(false))();
  TextColumn get privateMessage => text().withDefault(const Constant(''))();
  TextColumn get linkedTripId => text().nullable()();
  DateTimeColumn get snapshotUpdatedAt => dateTime().nullable()();
  IntColumn get likeCount => integer().withDefault(const Constant(0))();
  IntColumn get commentCount => integer().withDefault(const Constant(0))();
  BoolColumn get isLiked => boolean().withDefault(const Constant(false))();
  TextColumn get myApplicationStatus => text().map(const GroupEventApplicationStatusConverter()).nullable()();
  TextColumn get creatorName => text().withDefault(const Constant(''))();
  TextColumn get creatorAvatar => text().withDefault(const Constant('🐻'))();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get createdBy => text()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get updatedBy => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class GroupEventApplicationsTable extends Table {
  TextColumn get id => text()();
  TextColumn get eventId => text()();
  TextColumn get userId => text()();
  TextColumn get status =>
      text().map(const GroupEventApplicationStatusConverter()).withDefault(const Constant('pending'))();
  TextColumn get message => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get updatedBy => text()();
  TextColumn get userName => text().withDefault(const Constant(''))();
  TextColumn get userAvatar => text().withDefault(const Constant('🐻'))();

  @override
  Set<Column> get primaryKey => {id};
}

class GroupEventCategoryConverter extends TypeConverter<GroupEventCategory, String> {
  const GroupEventCategoryConverter();
  @override
  GroupEventCategory fromSql(String fromDb) =>
      GroupEventCategory.values.firstWhere((e) => e.name == fromDb, orElse: () => GroupEventCategory.other);
  @override
  String toSql(GroupEventCategory value) => value.name;
}

class GroupEventStatusConverter extends TypeConverter<GroupEventStatus, String> {
  const GroupEventStatusConverter();
  @override
  GroupEventStatus fromSql(String fromDb) =>
      GroupEventStatus.values.firstWhere((e) => e.name == fromDb, orElse: () => GroupEventStatus.open);
  @override
  String toSql(GroupEventStatus value) => value.name;
}

class GroupEventApplicationStatusConverter extends TypeConverter<GroupEventApplicationStatus, String> {
  const GroupEventApplicationStatusConverter();
  @override
  GroupEventApplicationStatus fromSql(String fromDb) => GroupEventApplicationStatus.values.firstWhere(
    (e) => e.name == fromDb,
    orElse: () => GroupEventApplicationStatus.pending,
  );
  @override
  String toSql(GroupEventApplicationStatus value) => value.name;
}

extension GroupEventMapping on GroupEvent {
  GroupEventsTableCompanion toCompanion() {
    return GroupEventsTableCompanion.insert(
      id: id,
      creatorId: creatorId,
      title: title,
      description: Value(description),
      category: Value(category),
      location: Value(location),
      startDate: startDate,
      endDate: Value(endDate),
      status: Value(status),
      maxMembers: Value(maxMembers),
      applicationCount: Value(applicationCount),
      totalApplicationCount: Value(totalApplicationCount),
      approvalRequired: Value(approvalRequired),
      privateMessage: Value(privateMessage),
      linkedTripId: Value(linkedTripId),
      snapshotUpdatedAt: Value(snapshotUpdatedAt),
      likeCount: Value(likeCount),
      commentCount: Value(commentCount),
      isLiked: Value(isLiked),
      myApplicationStatus: Value(myApplicationStatus),
      creatorName: Value(creatorName),
      creatorAvatar: Value(creatorAvatar),
      createdAt: createdAt,
      createdBy: createdBy,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
    );
  }
}

extension GroupEventApplicationMapping on GroupEventApplication {
  GroupEventApplicationsTableCompanion toCompanion() {
    return GroupEventApplicationsTableCompanion.insert(
      id: id,
      eventId: eventId,
      userId: userId,
      status: Value(status),
      message: Value(message),
      createdAt: createdAt,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
      userName: Value(userName),
      userAvatar: Value(userAvatar),
    );
  }
}
