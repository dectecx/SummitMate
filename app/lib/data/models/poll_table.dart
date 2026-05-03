import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:summitmate/infrastructure/database/app_database.dart';
import '../../domain/entities/poll.dart';

// TODO: 確認是否需要建立 Foreign Key 關聯 TripTable
class PollsTable extends Table {
  TextColumn get id => text()();
  TextColumn get tripId => text().withDefault(const Constant(''))();
  TextColumn get title => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get creatorId => text()();
  DateTimeColumn get deadline => dateTime().nullable()();
  BoolColumn get isAllowAddOption => boolean().withDefault(const Constant(false))();
  IntColumn get maxOptionLimit => integer().withDefault(const Constant(20))();
  BoolColumn get allowMultipleVotes => boolean().withDefault(const Constant(false))();
  TextColumn get resultDisplayType => text().withDefault(const Constant('realtime'))();
  TextColumn get status => text().withDefault(const Constant('active'))();

  // TODO: 確認 List<String> 序列化是否合適
  TextColumn get myVotes => text().map(const PollListStringTypeConverter()).withDefault(const Constant('[]'))();
  IntColumn get totalVotes => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get createdBy => text()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get updatedBy => text()();

  @override
  Set<Column> get primaryKey => {id};
}

// TODO: 確認 PollOption 是否要用獨立表，或是使用 JSON
class PollOptionsTable extends Table {
  TextColumn get id => text()();
  TextColumn get pollId => text()();
  TextColumn get textContent => text()(); // Avoid using "text" as it's a keyword in SQLite, mapped from text
  TextColumn get creatorId => text()();
  IntColumn get voteCount => integer().withDefault(const Constant(0))();

  // TODO: 確認 Voters 的 JSON List 儲存是否為最佳實踐
  TextColumn get voters => text().map(const VotersConverter()).withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get createdBy => text()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get updatedBy => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class PollListStringTypeConverter extends TypeConverter<List<String>, String> {
  const PollListStringTypeConverter();
  @override
  List<String> fromSql(String fromDb) => List<String>.from(json.decode(fromDb));
  @override
  String toSql(List<String> value) => json.encode(value);
}

class VotersConverter extends TypeConverter<List<Map<String, dynamic>>, String> {
  const VotersConverter();
  @override
  List<Map<String, dynamic>> fromSql(String fromDb) => List<Map<String, dynamic>>.from(json.decode(fromDb));
  @override
  String toSql(List<Map<String, dynamic>> value) => json.encode(value);
}

extension PollMapping on Poll {
  PollsTableCompanion toCompanion() {
    return PollsTableCompanion.insert(
      id: id,
      tripId: Value(tripId),
      title: title,
      description: Value(description),
      creatorId: creatorId,
      deadline: Value(deadline),
      isAllowAddOption: Value(isAllowAddOption),
      maxOptionLimit: Value(maxOptionLimit),
      allowMultipleVotes: Value(allowMultipleVotes),
      resultDisplayType: Value(resultDisplayType),
      status: Value(status),
      myVotes: Value(myVotes),
      totalVotes: Value(totalVotes),
      createdAt: createdAt,
      createdBy: createdBy,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
    );
  }
}

extension PollOptionMapping on PollOption {
  PollOptionsTableCompanion toCompanion() {
    return PollOptionsTableCompanion.insert(
      id: id,
      pollId: pollId,
      textContent: text,
      creatorId: creatorId,
      voteCount: Value(voteCount),
      voters: Value(voters),
      createdAt: createdAt,
      createdBy: createdBy,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
    );
  }
}
