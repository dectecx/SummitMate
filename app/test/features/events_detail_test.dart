import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:summitmate/features/events/data/events_api.dart';

import 'events_fakes.dart';
import 'harness.dart';

const snapshot = TripSnapshot(
  name: '嘉明湖三日',
  startDate: '2026-12-05',
  endDate: '2026-12-07',
  itinerary: [
    SnapshotItem(day: 1, name: '向陽登山口', time: '07:00', altitude: 2300),
    SnapshotItem(day: 1, name: '向陽山屋', time: '12:30', altitude: 2850),
    SnapshotItem(day: 2, name: '嘉明湖', altitude: 3310),
  ],
);

Finder action() => find.byKey(const ValueKey('event-action'));

String actionLabel(WidgetTester tester) => ((tester.widget(action()) as ButtonStyleButton).child! as Text).data!;

bool actionEnabled(WidgetTester tester) => (tester.widget(action()) as ButtonStyleButton).onPressed != null;

/// Opens the event [id] from the list.
Future<AppHarness> openDetail(WidgetTester tester, FakeEventsApi api, String id, {bool signedIn = true}) async {
  final app = await startEvents(tester, api, signedIn: signedIn);
  await openEvents(tester);
  await openEvent(tester, id);
  await settleUntil(tester, action());
  return app;
}

void main() {
  group('what each viewer sees', () {
    testWidgets('a guest sees the facts, a locked private message, and is asked to sign in for everything else', (
      tester,
    ) async {
      final api = FakeEventsApi(
        events: [
          ev(
            'e1',
            '嘉明湖三日',
            end: '2026-12-07',
            description: '三天兩夜走嘉明湖',
            privateMessage: '集合 LINE 群：abc',
            snapshot: snapshot,
            comments: 1,
          ),
        ],
      )..comments_['e1'] = [cm('c1', '好期待')];
      final app = await openDetail(tester, api, 'e1', signedIn: false);
      expect(find.text('嘉明湖三日'), findsWidgets);
      expect(find.text('陳大山'), findsOneWidget);
      expect(find.text('2026/12/5 – 12/7（3 天）'), findsOneWidget);
      expect(find.text('台東海端'), findsOneWidget);
      expect(find.textContaining('3 / 8 人'), findsOneWidget);
      expect(find.text('三天兩夜走嘉明湖'), findsOneWidget);
      expect(find.byKey(const ValueKey('event-snapshot')), findsOneWidget);
      expect(find.text('向陽登山口'), findsOneWidget);
      expect(find.text('07:00'), findsOneWidget);
      expect(find.text('2850 m'), findsOneWidget);
      expect(find.text('D2'), findsOneWidget);
      expect(find.byKey(const ValueKey('event-private-locked')), findsOneWidget);
      expect(find.textContaining('集合 LINE 群'), findsNothing, reason: 'the content never reaches this viewer');
      expect(find.text('好期待'), findsOneWidget, reason: 'comments are public');
      expect(find.byKey(const ValueKey('comment-input')), findsNothing);

      expect(actionLabel(tester), '登入後申請');
      await tester.tap(action());
      await settle(tester);
      expect(find.text('登入後使用'), findsOneWidget);
      await tapText(tester, '取消');

      await tester.tap(find.byKey(const ValueKey('event-like')));
      await settle(tester);
      expect(find.text('登入後使用'), findsOneWidget);
      await tapText(tester, '取消');

      await tester.tap(find.byKey(const ValueKey('comment-signin')));
      await settle(tester);
      expect(find.text('登入後使用'), findsOneWidget);
      await tapText(tester, '取消');

      await tester.tap(find.byKey(const ValueKey('event-menu')));
      await settle(tester);
      await tester.tap(find.text('舉報這個揪團'));
      await settle(tester);
      expect(find.text('登入後使用'), findsOneWidget);
      expect(api.reports, isEmpty);
      await app.dispose(tester);
    });

    testWidgets('someone who has not applied sees the apply button and a locked message', (tester) async {
      final api = FakeEventsApi(events: [ev('e1', '嘉明湖三日', privateMessage: '祕密')]);
      final app = await openDetail(tester, api, 'e1');
      expect(actionLabel(tester), '申請加入');
      expect(actionEnabled(tester), isTrue);
      expect(find.byKey(const ValueKey('event-private-locked')), findsOneWidget);
      expect(find.byKey(const ValueKey('comment-input')), findsOneWidget);
      await app.dispose(tester);
    });

    testWidgets('the host sees the secret message, the management button and the host menu', (tester) async {
      final api = FakeEventsApi(events: [ev('e1', '嘉明湖三日', isHost: true, privateMessage: '集合 07:00 登山口')]);
      final app = await openDetail(tester, api, 'e1');
      expect(actionLabel(tester), '管理申請');
      expect(find.byKey(const ValueKey('event-private')), findsOneWidget);
      expect(find.text('集合 07:00 登山口'), findsOneWidget);
      expect(find.byKey(const ValueKey('event-private-locked')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('event-menu')));
      await settle(tester);
      expect(
        [
          for (final t in ['編輯', '管理申請', '關閉報名', '取消揪團']) find.text(t).evaluate().length,
        ],
        [1, 2, 1, 1],
        reason: 'the menu, and the bottom button for 管理申請',
      );
      expect(find.text('舉報這個揪團'), findsNothing, reason: 'a host does not report their own event');
      await app.dispose(tester);
    });

    testWidgets('a pending applicant is told to wait', (tester) async {
      final api = FakeEventsApi(
        events: [ev('e1', '嘉明湖三日', mine: ApplicationStatus.pending, privateMessage: '祕密')],
      );
      final app = await openDetail(tester, api, 'e1');
      expect(actionLabel(tester), '審核中');
      expect(find.byKey(const ValueKey('event-private-locked')), findsOneWidget);
      await app.dispose(tester);
    });

    testWidgets('an approved member can read the private message', (tester) async {
      final api = FakeEventsApi(
        events: [ev('e1', '嘉明湖三日', mine: ApplicationStatus.approved, privateMessage: '集合 07:00')],
      );
      final app = await openDetail(tester, api, 'e1');
      expect(actionLabel(tester), '已加入');
      expect(find.byKey(const ValueKey('event-private')), findsOneWidget);
      expect(find.text('集合 07:00'), findsOneWidget);
      await app.dispose(tester);
    });

    testWidgets('a rejected applicant sees the reason and can apply again', (tester) async {
      final api = FakeEventsApi(
        events: [ev('e1', '嘉明湖三日', mine: ApplicationStatus.rejected, rejection: '這團需要有高山經驗')],
      );
      final app = await openDetail(tester, api, 'e1');
      expect(find.byKey(const ValueKey('event-rejected')), findsOneWidget);
      expect(find.text('原因：這團需要有高山經驗'), findsOneWidget);
      expect(actionLabel(tester), '再次申請');
      expect(actionEnabled(tester), isTrue);
      await app.dispose(tester);
    });

    for (final c in [
      ('full', '名額已滿', () => ev('e1', '嘉明湖三日', approved: 8)),
      ('closed', '報名已關閉', () => ev('e1', '嘉明湖三日', status: EventStatus.closed)),
      ('expired', '活動已過期', () => ev('e1', '嘉明湖三日', start: '2026-11-01')),
    ]) {
      testWidgets('a ${c.$1} event cannot be applied to', (tester) async {
        final api = FakeEventsApi(events: [c.$3()]);
        final app = await openDetail(tester, api, 'e1');
        expect(actionLabel(tester), c.$2);
        expect(actionEnabled(tester), isFalse);
        await app.dispose(tester);
      });
    }

    testWidgets('a cancelled event can still be opened by an applicant, but not joined', (tester) async {
      final api = FakeEventsApi(
        events: [ev('e1', '嘉明湖三日', status: EventStatus.cancelled, mine: ApplicationStatus.pending)],
      );
      final app = await startEvents(tester, api, signedIn: true);
      await openEvents(tester);
      await tapText(tester, '我參加的');
      await openEvent(tester, 'e1');
      expect(actionLabel(tester), '揪團已取消');
      expect(actionEnabled(tester), isFalse);
      await app.dispose(tester);
    });

    testWidgets('an event that is gone says so and can retry', (tester) async {
      final api = FakeEventsApi(events: [ev('e1', '嘉明湖三日')]);
      final app = await startEvents(tester, api, signedIn: true);
      await openEvents(tester);
      await settleUntil(tester, find.byKey(const ValueKey('event-e1')));
      final removed = api.events.removeAt(0);
      await tester.tap(find.byKey(const ValueKey('event-e1')));
      await settle(tester);
      expect(find.textContaining('找不到這個揪團'), findsOneWidget);
      api.events.add(removed);
      await tester.tap(find.text('重試'));
      await settle(tester);
      expect(action(), findsOneWidget);
      await app.dispose(tester);
    });
  });

  group('applying', () {
    testWidgets('apply with a message, wait, cancel, and apply again', (tester) async {
      final api = FakeEventsApi(events: [ev('e1', '嘉明湖三日')]);
      final app = await openDetail(tester, api, 'e1');
      await tester.tap(action());
      await settle(tester);
      expect(find.textContaining('主辦人審核後才會通過'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('apply-message')), '有三次高山經驗');
      await tester.tap(find.byKey(const ValueKey('apply-confirm')));
      await settle(tester);
      expect(api.applyMessages, ['有三次高山經驗']);
      expect(find.textContaining('等主辦人審核'), findsOneWidget);
      expect(actionLabel(tester), '審核中');
      await clearSnacks(tester);

      await tester.tap(action());
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('confirm-yes')));
      await settle(tester);
      expect(api.log, contains('cancelApply e1'));
      expect(actionLabel(tester), '再次申請');
      await clearSnacks(tester);

      await tester.tap(action());
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('apply-confirm')));
      await settle(tester);
      expect(api.applyMessages, ['有三次高山經驗', '']);
      expect(actionLabel(tester), '審核中');
      await app.dispose(tester);
    });

    testWidgets('an event without approval is joined at once, which unlocks the message; leaving locks it again', (
      tester,
    ) async {
      final api = FakeEventsApi(events: [ev('e1', '嘉明湖三日', approval: false, privateMessage: '集合 07:00')]);
      final app = await openDetail(tester, api, 'e1');
      await tester.tap(action());
      await settle(tester);
      expect(find.textContaining('不需審核'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('apply-confirm')));
      await settle(tester);
      expect(actionLabel(tester), '已加入');
      expect(find.text('集合 07:00'), findsOneWidget);
      expect(find.textContaining('4 / 8 人'), findsOneWidget);
      await clearSnacks(tester);

      await tester.tap(action());
      await settle(tester);
      expect(find.text('退出這個揪團？'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('confirm-yes')));
      await settle(tester);
      expect(actionLabel(tester), '再次申請');
      expect(find.text('集合 07:00'), findsNothing);
      expect(find.byKey(const ValueKey('event-private-locked')), findsOneWidget);
      expect(find.textContaining('3 / 8 人'), findsOneWidget);
      await app.dispose(tester);
    });

    testWidgets('when the server says the event filled up meanwhile, the page explains and refreshes', (tester) async {
      final api = FakeEventsApi(events: [ev('e1', '嘉明湖三日', approval: false, approved: 7)]);
      final app = await openDetail(tester, api, 'e1');
      // Someone else takes the last place after the page was loaded.
      api.events[0] = api.events[0].copyWith(approvedCount: 8);
      await tester.tap(action());
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('apply-confirm')));
      await settle(tester);
      expect(find.text('名額已滿。'), findsOneWidget);
      expect(actionLabel(tester), '名額已滿');
      expect(actionEnabled(tester), isFalse);
      await app.dispose(tester);
    });

    testWidgets('an offline apply shows the connection message and keeps the button', (tester) async {
      final api = FakeEventsApi(events: [ev('e1', '嘉明湖三日')]);
      final app = await openDetail(tester, api, 'e1');
      api.failNext = const EventsException(code: 'network');
      await tester.tap(action());
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('apply-confirm')));
      await settle(tester);
      expect(find.textContaining('需要連線'), findsOneWidget);
      expect(actionLabel(tester), '申請加入');
      await app.dispose(tester);
    });
  });

  group('comments, likes and reports', () {
    testWidgets('a signed-in person adds a comment and deletes their own', (tester) async {
      final api = FakeEventsApi(events: [ev('e1', '嘉明湖三日')])..comments_['e1'] = [cm('c1', '好期待')];
      final app = await openDetail(tester, api, 'e1');
      expect(find.byKey(const ValueKey('comment-delete-c1')), findsNothing, reason: 'not mine, and I am not the host');

      await tester.enterText(find.byKey(const ValueKey('comment-input')), '我也想去');
      await tester.tap(find.byKey(const ValueKey('comment-send')));
      await settle(tester);
      expect(find.text('我也想去'), findsOneWidget);
      expect(find.text('留言（1）'), findsOneWidget);
      expect(tester.widget<TextField>(find.byKey(const ValueKey('comment-input'))).controller!.text, isEmpty);

      await tester.tap(find.byKey(const ValueKey('comment-delete-c2-new')));
      await settle(tester);
      expect(find.text('刪除留言？'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('confirm-yes')));
      await settle(tester);
      expect(find.text('我也想去'), findsNothing);
      expect(find.text('好期待'), findsOneWidget);
      expect(api.log, contains('deleteComment c2-new'));
      await app.dispose(tester);
    });

    testWidgets('an empty comment is not sent', (tester) async {
      final api = FakeEventsApi(events: [ev('e1', '嘉明湖三日')]);
      final app = await openDetail(tester, api, 'e1');
      await tester.enterText(find.byKey(const ValueKey('comment-input')), '   ');
      await tester.tap(find.byKey(const ValueKey('comment-send')));
      await settle(tester);
      expect(api.comments_['e1'], isNull);
      await app.dispose(tester);
    });

    testWidgets('the host can delete anyone\'s comment', (tester) async {
      final api = FakeEventsApi(events: [ev('e1', '嘉明湖三日', isHost: true)])..comments_['e1'] = [cm('c1', '廣告留言')];
      final app = await openDetail(tester, api, 'e1');
      await tester.tap(find.byKey(const ValueKey('comment-delete-c1')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('confirm-yes')));
      await settle(tester);
      expect(find.text('廣告留言'), findsNothing);
      await app.dispose(tester);
    });

    testWidgets('the like button toggles and shows the count from the server', (tester) async {
      final api = FakeEventsApi(events: [ev('e1', '嘉明湖三日', likes: 2)]);
      final app = await openDetail(tester, api, 'e1');
      final like = find.byKey(const ValueKey('event-like'));
      expect(find.descendant(of: like, matching: find.text('2')), findsOneWidget);
      expect(find.descendant(of: like, matching: find.byIcon(Icons.favorite_border)), findsOneWidget);
      await tester.tap(like);
      await settle(tester);
      expect(find.descendant(of: like, matching: find.text('3')), findsOneWidget);
      expect(find.descendant(of: like, matching: find.byIcon(Icons.favorite)), findsOneWidget);
      expect(api.events.single.liked, isTrue);
      await tester.tap(like);
      await settle(tester);
      expect(find.descendant(of: like, matching: find.text('2')), findsOneWidget);
      expect(api.events.single.liked, isFalse);
      await app.dispose(tester);
    });

    testWidgets('an event is reported with a reason', (tester) async {
      final api = FakeEventsApi(events: [ev('e1', '嘉明湖三日')]);
      final app = await openDetail(tester, api, 'e1');
      await tester.tap(find.byKey(const ValueKey('event-menu')));
      await settle(tester);
      await tester.tap(find.text('舉報這個揪團'));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('report-confirm')));
      await settle(tester);
      expect(find.text('請輸入內容'), findsOneWidget, reason: 'a reason is required');
      expect(api.reports, isEmpty);
      await tester.enterText(find.byKey(const ValueKey('report-reason')), '疑似詐騙');
      await tester.tap(find.byKey(const ValueKey('report-confirm')));
      await settle(tester);
      expect(api.reports.single, (target: ReportTarget.groupEvent, id: 'e1', reason: '疑似詐騙'));
      expect(find.textContaining('已送出舉報'), findsOneWidget);
      await app.dispose(tester);
    });

    testWidgets('a comment is reported with a reason, and my own comment has no report button', (tester) async {
      final api = FakeEventsApi(events: [ev('e1', '嘉明湖三日')])
        ..comments_['e1'] = [cm('c1', '買藥請洽'), cm('c2', '我的留言', mine: true)];
      final app = await openDetail(tester, api, 'e1');
      expect(find.byKey(const ValueKey('comment-report-c2')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('comment-report-c1')));
      await settle(tester);
      await tester.enterText(find.byKey(const ValueKey('report-reason')), '廣告');
      await tester.tap(find.byKey(const ValueKey('report-confirm')));
      await settle(tester);
      expect(api.reports.single, (target: ReportTarget.groupEventComment, id: 'c1', reason: '廣告'));
      await app.dispose(tester);
    });
  });

  group('host actions', () {
    testWidgets('the management button opens the applications page', (tester) async {
      final api = FakeEventsApi(events: [ev('e1', '嘉明湖三日', isHost: true)])
        ..apps['e1'] = [ap('a1', '小明', ApplicationStatus.pending)];
      final app = await openDetail(tester, api, 'e1');
      await tester.tap(action());
      await settle(tester);
      expect(find.text('小明'), findsOneWidget);
      expect(find.text('待審核（1）'), findsOneWidget);
      await app.dispose(tester);
    });

    testWidgets('closing registration asks first, shows the state, and can be reopened', (tester) async {
      final api = FakeEventsApi(events: [ev('e1', '嘉明湖三日', isHost: true)]);
      final app = await openDetail(tester, api, 'e1');
      await tester.tap(find.byKey(const ValueKey('event-menu')));
      await settle(tester);
      await tester.tap(find.text('關閉報名'));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('confirm-yes')));
      await settle(tester);
      expect(api.updated.single, (id: 'e1', input: null, status: EventStatus.closed));
      expect(find.text('報名已關閉'), findsOneWidget, reason: 'the tag');

      await tester.tap(find.byKey(const ValueKey('event-menu')));
      await settle(tester);
      await tester.tap(find.text('重新開放報名'));
      await settle(tester);
      expect(api.updated.last.status, EventStatus.open);
      expect(find.text('報名已關閉'), findsNothing);
      await app.dispose(tester);
    });

    testWidgets('cancelling the event needs a confirmation and returns to the list', (tester) async {
      final api = FakeEventsApi(events: [ev('e1', '嘉明湖三日', isHost: true)]);
      final app = await openDetail(tester, api, 'e1');
      await tester.tap(find.byKey(const ValueKey('event-menu')));
      await settle(tester);
      await tester.tap(find.text('取消揪團'));
      await settle(tester);
      await tapText(tester, '不要');
      expect(api.log, isNot(contains('cancel e1')));

      await tester.tap(find.byKey(const ValueKey('event-menu')));
      await settle(tester);
      await tester.tap(find.text('取消揪團'));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('confirm-yes')));
      await settle(tester);
      expect(api.log, contains('cancel e1'));
      expect(find.byKey(const ValueKey('events-search')), findsOneWidget, reason: 'back on the list');
      expect(find.byKey(const ValueKey('event-e1')), findsNothing);
      await app.dispose(tester);
    });

    testWidgets('edit opens the form with the current values', (tester) async {
      final api = FakeEventsApi(events: [ev('e1', '嘉明湖三日', isHost: true, max: 9, description: '說明文字')]);
      final app = await openDetail(tester, api, 'e1');
      await tester.tap(find.byKey(const ValueKey('event-menu')));
      await settle(tester);
      await tester.tap(find.text('編輯'));
      await settle(tester);
      expect(find.text('編輯揪團'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '嘉明湖三日'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '9'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '說明文字'), findsOneWidget);
      await app.dispose(tester);
    });
  });
}
