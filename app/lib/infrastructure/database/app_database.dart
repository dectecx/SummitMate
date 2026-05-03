import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

// Tables
import '../../data/models/settings_table.dart';
import '../../data/models/trip_table.dart';
import '../../data/models/gear_item_table.dart';
import '../../data/models/itinerary_item_table.dart';
import '../../data/models/message_table.dart';
import '../../data/models/poll_table.dart';
import '../../data/models/group_event_table.dart';
import '../../data/models/gear_library_item_table.dart';
import '../../data/models/group_event_comment_table.dart';
import '../../data/models/trip_snapshot_table.dart';
import '../../data/models/favorite_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    SettingsTable,
    TripsTable,
    GearItemsTable,
    ItineraryItemsTable,
    MessagesTable,
    PollsTable,
    PollOptionsTable,
    GroupEventsTable,
    GroupEventApplicationsTable,
    GearLibraryItemsTable,
    GroupEventCommentsTable,
    TripSnapshotsTable,
    FavoritesTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'summitmate_db', native: const DriftNativeOptions());
}
