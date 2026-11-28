import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../../core/providers.dart';
import '../../explore/domain/mountain_models.dart';
import '../rudy/rudy_client.dart';
import '../rudy/rudy_constants.dart';
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
    return MapSource.rudy; // the offline map, unless the person picked the government one
  }

  Future<void> _load() async {
    final v = await ref.read(settingsStoreProvider).get(mapSourceKey);
    if (v == MapSource.nlsc.name) state = MapSource.nlsc;
  }

  Future<void> choose(MapSource s) async {
    state = s;
    await ref.read(settingsStoreProvider).set(mapSourceKey, s.name);
  }
}

final mapSourceProvider = NotifierProvider<MapSourceController, MapSource>(MapSourceController.new);

final rudyPathsProvider = FutureProvider<RudyPaths>((ref) => RudyPaths.open());

/// Debug builds only: the development server's copy of the map files (`/dev/maps/` next to the API), or null when
/// it has none. Using it spares the author's servers, and makes reinstalling quick.
final rudyDevMirrorProvider = FutureProvider<Uri?>((ref) async {
  if (!kDebugMode) return null;
  final base = Uri.parse(ref.watch(apiBaseUrlProvider)).replace(path: '/dev/maps/');
  try {
    final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 2), receiveTimeout: const Duration(seconds: 2)));
    for (final file in [rudyPmtilesFile, 'noto-sans.zip']) {
      await dio.headUri<void>(base.resolve(file));
    }
    return base;
  } on DioException {
    return null;
  }
});

final rudyInstallerProvider = FutureProvider<RudyInstaller>((ref) async {
  final paths = await ref.watch(rudyPathsProvider.future);
  final mirror = rudyDebugMapUrl.isEmpty ? await ref.watch(rudyDevMirrorProvider.future) : null;
  final mapUrl = rudyDebugMapUrl.isNotEmpty ? rudyDebugMapUrl : mirror?.resolve(rudyPmtilesFile).toString();
  final fonts = rudyDebugFontsUrl.isNotEmpty ? Uri.parse(rudyDebugFontsUrl) : mirror?.resolve('noto-sans.zip');
  final client = RudyClient(Dio(BaseOptions(connectTimeout: const Duration(seconds: 15), receiveTimeout: const Duration(seconds: 30))), appVersion: rudyAppVersion, contactUrl: rudyContactUrl);
  return BackgroundRudyInstaller(paths, client, debugMapUrlOverride: mapUrl, fontsUrl: fonts);
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

/// The map actually on screen: the Rudy Map when it is installed and either chosen or there is no connection (the
/// government map cannot load then); otherwise the government map.
final shownMapProvider = Provider<MapSource>((ref) {
  final installed = ref.watch(rudyReadyProvider).value ?? false;
  final wanted = ref.watch(mapSourceProvider) == MapSource.rudy || !ref.watch(onlineProvider);
  return installed && wanted ? MapSource.rudy : MapSource.nlsc;
});

/// The MapLibre style for the installed files, or null when they are not installed.
final rudyStyleProvider = FutureProvider<String?>((ref) async {
  if (!(await ref.watch(rudyReadyProvider.future))) return null;
  final paths = await ref.watch(rudyPathsProvider.future);
  return buildRudyStyle(pmtilesPath: paths.pmtiles.path, glyphsDir: paths.glyphs.path);
});

typedef RudyMapBuilder = Widget Function(BuildContext context, String style, List<Mountain> mountains, void Function(List<Mountain>) onPeaks, ValueChanged<MapHandle> onCreated);

/// Builds the Rudy map widget. Tests replace it because MapLibre needs the real platform view.
final rudyMapBuilderProvider = Provider<RudyMapBuilder>(
  (ref) => (context, style, mountains, onPeaks, onCreated) => RudyMapView(styleString: style, mountains: mountains, onPeaks: onPeaks, onCreated: onCreated),
);
