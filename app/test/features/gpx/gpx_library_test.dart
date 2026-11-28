import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/core/db/app_database.dart';
import 'package:summitmate/features/gpx/data/gpx_library.dart';
import 'package:summitmate/features/gpx/domain/gpx_models.dart';
import 'package:summitmate/features/gpx/ui/route_format.dart';

import '../../core/support.dart';
import 'sample_gpx.dart';

void main() {
  late AppDatabase db;
  late Directory dir;
  late GpxLibrary library;

  setUp(() async {
    db = memoryDb();
    dir = await Directory.systemTemp.createTemp('sm_gpx');
    library = GpxLibrary(db, () async => dir, now: () => DateTime(2026, 5, 10));
  });
  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  test('importing keeps an untouched copy with its length, climb and size', () async {
    final bytes = sampleGpx();
    final added = await library.add(bytes, fileName: 'download.gpx');
    expect(added.isNew, isTrue);
    final r = added.route;
    expect([r.name, r.hasTime, r.sizeBytes], ['向陽山屋', true, bytes.length]);
    expect(r.distanceKm, greaterThan(1));
    expect(r.ascent, greaterThan(500));
    expect(await (await library.fileOf(r.id)).readAsBytes(), bytes);

    final route = (await library.load(r.id))!;
    expect(route.points, hasLength(5));
    expect(route.waypoints.map((w) => w.name), ['登山口'], reason: 'only named points are shown');
    expect(route.elapsedAt(4), const Duration(hours: 4));
    expect(route.indexAt(0), 0);
    expect(route.indexAt(route.lengthKm * 2), 4);
    expect(route.indexAt(route.distancesKm[2] + .001), 2);
  });

  test('the same content is not kept twice; another file is', () async {
    final first = await library.add(sampleGpx(), fileName: 'a.gpx');
    final again = await library.add(sampleGpx(), fileName: 'b.gpx');
    expect([again.isNew, again.route.id], [false, first.route.id]);
    await library.add(sampleGpx(elevation: false), fileName: 'c.gpx');
    expect(await db.select(db.gpxRoutes).get(), hasLength(2));
    expect(dir.listSync(), hasLength(2));
  });

  test('a file without elevation or a name still imports, named after the file', () async {
    final r = (await library.add(sampleGpx(elevation: false, named: false), fileName: '北大武.GPX')).route;
    expect([r.name, r.ascent, r.descent], ['北大武', null, null]);
  });

  test('a file without a track is refused and nothing is kept', () async {
    final empty = Uint8List.fromList(utf8.encode('<gpx version="1.1" creator="t"><wpt lat="23" lon="121"><name>x</name></wpt></gpx>'));
    await expectLater(library.add(empty, fileName: 'w.gpx'), throwsA(isA<GpxFormatException>()));
    await expectLater(library.add(Uint8List.fromList(utf8.encode('not xml')), fileName: 'n.gpx'), throwsA(isA<GpxFormatException>()));
    expect(await db.select(db.gpxRoutes).get(), isEmpty);
    expect(dir.listSync(), isEmpty);
  });

  test('renaming and deleting', () async {
    final r = (await library.add(sampleGpx(), fileName: 'a.gpx')).route;
    await library.rename(r.id, '嘉明湖');
    expect((await library.load(r.id))!.name, '嘉明湖');
    await library.delete(r.id);
    expect(await library.load(r.id), isNull);
    expect(dir.listSync(), isEmpty);
  });

  test('numbers are written the way people read them', () {
    expect([formatKm(13.24), formatMetres(2860.4), formatMetres(86)], ['13.2 km', '2,860 m', '86 m']);
    expect([formatBytesShort(300 * 1024), formatBytesShort(3 * 1024 * 1024 + 100 * 1024)], ['300 KB', '3.1 MB']);
    expect([formatElapsed(const Duration(minutes: 45)), formatElapsed(const Duration(hours: 3, minutes: 20))], ['45 分', '3 小時 20 分']);
  });
}
