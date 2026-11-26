import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:summitmate/core/providers.dart';
import 'package:summitmate/core/sync/local_store.dart';
import 'package:summitmate/core/sync/sync_entity.dart';
import 'package:summitmate/features/trips/providers.dart';

import '../core/support.dart';
import 'harness.dart';

final _now = DateTime(2026, 5, 10, 9);
final _clock = clockProvider.overrideWithValue(() => _now);

Future<AppHarness> start(WidgetTester tester, {void Function(dynamic api)? seed}) =>
    AppHarness.start(tester, welcomeSeen: true, seed: seed == null ? null : (api) => seed(api), overrides: [_clock]);

Future<void> createTrip(WidgetTester tester, String name) async {
  await tapText(tester, '建立第一個行程');
  await enter(tester, '行程名稱', name);
  await tapText(tester, '建立');
}

void main() {
  testWidgets('the empty state offers to create a trip or try the sample', (tester) async {
    final app = await start(tester);
    expect(find.text('還沒有行程'), findsOneWidget);
    expect(find.text('建立第一個行程'), findsOneWidget);
    expect(find.text('用範例行程試試看'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    await app.dispose(tester);
  });

  testWidgets('a trip page whose data went away leaves for the list when the tab is seen again', (tester) async {
    final app = await start(tester);
    await createTrip(tester, '會消失的行程'); // its page is open in the trips tab
    await tapText(tester, '我');

    await act(tester, () => app.db.delete(app.db.trips).go()); // what signing out or switching account does
    await settle(tester);
    expect(find.text('訪客模式'), findsOneWidget, reason: 'clearing the data must not switch tabs by itself');

    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('行程')));
    await settle(tester);
    expect(find.textContaining('找不到這個行程'), findsNothing);
    expect(find.text('還沒有行程'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('creating a trip validates the name and opens the new trip', (tester) async {
    final app = await start(tester);
    await tapText(tester, '建立第一個行程');
    await tapText(tester, '建立');
    expect(find.text('請輸入行程名稱'), findsOneWidget);

    await enter(tester, '行程名稱', '嘉明湖三日');
    await tapText(tester, '建立');

    expect(find.text('嘉明湖三日'), findsWidgets);
    expect(find.text('行程'), findsWidgets);
    expect(find.text('裝備'), findsOneWidget);
    expect(find.text('這一天還沒有節點，按右下角新增登山口、山屋或山頭。'), findsOneWidget);
    expect(find.text('新增節點'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('the sample trip shows a complete example and is marked as a sample', (tester) async {
    final app = await start(tester);
    await tapText(tester, '用範例行程試試看');

    expect(find.text('範例：向陽山屋兩天一夜'), findsWidgets);
    for (final name in ['向陽登山口', '黑水塘', '向陽山屋']) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.text('07:00'), findsOneWidget);
    expect(find.text('2850 m  ·  累計 4.3 km'), findsOneWidget);
    expect(find.text('2700 m  ·  累計 2.1 km'), findsOneWidget);

    await tester.pageBack();
    await settle(tester);
    expect(find.text('範例'), findsOneWidget);
    expect(find.text('即將出發'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('adding, editing and deleting a node', (tester) async {
    final app = await start(tester);
    await createTrip(tester, '測試行程');

    await tapText(tester, '新增節點');
    await enter(tester, '名稱', '向陽山屋');
    await enter(tester, '海拔', '2850');
    await enter(tester, '與上一點距離', '4.3');
    await tapText(tester, '新增');
    expect(find.text('向陽山屋'), findsOneWidget);
    expect(find.text('2850 m  ·  累計 4.3 km'), findsOneWidget);

    await tapText(tester, '向陽山屋');
    expect(find.text('編輯節點'), findsOneWidget);
    await enter(tester, '名稱', '向陽山屋（過夜）');
    await tapText(tester, '儲存');
    expect(find.text('向陽山屋（過夜）'), findsOneWidget);
    expect(find.text('向陽山屋'), findsNothing);

    await tapText(tester, '向陽山屋（過夜）');
    await tapText(tester, '刪除節點');
    await tapText(tester, '刪除');
    expect(find.text('向陽山屋（過夜）'), findsNothing);
    expect(find.text('這一天還沒有節點，按右下角新增登山口、山屋或山頭。'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('nodes are shown in time order and can be marked as arrived', (tester) async {
    final app = await start(tester);
    await createTrip(tester, '排序');
    for (final (name, hour) in [('下午', 15), ('清晨', 6)]) {
      await real(tester, () => app.container.read(itineraryRepositoryProvider).add(
        app.container.read(tripsProvider).value!.single.id,
        dayIndex: 1,
        name: name,
        estMinutes: hour * 60,
      ));
    }
    await settle(tester);
    expect(tester.getTopLeft(find.text('清晨')).dy, lessThan(tester.getTopLeft(find.text('下午')).dy));

    await tester.tap(find.byTooltip('標記已抵達').first);
    await settle(tester);
    expect(find.textContaining('已抵達 '), findsOneWidget);
    await tester.tap(find.byTooltip('取消抵達'));
    await settle(tester);
    expect(find.textContaining('已抵達 '), findsNothing);
    await app.dispose(tester);
  });

  testWidgets('editing and deleting the trip', (tester) async {
    final app = await start(tester);
    await createTrip(tester, '舊名字');

    await tester.tap(find.byType(PopupMenuButton<String>));
    await settle(tester);
    await tapText(tester, '編輯行程');
    await enter(tester, '行程名稱', '新名字');
    await tapText(tester, '儲存');
    expect(find.text('新名字'), findsWidgets);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await settle(tester);
    await tapText(tester, '刪除行程');
    await tapText(tester, '刪除');
    expect(find.text('還沒有行程'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('the list groups trips by when they happen', (tester) async {
    final app = await start(tester);
    final store = LocalStore(app.db);
    await act(tester, () async {
      await store.upsertFromServer(tripsEntity, {...tripRow('now', name: '進行中的', start: '2026-05-09'), 'end_date': '2026-05-11'});
      await store.upsertFromServer(tripsEntity, tripRow('soon', name: '快到了', start: '2026-05-11'));
      await store.upsertFromServer(tripsEntity, tripRow('old', name: '去年的', start: '2025-05-01'));
    });
    await settle(tester);

    expect(find.text('進行中'), findsWidgets);
    expect(find.text('即將出發'), findsOneWidget);
    expect(find.text('過去的行程'), findsOneWidget);
    expect(find.text('明天出發'), findsOneWidget);
    expect(find.text('去年的'), findsNothing, reason: 'past trips are folded away');
    await tester.tap(find.byKey(const ValueKey('toggle-past')));
    await settle(tester);
    expect(find.text('去年的'), findsOneWidget);
    expect(find.text('已結束'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('a guest is told once that signing in backs up their trips', (tester) async {
    final app = await start(tester);
    await createTrip(tester, '我的行程');
    await tester.pageBack();
    await settle(tester);

    expect(find.text('登入後會自動備份行程，換手機也找得回來。'), findsOneWidget);
    await tester.tap(find.byTooltip('知道了'));
    await settle(tester);
    expect(find.text('登入後會自動備份行程，換手機也找得回來。'), findsNothing);
    await app.dispose(tester);
  });

  testWidgets('a team member can look at the itinerary but not change it', (tester) async {
    final app = await start(tester, seed: (api) => api.addAccount('a@x.co', 'Passw0rd1'));
    await real(tester, () => app.container.read(authRepositoryProvider).login(email: 'a@x.co', password: 'Passw0rd1'));
    final store = LocalStore(app.db);
    await act(tester, () async {
      await store.upsertFromServer(tripsEntity, tripRow('t1', name: '別人的行程', ownerId: 'someone-else', start: '2026-05-10'));
      await store.upsertFromServer(tripMembersEntity, {'id': 'm1', 'trip_id': 't1', 'user_id': 'id-a', 'role': 'member', 'display_name': 'a', 'avatar': ''});
      await store.upsertFromServer(itineraryItemsEntity, {...itemRow('i1', 't1', name: '向陽山屋'), 'day_index': 1});
    });
    await settle(tester);

    expect(find.text('隊員'), findsOneWidget);
    await tapText(tester, '別人的行程');
    expect(find.text('向陽山屋'), findsOneWidget);
    expect(find.text('新增節點'), findsNothing);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await settle(tester);
    expect(find.text('編輯行程'), findsNothing, reason: 'a team member cannot edit the trip');
    expect(find.text('刪除行程'), findsNothing);
    expect(find.text('存成範本'), findsOneWidget, reason: 'gear and meals are personal, so templates are for everyone');
    await tester.tapAt(const Offset(5, 5));
    await settle(tester);
    expect(find.byTooltip('標記已抵達'), findsNothing);

    await tapText(tester, '向陽山屋');
    expect(find.text('節點'), findsOneWidget);
    expect(find.text('儲存'), findsNothing);
    expect(find.text('刪除節點'), findsNothing);
    await app.dispose(tester);
  });
}
