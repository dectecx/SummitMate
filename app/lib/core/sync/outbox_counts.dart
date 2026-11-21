import '../db/app_database.dart';

typedef OutboxCounts = ({int pending, int failed});

/// Live count of outbox entries by state.
Stream<OutboxCounts> watchOutboxCounts(AppDatabase db) {
  return db
      .customSelect(
        "SELECT COALESCE(SUM(state = 'pending'), 0) AS pending, COALESCE(SUM(state = 'failed'), 0) AS failed FROM outbox",
        readsFrom: {db.outbox},
      )
      .watchSingle()
      .map((r) => (pending: r.read<int>('pending'), failed: r.read<int>('failed')));
}
