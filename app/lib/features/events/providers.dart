import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../trips/providers.dart';
import 'data/events_api.dart';
import 'domain/event_logic.dart';

final eventsApiProvider = Provider<EventsApi>((ref) => DioEventsApi(ref.watch(authedDioProvider)));

/// Applications waiting for the signed-in person's review, over the events they host that are neither cancelled nor
/// past. 0 for a guest and when it cannot be fetched. Invalidate it to fetch again; nothing polls.
final pendingApplicationsProvider = FutureProvider<int>((ref) async {
  if (ref.watch(accountIdProvider) == null) return 0;
  final api = ref.watch(eventsApiProvider);
  final today = ref.watch(clockProvider)();
  var total = 0;
  String? cursor;
  try {
    do {
      final page = await api.list(scope: EventScope.hosting, cursor: cursor, limit: 50);
      for (final e in page.items) {
        if (e.status != EventStatus.cancelled && !isExpired(e.startDate, today)) total += e.pendingCount;
      }
      cursor = page.nextCursor;
    } while (cursor != null);
  } on EventsException {
    return 0;
  }
  return total;
});
