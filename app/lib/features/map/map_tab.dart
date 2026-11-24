import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../shared/open_link.dart';
import '../explore/domain/mountain_models.dart';
import '../explore/providers.dart';
import 'data/location_service.dart';
import 'maplibre/rudy_map_view.dart';
import 'maplibre/rudy_providers.dart';
import 'rudy/rudy_constants.dart';
import 'domain/map_logic.dart';
import 'providers.dart';

/// NLSC (內政部國土測繪中心) open-data e-map with contour lines, online only. Note the z/y/x order.
const _nlscTileUrl = 'https://wmts.nlsc.gov.tw/wmts/EMAP5_OPENDATA/default/GoogleMapsCompatible/{z}/{y}/{x}';

/// "地圖": the topographic map with the mountains, the person's position; the Rudy Map when it is installed.
class MapTab extends ConsumerStatefulWidget {
  const MapTab({super.key});

  @override
  ConsumerState<MapTab> createState() => _MapTabState();
}

class _MapTabState extends ConsumerState<MapTab> {
  final _controller = MapController();
  LatLng? _me;
  bool _locating = false;
  MapHandle? _rudy; // set while the Rudy Map is the one on screen
  bool _usingRudy = false;
  bool _farView = true; // zoomed out: peaks are dots

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _zoom(double delta) {
    if (_usingRudy) {
      _rudy?.zoomBy(delta * 0.5); // half a level per press: finer than the raster map, which has no sub-levels
      return;
    }
    final cam = _controller.camera;
    _controller.move(cam.center, (cam.zoom + delta).clamp(6, 18));
  }

  Future<void> _locate() async {
    if (_locating) return;
    setState(() => _locating = true);
    final result = await ref.read(locationServiceProvider).current();
    if (!mounted) return;
    setState(() => _locating = false);
    switch (result) {
      case LocationFound(:final lat, :final lng):
        setState(() => _me = LatLng(lat, lng));
        if (_usingRudy) {
          _rudy?.setMe(lat, lng);
          _rudy?.moveTo(lat, lng, minZoom: 13);
        } else {
          _controller.move(LatLng(lat, lng), _controller.camera.zoom < 13 ? 13 : _controller.camera.zoom);
        }
      case LocationDenied(:final permanent):
        _say(permanent ? '位置權限已被關閉，請到系統設定開啟。' : '需要位置權限才能顯示你的位置。');
      case LocationDisabled():
        _say('手機的定位服務沒有開啟。');
      case LocationUnavailable():
        _say('暫時抓不到位置，請到空曠處再試一次。');
    }
  }

  void _say(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    final mountains = switch (ref.watch(mountainsProvider).value) {
      MountainsReady(:final data) => data.mountains,
      _ => const <Mountain>[],
    };
    final scheme = Theme.of(context).colorScheme;
    final source = ref.watch(mapSourceProvider);
    ref.watch(rudyReadyProvider); // keep it loaded so the menu knows whether the files are there
    final rudyStyle = source == MapSource.rudy ? ref.watch(rudyStyleProvider).value : null;
    _usingRudy = rudyStyle != null;
    if (!_usingRudy) {
      _rudy = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('地圖'),
        actions: [
          PopupMenuButton<MapSource>(
            key: const ValueKey('map-source'),
            tooltip: '底圖',
            icon: const Icon(Icons.layers_outlined),
            initialValue: source,
            onSelected: _chooseSource,
            itemBuilder: (_) => const [
              PopupMenuItem(value: MapSource.nlsc, child: Text('政府底圖（國土測繪中心）')),
              PopupMenuItem(value: MapSource.rudy, child: Text('魯地圖（登山地形圖）')),
            ],
          ),
          IconButton(
            tooltip: '離線地圖',
            onPressed: () => context.push(Routes.offlineMaps),
            icon: const Icon(Icons.download_for_offline_outlined),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (rudyStyle != null)
            ref.watch(rudyMapBuilderProvider)(context, rudyStyle, mountains, _onPeaksTapped, (h) {
              _rudy = h;
              h.setMe(_me?.latitude, _me?.longitude);
            })
          else
            FlutterMap(
              mapController: _controller,
              options: MapOptions(
                initialCenter: const LatLng(23.7, 121.0),
                initialZoom: 7.5,
                minZoom: 6,
                maxZoom: 18,
                // Peaks are small dots while the whole island is in view and become mountains once you zoom in.
                onPositionChanged: (camera, _) {
                  final far = camera.zoom < 10;
                  if (far != _farView) setState(() => _farView = far);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: _nlscTileUrl,
                  userAgentPackageName: 'com.declab.summitmate',
                  maxNativeZoom: 15, // z16 of the NLSC layer is only an enlarged z15
                  tileProvider: ref.watch(mapTileProviderProvider),
                ),
                MarkerLayer(
                  markers: [
                    for (final m in mountains)
                      Marker(
                        key: ValueKey('peak-${m.id}'),
                        point: LatLng(m.latitude, m.longitude),
                        width: 32,
                        height: 32,
                        child: GestureDetector(
                          onTap: () => _onPeakTap(m, mountains),
                          child: _farView
                              ? Center(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                                    child: const SizedBox.square(dimension: 9),
                                  ),
                                )
                              : Icon(
                                  Icons.landscape,
                                  color: scheme.primary,
                                  size: 24,
                                  shadows: const [Shadow(blurRadius: 4, color: Colors.white)],
                                ),
                        ),
                      ),
                    if (_me != null)
                      Marker(
                        key: const ValueKey('me'),
                        point: _me!,
                        width: 24,
                        height: 24,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: scheme.tertiary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          // Credit required by the data licence. It wraps (never overflows) and leaves room for the buttons.
          Positioned(
            left: 8,
            bottom: 8,
            right: 72,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: InkWell(
                  key: const ValueKey('map-attribution'),
                  onTap: () => ref
                      .read(linkOpenerProvider)(Uri.parse(_usingRudy ? rudyHomeUrl : 'https://maps.nlsc.gov.tw')),
                  child: Text(
                    _usingRudy
                        ? rudyAttribution
                        : '地圖：內政部國土測繪中心（政府資料開放授權條款第 1 版）',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(decoration: TextDecoration.underline),
                  ),
                ),
              ),
            ),
          ),
          // One control group so the buttons can never overlap each other or the attribution.
          Positioned(
            right: 12,
            bottom: 32,
            child: Material(
              elevation: 3,
              color: scheme.surface,
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: '我的位置',
                    onPressed: _locate,
                    icon: _locating
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location),
                  ),
                  const Divider(height: 1),
                  IconButton(tooltip: '放大', onPressed: () => _zoom(1), icon: const Icon(Icons.add)),
                  const Divider(height: 1),
                  IconButton(tooltip: '縮小', onPressed: () => _zoom(-1), icon: const Icon(Icons.remove)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _chooseSource(MapSource s) async {
    if (s == MapSource.rudy && !(ref.read(rudyReadyProvider).value ?? false)) {
      // Needs a download first: the offline maps page has it.
      _say('魯地圖需要先下載，請在「離線地圖」頁下載。');
      context.push(Routes.offlineMaps);
      return;
    }
    await ref.read(mapSourceProvider.notifier).choose(s);
  }

  void _onPeaksTapped(List<Mountain> near) {
    if (near.length == 1) return _showMountain(near.first);
    _showNear(near);
  }

  void _onPeakTap(Mountain m, List<Mountain> all) {
    final near = peaksNear(all, m.latitude, m.longitude, _controller.camera.zoom);
    if (near.length <= 1) return _showMountain(m);
    _showNear(near);
  }

  void _showNear(List<Mountain> near) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text('附近的山（${near.length}）', style: Theme.of(ctx).textTheme.titleLarge),
            ),
            for (final p in near)
              ListTile(
                key: ValueKey('near-${p.id}'),
                title: Text(p.name),
                subtitle: Text('${p.region}  ·  ${p.elevation} m'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(ctx);
                  context.go(Routes.mountain(p.id));
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showMountain(Mountain m) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(m.name, style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('${m.region}  ·  ${m.elevation} m'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go(Routes.mountain(m.id));
              },
              child: const Text('查看山岳資料'),
            ),
          ],
        ),
      ),
    );
  }
}
