import '../../../core/db/app_database.dart';
import '../../trips/domain/trip_logic.dart';
import '../data/events_api.dart';

/// At most this many stops go into a snapshot (the server rejects more).
const maxSnapshotItems = 200;

const titleMin = 5, titleMax = 200, maxMembersMin = 2, maxMembersMax = 100;

/// A simplified copy of [trip] for people who are not in it: stops ordered by day, then time
/// (stops without a time last, then by name), at most [maxSnapshotItems].
TripSnapshot buildTripSnapshot(Trip trip, List<ItineraryItem> items) {
  final sorted = [...items]
    ..sort((a, b) {
      if (a.dayIndex != b.dayIndex) return a.dayIndex.compareTo(b.dayIndex);
      final at = a.estMinutes, bt = b.estMinutes;
      if (at != null && bt != null) {
        final c = at.compareTo(bt);
        if (c != 0) return c;
      } else if (at != null) {
        return -1;
      } else if (bt != null) {
        return 1;
      }
      return a.name.compareTo(b.name);
    });
  return TripSnapshot(
    name: trip.name,
    startDate: trip.startDate.substring(0, 10),
    endDate: trip.endDate?.substring(0, 10),
    itinerary: [
      for (final i in sorted.take(maxSnapshotItems))
        SnapshotItem(
          day: i.dayIndex,
          name: i.name,
          time: formatMinutes(i.estMinutes),
          altitude: i.altitude,
          lat: i.lat,
          lng: i.lng,
        ),
    ],
  );
}

/// A trip can be linked to an event when the person is its owner (the bundled sample cannot).
bool canLinkTrip(Trip trip, TripRole? role) => !trip.isSample && role == TripRole.owner;

/// The start date is before today (the server refuses applications then).
bool isExpired(String startDate, DateTime today) =>
    parseDate(startDate).isBefore(DateTime(today.year, today.month, today.day));

bool isFull(EventSummary e) => e.approvedCount >= e.maxMembers;

/// What the bottom button of the detail page does.
enum EventAction { host, signIn, apply, reapply, pending, approved, closed, full, expired, cancelled }

class BottomAction {
  const BottomAction(this.kind, this.label, {this.enabled = true});
  final EventAction kind;
  final String label;
  final bool enabled;

  @override
  String toString() => 'BottomAction($kind, $label, $enabled)';
}

/// The bottom action for [e] as seen by the person ([signedIn]) on [today].
BottomAction bottomActionFor(EventSummary e, {required bool signedIn, required DateTime today}) {
  if (e.isHost) return const BottomAction(EventAction.host, '管理申請');
  if (e.status == EventStatus.cancelled) return const BottomAction(EventAction.cancelled, '揪團已取消', enabled: false);
  if (signedIn) {
    switch (e.myStatus) {
      case ApplicationStatus.approved:
        return const BottomAction(EventAction.approved, '已加入');
      case ApplicationStatus.pending:
        return const BottomAction(EventAction.pending, '審核中');
      case ApplicationStatus.rejected || ApplicationStatus.cancelled || null:
        break;
    }
  }
  if (e.status == EventStatus.closed) return const BottomAction(EventAction.closed, '報名已關閉', enabled: false);
  if (isExpired(e.startDate, today)) return const BottomAction(EventAction.expired, '活動已過期', enabled: false);
  if (isFull(e)) return const BottomAction(EventAction.full, '名額已滿', enabled: false);
  if (!signedIn) return const BottomAction(EventAction.signIn, '登入後申請');
  return switch (e.myStatus) {
    ApplicationStatus.rejected || ApplicationStatus.cancelled => const BottomAction(EventAction.reapply, '再次申請'),
    _ => const BottomAction(EventAction.apply, '申請加入'),
  };
}

/// "2026/12/5", or "2026/12/5 – 12/7（3 天）" for a range ("2026/12/30 – 2027/1/2" across years).
String formatEventDates(String start, String? end) {
  final s = parseDate(start);
  String full(DateTime d) => '${d.year}/${d.month}/${d.day}';
  if (end == null || end.isEmpty) return full(s);
  final e = parseDate(end);
  final days = e.difference(s).inDays + 1;
  if (days <= 1) return full(s);
  final endText = e.year == s.year ? '${e.month}/${e.day}' : full(e);
  return '${full(s)} – $endText（$days 天）';
}

/// "3 / 8 人".
String peopleLabel(int approved, int max) => '$approved / $max 人';

String statusLabel(EventStatus s) => switch (s) {
  EventStatus.open => '報名中',
  EventStatus.closed => '報名已關閉',
  EventStatus.cancelled => '已取消',
};

String applicationStatusLabel(ApplicationStatus s) => switch (s) {
  ApplicationStatus.pending => '審核中',
  ApplicationStatus.approved => '已通過',
  ApplicationStatus.rejected => '未通過',
  ApplicationStatus.cancelled => '已取消',
};

String? validateTitle(String? v) {
  final n = (v ?? '').trim().length;
  if (n < titleMin) return '標題至少 $titleMin 個字';
  if (n > titleMax) return '標題最多 $titleMax 個字';
  return null;
}

String? validateMaxMembers(String? v) {
  final n = int.tryParse((v ?? '').trim());
  if (n == null || n < maxMembersMin || n > maxMembersMax) return '人數需在 $maxMembersMin 到 $maxMembersMax 之間';
  return null;
}

/// The end date may not be before the start date.
String? validateEventDates(DateTime start, DateTime? end) => end != null && end.isBefore(start) ? '結束日期不能早於出發日期' : null;

/// Snapshot stops grouped by day, in order.
Map<int, List<SnapshotItem>> snapshotByDay(TripSnapshot s) {
  final out = <int, List<SnapshotItem>>{};
  for (final i in s.itinerary) {
    (out[i.day] ??= []).add(i);
  }
  return out;
}
