import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../../shared/icon_badge.dart';
import '../../shared/brand/cover_image.dart';
import '../../app/router.dart';
import '../trips/domain/trip_art.dart';
import '../trips/domain/gpx_trip.dart';
import '../trips/providers.dart';
import 'ui/map_markers.dart';
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

/// The credit the NLSC licence asks for.
const nlscAttribution = '地圖：內政部國土測繪中心（政府資料開放授權條款第 1 版）';

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
  String? _shownRoute; // what the map on screen has already drawn and framed

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

    final routeTripId = ref.watch(mapRouteProvider);
    final routeTrip = routeTripId == null ? null : ref.watch(tripProvider(routeTripId)).value;
    final route = [for (final p in decodeTrack(routeTrip?.track)) (lat: p.lat, lng: p.lng)];
    _drawRoute(routeTrip == null ? null : '${routeTrip.id}:${routeTrip.track.hashCode}', route);

    // The map fills the screen; its title and controls float over it. The map picture is light in both themes.
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Stack(
          children: [
            if (rudyStyle != null)
              ref.watch(rudyMapBuilderProvider)(context, rudyStyle, mountains, _onPeaksTapped, (h) {
                _rudy = h;
                h.setMe(_me?.latitude, _me?.longitude);
                if (route.length >= 2) h.setRoute(route);
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
                  if (route.length >= 2)
                    PolylineLayer(
                      key: const ValueKey('map-route'),
                      polylines: [
                        Polyline(
                          points: [for (final p in route) LatLng(p.lat, p.lng)],
                          color: const Color(0xFFB9532F),
                          strokeWidth: 4,
                          borderColor: Colors.white,
                          borderStrokeWidth: 1.5,
                        ),
                      ],
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
                            child: PeakMarker(far: _farView),
                          ),
                        ),
                      if (_me != null)
                        Marker(key: const ValueKey('me'), point: _me!, width: 24, height: 24, child: const MeMarker()),
                    ],
                  ),
                ],
              ),
            Positioned(
              left: 16,
              right: 16,
              top: MediaQuery.paddingOf(context).top + 8,
              child: Align(
                alignment: Alignment.topLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TitleCard(
                      sourceName: _usingRudy ? '魯地圖・登山地形圖' : '政府底圖・需要網路',
                      onOfflineMaps: () => context.push(Routes.offlineMaps),
                    ),
                    if (routeTrip != null && route.length >= 2)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: InputChip(
                          key: const ValueKey('map-route-chip'),
                          avatar: const Icon(Icons.route_outlined, size: 18),
                          label: Text('路線：${routeTrip.name}', overflow: TextOverflow.ellipsis),
                          deleteButtonTooltipMessage: '不顯示路線',
                          onDeleted: () => ref.read(mapRouteProvider.notifier).clear(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Credit required by the data licence, one tap away so it does not cover the map.
            Positioned(
              left: 12,
              bottom: 12 + MediaQuery.paddingOf(context).bottom,
              child: IconButton(
                key: const ValueKey('map-attribution'),
                tooltip: '地圖資料來源',
                style: IconButton.styleFrom(
                  backgroundColor: scheme.surfaceContainerLowest.withValues(alpha: 0.9),
                  foregroundColor: scheme.onSurfaceVariant,
                  minimumSize: const Size(44, 44),
                ),
                onPressed: _showCredit,
                icon: const Icon(Icons.info_outline, size: 20),
              ),
            ),
            // One control group so the buttons can never overlap each other or the info button.
            Positioned(
              right: 12,
              bottom: 32 + MediaQuery.paddingOf(context).bottom,
              child: Material(
                elevation: 3,
                shadowColor: Colors.black38,
                color: scheme.surfaceContainerLowest,
                shape: StadiumBorder(side: BorderSide(color: scheme.outlineVariant)),
                child: SizedBox(
                  width: 50,
                  child: IconButtonTheme(
                    data: IconButtonThemeData(
                      style: IconButton.styleFrom(foregroundColor: scheme.primary, minimumSize: const Size(48, 48)),
                    ),
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
                        const Divider(height: 1),
                        PopupMenuButton<MapSource>(
                          key: const ValueKey('map-source'),
                          tooltip: '底圖',
                          icon: Icon(Icons.layers_outlined, color: scheme.primary),
                          initialValue: source,
                          onSelected: _chooseSource,
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: MapSource.nlsc, child: Text('政府底圖（國土測繪中心）')),
                            PopupMenuItem(value: MapSource.rudy, child: Text('魯地圖（登山地形圖）')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Brings a newly chosen route into view, once. The Rudy Map also draws it itself.
  void _drawRoute(String? id, List<({double lat, double lng})> route) {
    final key = id == null ? null : '$id:$_usingRudy';
    if (key == _shownRoute) return;
    final hadRoute = _shownRoute != null;
    _shownRoute = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_usingRudy) {
        if (route.length >= 2 || hadRoute) _rudy?.setRoute(route);
      } else if (route.length >= 2) {
        _controller.fitCamera(
          CameraFit.coordinates(
            coordinates: [for (final p in route) LatLng(p.lat, p.lng)],
            padding: const EdgeInsets.fromLTRB(48, 160, 80, 140),
            maxZoom: 15,
          ),
        );
      }
    });
  }

  void _showCredit() {
    final rudy = _usingRudy;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('地圖資料來源'),
        content: Text(rudy ? rudyAttribution : nlscAttribution),
        actions: [
          TextButton(
            key: const ValueKey('map-attribution-link'),
            onPressed: () => ref.read(linkOpenerProvider)(Uri.parse(rudy ? rudyHomeUrl : 'https://maps.nlsc.gov.tw')),
            child: const Text('開啟網站'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('關閉')),
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
                leading: const IconBadge(Icons.terrain_outlined),
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
            if (MediaQuery.orientationOf(ctx) == Orientation.portrait)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(height: 120, child: CoverImage(cover: coverFor(m.id, coverCount))),
                ),
              ),
            Text(m.name, style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
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

/// The floating title: which base map is on screen, and the way to the offline maps.
class _TitleCard extends StatelessWidget {
  const _TitleCard({required this.sourceName, required this.onOfflineMaps});
  final String sourceName;
  final VoidCallback onOfflineMaps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      elevation: 3,
      shadowColor: Colors.black38,
      color: scheme.surfaceContainerLowest,
      shape: StadiumBorder(side: BorderSide(color: scheme.outlineVariant)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 8, 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '地圖',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 1),
                  ),
                  Text(
                    sourceName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              tooltip: '離線地圖',
              style: IconButton.styleFrom(foregroundColor: scheme.primary, minimumSize: const Size(48, 48)),
              onPressed: onOfflineMaps,
              icon: const Icon(Icons.download_for_offline_outlined),
            ),
          ],
        ),
      ),
    );
  }
}
