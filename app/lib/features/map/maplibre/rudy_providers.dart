import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:path_provider/path_provider.dart';

import '../../../core/providers.dart';
import '../../explore/domain/mountain_models.dart';
import '../data/offline_manager.dart';
import '../data/offline_tile_store.dart';
import '../domain/offline_regions.dart';
import '../providers.dart';
import '../rudy/rudy_client.dart';
import '../rudy/rudy_installer.dart';
import '../rudy/rudy_paths.dart';
import 'rudy_map_view.dart';
import 'rudy_style.dart';

/// Which base map the map tab shows.
enum MapSource { nlsc, rudy }

const mapSourceKey = 'map_source';

/// Contact address sent in the User-Agent of every Rudy Map request (the author asks for one).
/// TODO(release): replace with the real SummitMate contact page.
const rudyContactUrl = String.fromEnvironment('RUDY_CONTACT_URL', defaultValue: 'https://example.com/summitmate');
const rudyAppVersion = '0.1.0';

/// A development-only direct map file address (a mirror), for testing before rudymap.tw serves the PMTiles file.
const rudyDebugMapUrl = String.fromEnvironment('RUDY_PMTILES_URL');

/// Development-only direct address of the fonts zip (a local test server).
const rudyDebugFontsUrl = String.fromEnvironment('RUDY_FONTS_URL');

class MapSourceController extends Notifier<MapSource> {
  @override
  MapSource build() {
    _load();
    return MapSource.nlsc;
  }

  Future<void> _load() async {
    final v = await ref.read(settingsStoreProvider).get(mapSourceKey);
    if (v == MapSource.rudy.name) state = MapSource.rudy;
  }

  Future<void> choose(MapSource s) async {
    state = s;
    await ref.read(settingsStoreProvider).set(mapSourceKey, s.name);
  }
}

final mapSourceProvider = NotifierProvider<MapSourceController, MapSource>(MapSourceController.new);

final rudyPathsProvider = FutureProvider<RudyPaths>((ref) => RudyPaths.open());

final rudyInstallerProvider = FutureProvider<RudyInstaller>((ref) async {
  final paths = await ref.watch(rudyPathsProvider.future);
  final client = RudyClient(Dio(BaseOptions(connectTimeout: const Duration(seconds: 15), receiveTimeout: const Duration(seconds: 30))), appVersion: rudyAppVersion, contactUrl: rudyContactUrl);
  return BackgroundRudyInstaller(paths, client, debugMapUrlOverride: rudyDebugMapUrl.isEmpty ? null : rudyDebugMapUrl, fontsUrl: rudyDebugFontsUrl.isEmpty ? null : Uri.parse(rudyDebugFontsUrl));
});

/// Progress of the Rudy Map download; the first value is the current state.
final rudyInstallStateProvider = StreamProvider<RudyInstallState>((ref) async* {
  final installer = await ref.watch(rudyInstallerProvider.future);
  yield installer.state;
  yield* installer.states;
});

/// True once the Rudy Map files are on the device.
final rudyReadyProvider = FutureProvider<bool>((ref) async {
  final paths = await ref.watch(rudyPathsProvider.future);
  ref.watch(rudyInstallStateProvider.select((s) => s.value?.phase)); // re-check when a download ends or the files are removed
  return paths.isInstalled;
});

/// Folder of the elevation tiles of the 3D view once they are downloaded, else null.
final rudyDemDirProvider = FutureProvider<String?>((ref) async {
  final rows = ref.watch(offlineRegionsProvider).value ?? const [];
  final done = rows.any((r) => r.id == terrainDem.id && r.state == OfflineState.done);
  if (!done) return null;
  final support = await getApplicationSupportDirectory();
  return '${support.path}/${OfflineTileStore.demRelativeRoot}/${terrainDem.id}';
});

/// The MapLibre style for the installed files, or null when they are not installed.
final rudyStyleProvider = FutureProvider<String?>((ref) async {
  if (!(await ref.watch(rudyReadyProvider.future))) return null;
  final paths = await ref.watch(rudyPathsProvider.future);
  final dem = await ref.watch(rudyDemDirProvider.future);
  return buildRudyStyle(pmtilesPath: paths.pmtiles.path, glyphsDir: paths.glyphs.path, demDir: dem);
});

typedef RudyMapBuilder = Widget Function(BuildContext context, String style, List<Mountain> mountains, void Function(List<Mountain>) onPeaks, ValueChanged<MapHandle> onCreated);

/// Builds the Rudy map widget. Tests replace it because MapLibre needs the real platform view.
final rudyMapBuilderProvider = Provider<RudyMapBuilder>(
  (ref) => (context, style, mountains, onPeaks, onCreated) => RudyMapView(styleString: style, mountains: mountains, onPeaks: onPeaks, onCreated: onCreated),
);
