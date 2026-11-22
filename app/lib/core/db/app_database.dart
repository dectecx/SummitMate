import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Trips, TripMembers, ItineraryItems, GearItems, MealPlanDays, MealItems, LibraryItems, Templates, TripMessages, Polls, PollOptions, PollVotes, Favorites, Outbox, AppMeta, AppSettings, WeatherCache, HttpCache, OfflineRegions],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// The on-device database used by the app.
  factory AppDatabase.open() => AppDatabase(driftDatabase(name: 'summitmate'));

  // Initial development: no migrations. Change the tables and reinstall (see AGENTS.md).
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement('CREATE INDEX idx_outbox_entity ON outbox(entity, entity_id)');
      await customStatement('CREATE INDEX idx_itinerary_trip ON itinerary_items(trip_id)');
      await customStatement('CREATE INDEX idx_gear_trip ON gear_items(trip_id)');
      await customStatement('CREATE INDEX idx_meal_days_trip ON meal_plan_days(trip_id)');
      await customStatement('CREATE INDEX idx_meal_items_trip ON meal_items(trip_id)');
      await customStatement('CREATE INDEX idx_messages_trip ON trip_messages(trip_id)');
      await customStatement('CREATE INDEX idx_polls_trip ON polls(trip_id)');
      await customStatement('CREATE INDEX idx_poll_options_poll ON poll_options(poll_id)');
      await customStatement('CREATE INDEX idx_poll_votes_poll ON poll_votes(poll_id)');
      await customStatement('CREATE INDEX idx_members_trip ON trip_members(trip_id)');
      await into(appMeta).insert(AppMetaCompanion.insert());
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
