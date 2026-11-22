import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:summitmate/features/events/data/events_api.dart';
import 'package:summitmate/features/explore/providers.dart';

import 'events_fakes.dart';
import 'explore_test.dart' show FakeExploreApi, m, payloadOf;
import 'harness.dart';

FakeEventsApi sample() => FakeEventsApi(
  events: [
    ev('e1', '嘉明湖三日', end: '2026-12-07', approved: 3, likes: 12, comments: 5),
    ev('e2', '合歡山看日出', category: EventCategory.camping, location: '南投', start: '2026-12-20', approved: 1, likes: 1),
    ev('e3', '龍洞攀岩體驗', category: EventCategory.bouldering, location: '新北', start: '2026-11-10', approved: 8, likes: 30),
    ev('e4', '我參加的玉山', mine: ApplicationStatus.approved, start: '2026-12-25', likes: 0),
    ev('e5', '我主辦的雪山', isHost: true, start: '2026-12-30', approved: 0, likes: 0),
    ev('e7', '額滿的活動', approved: 8, start: '2026-12-12', likes: 0),
    ev('e6', '我取消的活動', isHost: true, status: EventStatus.cancelled, start: '2026-12-31'),
  ],
);

Finder card(String id) => find.byKey(ValueKey('event-$id'));

void main() {
  testWidgets('the explore tab switches between mountains and group events, and mountains stay as they were', (
    tester,
  ) async {
    final api = sample();
    final explore = FakeExploreApi(payloadOf([m('yushan-main', '玉山主峰', 3952), m('xueshan-main', '雪山主峰', 3886)]));
    final app = await startEvents(tester, api, overrides: [exploreApiProvider.overrideWithValue(explore)]);
    await tapText(tester, '探索');
    expect(find.text('玉山主峰'), findsOneWidget, reason: 'mountains are the first segment');
    expect(find.byKey(const ValueKey('events-search')), findsNothing);
    expect(find.text('建立揪團'), findsNothing);

    await tapText(tester, '揪團');
    expect(find.text('玉山主峰'), findsNothing);
    expect(card('e1'), findsOneWidget);
    expect(find.text('建立揪團'), findsOneWidget);

    await tapText(tester, '山岳');
    expect(find.text('玉山主峰'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, '搜尋山名或地區'), '雪山');
    await settle(tester);
    expect(find.text('玉山主峰'), findsNothing);
    expect(find.text('雪山主峰'), findsOneWidget);
    expect(find.text('建立揪團'), findsNothing);
    await app.dispose(tester);
  });

  testWidgets('cards show the title, category, place, dates, people, likes and comments; cancelled ones are hidden', (
    tester,
  ) async {
    final api = sample();
    final app = await startEvents(tester, api);
    await openEvents(tester);
    expect(card('e1'), findsOneWidget);
    expect(find.descendant(of: card('e1'), matching: find.text('嘉明湖三日')), findsOneWidget);
    expect(find.descendant(of: card('e1'), matching: find.text('登山')), findsOneWidget);
    expect(
      find.descendant(of: card('e1'), matching: find.textContaining('台東海端  ·  2026/12/5 – 12/7（3 天）')),
      findsOneWidget,
    );
    expect(find.descendant(of: card('e1'), matching: find.text('3 / 8 人')), findsOneWidget);
    expect(find.descendant(of: card('e1'), matching: find.text('12')), findsOneWidget);
    expect(find.descendant(of: card('e1'), matching: find.text('5')), findsOneWidget);
    expect(find.descendant(of: card('e1'), matching: find.text('陳大山')), findsOneWidget);
    expect(find.descendant(of: card('e2'), matching: find.text('露營')), findsOneWidget);
    expect(find.descendant(of: card('e3'), matching: find.text('攀岩')), findsOneWidget);
    expect(find.descendant(of: card('e3'), matching: find.text('已過期')), findsOneWidget);
    expect(find.descendant(of: card('e7'), matching: find.text('已額滿')), findsOneWidget);
    expect(find.descendant(of: card('e4'), matching: find.text('已加入')), findsOneWidget);
    expect(find.descendant(of: card('e5'), matching: find.text('我主辦')), findsOneWidget);
    expect(card('e6'), findsNothing, reason: 'cancelled events are not listed in 全部');
    await app.dispose(tester);
  });

  testWidgets('the filter chips ask the server for their scope', (tester) async {
    final api = sample();
    final app = await startEvents(tester, api, signedIn: true);
    await openEvents(tester);
    expect(api.listCalls.last.scope, EventScope.all);

    await tapText(tester, '即將出發');
    expect(api.listCalls.last.scope, EventScope.upcoming);
    expect(card('e3'), findsNothing, reason: 'already started');
    expect(card('e1'), findsOneWidget);

    await tapText(tester, '熱門');
    expect(api.listCalls.last.scope, EventScope.popular);
    expect(tester.getTopLeft(card('e3')).dy, lessThan(tester.getTopLeft(card('e1')).dy), reason: 'most liked first');

    await tapText(tester, '我參加的');
    expect(api.listCalls.last.scope, EventScope.joined);
    expect(card('e4'), findsOneWidget);
    expect(card('e1'), findsNothing);

    await tapText(tester, '我主辦的');
    expect(api.listCalls.last.scope, EventScope.hosting);
    expect(card('e5'), findsOneWidget);
    expect(card('e6'), findsOneWidget, reason: 'my cancelled events show here');
    expect(find.descendant(of: card('e6'), matching: find.text('已取消')), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('search narrows the list by title or place and can be cleared', (tester) async {
    final api = sample();
    final app = await startEvents(tester, api);
    await openEvents(tester);
    await tester.enterText(find.byKey(const ValueKey('events-search')), '南投');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await settle(tester);
    expect(api.listCalls.last.q, '南投');
    expect(card('e2'), findsOneWidget);
    expect(card('e1'), findsNothing);

    await tester.enterText(find.byKey(const ValueKey('events-search')), '不存在的活動');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await settle(tester);
    expect(find.text('沒有符合的揪團。'), findsOneWidget);

    await tester.tap(find.byTooltip('清除'));
    await settle(tester);
    expect(card('e1'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('a long list loads more on request and stops when there is no more', (tester) async {
    final api = sample()..pageSize = 2;
    final app = await startEvents(tester, api);
    await openEvents(tester);
    expect([card('e1'), card('e2')].every((f) => f.evaluate().length == 1), isTrue);
    expect(card('e3'), findsNothing);
    expect(api.listCalls.last.cursor, isNull);

    await tester.ensureVisible(find.byKey(const ValueKey('events-more')));
    await tester.tap(find.byKey(const ValueKey('events-more')));
    await settle(tester);
    expect(api.listCalls.last.cursor, '2');
    expect(card('e1'), findsOneWidget, reason: 'the first page stays');
    expect(card('e3'), findsOneWidget);
    expect(card('e4'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('events-more')));
    await tester.tap(find.byKey(const ValueKey('events-more')));
    await settle(tester);
    expect(card('e5'), findsOneWidget);
    expect(find.byKey(const ValueKey('events-more')), findsNothing);
    await app.dispose(tester);
  });

  testWidgets('pulling down refreshes the list', (tester) async {
    final api = sample();
    final app = await startEvents(tester, api);
    await openEvents(tester);
    final before = api.listCalls.length;
    api.events.insert(0, ev('e0', '剛開的新揪團'));
    // The tall test viewport needs a long pull.
    await tester.drag(card('e1'), const Offset(0, 900));
    await settle(tester);
    expect(api.listCalls.length, greaterThan(before));
    expect(card('e0'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('offline, the list says a connection is needed and retries', (tester) async {
    final api = sample()..offline = true;
    final app = await startEvents(tester, api);
    await openEvents(tester);
    expect(find.textContaining('需要連線'), findsOneWidget);
    expect(card('e1'), findsNothing);
    api.offline = false;
    await tester.tap(find.text('重試'));
    await settle(tester);
    expect(find.textContaining('需要連線'), findsNothing);
    expect(card('e1'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('a guest sees the sign-in notice for the personal lists and is asked to sign in to create', (
    tester,
  ) async {
    final api = sample();
    final app = await startEvents(tester, api);
    await openEvents(tester);
    final calls = api.listCalls.length;

    await tapText(tester, '我參加的');
    expect(find.text('登入後使用'), findsOneWidget);
    expect(find.byKey(const ValueKey('events-signin')), findsOneWidget);
    expect(card('e4'), findsNothing);
    await tapText(tester, '我主辦的');
    expect(find.text('登入後使用'), findsOneWidget);
    expect(api.listCalls.length, calls, reason: 'nothing is requested while locked');

    await tapText(tester, '全部');
    expect(card('e1'), findsOneWidget);
    expect(find.text('登入後使用'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('events-create')));
    await settle(tester);
    expect(find.text('登入後使用'), findsOneWidget, reason: 'the dialog title');
    expect(find.byKey(const ValueKey('events-signin-confirm')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('events-signin-confirm')));
    await settle(tester);
    expect(find.text('登入'), findsWidgets, reason: 'the sign-in page');
    expect(find.byKey(const ValueKey('event-title')), findsNothing);
    await app.dispose(tester);
  });

  testWidgets('a signed-in person opens the create form and the detail from the list', (tester) async {
    final api = sample();
    final app = await startEvents(tester, api, signedIn: true);
    await openEvents(tester);
    await tester.tap(find.byKey(const ValueKey('events-create')));
    await settle(tester);
    expect(find.byKey(const ValueKey('event-title')), findsOneWidget);
    await tester.pageBack();
    await settle(tester);

    await tester.tap(card('e1'));
    await settle(tester);
    expect(find.byKey(const ValueKey('event-action')), findsOneWidget);
    expect(api.log, contains('get e1'));
    await app.dispose(tester);
  });
}
