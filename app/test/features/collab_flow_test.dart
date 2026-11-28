import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:summitmate/core/providers.dart';
import 'package:summitmate/core/sync/local_store.dart';
import 'package:summitmate/core/sync/sync_coordinator.dart';
import 'package:summitmate/core/sync/sync_entity.dart';
import 'package:summitmate/features/collab/domain/collab_logic.dart';
import 'package:summitmate/features/trips/providers.dart';

import '../core/support.dart';
import 'harness.dart';

class NoSync implements SyncCoordinator {
  @override
  Future<void> refresh() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

// 2026-05-10 09:00 on every device in these tests.
final _now = DateTime(2026, 5, 10, 9);

Future<AppHarness> start(WidgetTester tester, {bool signedIn = true}) async {
  tester.view.physicalSize = const Size(800, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final app = await AppHarness.start(
    tester,
    welcomeSeen: true,
    seed: (api) => api.addAccount('a@x.co', 'Passw0rd1', name: 'Anna'),
    overrides: [
      clockProvider.overrideWithValue(() => _now),
      syncCoordinatorProvider.overrideWithValue(NoSync()),
    ],
  );
  if (signedIn) {
    await real(
      tester,
      () => app.container
          .read(authRepositoryProvider)
          .login(email: 'a@x.co', password: 'Passw0rd1'),
    );
  }
  return app;
}

/// A trip owned by someone else, in which the signed-in Anna (id-a) has [role].
Future<void> joinTrip(WidgetTester tester, AppHarness app, String role) async {
  final store = LocalStore(app.db);
  await act(tester, () async {
    await store.upsertFromServer(
      tripsEntity,
      tripRow('t1', name: '合歡山', ownerId: 'owner-id', start: '2026-05-10'),
    );
    for (final m in [
      ('mo', 'owner-id', 'owner', 'Olly'),
      ('ma', 'id-a', role, 'Anna'),
      ('mm', 'mia-id', 'member', 'Mia'),
    ]) {
      await store.upsertFromServer(tripMembersEntity, {
        'id': m.$1,
        'trip_id': 't1',
        'user_id': m.$2,
        'role': m.$3,
        'display_name': m.$4,
        'avatar': '🦊',
      });
    }
  });
  await settle(tester);
}

Future<void> openDiscussion(WidgetTester tester) async {
  await tapText(tester, '合歡山');
  await tapText(tester, '討論');
}

Future<void> openPolls(WidgetTester tester) async {
  await openDiscussion(tester);
  await tester.tap(find.byKey(const ValueKey('discussion-polls')));
  await settle(tester);
}

Future<void> seedMessage(
  WidgetTester tester,
  AppHarness app,
  String id,
  String user,
  String body, {
  String? parent,
  int minute = 0,
}) => act(
  tester,
  () => LocalStore(app.db).upsertFromServer(tripMessagesEntity, {
    'id': id,
    'trip_id': 't1',
    'user_id': user,
    'parent_id': parent,
    'body': body,
    'created_at': '2026-05-09T10:${minute.toString().padLeft(2, '0')}:00Z',
  }),
);

Future<void> seedPoll(
  WidgetTester tester,
  AppHarness app, {
  String title = '早餐吃什麼',
  List<String> options = const ['蛋餅', '飯糰'],
  bool multiple = false,
  bool addOption = false,
  bool blind = false,
  String status = 'open',
  String? deadline,
  Map<String, String> votes = const {}, // option text -> voter
}) => act(tester, () async {
  final store = LocalStore(app.db);
  await store.upsertFromServer(pollsEntity, {
    'id': 'p1',
    'trip_id': 't1',
    'title': title,
    'description': '',
    'deadline': deadline,
    'allow_multiple': multiple,
    'allow_add_option': addOption,
    'blind': blind,
    'status': status,
    'created_at': '2026-05-09T09:00:00Z',
  });
  for (var i = 0; i < options.length; i++) {
    await store.upsertFromServer(pollOptionsEntity, {
      'id': 'o$i',
      'poll_id': 'p1',
      'trip_id': 't1',
      'text': options[i],
      'sort_order': i,
      'created_by': 'owner-id',
    });
  }
  for (final v in votes.entries) {
    final i = options.indexOf(v.key);
    await store.upsertFromServer(pollVotesEntity, {
      'id': voteIdFor('o$i', v.value),
      'poll_id': 'p1',
      'option_id': 'o$i',
      'trip_id': 't1',
      'user_id': v.value,
      'updated_at': '2026-05-09T11:00:00Z',
    });
  }
});

Finder rich(String text) => find.textContaining(text, findRichText: true);

Future<List<String>> ops(WidgetTester tester, AppHarness app) async => [
  for (final o in await real(tester, () => app.db.select(app.db.outbox).get()))
    '${o.type}:${o.entity}',
];

void main() {
  group('message board', () {
    testWidgets(
      'a member posts a message; it appears at once and is queued without an author',
      (tester) async {
        final app = await start(tester);
        await joinTrip(tester, app, 'member');
        await seedMessage(tester, app, 'm1', 'owner-id', '集合時間改 6 點');
        await openDiscussion(tester);
        expect(find.text('集合時間改 6 點'), findsOneWidget);
        expect(rich('Olly'), findsOneWidget);

        await tester.enterText(find.widgetWithText(TextField, '寫留言'), '收到');
        await tester.tap(find.byTooltip('送出'));
        await settle(tester);

        expect(find.text('收到'), findsOneWidget);
        expect(rich('Anna'), findsOneWidget);
        final rows = await real(
          tester,
          () => app.db.select(app.db.tripMessages).get(),
        );
        expect(rows.where((r) => r.body == '收到').single.userId, 'id-a');
        final op = (await real(
          tester,
          () => app.db.select(app.db.outbox).get(),
        )).single;
        expect(op.patch, '{"trip_id":"t1","body":"收到"}');
        await app.dispose(tester);
      },
    );

    testWidgets('an empty message is not sent', (tester) async {
      final app = await start(tester);
      await joinTrip(tester, app, 'member');
      await openDiscussion(tester);
      await tester.tap(find.byTooltip('送出'));
      await settle(tester);
      expect(find.text('請輸入留言內容'), findsOneWidget);
      expect(await ops(tester, app), isEmpty);
      await app.dispose(tester);
    });

    testWidgets(
      'replying puts the answer under the message and uploads its parent',
      (tester) async {
        final app = await start(tester);
        await joinTrip(tester, app, 'member');
        await seedMessage(tester, app, 'm1', 'owner-id', '要帶雨衣嗎');
        await openDiscussion(tester);

        await tapText(tester, '回覆');
        expect(find.textContaining('回覆 Olly'), findsOneWidget);
        await tester.enterText(find.widgetWithText(TextField, '寫回覆'), '要');
        await tester.tap(find.byTooltip('送出'));
        await settle(tester);

        expect(find.text('要'), findsOneWidget);
        expect(
          find.textContaining('回覆 Olly'),
          findsNothing,
          reason: 'the reply banner is gone',
        );
        expect(
          find.text('回覆'),
          findsOneWidget,
          reason: 'only the top-level message offers a reply',
        );
        final op = (await real(
          tester,
          () => app.db.select(app.db.outbox).get(),
        )).single;
        expect(op.patch, '{"trip_id":"t1","parent_id":"m1","body":"要"}');
        await app.dispose(tester);
      },
    );

    testWidgets(
      'a member can delete their own message but not someone else\'s',
      (tester) async {
        final app = await start(tester);
        await joinTrip(tester, app, 'member');
        await seedMessage(tester, app, 'm1', 'owner-id', '團長的話');
        await seedMessage(tester, app, 'm2', 'id-a', '我的話', minute: 5);
        await openDiscussion(tester);
        expect(find.byTooltip('刪除留言'), findsOneWidget);

        await tester.tap(find.byTooltip('刪除留言'));
        await settle(tester);
        await tapText(tester, '刪除');

        expect(find.text('我的話'), findsNothing);
        expect(find.text('團長的話'), findsOneWidget);
        expect(
          await real(tester, () => app.db.select(app.db.tripMessages).get()),
          hasLength(1),
        );
        await app.dispose(tester);
      },
    );

    testWidgets(
      'a guide deletes someone else\'s message, and a departed author is named as such',
      (tester) async {
        final app = await start(tester);
        await joinTrip(tester, app, 'guide');
        await seedMessage(tester, app, 'm1', 'mia-id', 'Mia 的話');
        await seedMessage(tester, app, 'm2', 'left-id', '前隊員的話', minute: 5);
        await openDiscussion(tester);
        expect(rich('已離開的成員'), findsOneWidget);
        expect(find.byTooltip('刪除留言'), findsNWidgets(2));

        await tester.tap(find.byTooltip('刪除留言').first);
        await settle(tester);
        await tapText(tester, '刪除');

        expect(find.text('Mia 的話'), findsNothing);
        expect(find.text('前隊員的話'), findsOneWidget);
        expect(await ops(tester, app), ['delete:trip_messages']);
        await app.dispose(tester);
      },
    );

    testWidgets(
      'replies sit under their parent, and a reply without its parent shows on its own',
      (tester) async {
        final app = await start(tester);
        await joinTrip(tester, app, 'member');
        await seedMessage(
          tester,
          app,
          'r1',
          'mia-id',
          '孤兒回覆',
          parent: 'missing',
          minute: 3,
        );
        await seedMessage(tester, app, 'm1', 'owner-id', '第一則', minute: 1);
        await seedMessage(
          tester,
          app,
          'r2',
          'mia-id',
          '第一則的回覆',
          parent: 'm1',
          minute: 2,
        );
        await openDiscussion(tester);

        double y(String t) => tester.getTopLeft(find.text(t)).dy;
        expect(y('第一則'), lessThan(y('第一則的回覆')));
        expect(y('第一則的回覆'), lessThan(y('孤兒回覆')));
        expect(
          tester.getTopLeft(find.text('第一則的回覆')).dx,
          greaterThan(tester.getTopLeft(find.text('第一則')).dx),
        );
        expect(
          tester.getTopLeft(find.text('孤兒回覆')).dx,
          tester.getTopLeft(find.text('第一則')).dx,
        );
        await app.dispose(tester);
      },
    );

    testWidgets('a trip of one person has no discussion tab', (tester) async {
      final app = await start(tester, signedIn: false);
      await act(tester, () => app.container.read(tripRepositoryProvider).create(name: '我的行程', start: DateTime(2026, 5, 10)));
      await settle(tester);
      await tapText(tester, '我的行程');
      expect(find.text('討論'), findsNothing);
      await app.dispose(tester);
    });
  });

  group('polls', () {
    testWidgets('the switch counts open polls and moves between the two views', (tester) async {
      final app = await start(tester);
      await joinTrip(tester, app, 'member');
      await seedPoll(tester, app);
      await openDiscussion(tester);
      expect(find.text('投票 1'), findsOneWidget);
      expect(find.text('早餐吃什麼'), findsNothing);
      expect(find.widgetWithText(TextField, '寫留言'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('discussion-polls')));
      await settle(tester);
      expect(find.text('早餐吃什麼'), findsOneWidget);
      expect(find.widgetWithText(TextField, '寫留言'), findsNothing);
      await app.dispose(tester);
    });

    testWidgets('a member cannot create a poll', (tester) async {
      final app = await start(tester);
      await joinTrip(tester, app, 'member');
      await openPolls(tester);
      expect(find.text('建立投票'), findsNothing);
      expect(find.text('還沒有投票'), findsOneWidget);
      await app.dispose(tester);
    });

    testWidgets('the owner creates a poll with its settings', (tester) async {
      final app = await start(tester);
      await joinTrip(tester, app, 'guide');
      await openPolls(tester);

      await tapText(tester, '建立投票');
      await tapText(tester, '建立');
      expect(find.text('請輸入投票標題'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, '標題'), '哪天攻頂');
      await tester.enterText(find.widgetWithText(TextField, '選項 1'), '週六');
      await tester.enterText(find.widgetWithText(TextField, '選項 2'), '週日');
      await tapText(tester, '建立');
      expect(find.text('至少要有 2 個選項'), findsNothing);

      expect(find.text('哪天攻頂'), findsOneWidget);
      expect(find.text('週六'), findsOneWidget);
      expect(find.text('進行中'), findsOneWidget);
      expect(find.text('單選'), findsOneWidget);
      final poll = (await real(
        tester,
        () => app.db.select(app.db.polls).getSingle(),
      ));
      expect(
        [poll.title, poll.status, poll.allowMultiple, poll.blind],
        ['哪天攻頂', 'open', false, false],
      );
      expect(await ops(tester, app), [
        'upsert:polls',
        'upsert:poll_options',
        'upsert:poll_options',
      ]);
      await app.dispose(tester);
    });

    testWidgets(
      'the creation sheet takes more options, the switches and refuses too few options',
      (tester) async {
        final app = await start(tester);
        await joinTrip(tester, app, 'guide');
        await openPolls(tester);
        await tapText(tester, '建立投票');
        await tester.enterText(find.widgetWithText(TextField, '標題'), '晚餐');
        await tester.enterText(find.widgetWithText(TextField, '選項 1'), '火鍋');
        await tapText(tester, '建立');
        expect(find.text('至少要有 2 個選項'), findsOneWidget);

        await tapText(tester, '再加一個選項');
        await tester.enterText(find.widgetWithText(TextField, '選項 2'), '泡麵');
        await tester.enterText(find.widgetWithText(TextField, '選項 3'), '');
        await tester.tap(find.widgetWithText(SwitchListTile, '允許多選'));
        await tester.tap(find.widgetWithText(SwitchListTile, '盲投'));
        await tester.tap(find.widgetWithText(SwitchListTile, '允許成員新增選項'));
        await tester.pump();
        await tapText(tester, '建立');

        final poll = await real(
          tester,
          () => app.db.select(app.db.polls).getSingle(),
        );
        expect(
          [poll.allowMultiple, poll.blind, poll.allowAddOption],
          [true, true, true],
        );
        expect(
          await real(tester, () => app.db.select(app.db.pollOptions).get()),
          hasLength(2),
        );
        expect(find.text('可多選'), findsOneWidget);
        expect(find.text('盲投'), findsOneWidget);
        await app.dispose(tester);
      },
    );

    testWidgets('a member votes, sees the result, and changes the vote', (
      tester,
    ) async {
      final app = await start(tester);
      await joinTrip(tester, app, 'member');
      await seedPoll(tester, app, votes: {'蛋餅': 'mia-id'});
      await openPolls(tester);
      expect(find.text('1 票'), findsOneWidget);
      expect(find.text('Mia'), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_checked), findsNothing);

      await tester.tap(find.text('蛋餅'));
      await settle(tester);
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      expect(find.text('2 票'), findsOneWidget);
      expect(find.text('Mia、Anna'), findsOneWidget);
      expect(await ops(tester, app), ['upsert:poll_votes']);
      final op = (await real(
        tester,
        () => app.db.select(app.db.outbox).get(),
      )).single;
      expect(op.entityId, voteIdFor('o0', 'id-a'));
      expect(op.patch, '{"poll_id":"p1","option_id":"o0","trip_id":"t1"}');

      await tester.tap(find.text('飯糰'));
      await settle(tester);
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      expect(find.text('1 票'), findsNWidgets(2), reason: 'Mia on 蛋餅, me on 飯糰');
      final votes = await real(
        tester,
        () => app.db.select(app.db.pollVotes).get(),
      );
      expect(votes.where((v) => v.userId == 'id-a').map((v) => v.optionId), [
        'o1',
      ]);

      await tester.tap(find.text('飯糰'));
      await settle(tester);
      expect(find.byIcon(Icons.radio_button_checked), findsNothing);
      await app.dispose(tester);
    });

    testWidgets('a multiple-choice poll takes several votes', (tester) async {
      final app = await start(tester);
      await joinTrip(tester, app, 'member');
      await seedPoll(tester, app, multiple: true);
      await openPolls(tester);
      await tester.tap(find.text('蛋餅'));
      await settle(tester);
      await tester.tap(find.text('飯糰'));
      await settle(tester);
      expect(find.byIcon(Icons.check_box), findsNWidgets(2));
      await tester.tap(find.text('蛋餅'));
      await settle(tester);
      expect(find.byIcon(Icons.check_box), findsOneWidget);
      await app.dispose(tester);
    });

    testWidgets(
      'a blind poll shows no results until it is closed, then the owner\'s close reveals them',
      (tester) async {
        final app = await start(tester);
        await joinTrip(tester, app, 'guide');
        await seedPoll(tester, app, blind: true, votes: {'飯糰': 'mia-id'});
        await openPolls(tester);
        expect(find.textContaining('結果會在投票結束或截止後公開'), findsOneWidget);
        expect(find.textContaining(RegExp(r'\d 票')), findsNothing);
        expect(find.text('Mia'), findsNothing);

        await tester.tap(find.text('蛋餅'));
        await settle(tester);
        expect(
          find.byIcon(Icons.radio_button_checked),
          findsOneWidget,
          reason: 'my own vote is always shown',
        );
        expect(find.text('1 票'), findsNothing);

        await tester.tap(find.byTooltip('投票選單'));
        await settle(tester);
        await tapText(tester, '結束投票');
        expect(find.text('已結束'), findsOneWidget);
        expect(find.text('1 票'), findsNWidgets(2));
        expect(find.text('Mia'), findsOneWidget);
        expect(
          (await real(
            tester,
            () => app.db.select(app.db.polls).getSingle(),
          )).status,
          'closed',
        );

        // Nobody can vote any more, and the owner can open it again.
        await tester.tap(find.text('飯糰'));
        await settle(tester);
        expect(
          await real(tester, () => app.db.select(app.db.pollVotes).get()),
          hasLength(2),
        );
        await tester.tap(find.byTooltip('投票選單'));
        await settle(tester);
        await tapText(tester, '重新開啟');
        expect(find.text('進行中'), findsOneWidget);
        await app.dispose(tester);
      },
    );

    testWidgets('a poll past its deadline is expired and cannot be voted on', (
      tester,
    ) async {
      final app = await start(tester);
      await joinTrip(tester, app, 'member');
      await seedPoll(tester, app, deadline: '2026-05-09T00:00:00Z');
      await openPolls(tester);
      expect(find.text('已截止'), findsOneWidget);
      await tester.tap(find.text('蛋餅'));
      await settle(tester);
      expect(
        await real(tester, () => app.db.select(app.db.pollVotes).get()),
        isEmpty,
      );
      await app.dispose(tester);
    });

    testWidgets(
      'members add an option only when the poll allows it, and remove only their own',
      (tester) async {
        final app = await start(tester);
        await joinTrip(tester, app, 'member');
        await seedPoll(tester, app);
        await openPolls(tester);
        expect(find.text('新增選項'), findsNothing);
        expect(find.byTooltip('刪除選項'), findsNothing);
        await app.dispose(tester);

        final app2 = await start(tester);
        await joinTrip(tester, app2, 'member');
        await seedPoll(tester, app2, addOption: true);
        await openPolls(tester);
        expect(
          find.byTooltip('刪除選項'),
          findsNothing,
          reason: 'the owner\'s options are not mine',
        );
        await tester.enterText(find.widgetWithText(TextField, '新增選項'), '燒餅');
        await tester.tap(find.byTooltip('加入選項'));
        await settle(tester);
        expect(find.text('燒餅'), findsOneWidget);
        expect(find.byTooltip('刪除選項'), findsOneWidget);
        expect(await ops(tester, app2), ['upsert:poll_options']);

        await tester.tap(find.byTooltip('刪除選項'));
        await settle(tester);
        expect(find.text('燒餅'), findsNothing);
        await app2.dispose(tester);
      },
    );

    testWidgets('the owner removes any option and deletes the poll', (
      tester,
    ) async {
      final app = await start(tester);
      await joinTrip(tester, app, 'guide');
      await seedPoll(tester, app, options: ['蛋餅', '飯糰', '燒餅']);
      await openPolls(tester);
      expect(find.byTooltip('刪除選項'), findsNWidgets(3));
      await tester.tap(find.byTooltip('刪除選項').last);
      await settle(tester);
      expect(find.text('燒餅'), findsNothing);

      await tester.tap(find.byTooltip('投票選單'));
      await settle(tester);
      await tapText(tester, '刪除投票');
      await tapText(tester, '刪除');
      expect(find.text('早餐吃什麼'), findsNothing);
      expect(
        await real(tester, () => app.db.select(app.db.polls).get()),
        isEmpty,
      );
      await app.dispose(tester);
    });
  });
}
