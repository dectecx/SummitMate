import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/core/db/app_database.dart';
import 'package:summitmate/features/events/data/events_api.dart';
import 'package:summitmate/features/events/domain/event_logic.dart';
import 'package:summitmate/features/trips/domain/trip_logic.dart';

import '../core/auth_support.dart';
import 'events_fakes.dart';

Trip trip({
  String id = 't1',
  String? owner,
  String start = '2026-12-05',
  String? end = '2026-12-07',
  bool sample = false,
}) => Trip(id: id, ownerId: owner, name: '嘉明湖三日', description: '', startDate: start, endDate: end, isSample: sample);

ItineraryItem node(String id, int day, String name, {int? minutes, int altitude = 0, double? lat, double? lng}) =>
    ItineraryItem(
      id: id,
      tripId: 't1',
      dayIndex: day,
      name: name,
      estMinutes: minutes,
      altitude: altitude,
      distance: 0,
      lat: lat,
      lng: lng,
      note: '',
    );

void main() {
  group('trip snapshot', () {
    test('orders nodes by day then time, nodes without a time last, and formats the time', () {
      final s = buildTripSnapshot(trip(), [
        node('a', 2, '山屋', minutes: 15 * 60 + 30, altitude: 3300),
        node('b', 1, '登山口', minutes: 7 * 60, altitude: 2300, lat: 23.3, lng: 121.0),
        node('c', 1, '午餐點'),
        node('d', 1, '觀景台', minutes: 9 * 60 + 5),
        node('e', 2, '早餐', minutes: 5 * 60),
      ]);
      expect([for (final i in s.itinerary) i.name], ['登山口', '觀景台', '午餐點', '早餐', '山屋']);
      expect([for (final i in s.itinerary) i.time], ['07:00', '09:05', null, '05:00', '15:30']);
      expect(
        s.itinerary.first,
        const SnapshotItem(day: 1, name: '登山口', time: '07:00', altitude: 2300, lat: 23.3, lng: 121.0),
      );
      expect(s.itinerary.last.altitude, 3300);
      expect(s.itinerary.last.lat, isNull);
    });

    test('takes the trip name and dates (date only), and keeps a missing end date missing', () {
      final s = buildTripSnapshot(trip(start: '2026-12-05T00:00:00', end: null), const []);
      expect(s.name, '嘉明湖三日');
      expect(s.startDate, '2026-12-05');
      expect(s.endDate, isNull);
      expect(s.itinerary, isEmpty);
    });

    test('keeps at most 200 nodes, the first ones in order', () {
      final many = [
        for (var i = 0; i < 250; i++) node('n$i', 1 + i ~/ 100, 'N${i.toString().padLeft(3, '0')}', minutes: i % 100),
      ];
      final s = buildTripSnapshot(trip(), many);
      expect(s.itinerary.length, maxSnapshotItems);
      expect(s.itinerary.first.name, 'N000');
      expect(s.itinerary.last.day, 2);
    });

    test('serializes to the contract', () {
      final s = buildTripSnapshot(trip(), [node('b', 1, '登山口', minutes: 420, altitude: 2300)]);
      expect(s.toJson(), {
        'name': '嘉明湖三日',
        'start_date': '2026-12-05',
        'end_date': '2026-12-07',
        'itinerary': [
          {'day': 1, 'name': '登山口', 'time': '07:00', 'altitude': 2300, 'lat': null, 'lng': null},
        ],
      });
      expect(TripSnapshot.fromJson(s.toJson()).itinerary.single, s.itinerary.single);
    });

    test('only the owner can link a trip, never the sample', () {
      expect(canLinkTrip(trip(), TripRole.owner), isTrue);
      expect(canLinkTrip(trip(), TripRole.guide), isFalse);
      expect(canLinkTrip(trip(), TripRole.member), isFalse);
      expect(canLinkTrip(trip(), null), isFalse);
      expect(canLinkTrip(trip(sample: true), TripRole.owner), isFalse);
    });
  });

  group('the bottom action', () {
    final t = DateTime(2026, 11, 22, 9);
    BottomAction of(EventSummary e, {bool signedIn = true}) => bottomActionFor(e, signedIn: signedIn, today: t);

    test('the host manages, whatever else is true', () {
      expect(of(ev('1', 'x' * 5, isHost: true)).kind, EventAction.host);
      expect(of(ev('1', 'x' * 5, isHost: true, status: EventStatus.closed)).kind, EventAction.host);
    });

    test('a guest is asked to sign in on an open event, but sees why an event cannot be joined', () {
      expect(
        of(ev('1', 'x' * 5), signedIn: false),
        isA<BottomAction>().having((a) => a.kind, 'kind', EventAction.signIn).having((a) => a.label, 'label', '登入後申請'),
      );
      expect(of(ev('1', 'x' * 5, status: EventStatus.closed), signedIn: false).kind, EventAction.closed);
      expect(of(ev('1', 'x' * 5, approved: 8), signedIn: false).kind, EventAction.full);
    });

    test('someone who has not applied can apply', () {
      final a = of(ev('1', 'x' * 5));
      expect((a.kind, a.label, a.enabled), (EventAction.apply, '申請加入', true));
    });

    test('pending and approved people see their state and can still leave when it is closed or full', () {
      final p = of(ev('1', 'x' * 5, mine: ApplicationStatus.pending, status: EventStatus.closed));
      expect((p.kind, p.label, p.enabled), (EventAction.pending, '審核中', true));
      final ok = of(ev('1', 'x' * 5, mine: ApplicationStatus.approved, approved: 8, start: '2026-01-01'));
      expect((ok.kind, ok.label), (EventAction.approved, '已加入'));
    });

    test('a rejected or withdrawn application can be sent again', () {
      expect(of(ev('1', 'x' * 5, mine: ApplicationStatus.rejected)).label, '再次申請');
      expect(of(ev('1', 'x' * 5, mine: ApplicationStatus.cancelled)).kind, EventAction.reapply);
    });

    test('closed, full, expired and cancelled events cannot be applied to', () {
      final closed = of(ev('1', 'x' * 5, status: EventStatus.closed));
      expect((closed.kind, closed.label, closed.enabled), (EventAction.closed, '報名已關閉', false));
      final full = of(ev('1', 'x' * 5, approved: 8));
      expect((full.kind, full.label, full.enabled), (EventAction.full, '名額已滿', false));
      final expired = of(ev('1', 'x' * 5, start: '2026-11-21'));
      expect((expired.kind, expired.label, expired.enabled), (EventAction.expired, '活動已過期', false));
      expect(of(ev('1', 'x' * 5, start: '2026-11-22')).kind, EventAction.apply, reason: 'today is not expired');
      final cancelled = of(ev('1', 'x' * 5, status: EventStatus.cancelled, mine: ApplicationStatus.approved));
      expect((cancelled.kind, cancelled.label, cancelled.enabled), (EventAction.cancelled, '揪團已取消', false));
      expect(
        of(ev('1', 'x' * 5, mine: ApplicationStatus.rejected, status: EventStatus.closed)).kind,
        EventAction.closed,
      );
    });
  });

  group('formatting and validation', () {
    test('dates and people', () {
      expect(formatEventDates('2026-12-05', null), '2026/12/5');
      expect(formatEventDates('2026-12-05', '2026-12-05'), '2026/12/5');
      expect(formatEventDates('2026-12-05', '2026-12-07'), '2026/12/5 – 12/7（3 天）');
      expect(formatEventDates('2026-12-30', '2027-01-02'), '2026/12/30 – 2027/1/2（4 天）');
      expect(peopleLabel(3, 8), '3 / 8 人');
    });

    test('labels', () {
      expect([for (final c in EventCategory.values) c.label], ['登山', '露營', '攀岩', '其他']);
      expect([for (final s in EventScope.values) s.label], ['全部', '即將出發', '熱門', '我參加的', '我主辦的']);
      expect(EventScope.joined.needsLogin && EventScope.hosting.needsLogin, isTrue);
      expect(EventScope.all.needsLogin || EventScope.upcoming.needsLogin || EventScope.popular.needsLogin, isFalse);
      expect(EventCategory.parse('bouldering'), EventCategory.bouldering);
      expect(EventCategory.parse('nonsense'), EventCategory.other);
      expect(statusLabel(EventStatus.cancelled), '已取消');
    });

    test('title and member limits', () {
      expect(validateTitle('四個字呢'), isNotNull);
      expect(validateTitle('  五個字的標題 '), isNull);
      expect(validateTitle('x' * 200), isNull);
      expect(validateTitle('x' * 201), isNotNull);
      expect(validateMaxMembers('1'), isNotNull);
      expect(validateMaxMembers('2'), isNull);
      expect(validateMaxMembers('100'), isNull);
      expect(validateMaxMembers('101'), isNotNull);
      expect(validateMaxMembers('abc'), isNotNull);
      expect(validateMaxMembers(''), isNotNull);
    });

    test('the end date may not be before the start', () {
      expect(validateEventDates(DateTime(2026, 12, 5), DateTime(2026, 12, 4)), isNotNull);
      expect(validateEventDates(DateTime(2026, 12, 5), DateTime(2026, 12, 5)), isNull);
      expect(validateEventDates(DateTime(2026, 12, 5), null), isNull);
    });
  });

  group('models and the Dio client', () {
    test('an event reads from the contract, including the private message state', () {
      final d = EventDetail.fromJson({
        'id': 'e1',
        'title': '嘉明湖',
        'category': 'camping',
        'location': '台東',
        'start_date': '2026-12-05',
        'end_date': null,
        'max_members': 8,
        'approved_count': 3,
        'like_count': 12,
        'comment_count': 5,
        'status': 'closed',
        'approval_required': false,
        'host': {'display_name': '陳大山', 'avatar': '🐻'},
        'created_at': '2026-11-01T00:00:00Z',
        'liked': true,
        'my_status': 'rejected',
        'is_host': false,
        'description': '說明',
        'private_message': null,
        'private_message_locked': true,
        'my_rejection_reason': '名額已預留',
        'linked_trip_id': null,
        'trip_snapshot': null,
        'snapshot_updated_at': null,
      });
      expect(
        (d.category, d.status, d.approvalRequired, d.myStatus, d.liked),
        (EventCategory.camping, EventStatus.closed, false, ApplicationStatus.rejected, true),
      );
      expect(
        (d.privateMessage, d.privateMessageLocked, d.myRejectionReason, d.host.displayName),
        (null, true, '名額已預留', '陳大山'),
      );
      expect(EventDetail.fromJson(d.toJson()).toJson(), d.toJson());
    });

    test('the input leaves out what is not set', () {
      const input = EventInput(title: '嘉明湖三日', category: EventCategory.hiking, startDate: '2026-12-05', maxMembers: 8);
      expect(
        input.toJson().keys,
        unorderedEquals([
          'title',
          'category',
          'location',
          'start_date',
          'max_members',
          'approval_required',
          'description',
          'private_message',
        ]),
      );
    });

    late ScriptedAdapter adapter;
    DioEventsApi apiWith(Future<ResponseBody> Function(RequestOptions) h) {
      adapter = ScriptedAdapter(h);
      return DioEventsApi(Dio(BaseOptions(baseUrl: 'http://x/api/v1'))..httpClientAdapter = adapter);
    }

    test('every endpoint uses the path, method and parameters of the contract', () async {
      final api = apiWith((o) async {
        final p = o.path;
        if (p.endsWith('/comments') && o.method == 'GET') return json({'items': [], 'next_cursor': 'c2'});
        if (p.endsWith('/like')) return json({'liked': o.method == 'PUT', 'like_count': 4});
        if (p.endsWith('/apply') && o.method == 'POST') return json({'my_status': 'pending'});
        if (p.endsWith('/applications') && o.method == 'GET') {
          return json({
            'items': [ap('a1', '小明', ApplicationStatus.pending).toJson()],
          });
        }
        if (p.endsWith('/review')) return json(ap('a1', '小明', ApplicationStatus.approved).toJson());
        if (p.endsWith('/comments')) return json(cm('c1', '嗨').toJson(), 201);
        if (p == '/group-events' && o.method == 'GET') {
          return json({
            'items': [ev('e1', '嘉明湖三日').toJson()],
            'next_cursor': 'n2',
          });
        }
        if (p == '/group-events') return json(ev('e1', '嘉明湖三日').toJson(), 201);
        if (o.method == 'GET') return json(ev('e1', '嘉明湖三日').toJson());
        return ResponseBody.fromString('', 204);
      });

      final page = await api.list(scope: EventScope.popular, q: ' 嘉明 ', cursor: 'n1', limit: 10);
      expect((page.items.single.id, page.nextCursor), ('e1', 'n2'));
      var r = adapter.requests.last;
      expect((r.method, r.path), ('GET', '/group-events'));
      expect(r.queryParameters, {'scope': 'popular', 'q': '嘉明', 'limit': 10, 'cursor': 'n1'});
      await api.list(scope: EventScope.all);
      expect(adapter.requests.last.queryParameters, {'scope': 'all', 'limit': 20}, reason: 'no empty q or cursor');

      await api.create(
        const EventInput(
          title: '嘉明湖三日',
          category: EventCategory.camping,
          startDate: '2026-12-05',
          maxMembers: 8,
          linkedTripId: 't1',
        ),
      );
      r = adapter.requests.last;
      expect((r.method, r.path), ('POST', '/group-events'));
      expect((r.data as Map)['category'], 'camping');
      expect((r.data as Map)['linked_trip_id'], 't1');

      await api.get('e1');
      expect(adapter.requests.last.path, '/group-events/e1');

      await api.update('e1', status: EventStatus.closed);
      r = adapter.requests.last;
      expect((r.method, r.path), ('PATCH', '/group-events/e1'));
      expect(r.data, {'status': 'closed'});

      await api.cancel('e1');
      expect((adapter.requests.last.method, adapter.requests.last.path), ('DELETE', '/group-events/e1'));

      expect(await api.apply('e1', message: ' 我想參加 '), ApplicationStatus.pending);
      r = adapter.requests.last;
      expect((r.method, r.path), ('POST', '/group-events/e1/apply'));
      expect(r.data, {'message': '我想參加'});
      await api.apply('e1');
      expect(adapter.requests.last.data, <String, Object?>{}, reason: 'no empty message');

      await api.cancelApply('e1');
      expect((adapter.requests.last.method, adapter.requests.last.path), ('DELETE', '/group-events/e1/apply'));

      final apps = await api.applications('e1', status: ApplicationStatus.rejected);
      expect(apps.single.user.displayName, '小明');
      expect(adapter.requests.last.queryParameters, {'status': 'rejected'});
      await api.applications('e1');
      expect(adapter.requests.last.queryParameters, isEmpty);

      final reviewed = await api.review('e1', 'a1', approve: false, reason: '名額已預留');
      r = adapter.requests.last;
      expect((r.method, r.path), ('POST', '/group-events/e1/applications/a1/review'));
      expect(r.data, {'approve': false, 'reason': '名額已預留'});
      expect(reviewed.status, ApplicationStatus.approved);
      await api.removeMember('e1', 'a1');
      expect(
        (adapter.requests.last.method, adapter.requests.last.path),
        ('DELETE', '/group-events/e1/applications/a1'),
      );

      final cs = await api.comments('e1', cursor: 'x');
      expect(cs.nextCursor, 'c2');
      expect(adapter.requests.last.queryParameters, {'limit': 20, 'cursor': 'x'});
      expect((await api.addComment('e1', '嗨')).body, '嗨');
      expect(adapter.requests.last.method, 'POST');
      expect(adapter.requests.last.data, {'body': '嗨'});
      await api.deleteComment('e1', 'c1');
      expect((adapter.requests.last.method, adapter.requests.last.path), ('DELETE', '/group-events/e1/comments/c1'));

      var like = await api.like('e1');
      expect((adapter.requests.last.method, like.liked, like.likeCount), ('PUT', true, 4));
      like = await api.unlike('e1');
      expect(
        (adapter.requests.last.method, adapter.requests.last.path, like.liked),
        ('DELETE', '/group-events/e1/like', false),
      );

      await api.report(target: ReportTarget.groupEventComment, targetId: 'c1', reason: ' 廣告 ');
      r = adapter.requests.last;
      expect((r.method, r.path), ('POST', '/reports'));
      expect(r.data, {'target_type': 'group_event_comment', 'target_id': 'c1', 'reason': '廣告'});
    });

    test('errors carry the server code, with a friendly message for each code of the contract', () async {
      Future<EventsException> failWith(int status, [Object? body]) async {
        final api = apiWith((_) async => json(body ?? {}, status));
        try {
          await api.apply('e1');
        } on EventsException catch (e) {
          return e;
        }
        throw StateError('did not fail');
      }

      var e = await failWith(409, {'code': 'event_full', 'message': 'raw'});
      expect((e.code, e.status, e.text), ('event_full', 409, '名額已滿。'));
      e = await failWith(401);
      expect((e.code, e.needsLogin), ('unauthorized', true));
      e = await failWith(500);
      expect((e.code, e.text), ('http_500', '發生錯誤（http_500）'));
      expect((await failWith(404, {'code': 'group_event_not_found'})).notFound, isTrue);

      final offline = apiWith((o) async => throw DioException.connectionError(requestOptions: o, reason: 'down'));
      await expectLater(
        offline.get('e1'),
        throwsA(
          isA<EventsException>()
              .having((e) => e.isNetwork, 'isNetwork', true)
              .having((e) => e.text, 'text', contains('需要連線')),
        ),
      );

      for (final code in [
        'event_full',
        'registration_closed',
        'already_applied',
        'host_cannot_apply',
        'not_trip_owner',
        'invalid_snapshot',
        'invalid_review',
        'group_event_not_found',
        'unauthorized',
        'network',
      ]) {
        expect(EventsException(code: code).text, isNot(contains(code)), reason: '$code has its own message');
      }
      for (final code in ['application_not_found', 'comment_not_found', 'event_cancelled', 'too_many_requests']) {
        expect(EventsException(code: code).text, isNot(contains(code)), reason: code);
      }
      expect(const EventsException(code: 'too_many_requests').text, '操作太頻繁，請稍後再試。');
      expect(const EventsException(code: 'x', message: '伺服器說的').text, '伺服器說的');
    });

    test('a request body is JSON the server can read', () {
      expect(jsonEncode(ev('e1', '嘉明湖三日').toJson()), contains('"approved_count":3'));
    });
  });
}
