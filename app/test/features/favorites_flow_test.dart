import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:summitmate/features/explore/providers.dart';

import 'explore_test.dart' show FakeExploreApi, m, payloadOf;
import 'harness.dart';

Future<AppHarness> start(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  return AppHarness.start(
    tester,
    welcomeSeen: true,
    overrides: [exploreApiProvider.overrideWithValue(FakeExploreApi(payloadOf([m('yushan-main', '玉山', 3952), m('xueshan-main', '雪山', 3885), m('nanhu', '南湖大山', 3742)])))],
  );
}

Future<void> openExplore(WidgetTester tester) async {
  await tapText(tester, '探索');
  await settleUntil(tester, find.byKey(const ValueKey('mountain-yushan-main')));
}

void main() {
  testWidgets('the heart stars a mountain offline, queues one upload, and the 已收藏 filter shows only starred ones', (tester) async {
    final app = await start(tester);
    await openExplore(tester);

    await tester.tap(find.byKey(const ValueKey('fav-yushan-main')));
    await settle(tester);
    final rows = await real(tester, () => app.db.select(app.db.favorites).get());
    expect(rows.map((r) => [r.kind, r.targetId]), [['mountain', 'yushan-main']]);
    expect((await real(tester, () => app.db.select(app.db.outbox).get())).length, 1);
    expect(find.byTooltip('取消收藏'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('filter-favorites')));
    await settle(tester);
    expect(find.byKey(const ValueKey('mountain-yushan-main')), findsOneWidget);
    expect(find.byKey(const ValueKey('mountain-xueshan-main')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('fav-yushan-main'))); // unstar it
    await settle(tester);
    expect(await real(tester, () => app.db.select(app.db.favorites).get()), isEmpty);
    expect(find.textContaining('還沒有收藏的山'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('the mountain page has a heart too, and 我的收藏 lists the starred mountains', (tester) async {
    final app = await start(tester);
    await openExplore(tester);
    await tapText(tester, '雪山');
    await tester.tap(find.byKey(const ValueKey('fav-xueshan-main')));
    await settle(tester);
    expect((await real(tester, () => app.db.select(app.db.favorites).get())).single.targetId, 'xueshan-main');
    await tester.pageBack();
    await settle(tester);

    await tapText(tester, '我');
    await tapText(tester, '我的收藏');
    expect(find.byKey(const ValueKey('favorite-xueshan-main')), findsOneWidget);
    expect(find.byKey(const ValueKey('favorite-yushan-main')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('fav-xueshan-main')));
    await settle(tester);
    expect(find.textContaining('還沒有收藏'), findsOneWidget);
    await app.dispose(tester);
  });
}
