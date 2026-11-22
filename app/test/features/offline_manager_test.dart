import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/core/db/app_database.dart';
import 'package:summitmate/features/map/data/offline_manager.dart';
import 'package:summitmate/features/map/data/tile_downloader.dart';
import 'package:summitmate/features/map/domain/offline_regions.dart';

import '../core/support.dart';

/// A downloader the test drives by hand.
class FakeDownloader implements TileDownloader {
  final started = <String>[];
  final deleted = <String>[];
  final cancelled = <String>[];
  final running = <String>{}; // regions the system is still downloading
  final _controllers = <String, StreamController<DownloadUpdate>>{};

  @override
  Stream<DownloadUpdate> download(OfflineRegionDef region) {
    started.add(region.id);
    return (_controllers[region.id] = StreamController<DownloadUpdate>()).stream;
  }

  void progress(String id, int done, int total, [double bytes = 0]) => _controllers[id]!.add(DownloadUpdate(done: done, total: total, bytes: bytes));
  Future<void> finish(String id) => _controllers[id]!.close();
  void fail(String id, Object error) => _controllers[id]!.addError(error);

  @override
  Future<bool> isRunning(String regionId) async => running.contains(regionId);

  @override
  Future<void> cancel(String regionId) async {
    cancelled.add(regionId);
    await _controllers[regionId]?.close();
  }

  @override
  Future<void> deleteTiles(String regionId) async => deleted.add(regionId);
}

Future<void> settleDb() => pumpEventQueue(times: 30);

void main() {
  late AppDatabase db;
  late FakeDownloader dl;
  late OfflineMapsManager manager;

  Future<Map<String, String>> states() async => {for (final r in await db.select(db.offlineRegions).get()) r.id: r.state};

  setUp(() {
    db = memoryDb();
    dl = FakeDownloader();
    manager = OfflineMapsManager(db, dl, now: () => DateTime(2026, 11, 22));
  });
  tearDown(() => db.close());

  test('downloads run one at a time in the order they were requested', () async {
    await manager.start('yushan');
    await manager.start('xueba');
    await manager.start('nanhu');
    await settleDb();

    expect(dl.started, ['yushan']);
    expect(await states(), {'yushan': 'downloading', 'xueba': 'queued', 'nanhu': 'queued'});

    dl.progress('yushan', 100, 700, 2.5e6);
    await settleDb();
    final row = (await db.select(db.offlineRegions).get()).firstWhere((r) => r.id == 'yushan');
    expect([row.tilesDone, row.tilesTotal, row.bytes], [100, 700, 2.5e6]);

    await dl.finish('yushan');
    await settleDb();
    expect(dl.started, ['yushan', 'xueba']);
    expect(await states(), {'yushan': 'done', 'xueba': 'downloading', 'nanhu': 'queued'});
    expect((await db.select(db.offlineRegions).get()).firstWhere((r) => r.id == 'yushan').tilesDone, 700, reason: 'done means all tiles');
  });

  test('a failed download is marked failed and the queue moves on', () async {
    await manager.start('yushan');
    await manager.start('xueba');
    await settleDb();

    dl.fail('yushan', Exception('server said no'));
    await settleDb();

    final yushan = (await db.select(db.offlineRegions).get()).firstWhere((r) => r.id == 'yushan');
    expect(yushan.state, 'failed');
    expect(yushan.error, contains('server said no'));
    expect(dl.started, ['yushan', 'xueba'], reason: 'the next one still starts');
    expect((await states())['xueba'], 'downloading');
  });

  test('retrying a failed or interrupted region queues it again and keeps its progress', () async {
    await manager.start('yushan');
    await settleDb();
    dl.progress('yushan', 300, 700);
    await settleDb();
    dl.fail('yushan', Exception('offline'));
    await settleDb();

    await manager.start('yushan');
    await settleDb();
    expect(dl.started, ['yushan', 'yushan']);
    final row = (await db.select(db.offlineRegions).get()).single;
    expect([row.state, row.tilesDone, row.error], ['downloading', 300, null]);
  });

  test('starting something that is already queued, running or done does nothing', () async {
    await manager.start('yushan');
    await manager.start('yushan');
    await settleDb();
    expect(dl.started, ['yushan']);
    await dl.finish('yushan');
    await settleDb();
    await manager.start('yushan');
    await settleDb();
    expect(dl.started, ['yushan']);
    await manager.start('no-such-region');
    expect((await states()).keys, ['yushan']);
  });

  test('cancelling a queued region removes it; cancelling the running one stops it and forgets it', () async {
    await manager.start('yushan');
    await manager.start('xueba');
    await manager.start('nanhu');
    await settleDb();

    await manager.cancel('xueba');
    expect(await states(), {'yushan': 'downloading', 'nanhu': 'queued'});
    expect(dl.deleted, ['xueba']);

    await manager.cancel('yushan');
    await settleDb();
    expect(dl.cancelled, ['yushan']);
    expect(dl.deleted, containsAll(['xueba', 'yushan']));
    expect(await states(), {'nanhu': 'downloading'}, reason: 'the queue continues with the next region');
  });

  test('deleting a downloaded region removes its row and tiles', () async {
    await manager.start('yushan');
    await settleDb();
    await dl.finish('yushan');
    await settleDb();

    await manager.delete('yushan');
    expect(await states(), isEmpty);
    expect(dl.deleted, ['yushan']);
  });

  test('after the app was killed, queued and running downloads show up as interrupted and can be resumed', () async {
    await manager.start('yushan');
    await manager.start('xueba');
    await manager.start('nanhu');
    await settleDb();
    await dl.finish('yushan');
    await settleDb();

    // New process: a fresh manager over the same database.
    final restarted = OfflineMapsManager(db, FakeDownloader(), now: () => DateTime(2026, 11, 23));
    await restarted.recover();
    expect(await states(), {'yushan': 'done', 'xueba': 'interrupted', 'nanhu': 'interrupted'});

    final fresh = FakeDownloader();
    final resumed = OfflineMapsManager(db, fresh, now: () => DateTime(2026, 11, 23));
    await resumed.start('xueba');
    await settleDb();
    expect(fresh.started, ['xueba']);
  });

  test('a download the system kept running in the background is picked up again, not marked interrupted', () async {
    await manager.start('yushan');
    await manager.start('xueba');
    await settleDb();

    final restartedDownloader = FakeDownloader()..running.add('yushan');
    final restarted = OfflineMapsManager(db, restartedDownloader, now: () => DateTime(2026, 11, 23));
    await restarted.recover();
    await settleDb();
    expect(restartedDownloader.started, ['yushan'], reason: 'reattached to the running one');
    expect(await states(), {'yushan': 'downloading', 'xueba': 'interrupted'});

    restartedDownloader.progress('yushan', 5, 10);
    await restartedDownloader.finish('yushan');
    await settleDb();
    expect((await states())['yushan'], 'done');
  });

  group('regions', () {
    test('the tile list matches the tile count', () {
      for (final r in allOfflineRegions) {
        final tiles = tilesFor(r.bounds, r.minZoom, r.maxZoom).toList();
        expect(tiles.length, r.estimatedTiles, reason: r.id);
        expect(tiles.toSet().length, tiles.length, reason: 'no tile twice');
      }
    });

    test('tile counts match known values', () {
      expect(taiwanBase.estimatedTiles, 1589 - 0, reason: 'z8..z12 over the island, as measured in the research');
      expect(countTiles(const GeoBounds(south: 10, west: 10, north: 10.0001, east: 10.0001), 3, 3), 1);
    });

    test('every region is inside Taiwan, has a sensible size, and ids are unique', () {
      final ids = <String>{};
      for (final r in allOfflineRegions) {
        expect(ids.add(r.id), isTrue, reason: 'duplicate id ${r.id}');
        expect(r.bounds.south, greaterThan(21.5));
        expect(r.bounds.north, lessThan(25.6));
        expect(r.bounds.west, greaterThan(119.5));
        expect(r.bounds.east, lessThan(122.3));
        expect(r.maxZoom, lessThanOrEqualTo(nlscMaxNativeZoom));
        expect(r.estimatedBytes, lessThan(80 * 1024 * 1024), reason: '${r.id} would be too big to offer as one tap');
        expect(r.estimatedTiles, greaterThan(0));
      }
      expect(offlineRegionById('yushan')!.name, '玉山');
      expect(offlineRegionById('nope'), isNull);
    });

    test('sizes are shown for people', () {
      expect(formatBytes(512 * 1024), '512 KB');
      expect(formatBytes(5.5 * 1024 * 1024), '5.5 MB');
      expect(formatBytes(42 * 1024 * 1024), '42 MB');
      expect(formatBytes(1.5 * 1024 * 1024 * 1024), '1.5 GB');
    });
  });
}
