import '../../../core/db/app_database.dart';

/// What the signed-in person may do in a trip.
enum TripRole {
  owner,
  guide,
  member;

  /// Shared content (itinerary) can be edited by the owner and guides.
  bool get canEditShared => this != member;
  bool get canDeleteTrip => this == owner;
  String get label => switch (this) {
    owner => '團長',
    guide => '嚮導',
    member => '隊員',
  };
}

/// Role of [accountId] in [trip]. Trips made as a guest have no owner yet, so the person is the owner.
TripRole roleFor({required Trip trip, required String? accountId, required List<TripMember> members}) {
  if (trip.ownerId == null || trip.ownerId == accountId) return TripRole.owner;
  for (final m in members) {
    if (m.userId == accountId) {
      return switch (m.role) {
        'owner' => TripRole.owner,
        'guide' => TripRole.guide,
        _ => TripRole.member,
      };
    }
  }
  return TripRole.member;
}

String formatDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime parseDate(String s) {
  final p = s.substring(0, 10).split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

extension TripDates on Trip {
  DateTime get start => parseDate(startDate);
  DateTime get end => endDate == null ? start : parseDate(endDate!);

  /// Number of hiking days (D1..Dn). A trip without an end date is one day.
  int get dayCount => end.difference(start).inDays + 1;

  /// Calendar date of day [dayIndex]: D1 is the start date, D0 is the day before.
  DateTime dateOfDay(int dayIndex) => DateTime(start.year, start.month, start.day + dayIndex - 1);

  String get rangeLabel {
    String md(DateTime d) => '${d.month}/${d.day}';
    return dayCount == 1 ? md(start) : '${md(start)} – ${md(end)}（$dayCount 天）';
  }
}

enum TripPhase { ongoing, upcoming, past }

TripPhase phaseOf(Trip t, DateTime today) {
  final d = DateTime(today.year, today.month, today.day);
  if (d.isAfter(t.end)) return TripPhase.past;
  if (d.isBefore(t.start)) return TripPhase.upcoming;
  return TripPhase.ongoing;
}

/// Trips split into the three sections of the list. Ongoing and upcoming sort soonest first,
/// past trips most recent first.
({List<Trip> ongoing, List<Trip> upcoming, List<Trip> past}) groupTrips(List<Trip> trips, DateTime today) {
  final ongoing = <Trip>[], upcoming = <Trip>[], past = <Trip>[];
  for (final t in trips) {
    switch (phaseOf(t, today)) {
      case TripPhase.ongoing:
        ongoing.add(t);
      case TripPhase.upcoming:
        upcoming.add(t);
      case TripPhase.past:
        past.add(t);
    }
  }
  ongoing.sort((a, b) => a.start.compareTo(b.start));
  upcoming.sort((a, b) => a.start.compareTo(b.start));
  past.sort((a, b) => b.start.compareTo(a.start));
  return (ongoing: ongoing, upcoming: upcoming, past: past);
}

// ------------------------------------------------------------------ itinerary

String dayLabel(int dayIndex) => 'D$dayIndex';

/// "07:30" for minutes after midnight, or null.
String? formatMinutes(int? minutes) =>
    minutes == null ? null : '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

/// Items of one day in the order they happen: by time, items without a time last (by name).
List<ItineraryItem> itemsOfDay(List<ItineraryItem> all, int dayIndex) {
  final list = all.where((i) => i.dayIndex == dayIndex).toList();
  list.sort((a, b) {
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
  return list;
}

/// Running total of the distance walked up to and including each item.
List<double> cumulativeDistance(List<ItineraryItem> dayItems) {
  var sum = 0.0;
  return [for (final i in dayItems) sum += i.distance];
}

String formatKm(double km) => km == km.roundToDouble() ? km.toStringAsFixed(0) : km.toStringAsFixed(1);

/// Day indexes to show: D0 (the day before) plus D1..Dn, and any extra day that already has items.
List<int> dayIndexesFor(Trip trip, List<ItineraryItem> items) {
  final maxItemDay = items.isEmpty ? 0 : items.map((i) => i.dayIndex).reduce((a, b) => a > b ? a : b);
  final last = trip.dayCount > maxItemDay ? trip.dayCount : maxItemDay;
  return [for (var d = 0; d <= last; d++) d];
}
