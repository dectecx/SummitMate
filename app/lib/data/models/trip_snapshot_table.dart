import 'package:drift/drift.dart';
import 'package:summitmate/infrastructure/database/app_database.dart';
import '../../domain/entities/trip_snapshot.dart';

class TripSnapshotsTable extends Table {
  TextColumn get id => text()(); // Trip Id 也可以當作 Primary Key
  TextColumn get name => text()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

extension TripSnapshotMapping on TripSnapshot {
  TripSnapshotsTableCompanion toCompanion(String id) {
    return TripSnapshotsTableCompanion.insert(id: id, name: name, startDate: startDate, endDate: Value(endDate));
  }
}
