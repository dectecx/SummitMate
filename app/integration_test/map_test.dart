// On-device check of the map: markers, the real tile cache and a small real download from the NLSC server.
//
//   flutter test integration_test/map_test.dart -d <device> --dart-define=E2E_API=http://localhost:8080/api/v1
//
// Needs the backend (for the mountain list) and internet access. It downloads only a handful of tiles.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:summitmate/core/auth/token_store.dart';
import 'package:summitmate/core/db/app_database.dart';
import 'package:summitmate/features/map/data/tile_cache.dart';
import 'package:summitmate/features/map/domain/offline_regions.dart';
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

  testWidgets('map markers sit at different places and a real region downloads and deletes', (t) async {
    final cache = await FmtcTileCache.initialise();
    await t.pumpWidget(await buildApp(database: AppDatabase(NativeDatabase.memory()), tokens: MemoryTokenStore(), apiBaseUrl: _api, tileCache: cache));
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

    // A tiny region (about 1 km, z13..z15) from the real server, then removal.
    const tiny = OfflineRegionDef(id: 'device-test', name: '測試', description: '', bounds: GeoBounds(south: 23.470, west: 120.957, north: 23.478, east: 120.965), minZoom: 13, maxZoom: 15);
    final downloader = cache.downloader;
    final updates = await downloader.download(tiny).toList();
    expect(updates, isNotEmpty);
    expect(updates.last.done, updates.last.total);
    final dir = Directory('${cache.store.root.path}/device-test');
    final files = dir.listSync(recursive: true).whereType<File>().toList();
    expect(files.length, updates.last.total, reason: 'every tile is a file on disk');
    expect(files.every((f) => f.lengthSync() > 0), isTrue);
    final parts = files.first.path.split('/');
    final y = int.parse(parts.last.split('.').first), x = int.parse(parts[parts.length - 2]), z = int.parse(parts[parts.length - 3]);
    expect(cache.store.find(z, x, y)?.path, files.first.path, reason: 'the map finds the downloaded tile');
    await downloader.deleteTiles('device-test');
    expect(dir.existsSync(), isFalse, reason: 'the region is gone');

    expect(find.byType(FlutterMap), findsOneWidget);
  });
}
