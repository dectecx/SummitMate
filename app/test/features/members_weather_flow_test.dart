import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:summitmate/core/auth/auth_api.dart';
import 'package:summitmate/core/providers.dart';
import 'package:summitmate/core/sync/local_store.dart';
import 'package:summitmate/core/sync/sync_coordinator.dart';
import 'package:summitmate/core/sync/sync_entity.dart';
import 'package:summitmate/features/members/data/trip_owner_api.dart';
import 'package:summitmate/features/members/data/user_search_api.dart';
import 'package:summitmate/features/members/domain/member_logic.dart';
import 'package:summitmate/features/members/providers.dart';
import 'package:summitmate/features/trips/providers.dart';
import 'package:summitmate/features/weather/data/weather_repository.dart';
import 'package:summitmate/features/weather/domain/weather_models.dart';
import 'package:summitmate/features/weather/providers.dart';

import '../core/support.dart';
import 'harness.dart';

class FakeSearch implements UserSearchApi {
  final users = <String, FoundUser>{'bob@x.co': const FoundUser(id: 'bob-id', displayName: 'Bob', avatar: '🦊')};
  @override
  Future<List<FoundUser>> findByEmail(String email) async => [if (users[email] != null) users[email]!];
}

/// The harness has no network, so syncing is a no-op here.
class NoSync implements SyncCoordinator {
  @override
  Future<void> refresh() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeOwnerApi implements TripOwnerApi {
  final calls = <String>[];
  Object? failWith;
  @override
  Future<void> transfer(String tripId, String newOwnerId) async {
    if (failWith != null) throw failWith!;
    calls.add('$tripId>$newOwnerId');
  }
}

class FakeWeather implements WeatherApi {
  bool fail = false;
  @override
  Future<String> forecast(WeatherQuery q, {int days = 7}) async {
    if (fail) throw Exception('offline');
    return jsonEncode({
      'latitude': q.lat, 'longitude': q.lng, 'elevation': q.elevation, 'timezone': 'Asia/Taipei', 'fetched_at': '2026-11-22T01:00:00Z',
      'daily': [
        {'date': '2026-05-10', 'weather_code': 0, 'temp_max': 11.4, 'temp_min': 2.2, 'precipitation_probability_max': 20, 'precipitation_sum': 0, 'wind_speed_max': 12, 'wind_gusts_max': 30},
        {'date': '2026-05-11', 'weather_code': 61, 'temp_max': 9, 'temp_min': 1, 'precipitation_probability_max': 80, 'precipitation_sum': 5, 'wind_speed_max': 20, 'wind_gusts_max': null},
      ],
    });
  }
}

final _now = DateTime(2026, 5, 10, 9);

Future<AppHarness> start(WidgetTester tester, {bool signedIn = true, FakeWeather? weather, FakeSearch? search, FakeOwnerApi? owner}) async {
  final app = await AppHarness.start(
    tester,
    welcomeSeen: true,
    seed: (api) => api.addAccount('a@x.co', 'Passw0rd1', name: 'Anna'),
    overrides: [
      clockProvider.overrideWithValue(() => _now),
      userSearchApiProvider.overrideWithValue(search ?? FakeSearch()),
      weatherApiProvider.overrideWithValue(weather ?? FakeWeather()),
      tripOwnerApiProvider.overrideWithValue(owner ?? FakeOwnerApi()),
      syncCoordinatorProvider.overrideWithValue(NoSync()),
    ],
  );
  if (signedIn) await real(tester, () => app.container.read(authRepositoryProvider).login(email: 'a@x.co', password: 'Passw0rd1'));
  return app;
}

Future<String> ownTrip(WidgetTester tester, AppHarness app) async {
  final id = await act(tester, () => app.container.read(tripRepositoryProvider).create(name: '我的行程', start: DateTime(2026, 5, 10), end: DateTime(2026, 5, 11)));
  await settle(tester);
  await tapText(tester, '我的行程');
  await tapText(tester, '成員');
  return id;
}

Future<void> searchFor(WidgetTester tester, String email) async {
  await tester.enterText(find.widgetWithText(TextField, '對方的 Email'), email);
  await tester.tap(find.byTooltip('搜尋'));
  await settle(tester);
}

void main() {
  testWidgets('a guest is asked to sign in before inviting anyone', (tester) async {
    final app = await start(tester, signedIn: false);
    await ownTrip(tester, app);
    expect(find.textContaining('登入後才能邀請隊友'), findsOneWidget);
    expect(find.text('邀請'), findsNothing);
    expect(find.text('成員（0）'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('the owner invites someone by e-mail, changes their role and removes them', (tester) async {
    final app = await start(tester);
    final trip = await ownTrip(tester, app);
    expect(find.text('Anna（你）'), findsOneWidget);
    expect(find.text('團長'), findsOneWidget);

    await tapText(tester, '邀請');
    await searchFor(tester, 'nobody@x.co');
    expect(find.textContaining('找不到這個 Email'), findsOneWidget);
    await searchFor(tester, 'bad');
    expect(find.text('Email 格式不正確'), findsOneWidget);

    await searchFor(tester, 'bob@x.co');
    expect(find.text('找到了'), findsOneWidget);
    await tapText(tester, '嚮導');
    await tapText(tester, '邀請 Bob');
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('嚮導'), findsOneWidget);
    expect(find.text('成員（2）'), findsOneWidget);
    final queued = await real(tester, () => app.db.select(app.db.outbox).get());
    expect(queued.where((o) => o.entity == 'trip_members' && o.entityId == memberIdFor(trip, 'bob-id')), hasLength(1));

    await tester.tap(find.byTooltip('管理 Bob'));
    await settle(tester);
    await tapText(tester, '設為隊員');
    expect(find.text('隊員'), findsOneWidget);

    await tester.tap(find.byTooltip('管理 Bob'));
    await settle(tester);
    await tapText(tester, '移除成員');
    await tapText(tester, '移除');
    expect(find.text('Bob'), findsNothing);
    expect(find.text('成員（1）'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('inviting someone who is already on the trip says so', (tester) async {
    final app = await start(tester);
    await ownTrip(tester, app);
    for (var i = 0; i < 2; i++) {
      await tapText(tester, '邀請');
      await searchFor(tester, 'bob@x.co');
      if (i == 0) {
        await tapText(tester, '邀請 Bob');
      }
    }
    expect(find.textContaining('已經在這個行程裡了'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('a team member sees everyone, cannot manage anyone, and can leave', (tester) async {
    final app = await start(tester);
    final store = LocalStore(app.db);
    await act(tester, () async {
      await store.upsertFromServer(tripsEntity, tripRow('t1', name: '別人的行程', ownerId: 'owner-id', start: '2026-05-10'));
      await store.upsertFromServer(tripMembersEntity, {'id': 'mo', 'trip_id': 't1', 'user_id': 'owner-id', 'role': 'owner', 'display_name': 'Olly', 'avatar': '🐻'});
      await store.upsertFromServer(tripMembersEntity, {'id': 'mm', 'trip_id': 't1', 'user_id': 'id-a', 'role': 'member', 'display_name': 'Anna', 'avatar': '🐻'});
    });
    await settle(tester);
    await tapText(tester, '別人的行程');
    await tapText(tester, '成員');

    expect(find.text('Olly'), findsOneWidget);
    expect(find.text('Anna（你）'), findsOneWidget);
    expect(find.text('邀請'), findsNothing);
    expect(find.byTooltip('管理 Olly'), findsNothing);

    await tapText(tester, '離開這個行程');
    await tapText(tester, '離開');
    expect(find.text('還沒有行程'), findsOneWidget);
    final ops = await real(tester, () => app.db.select(app.db.outbox).get());
    expect(ops.map((o) => '${o.type}:${o.entity}/${o.entityId}'), [contains('delete:trip_members/${memberIdFor('t1', 'id-a')}')]);
    await app.dispose(tester);
  });

  testWidgets('a guide can manage team members but not another guide', (tester) async {
    final app = await start(tester);
    final store = LocalStore(app.db);
    await act(tester, () async {
      await store.upsertFromServer(tripsEntity, tripRow('t1', name: '嚮導視角', ownerId: 'owner-id', start: '2026-05-10'));
      for (final m in [('mo', 'owner-id', 'owner', 'Olly'), ('mg', 'id-a', 'guide', 'Anna'), ('mg2', 'g2', 'guide', 'Gus'), ('mm', 'm1', 'member', 'Mia')]) {
        await store.upsertFromServer(tripMembersEntity, {'id': m.$1, 'trip_id': 't1', 'user_id': m.$2, 'role': m.$3, 'display_name': m.$4, 'avatar': '🐻'});
      }
    });
    await settle(tester);
    await tapText(tester, '嚮導視角');
    await tapText(tester, '成員');

    expect(find.text('邀請'), findsOneWidget);
    expect(find.byTooltip('管理 Mia'), findsOneWidget);
    expect(find.byTooltip('管理 Gus'), findsNothing);
    expect(find.byTooltip('管理 Olly'), findsNothing);
    await app.dispose(tester);
  });

  Future<void> openItineraryTab(WidgetTester tester) async {
    await tester.tap(find.descendant(of: find.byType(TabBar), matching: find.text('行程')));
    await settle(tester);
  }

  testWidgets('the itinerary shows the weather of the selected day, at where the group is that day', (tester) async {
    final app = await start(tester);
    final trip = await ownTrip(tester, app);
    await act(tester, () => app.container.read(itineraryRepositoryProvider).add(trip, dayIndex: 1, name: '向陽山屋', altitude: 2850, lat: 23.4, lng: 121.0));
    await openItineraryTab(tester);

    expect(find.byKey(const ValueKey('weather-day-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('weather-day-2')), findsNothing);
    expect(find.text('第 1 天  5/10（日）'), findsOneWidget);
    expect(find.text('向陽山屋  2850 m'), findsOneWidget);
    expect(find.text('2° / 11°'), findsOneWidget);
    expect(find.text('降雨 20%  ·  風 12 km/h'), findsOneWidget);
    expect(find.textContaining('提醒：低溫'), findsOneWidget); // 2° at night

    await tester.tap(find.byKey(const ValueKey('day-2')));
    await settle(tester);
    expect(find.text('第 2 天  5/11（一）'), findsOneWidget);
    expect(find.text('向陽山屋  2850 m'), findsOneWidget); // day 2 has no node of its own and stays there
    expect(find.text('雨'), findsOneWidget);
    expect(find.textContaining('提醒：帶雨具'), findsOneWidget); // 80% rain
    await app.dispose(tester);
  });

  testWidgets('weather says so when it cannot be loaded, and asks guests to sign in', (tester) async {
    final weather = FakeWeather()..fail = true;
    final app = await start(tester, weather: weather);
    final trip = await ownTrip(tester, app);
    await act(tester, () => app.container.read(itineraryRepositoryProvider).add(trip, dayIndex: 1, name: 'x', lat: 23.4, lng: 121.0));
    await openItineraryTab(tester);
    expect(find.text('目前無法取得天氣，請稍後再試。'), findsOneWidget);
    await app.dispose(tester);

    final guestApp = await start(tester, signedIn: false);
    final t2 = await ownTrip(tester, guestApp);
    await act(tester, () => guestApp.container.read(itineraryRepositoryProvider).add(t2, dayIndex: 1, name: 'x', lat: 23.4, lng: 121.0));
    await openItineraryTab(tester);
    expect(find.text('登入後可以查看天氣預報。'), findsOneWidget);
    await guestApp.dispose(tester);
  });

  testWidgets('a node form accepts coordinates and validates their range', (tester) async {
    final app = await start(tester, signedIn: false);
    await act(tester, () => app.container.read(tripRepositoryProvider).create(name: '座標', start: DateTime(2026, 5, 10)));
    await settle(tester);
    await tapText(tester, '座標');
    await tapText(tester, '新增節點');
    await enter(tester, '名稱', '山頭');
    await tapText(tester, '手動輸入座標（進階）');
    await enter(tester, '緯度', '123');
    await tapText(tester, '新增');
    expect(find.text('緯度 需介於 -90 到 90'), findsOneWidget);

    await enter(tester, '緯度', '23.4');
    await enter(tester, '經度', '121.0');
    await tapText(tester, '新增');
    final row = (await real(tester, () => app.db.select(app.db.itineraryItems).get())).single;
    expect([row.lat, row.lng], [23.4, 121.0]);
    await app.dispose(tester);
  });

  testWidgets('the owner can hand the trip to a member, and sees why when it fails', (tester) async {
    final owner = FakeOwnerApi();
    final app = await start(tester, owner: owner);
    final store = LocalStore(app.db);
    await act(tester, () async {
      await store.upsertFromServer(tripsEntity, tripRow('t1', name: '移交', ownerId: 'id-a', start: '2026-05-10'));
      for (final m in [('mo', 'id-a', 'owner', 'Anna'), ('mm', 'm1', 'member', 'Mia')]) {
        await store.upsertFromServer(tripMembersEntity, {'id': m.$1, 'trip_id': 't1', 'user_id': m.$2, 'role': m.$3, 'display_name': m.$4, 'avatar': '🐻'});
      }
    });
    await settle(tester);
    await tapText(tester, '移交');
    await tapText(tester, '成員');

    await tester.tap(find.byTooltip('管理 Mia'));
    await settle(tester);
    await tapText(tester, '移交團長');
    expect(find.textContaining('Mia 會成為團長'), findsOneWidget);
    await tapText(tester, '取消');
    expect(owner.calls, isEmpty);

    owner.failWith = const AuthNetworkException('connectionError');
    await tester.tap(find.byTooltip('管理 Mia'));
    await settle(tester);
    await tapText(tester, '移交團長');
    await tapText(tester, '移交');
    expect(find.textContaining('移交團長需要網路'), findsOneWidget);

    owner.failWith = null;
    await tester.pump(const Duration(seconds: 5));
    await tester.tap(find.byTooltip('管理 Mia'));
    await settle(tester);
    await tapText(tester, '移交團長');
    await tapText(tester, '移交');
    expect(owner.calls, ['t1>m1']);
    expect(find.text('已把團長交給 Mia'), findsOneWidget);
    await app.dispose(tester);
  });
}
