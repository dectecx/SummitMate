/// Column value types used in server JSON and outbox patches.
enum ColType { text, integer, real, boolean, date, timestamp }

/// One synced column.
class Col {
  const Col(this.type, {this.nullable = false});
  final ColType type;
  final bool nullable;
}

/// Describes how a synced entity maps between server JSON, the local table and outbox patches.
///
/// The sync engine only uses these descriptors to build SQL, so a typo here cannot reach SQL as
/// long as `entity_descriptors_test.dart` passes (it checks them against the Drift tables).
class SyncEntity {
  const SyncEntity({required this.name, required this.columns, this.parents = const [], this.localOnlyColumns = const {}});

  /// Table name and the entity name used by the server.
  final String name;

  /// Synced columns, excluding `id`. Keys are snake_case column names.
  final Map<String, Col> columns;

  /// Foreign keys whose parent row must exist locally before this row can be stored.
  final List<Parent> parents;

  /// Columns that exist locally but are never synced (e.g. `is_sample`).
  final Set<String> localOnlyColumns;
}

class Parent {
  const Parent(this.column, this.table);
  final String column;
  final String table;
}

const tripsEntity = SyncEntity(
  name: 'trips',
  localOnlyColumns: {'is_sample'},
  columns: {
    'owner_id': Col(ColType.text, nullable: true),
    'name': Col(ColType.text),
    'description': Col(ColType.text),
    'start_date': Col(ColType.date),
    'end_date': Col(ColType.date, nullable: true),
    'mountain_id': Col(ColType.text, nullable: true),
    'track': Col(ColType.text, nullable: true),
    'cover_image': Col(ColType.text, nullable: true),
  },
);

const tripMembersEntity = SyncEntity(
  name: 'trip_members',
  parents: [Parent('trip_id', 'trips')],
  columns: {
    'trip_id': Col(ColType.text),
    'user_id': Col(ColType.text),
    'role': Col(ColType.text),
    'display_name': Col(ColType.text),
    'avatar': Col(ColType.text),
  },
);

const itineraryItemsEntity = SyncEntity(
  name: 'itinerary_items',
  parents: [Parent('trip_id', 'trips')],
  columns: {
    'trip_id': Col(ColType.text),
    'day_index': Col(ColType.integer),
    'name': Col(ColType.text),
    'est_minutes': Col(ColType.integer, nullable: true),
    'altitude': Col(ColType.integer),
    'distance': Col(ColType.real),
    'lat': Col(ColType.real, nullable: true),
    'lng': Col(ColType.real, nullable: true),
    'note': Col(ColType.text),
    'checked_in_at': Col(ColType.timestamp, nullable: true),
  },
);

const gearItemsEntity = SyncEntity(
  name: 'gear_items',
  parents: [Parent('trip_id', 'trips')],
  columns: {
    'trip_id': Col(ColType.text),
    'name': Col(ColType.text),
    'weight': Col(ColType.real),
    'category': Col(ColType.text),
    'quantity': Col(ColType.integer),
    'is_checked': Col(ColType.boolean),
    'sort_order': Col(ColType.integer),
  },
);

const mealPlanDaysEntity = SyncEntity(
  name: 'meal_plan_days',
  parents: [Parent('trip_id', 'trips')],
  columns: {
    'trip_id': Col(ColType.text),
    'name': Col(ColType.text),
    'day_index': Col(ColType.integer),
  },
);

const mealItemsEntity = SyncEntity(
  name: 'meal_items',
  parents: [Parent('trip_id', 'trips'), Parent('meal_plan_day_id', 'meal_plan_days')],
  columns: {
    'trip_id': Col(ColType.text),
    'meal_plan_day_id': Col(ColType.text),
    'meal_type': Col(ColType.text),
    'name': Col(ColType.text),
    'weight': Col(ColType.real),
    'calories': Col(ColType.real),
    'quantity': Col(ColType.integer),
    'note': Col(ColType.text),
  },
);

const libraryItemsEntity = SyncEntity(
  name: 'library_items',
  columns: {
    'kind': Col(ColType.text),
    'name': Col(ColType.text),
    'category': Col(ColType.text),
    'weight': Col(ColType.real),
    'calories': Col(ColType.real),
    'note': Col(ColType.text),
  },
);

const templatesEntity = SyncEntity(
  name: 'templates',
  columns: {
    'title': Col(ColType.text),
    'note': Col(ColType.text),
    'items': Col(ColType.text),
  },
);

// Collaboration. `user_id`, `created_at`, `updated_at` and `created_by` come from the server but are
// never uploaded (the server sets them), so repositories leave them out of patches.
const tripMessagesEntity = SyncEntity(
  name: 'trip_messages',
  parents: [Parent('trip_id', 'trips')], // parent_id is deliberately not a parent: replies can arrive first
  columns: {
    'trip_id': Col(ColType.text),
    'user_id': Col(ColType.text, nullable: true),
    'parent_id': Col(ColType.text, nullable: true),
    'body': Col(ColType.text),
    'created_at': Col(ColType.timestamp),
  },
);

const pollsEntity = SyncEntity(
  name: 'polls',
  parents: [Parent('trip_id', 'trips')],
  columns: {
    'trip_id': Col(ColType.text),
    'title': Col(ColType.text),
    'description': Col(ColType.text),
    'deadline': Col(ColType.timestamp, nullable: true),
    'allow_multiple': Col(ColType.boolean),
    'allow_add_option': Col(ColType.boolean),
    'blind': Col(ColType.boolean),
    'status': Col(ColType.text),
    'created_at': Col(ColType.timestamp),
  },
);

const pollOptionsEntity = SyncEntity(
  name: 'poll_options',
  parents: [Parent('trip_id', 'trips'), Parent('poll_id', 'polls')],
  columns: {
    'poll_id': Col(ColType.text),
    'trip_id': Col(ColType.text),
    'text': Col(ColType.text),
    'sort_order': Col(ColType.integer),
    'created_by': Col(ColType.text, nullable: true),
  },
);

const pollVotesEntity = SyncEntity(
  name: 'poll_votes',
  parents: [Parent('trip_id', 'trips'), Parent('poll_id', 'polls'), Parent('option_id', 'poll_options')],
  columns: {
    'poll_id': Col(ColType.text),
    'option_id': Col(ColType.text),
    'trip_id': Col(ColType.text),
    'user_id': Col(ColType.text, nullable: true),
    'updated_at': Col(ColType.timestamp),
  },
);

const favoritesEntity = SyncEntity(
  name: 'favorites',
  columns: {
    'kind': Col(ColType.text),
    'target_id': Col(ColType.text),
  },
);

/// All entities in pull/parent-first order.
const syncEntities = <SyncEntity>[
  tripsEntity,
  tripMembersEntity,
  itineraryItemsEntity,
  mealPlanDaysEntity,
  gearItemsEntity,
  mealItemsEntity,
  libraryItemsEntity,
  templatesEntity,
  tripMessagesEntity,
  pollsEntity,
  pollOptionsEntity,
  pollVotesEntity,
  favoritesEntity,
];

final Map<String, SyncEntity> syncEntityByName = {for (final e in syncEntities) e.name: e};

/// Converts a server JSON value to the value stored in SQLite.
/// Returns [FormatException] for values that do not match the column type.
Object? toSql(Col c, Object? v) {
  if (v == null) {
    if (!c.nullable) throw const FormatException('null for non-nullable column');
    return null;
  }
  switch (c.type) {
    case ColType.text:
      if (v is String) return v;
    case ColType.integer:
      if (v is num && v == v.truncate()) return v.toInt();
    case ColType.real:
      if (v is num) return v.toDouble();
    case ColType.boolean:
      if (v is bool) return v ? 1 : 0;
    case ColType.date:
      if (v is String && v.length >= 10) return v.substring(0, 10);
    case ColType.timestamp:
      if (v is String && DateTime.tryParse(v) != null) return v;
  }
  throw FormatException('bad value for ${c.type.name}: $v');
}

/// Converts a Dart value to its JSON form for an outbox patch.
Object? toJson(Object? v) {
  if (v is DateTime) return v.toUtc().toIso8601String();
  return v;
}
