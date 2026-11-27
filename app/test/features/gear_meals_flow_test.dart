import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:summitmate/core/providers.dart';
import 'package:summitmate/core/sync/local_store.dart';
import 'package:summitmate/core/sync/sync_entity.dart';
import 'package:summitmate/features/gear/providers.dart';
import 'package:summitmate/features/meals/providers.dart';
import 'package:summitmate/features/trips/providers.dart';

import '../core/support.dart';
import 'harness.dart';

final _now = DateTime(2026, 5, 10, 9);

Future<AppHarness> startWithTrip(WidgetTester tester) async {
  final app = await AppHarness.start(tester, welcomeSeen: true, overrides: [clockProvider.overrideWithValue(() => _now)]);
  await act(tester, () => app.container.read(tripRepositoryProvider).create(name: '裝備測試', start: DateTime(2026, 5, 10), end: DateTime(2026, 5, 11)));
  await settle(tester);
  await tapText(tester, '裝備測試');
  return app;
}

void main() {
  testWidgets('gear can be dragged into order by its handle, only in reorder mode', (tester) async {
    tester.view.physicalSize = const Size(800, 1000); // room below the rows, so the drag does not auto-scroll
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final app = await startWithTrip(tester);
    await tapText(tester, '裝備');
    for (final name in ['甲', '乙']) {
      await tapText(tester, '新增裝備');
      await enter(tester, '名稱', name);
      await tapText(tester, '新增');
    }
    expect(find.byIcon(Icons.drag_handle), findsNothing);

    await tester.tap(find.byKey(const ValueKey('reorder-toggle')));
    await settle(tester);
    expect(find.byIcon(Icons.drag_handle), findsNWidgets(2));
    final gesture = await tester.startGesture(tester.getCenter(find.byIcon(Icons.drag_handle).first));
    await tester.pump(const Duration(milliseconds: 100));
    for (var i = 0; i < 6; i++) {
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await gesture.up();
    await settle(tester);

    final rows = await real(tester, () => app.db.select(app.db.gearItems).get());
    rows.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    expect(rows.map((r) => r.name), ['乙', '甲']);
    await app.dispose(tester);
  });

  testWidgets('gear: add items, see totals, pack, edit and delete', (tester) async {
    final app = await startWithTrip(tester);
    await tapText(tester, '裝備');
    expect(find.textContaining('只有你看得到'), findsOneWidget);

    await tapText(tester, '新增裝備');
    await enter(tester, '名稱', '睡袋');
    await enter(tester, '單件重量', '900');
    await tapText(tester, '新增');
    await tapText(tester, '新增裝備');
    await enter(tester, '名稱', '爐頭');
    await enter(tester, '單件重量', '380');
    await enter(tester, '數量', '2');
    await tapText(tester, '新增');

    expect(find.text('睡袋'), findsOneWidget);
    expect(find.text('爐頭'), findsOneWidget);
    expect(find.text('1.66 kg'), findsNWidgets(2), reason: '900 + 2 × 380, in the summary and the category subtotal');
    expect(find.text('380 g × 2'), findsOneWidget);
    expect(find.text('已打包 0 / 2 項'), findsOneWidget);

    await tester.tap(find.byType(Checkbox).first);
    await settle(tester);
    expect(find.text('已打包 1 / 2 項'), findsOneWidget);

    await tapText(tester, '爐頭');
    await enter(tester, '名稱', '爐頭與瓦斯');
    await tapText(tester, '儲存');
    expect(find.text('爐頭與瓦斯'), findsOneWidget);

    await tapText(tester, '睡袋');
    await tapText(tester, '刪除裝備');
    expect(find.text('睡袋'), findsNothing);
    expect(find.text('1 項'), findsNothing);
    expect(find.text('已打包 0 / 1 項'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('gear is only validated for what matters: a name and at least one item', (tester) async {
    final app = await startWithTrip(tester);
    await tapText(tester, '裝備');
    await tapText(tester, '新增裝備');
    await tapText(tester, '新增');
    expect(find.text('請輸入裝備名稱'), findsOneWidget);
    await enter(tester, '名稱', 'x');
    await enter(tester, '數量', '0');
    await tapText(tester, '新增');
    expect(find.text('至少 1 件'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('meals: add per day, totals, switch day, edit and delete', (tester) async {
    final app = await startWithTrip(tester);
    await tapText(tester, '餐食');
    expect(find.textContaining('這一天還沒有餐食'), findsOneWidget);

    await tapText(tester, '新增餐食');
    await enter(tester, '名稱', '飯糰');
    await enter(tester, '單份重量', '180');
    await enter(tester, '單份熱量', '320');
    await enter(tester, '份數', '2');
    await tapText(tester, '新增');

    expect(find.text('午餐'), findsOneWidget);
    expect(find.text('飯糰'), findsOneWidget);
    expect(find.text('360 g'), findsWidgets);
    expect(find.text('640 kcal'), findsWidgets);

    // Another day starts empty but the whole-trip total still counts the first.
    await tester.tap(find.byKey(const ValueKey('meal-day-2')));
    await settle(tester);
    expect(find.text('飯糰'), findsNothing);
    expect(find.textContaining('這一天還沒有餐食'), findsOneWidget);
    expect(find.text('640 kcal'), findsOneWidget, reason: 'only the whole-trip total');

    await tester.tap(find.byKey(const ValueKey('meal-day-1')));
    await settle(tester);
    await tapText(tester, '飯糰');
    await enter(tester, '名稱', '鮪魚飯糰');
    await tapText(tester, '儲存');
    expect(find.text('鮪魚飯糰'), findsOneWidget);

    await tapText(tester, '鮪魚飯糰');
    await tapText(tester, '刪除餐食');
    expect(find.text('鮪魚飯糰'), findsNothing);
    await app.dispose(tester);
  });

  testWidgets('a team member can fill in their own gear and meals', (tester) async {
    final app = await AppHarness.start(tester, welcomeSeen: true, seed: (api) => api.addAccount('a@x.co', 'Passw0rd1'), overrides: [clockProvider.overrideWithValue(() => _now)]);
    await real(tester, () => app.container.read(authRepositoryProvider).login(email: 'a@x.co', password: 'Passw0rd1'));
    final store = LocalStore(app.db);
    await act(tester, () async {
      await store.upsertFromServer(tripsEntity, tripRow('t1', name: '別人的行程', ownerId: 'someone-else', start: '2026-05-10'));
      await store.upsertFromServer(tripMembersEntity, {'id': 'm1', 'trip_id': 't1', 'user_id': 'id-a', 'role': 'member', 'display_name': 'a', 'avatar': ''});
    });
    await settle(tester);
    await tapText(tester, '別人的行程');

    expect(find.text('新增節點'), findsNothing, reason: 'shared itinerary is read-only for members');
    await tapText(tester, '裝備');
    await tapText(tester, '新增裝備');
    await enter(tester, '名稱', '我的睡袋');
    await tapText(tester, '新增');
    expect(find.text('我的睡袋'), findsOneWidget);

    await tapText(tester, '餐食');
    await tapText(tester, '新增餐食');
    await enter(tester, '名稱', '我的午餐');
    await tapText(tester, '新增');
    expect(find.text('我的午餐'), findsOneWidget);

    expect((await real(tester, () => app.container.read(gearRepositoryProvider).watch('t1').first)).length, 1);
    expect((await real(tester, () => app.container.read(mealRepositoryProvider).watch('t1').first)).length, 1);
    await app.dispose(tester);
  });

  testWidgets('the sample trip comes with a packing list and a meal plan', (tester) async {
    tester.view.physicalSize = const Size(800, 2400); // tall: the grouped list is lazy
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final app = await AppHarness.start(tester, welcomeSeen: true, overrides: [clockProvider.overrideWithValue(() => _now)]);
    await tapText(tester, '用範例行程試試看');
    await tapText(tester, '裝備');
    expect(find.text('睡袋'), findsOneWidget);
    expect(find.text('已打包 2 / 6 項'), findsOneWidget);
    await tapText(tester, '餐食');
    expect(find.text('飯糰'), findsOneWidget);
    expect(find.text('行動糧'), findsOneWidget);
    await app.dispose(tester);
  });
}
