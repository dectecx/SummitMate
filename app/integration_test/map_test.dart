// On-device check of the map: markers, and the online government map.
//
//   flutter test integration_test/map_test.dart -d <device> --dart-define=E2E_API=http://localhost:8080/api/v1
//
// Needs the backend (for the mountain list) and internet access.
import 'package:drift/native.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:summitmate/core/auth/token_store.dart';
import 'package:summitmate/core/db/app_database.dart';
import 'package:summitmate/main.dart';

const _api = String.fromEnvironment('E2E_API');

Future<void> pumpUntil(WidgetTester t, Finder f, {int seconds = 25}) async {
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (DateTime.now().isBefore(end)) {
    await t.pump(const Duration(milliseconds: 100));
    if (f.evaluate().isNotEmpty) return;
  }
  final texts = find.byType(Text).evaluate().map((e) => (e.widget as Text).data).whereType<String>().toList();
  throw TestFailure('Timed out waiting for $f. On screen: $texts');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('map markers sit at different places and are tappable', (t) async {
    await t.pumpWidget(await buildApp(database: AppDatabase(NativeDatabase.memory()), tokens: MemoryTokenStore(), apiBaseUrl: _api));
    await t.pumpAndSettle();
    await t.tap(find.text('開始使用'));
    await t.pumpAndSettle();

    // The mountain list loads in the explore tab; the map tab then shows a marker per peak.
    await t.tap(find.text('探索'));
    await pumpUntil(t, find.text('玉山'));
    await t.tap(find.text('地圖'));
    await pumpUntil(t, find.byKey(const ValueKey('peak-yushan-main')));
    await t.pump(const Duration(milliseconds: 500));

    final yushan = t.getCenter(find.byKey(const ValueKey('peak-yushan-main')));
    final xueshan = t.getCenter(find.byKey(const ValueKey('peak-xueshan-main')));
    expect((yushan - xueshan).distance, greaterThan(20), reason: 'two mountains 100 km apart must not be drawn on top of each other');

    // Several peaks of the Xueshan area crowd together at this zoom, so the tap offers a list that contains it.
    await t.tap(find.byKey(const ValueKey('peak-xueshan-main')), warnIfMissed: false);
    await pumpUntil(t, find.textContaining('附近的山'));
    expect(find.text('雪山'), findsOneWidget, reason: 'the list contains the mountain that was tapped');
    await t.tap(find.byKey(const ValueKey('near-xueshan-main')));
    await pumpUntil(t, find.text('天氣預報'));
    expect(find.text('雪山'), findsWidgets, reason: 'its own mountain page opened');
    await t.pageBack();
    await t.pumpAndSettle();
    await t.tap(find.text('地圖'));
    await t.pumpAndSettle();

    expect(find.byType(FlutterMap), findsOneWidget);
  });
}
