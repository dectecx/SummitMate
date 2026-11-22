import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/features/map/rudy/rudy_client.dart';
import 'package:summitmate/features/map/rudy/rudy_installer.dart';
import 'package:summitmate/features/map/rudy/rudy_models.dart';
import 'package:summitmate/features/map/rudy/rudy_paths.dart';

class FakeClient extends RudyClient {
  FakeClient(this.probeResult) : super(Dio(), appVersion: '1.0', contactUrl: 'https://example.test');
  RudyProbe probeResult;
  int probes = 0;
  @override
  Future<RudyProbe> probe(String fileName) async {
    probes++;
    return probeResult;
  }
}

RudyProbe available({String modified = 'Mon', int length = 1000}) => RudyProbe(
  RudyAvailability.available,
  RudyRemoteFile(
    name: 'm',
    resolvedUrl: Uri.parse('https://mirror.test/m.pmtiles'),
    contentLength: length,
    lastModified: modified,
    acceptsRanges: true,
  ),
);

List<int> fontsZip({bool withRegular = true}) {
  final a = Archive();
  void add(String n) => a.addFile(ArchiveFile.bytes(n, utf8.encode('pbf $n')));
  for (final f in ['Noto Sans Regular', 'Noto Sans Bold', 'Noto Sans Italic', 'Noto Sans Display']) {
    if (f == 'Noto Sans Regular' && !withRegular) continue;
    add('$f/0-255.pbf');
    add('$f/256-511.pbf');
  }
  add('README.md');
  return ZipEncoder().encode(a);
}

class FakeFetcher implements RudyFileFetcher {
  final calls = <({Uri url, String name, Map<String, String> headers})>[];
  bool failMap = false;
  bool holdMap = false;
  bool? lastKeepPartial;
  bool holding = false;
  final _hold = Completer<void>();
  List<int> zip = fontsZip();

  @override
  Stream<FetchProgress> fetch({
    required Uri url,
    required File target,
    required Map<String, String> headers,
    int? expectedBytes,
    bool resume = true,
  }) async* {
    final name = target.uri.pathSegments.last;
    calls.add((url: url, name: name, headers: headers));
    final isZip = name.endsWith('.zip');
    if (!isZip && failMap) throw RudyFetchException('boom');
    yield FetchProgress(0, 1000);
    yield FetchProgress(500, 1000);
    if (!isZip && holdMap) {
      holding = true;
      await _hold.future;
    }
    await target.writeAsBytes(isZip ? zip : List.filled(1000, 1));
    yield FetchProgress(1000, 1000);
  }

  @override
  Future<void> cancel({bool keepPartial = false}) async {
    lastKeepPartial = keepPartial;
    if (holding && !_hold.isCompleted) _hold.completeError(const RudyFetchCanceled());
  }

  @override
  Future<bool> hasRunningTask() async => false;
}

void main() {
  late Directory tmp;
  late RudyPaths paths;
  late FakeClient client;
  late FakeFetcher fetcher;

  BackgroundRudyInstaller make({String? override}) =>
      BackgroundRudyInstaller(paths, client, fetcher: fetcher, debugMapUrlOverride: override);

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('rudy_test');
    paths = RudyPaths(Directory('${tmp.path}/rudy'));
    client = FakeClient(available());
    fetcher = FakeFetcher();
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  test('full install: phases in order, weighted progress, only 3 font folders, marker last', () async {
    final inst = make();
    final states = <RudyInstallState>[];
    inst.states.listen(states.add);
    await inst.start();
    await Future<void>.delayed(Duration.zero);

    final phases = states.map((s) => s.phase).toSet().toList();
    expect(phases, [
      RudyInstallPhase.probing,
      RudyInstallPhase.downloadingMap,
      RudyInstallPhase.downloadingFonts,
      RudyInstallPhase.unpacking,
      RudyInstallPhase.done,
    ]);
    final progress = states.map((s) => s.progress).toList();
    for (var i = 1; i < progress.length; i++) {
      expect(progress[i], greaterThanOrEqualTo(progress[i - 1]));
    }
    expect(states.where((s) => s.phase == RudyInstallPhase.downloadingMap).last.progress, closeTo(0.82, 0.001));
    expect(states.where((s) => s.phase == RudyInstallPhase.downloadingFonts).last.progress, closeTo(0.96, 0.001));
    expect(inst.state.progress, 1);

    expect(fetcher.calls.first.url.toString(), 'https://mirror.test/m.pmtiles');
    expect(fetcher.calls.first.headers['User-Agent'], contains('SummitMate/1.0'));
    expect(fetcher.calls.last.url, rudyFontsUrl);

    expect(paths.isInstalled, isTrue);
    expect(paths.installedFingerprint, available().file!.fingerprint);
    expect(paths.fontsZip.existsSync(), isFalse);
    final folders = paths.glyphs.listSync().map((e) => e.uri.pathSegments.where((s) => s.isNotEmpty).last).toSet();
    expect(folders, {'Noto Sans Regular', 'Noto Sans Bold', 'Noto Sans Italic'});
    expect(File('${paths.glyphs.path}/Noto Sans Bold/256-511.pbf').existsSync(), isTrue);
    final src = jsonDecode(paths.sourceInfo.readAsStringSync()) as Map;
    expect(src['url'], 'https://mirror.test/m.pmtiles');
    expect(src['mapComplete'], isTrue);
    final marker = jsonDecode(paths.readyMarker.readAsStringSync()) as Map;
    expect(marker['pmtilesBytes'], 1000);
    expect(marker['installedAt'], isNotNull);
  });

  test('not available (404) -> unavailable with message, nothing downloaded', () async {
    client.probeResult = const RudyProbe(RudyAvailability.notAvailable);
    final inst = make();
    await inst.start();
    expect(inst.state.phase, RudyInstallPhase.unavailable);
    expect(inst.state.error, '魯地圖檔案目前還沒有開放下載');
    expect(fetcher.calls, isEmpty);
    expect(paths.isInstalled, isFalse);
  });

  test('unreachable -> failed', () async {
    client.probeResult = const RudyProbe(RudyAvailability.unreachable);
    final inst = make();
    await inst.start();
    expect(inst.state.phase, RudyInstallPhase.failed);
    expect(inst.state.error, isNotNull);
    expect(fetcher.calls, isEmpty);
  });

  test('map download failure -> failed, no ready marker', () async {
    fetcher.failMap = true;
    final inst = make();
    await inst.start();
    expect(inst.state.phase, RudyInstallPhase.failed);
    expect(paths.readyMarker.existsSync(), isFalse);
    expect(paths.isInstalled, isFalse);
  });

  test('bad fonts zip (missing a font folder) -> failed, no marker, no glyphs', () async {
    fetcher.zip = fontsZip(withRegular: false);
    final inst = make();
    await inst.start();
    expect(inst.state.phase, RudyInstallPhase.failed);
    expect(paths.readyMarker.existsSync(), isFalse);
    expect(paths.glyphs.existsSync(), isFalse);
  });

  test('resume info persisted; retry after a font failure does not refetch the map', () async {
    fetcher.zip = fontsZip(withRegular: false);
    final inst = make();
    await inst.start();
    expect(inst.state.phase, RudyInstallPhase.failed);
    expect(jsonDecode(paths.sourceInfo.readAsStringSync())['mapComplete'], isTrue);

    fetcher.zip = fontsZip();
    fetcher.calls.clear();
    paths.fontsZip.deleteSync(); // as a failed unpack would leave it; force a re-download
    await inst.start();
    expect(inst.state.phase, RudyInstallPhase.done);
    expect(fetcher.calls.map((c) => c.name), [RudyPaths.fontsZipName]);
  });

  test('stored resolved URL is reused for the map when the fingerprint still matches', () async {
    paths.root.createSync(recursive: true);
    final fp = available().file!.fingerprint;
    paths.sourceInfo.writeAsStringSync(
      jsonEncode({'url': 'https://stored.test/x', 'fingerprint': fp, 'mapComplete': false}),
    );
    final inst = make();
    await inst.start();
    expect(fetcher.calls.first.url.toString(), 'https://stored.test/x');
    expect(inst.state.phase, RudyInstallPhase.done);
  });

  test('new fingerprint on update: map refetched, fonts kept', () async {
    await make().start();
    fetcher.calls.clear();
    client.probeResult = available(modified: 'Tue', length: 2000);
    final inst = make();
    expect(await inst.isUpdateAvailable(), isTrue);
    await inst.start();
    expect(fetcher.calls.map((c) => c.name), ['MOI_OSM_Taiwan_TOPO_Rudy.pmtiles']);
    expect(paths.installedFingerprint, available(modified: 'Tue', length: 2000).file!.fingerprint);
  });

  test('isUpdateAvailable: false when same, unreachable, unavailable or not installed', () async {
    final inst = make();
    expect(await inst.isUpdateAvailable(), isFalse); // not installed
    await inst.start();
    expect(await inst.isUpdateAvailable(), isFalse); // same fingerprint
    client.probeResult = const RudyProbe(RudyAvailability.unreachable);
    expect(await inst.isUpdateAvailable(), isFalse);
    client.probeResult = const RudyProbe(RudyAvailability.notAvailable);
    expect(await inst.isUpdateAvailable(), isFalse);
  });

  test('debugMapUrlOverride skips the probe and uses the override url', () async {
    final inst = make(override: 'http://localhost:8080/m.pmtiles');
    await inst.start();
    expect(client.probes, 0);
    expect(fetcher.calls.first.url.toString(), 'http://localhost:8080/m.pmtiles');
    expect(inst.state.phase, RudyInstallPhase.done);
  });

  test('cancel during map download keeps the partial and returns to idle', () async {
    fetcher.holdMap = true;
    final inst = make();
    final run = inst.start();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(inst.state.phase, RudyInstallPhase.downloadingMap);
    await inst.cancel();
    await run;
    expect(fetcher.lastKeepPartial, isTrue);
    expect(inst.state.phase, RudyInstallPhase.idle);
    expect(paths.isInstalled, isFalse);
  });

  test('remove deletes everything', () async {
    final inst = make();
    await inst.start();
    expect(paths.isInstalled, isTrue);
    await inst.remove();
    expect(paths.root.existsSync(), isFalse);
    expect(paths.isInstalled, isFalse);
    expect(inst.state.phase, RudyInstallPhase.idle);
  });

  test('isInstalled needs marker, non-empty pmtiles and the Regular font folder', () async {
    paths.root.createSync(recursive: true);
    expect(paths.isInstalled, isFalse);
    paths.readyMarker.writeAsStringSync('{"fingerprint":"f"}');
    paths.pmtiles.writeAsBytesSync([]);
    Directory('${paths.glyphs.path}/Noto Sans Regular').createSync(recursive: true);
    expect(paths.isInstalled, isFalse); // empty pmtiles
    paths.pmtiles.writeAsBytesSync([1]);
    expect(paths.isInstalled, isTrue);
    expect(paths.installedFingerprint, 'f');
  });
}
