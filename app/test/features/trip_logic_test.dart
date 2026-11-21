import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/core/db/app_database.dart';
import 'package:summitmate/features/trips/domain/trip_logic.dart';

Trip trip(String id, String start, {String? end, String? owner}) =>
    Trip(id: id, ownerId: owner, name: id, description: '', startDate: start, endDate: end, coverImage: null, isSample: false);

ItineraryItem item(String id, int day, {int? minutes, String name = '', double km = 0}) => ItineraryItem(
  id: id, tripId: 't', dayIndex: day, name: name.isEmpty ? id : name, estMinutes: minutes, altitude: 0, distance: km, lat: null, lng: null, note: '', checkedInAt: null,
);

TripMember member(String user, String role) => TripMember(id: 'm$user', tripId: 't', userId: user, role: role, displayName: user, avatar: '');

void main() {
  group('dates', () {
    test('day count, labels and the date of each day', () {
      final t = trip('a', '2026-05-01', end: '2026-05-03');
      expect(t.dayCount, 3);
      expect(t.rangeLabel, '5/1 – 5/3（3 天）');
      expect(t.dateOfDay(1), DateTime(2026, 5, 1));
      expect(t.dateOfDay(3), DateTime(2026, 5, 3));
      expect(t.dateOfDay(0), DateTime(2026, 4, 30), reason: 'D0 is the day before');
      expect(trip('b', '2026-05-01').dayCount, 1);
      expect(trip('b', '2026-05-01').rangeLabel, '5/1');
    });

    test('dates survive month ends and round-trip as text', () {
      final t = trip('a', '2026-01-31', end: '2026-02-02');
      expect(t.dayCount, 3);
      expect(t.dateOfDay(2), DateTime(2026, 2, 1));
      expect(formatDate(DateTime(2026, 3, 4)), '2026-03-04');
      expect(parseDate('2026-03-04T10:00:00Z'), DateTime(2026, 3, 4));
    });
  });

  group('grouping', () {
    test('splits into ongoing, upcoming and past with sensible order', () {
      final today = DateTime(2026, 5, 10);
      final g = groupTrips([
        trip('past-old', '2026-01-01'),
        trip('past-new', '2026-04-01', end: '2026-04-02'),
        trip('now', '2026-05-09', end: '2026-05-11'),
        trip('last-day', '2026-05-08', end: '2026-05-10'),
        trip('soon', '2026-05-11'),
        trip('later', '2026-08-01'),
      ], today);
      expect(g.ongoing.map((t) => t.id), ['last-day', 'now']);
      expect(g.upcoming.map((t) => t.id), ['soon', 'later']);
      expect(g.past.map((t) => t.id), ['past-new', 'past-old']);
    });

    test('a trip is still ongoing on its last day and past the day after', () {
      final t = trip('a', '2026-05-01', end: '2026-05-03');
      expect(phaseOf(t, DateTime(2026, 5, 3, 23, 59)), TripPhase.ongoing);
      expect(phaseOf(t, DateTime(2026, 5, 4)), TripPhase.past);
      expect(phaseOf(t, DateTime(2026, 4, 30)), TripPhase.upcoming);
    });
  });

  group('role', () {
    test('a guest owns the trips made on this device', () {
      expect(roleFor(trip: trip('a', '2026-05-01'), accountId: null, members: const []), TripRole.owner);
    });

    test('the owner, then members by their stored role', () {
      final t = trip('a', '2026-05-01', owner: 'me');
      expect(roleFor(trip: t, accountId: 'me', members: const []), TripRole.owner);
      final members = [member('g', 'guide'), member('m', 'member')];
      expect(roleFor(trip: t, accountId: 'g', members: members), TripRole.guide);
      expect(roleFor(trip: t, accountId: 'm', members: members), TripRole.member);
      expect(roleFor(trip: t, accountId: 'stranger', members: members), TripRole.member, reason: 'least privilege');
    });

    test('permissions', () {
      expect(TripRole.owner.canEditShared && TripRole.guide.canEditShared, isTrue);
      expect(TripRole.member.canEditShared, isFalse);
      expect([TripRole.owner, TripRole.guide, TripRole.member].map((r) => r.canDeleteTrip), [true, false, false]);
    });
  });

  group('itinerary', () {
    test('items of a day are ordered by time with untimed items last', () {
      final all = [item('c', 1, minutes: 12 * 60), item('x', 2, minutes: 60), item('z', 1), item('a', 1, minutes: 7 * 60), item('b', 1)];
      expect(itemsOfDay(all, 1).map((i) => i.id), ['a', 'c', 'b', 'z']);
      expect(itemsOfDay(all, 2).map((i) => i.id), ['x']);
      expect(itemsOfDay(all, 9), isEmpty);
    });

    test('cumulative distance and formatting', () {
      final d = [item('a', 1, km: 0), item('b', 1, km: 2.1), item('c', 1, km: 2.2)];
      expect(cumulativeDistance(d).map((v) => v.toStringAsFixed(1)), ['0.0', '2.1', '4.3']);
      expect(formatKm(4.0), '4');
      expect(formatKm(2.1), '2.1');
      expect(formatMinutes(7 * 60 + 5), '07:05');
      expect(formatMinutes(null), isNull);
      expect(dayLabel(0), 'D0');
    });

    test('day chips cover D0..Dn and any day that already has items', () {
      final t = trip('a', '2026-05-01', end: '2026-05-03');
      expect(dayIndexesFor(t, const []), [0, 1, 2, 3]);
      expect(dayIndexesFor(t, [item('late', 5)]), [0, 1, 2, 3, 4, 5]);
    });
  });
}
