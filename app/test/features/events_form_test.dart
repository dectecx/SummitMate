import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:summitmate/core/db/app_database.dart';
import 'package:summitmate/features/events/data/events_api.dart';
import 'package:summitmate/features/trips/providers.dart';

import 'events_fakes.dart';
import 'harness.dart';

Finder field(String key) => find.byKey(ValueKey(key));

Future<AppHarness> openCreate(WidgetTester tester, FakeEventsApi api) async {
  final app = await startEvents(tester, api, signedIn: true);
  await openEvents(tester);
  await tester.tap(field('events-create'));
  await settle(tester);
  return app;
}

/// Opens the edit form of the host's event [id] through the detail page.
Future<AppHarness> openEdit(WidgetTester tester, FakeEventsApi api, String id) async {
  final app = await startEvents(tester, api, signedIn: true);
  await openEvents(tester);
  await openEvent(tester, id);
  await tester.tap(field('event-menu'));
  await settle(tester);
  await tester.tap(find.text('編輯'));
  await settle(tester);
  return app;
}

Future<void> submit(WidgetTester tester) async {
  await tester.ensureVisible(field('event-submit'));
  await tester.tap(field('event-submit'));
  await settle(tester);
}

void main() {
  group('create', () {
    testWidgets('invalid values are explained and nothing is sent', (tester) async {
      final api = FakeEventsApi();
      final app = await openCreate(tester, api);
      await tester.enterText(field('event-title'), '短短');
      await tester.enterText(field('event-max'), '1');
      await submit(tester);
      expect(find.text('標題至少 5 個字'), findsOneWidget);
      expect(find.text('人數需在 2 到 100 之間'), findsOneWidget);
      await tester.enterText(field('event-max'), '101');
      await submit(tester);
      expect(find.text('人數需在 2 到 100 之間'), findsOneWidget);
      expect(api.created, isEmpty);
      await app.dispose(tester);
    });

    testWidgets('a valid form creates the event and opens it', (tester) async {
      final api = FakeEventsApi();
      final app = await openCreate(tester, api);
      expect(find.text('建立揪團'), findsWidgets);
      await tester.enterText(field('event-title'), '龍洞攀岩體驗日');
      await tester.tap(field('event-category-bouldering'));
      await tester.enterText(field('event-location'), '新北龍洞');
      await tester.enterText(field('event-max'), '6');
      await tester.enterText(field('event-description'), '新手也可以');
      await tester.enterText(field('event-private-message'), '集合：龍洞停車場');
      await tester.ensureVisible(field('event-approval'));
      await tester.tap(field('event-approval'));
      await settle(tester);
      await submit(tester);

      final input = api.created.single;
      expect(input.title, '龍洞攀岩體驗日');
      expect(input.category, EventCategory.bouldering);
      expect(input.location, '新北龍洞');
      expect(input.startDate, '2026-11-22', reason: 'defaults to today');
      expect(input.endDate, isNull);
      expect(input.maxMembers, 6);
      expect(input.approvalRequired, isFalse);
      expect(input.description, '新手也可以');
      expect(input.privateMessage, '集合：龍洞停車場');
      expect(input.linkedTripId, isNull);
      expect(input.tripSnapshot, isNull);
      expect(find.text('龍洞攀岩體驗日'), findsWidgets, reason: 'the new event opens');
      expect(field('event-action'), findsOneWidget);
      expect(find.text('管理申請'), findsWidgets, reason: 'as its host');
      await app.dispose(tester);
    });

    testWidgets('the date pickers set the start and the end date', (tester) async {
      final api = FakeEventsApi();
      final app = await openCreate(tester, api);
      await tester.enterText(field('event-title'), '合歡山兩天一夜');
      await tester.tap(field('event-start'));
      await settle(tester);
      await tester.tap(find.text('25'));
      await tapText(tester, 'OK');
      expect(find.text('2026-11-25'), findsOneWidget);
      await tester.tap(field('event-end'));
      await settle(tester);
      await tester.tap(find.text('27'));
      await tapText(tester, 'OK');
      expect(find.text('2026-11-27'), findsOneWidget);
      await submit(tester);
      expect((api.created.single.startDate, api.created.single.endDate), ('2026-11-25', '2026-11-27'));
      await app.dispose(tester);
    });

    testWidgets('only trips I own can be linked, and the snapshot is built from the local trip', (tester) async {
      final api = FakeEventsApi();
      final app = await startEvents(tester, api, signedIn: true);
      final trips = app.container.read(tripRepositoryProvider);
      final items = app.container.read(itineraryRepositoryProvider);
      final mine = await act(
        tester,
        () => trips.create(name: '嘉明湖三日', start: DateTime(2026, 12, 5), end: DateTime(2026, 12, 7)),
      );
      await act(tester, () async {
        await items.add(mine, dayIndex: 2, name: '嘉明湖', altitude: 3310);
        await items.add(mine, dayIndex: 1, name: '向陽山屋', estMinutes: 750, altitude: 2850, lat: 23.28, lng: 121.05);
        await items.add(mine, dayIndex: 1, name: '向陽登山口', estMinutes: 420, altitude: 2300);
      });
      await real(tester, () async {
        await app.db
            .into(app.db.trips)
            .insert(
              TripsCompanion.insert(
                id: 'theirs',
                ownerId: const Value('someone-else'),
                name: '別人的行程',
                startDate: '2026-12-01',
              ),
            );
      });
      await settle(tester);

      await openEvents(tester);
      await tester.tap(field('events-create'));
      await settle(tester);
      await tester.enterText(field('event-title'), '嘉明湖三日團');
      await tester.ensureVisible(field('event-link'));
      await tester.tap(field('event-link'));
      await settle(tester);
      expect(find.text('嘉明湖三日'), findsOneWidget);
      expect(find.text('別人的行程'), findsNothing, reason: 'I am only a member there');
      await tester.tap(field('link-trip-$mine'));
      await settle(tester);
      await submit(tester);

      final input = api.created.single;
      expect(input.linkedTripId, mine);
      final snap = input.tripSnapshot!;
      expect((snap.name, snap.startDate, snap.endDate), ('嘉明湖三日', '2026-12-05', '2026-12-07'));
      expect(snap.itinerary, const [
        SnapshotItem(day: 1, name: '向陽登山口', time: '07:00', altitude: 2300),
        SnapshotItem(day: 1, name: '向陽山屋', time: '12:30', altitude: 2850, lat: 23.28, lng: 121.05),
        SnapshotItem(day: 2, name: '嘉明湖', altitude: 3310),
      ]);
      expect(find.text('向陽登山口'), findsOneWidget, reason: 'the detail shows the preview the server stored');
      await app.dispose(tester);
    });

    testWidgets('a server refusal is shown and the form stays', (tester) async {
      final api = FakeEventsApi()..failNext = const EventsException(code: 'not_trip_owner', status: 403);
      final app = await openCreate(tester, api);
      await tester.enterText(field('event-title'), '龍洞攀岩體驗日');
      await submit(tester);
      expect(find.text('只能連結自己是團長的行程。'), findsOneWidget);
      expect(field('event-title'), findsOneWidget);
      expect(api.created, isEmpty);
      await app.dispose(tester);
    });
  });

  group('edit', () {
    testWidgets('saves the changed fields, keeps the link and snapshot as they are', (tester) async {
      final api = FakeEventsApi(
        events: [ev('e1', '嘉明湖三日', isHost: true, max: 9, approved: 2, end: '2026-12-07', privateMessage: '舊的集合訊息')],
      );
      final app = await openEdit(tester, api, 'e1');
      expect(find.text('編輯揪團'), findsOneWidget);
      expect(find.text('2026-12-07'), findsOneWidget);
      await tester.enterText(field('event-title'), '嘉明湖三日（改期）');
      await tester.enterText(field('event-max'), '12');
      await tester.tap(field('event-category-camping'));
      await submit(tester);

      final u = api.updated.single;
      expect(u.id, 'e1');
      expect(u.input!.title, '嘉明湖三日（改期）');
      expect((u.input!.maxMembers, u.input!.category, u.input!.endDate), (12, EventCategory.camping, '2026-12-07'));
      expect(u.input!.privateMessage, '舊的集合訊息');
      expect(u.input!.linkedTripId, isNull);
      expect(u.input!.tripSnapshot, isNull);
      expect(find.text('嘉明湖三日（改期）'), findsWidgets, reason: 'back on the detail, refreshed');
      expect(find.text('編輯揪團'), findsNothing);
      await app.dispose(tester);
    });

    testWidgets('the maximum cannot go below the people already approved', (tester) async {
      final api = FakeEventsApi(events: [ev('e1', '嘉明湖三日', isHost: true, max: 9, approved: 5)]);
      final app = await openEdit(tester, api, 'e1');
      await tester.enterText(field('event-max'), '4');
      await submit(tester);
      expect(find.textContaining('不能少於目前已通過的 5 人'), findsOneWidget);
      expect(api.updated, isEmpty);
      await app.dispose(tester);
    });

    testWidgets('the end date can be removed, and an invalid title is not saved', (tester) async {
      final api = FakeEventsApi(events: [ev('e1', '嘉明湖三日', isHost: true, end: '2026-12-07')]);
      final app = await openEdit(tester, api, 'e1');
      await tester.tap(find.byTooltip('清除結束日期'));
      await settle(tester);
      await tester.enterText(field('event-title'), 'abc');
      await submit(tester);
      expect(api.updated, isEmpty);
      await tester.enterText(field('event-title'), '嘉明湖單日行');
      await submit(tester);
      expect(api.updated.single.input!.endDate, isNull);
      expect(
        api.updated.single.input!.toPatchJson().containsKey('end_date'),
        isTrue,
        reason: 'null clears it on the server',
      );
      await app.dispose(tester);
    });

    testWidgets('the snapshot of the linked trip can be sent again', (tester) async {
      final api = FakeEventsApi();
      final app = await startEvents(tester, api, signedIn: true);
      final trips = app.container.read(tripRepositoryProvider);
      final tripId = await act(
        tester,
        () => trips.create(name: '嘉明湖三日', start: DateTime(2026, 12, 5), end: DateTime(2026, 12, 7)),
      );
      await act(
        tester,
        () => app.container
            .read(itineraryRepositoryProvider)
            .add(tripId, dayIndex: 1, name: '新的節點', estMinutes: 480, altitude: 2400),
      );
      api.events.add(
        ev(
          'e1',
          '嘉明湖三日團',
          isHost: true,
          linkedTripId: tripId,
          snapshot: const TripSnapshot(name: '舊', startDate: '2026-12-05', itinerary: []),
        ),
      );
      await settle(tester);
      await openEvents(tester);
      await openEvent(tester, 'e1');
      await tester.tap(field('event-menu'));
      await settle(tester);
      await tester.tap(find.text('編輯'));
      await settle(tester);

      await tester.ensureVisible(field('event-resend'));
      await tester.tap(field('event-resend'));
      await settle(tester);
      await submit(tester);
      final input = api.updated.single.input!;
      expect(input.linkedTripId, tripId);
      expect(
        input.tripSnapshot!.itinerary.single,
        const SnapshotItem(day: 1, name: '新的節點', time: '08:00', altitude: 2400),
      );
      expect(find.text('新的節點'), findsOneWidget, reason: 'the new preview on the detail page');
      await app.dispose(tester);
    });
  });

  group('the host\'s applications', () {
    FakeEventsApi hosted({int approved = 1, int max = 8}) =>
        FakeEventsApi(
            events: [ev('e1', '嘉明湖三日', isHost: true, approved: approved, max: max)],
          )
          ..apps['e1'] = [
            ap('p1', '小明', ApplicationStatus.pending, message: '我有高山經驗'),
            ap('p2', '小華', ApplicationStatus.pending),
            ap('m1', '老王', ApplicationStatus.approved),
          ];

    Future<AppHarness> open(WidgetTester tester, FakeEventsApi api) async {
      final app = await startEvents(tester, api, signedIn: true);
      await openEvents(tester);
      await openEvent(tester, 'e1');
      await tester.tap(field('event-action'));
      await settle(tester);
      return app;
    }

    testWidgets('pending and approved people are listed with their messages', (tester) async {
      final api = hosted();
      final app = await open(tester, api);
      expect(find.text('待審核（2）'), findsOneWidget);
      expect(find.text('已通過（1）'), findsOneWidget);
      expect(find.text('我有高山經驗'), findsOneWidget);
      expect(find.textContaining('1 / 8 人'), findsOneWidget);
      expect(field('remove-m1'), findsOneWidget);
      await app.dispose(tester);
    });

    testWidgets('approving moves the person to the members and updates the count', (tester) async {
      final api = hosted();
      final app = await open(tester, api);
      await tester.tap(field('approve-p1'));
      await settle(tester);
      expect(api.reviews.single, (appId: 'p1', approve: true, reason: ''));
      expect(find.text('待審核（1）'), findsOneWidget);
      expect(find.text('已通過（2）'), findsOneWidget);
      expect(find.textContaining('2 / 8 人'), findsOneWidget);
      await app.dispose(tester);
    });

    testWidgets('approving into a full event shows the server\'s message and changes nothing', (tester) async {
      final api = hosted(approved: 8);
      final app = await open(tester, api);
      await tester.tap(field('approve-p1'));
      await settle(tester);
      expect(find.text('名額已滿。'), findsOneWidget);
      expect(find.text('待審核（2）'), findsOneWidget);
      await app.dispose(tester);
    });

    testWidgets('rejecting can carry a reason, or none', (tester) async {
      final api = hosted();
      final app = await open(tester, api);
      await tester.tap(field('reject-p1'));
      await settle(tester);
      await tester.enterText(field('reject-reason'), '這團需要高山經驗');
      await tester.tap(field('reject-confirm'));
      await settle(tester);
      expect(api.reviews.last, (appId: 'p1', approve: false, reason: '這團需要高山經驗'));
      expect(find.text('待審核（1）'), findsOneWidget);

      await tester.tap(field('reject-p2'));
      await settle(tester);
      await tester.tap(field('reject-confirm'));
      await settle(tester);
      expect(api.reviews.last, (appId: 'p2', approve: false, reason: ''));
      expect(find.text('沒有待審核的申請。'), findsOneWidget);
      await app.dispose(tester);
    });

    testWidgets('cancelling the reject dialog does nothing', (tester) async {
      final api = hosted();
      final app = await open(tester, api);
      await tester.tap(field('reject-p1'));
      await settle(tester);
      await tapText(tester, '取消');
      expect(api.reviews, isEmpty);
      await app.dispose(tester);
    });

    testWidgets('removing a member asks first', (tester) async {
      final api = hosted();
      final app = await open(tester, api);
      await tester.tap(field('remove-m1'));
      await settle(tester);
      expect(find.textContaining('移除 老王？'), findsOneWidget);
      await tapText(tester, '取消');
      expect(api.log, isNot(contains('remove m1')));

      await tester.tap(field('remove-m1'));
      await settle(tester);
      await tester.tap(field('confirm-yes'));
      await settle(tester);
      expect(api.log, contains('remove m1'));
      expect(find.text('已通過（0）'), findsOneWidget);
      expect(find.textContaining('0 / 8 人'), findsOneWidget);
      await app.dispose(tester);
    });

    testWidgets('offline, the page asks for a connection and retries', (tester) async {
      final api = hosted();
      final app = await startEvents(tester, api, signedIn: true);
      await openEvents(tester);
      await openEvent(tester, 'e1');
      api.offline = true;
      await tester.tap(field('event-action'));
      await settle(tester);
      expect(find.textContaining('需要連線'), findsOneWidget);
      api.offline = false;
      await tester.tap(find.text('重試'));
      await settle(tester);
      expect(find.text('待審核（2）'), findsOneWidget);
      await app.dispose(tester);
    });
  });
}
