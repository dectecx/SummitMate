import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/features/map/data/offline_tile_store.dart';

void main() {
  late Directory root;
  setUp(() => root = Directory.systemTemp.createTempSync('tiles_test'));
  tearDown(() => root.deleteSync(recursive: true));

  test('finds tiles of registered regions, forgets deleted ones, and rediscovers regions after a restart', () async {
    final store = OfflineTileStore(Directory('${root.path}/offline_tiles'));
    expect(store.find(12, 3, 4), isNull);

    final f = store.tileFile('yushan', 12, 3, 4)..createSync(recursive: true);
    f.writeAsBytesSync([1, 2, 3]);
    expect(store.find(12, 3, 4), isNull, reason: 'a region counts once it is registered (its download started)');
    store.register('yushan');
    expect(store.find(12, 3, 4)?.path, f.path);
    expect(store.find(12, 3, 5), isNull);

    final restarted = OfflineTileStore(Directory('${root.path}/offline_tiles'));
    expect(restarted.find(12, 3, 4), isNotNull, reason: 'regions on disk are known without a download running');

    await store.delete('yushan');
    expect(store.find(12, 3, 4), isNull);
    expect(f.existsSync(), isFalse);
  });

  test('the downloader writes where the store reads', () {
    expect('${OfflineTileStore.tileDirectory('yushan', 12, 3)}/${OfflineTileStore.tileFilename(4)}', 'offline_tiles/yushan/12/3/4.tile');
  });
}
