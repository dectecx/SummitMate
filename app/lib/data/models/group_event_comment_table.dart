import 'package:drift/drift.dart';
import 'package:summitmate/infrastructure/database/app_database.dart';
import '../../domain/entities/group_event_comment.dart';

class GroupEventCommentsTable extends Table {
  TextColumn get id => text()();
  TextColumn get eventId => text()();
  TextColumn get userId => text()();
  TextColumn get content => text()();
  TextColumn get userName => text()();
  TextColumn get userAvatar => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

extension GroupEventCommentMapping on GroupEventComment {
  GroupEventCommentsTableCompanion toCompanion() {
    return GroupEventCommentsTableCompanion.insert(
      id: id,
      eventId: eventId,
      userId: userId,
      content: content,
      userName: userName,
      userAvatar: userAvatar,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
