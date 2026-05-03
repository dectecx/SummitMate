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
import '../../data/models/sync_meta_data_table.dart';
import '../../data/models/log_table.dart';
import '../../data/models/weather_table.dart';

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
    SyncMetaDataTable,
    LogsTable,
    WeatherDataTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  /// 清除所有資料
  Future<void> clearAllData() async {
    await transaction(() async {
      for (final table in allTables) {
        await delete(table).go();
      }
    });
  }

  /// 選擇性清除資料
  Future<void> clearSelectedData({
    bool trips = false,
    bool messages = false,
    bool gear = false,
    bool gearLibrary = false,
    bool polls = false,
    bool groupEvents = false,
    bool favorites = false,
    bool logs = false,
    bool settings = false,
    bool weather = false,
  }) async {
    await transaction(() async {
      if (trips) {
        await delete(tripsTable).go();
        await delete(itineraryItemsTable).go();
        await delete(tripSnapshotsTable).go();
      }
      if (messages) await delete(messagesTable).go();
      if (gear) await delete(gearItemsTable).go();
      if (gearLibrary) await delete(gearLibraryItemsTable).go();
      if (polls) {
        await delete(pollsTable).go();
        await delete(pollOptionsTable).go();
      }
      if (groupEvents) {
        await delete(groupEventsTable).go();
        await delete(groupEventApplicationsTable).go();
        await delete(groupEventCommentsTable).go();
      }
      if (favorites) await delete(favoritesTable).go();
      if (logs) await delete(logsTable).go();
      if (settings) await delete(settingsTable).go();
      if (weather) await delete(weatherDataTable).go();
    });
  }
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'summitmate_db', native: const DriftNativeOptions());
}
