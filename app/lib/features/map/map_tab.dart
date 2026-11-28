import 'dart:async';

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
import 'ui/map_controls.dart';
import 'ui/map_markers.dart';
import '../../core/providers.dart';
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

/// The credit the Open Government Data License asks for (its exhibit): provider, year, dataset, statement and link.
/// Dataset: https://data.gov.tw/dataset/17214 (layer EMAP5_OPENDATA, updated irregularly; year checked 2026-11-28).
const nlscAttribution =
    '內政部國土測繪中心　2026　臺灣通用電子地圖（套疊等高線，比例尺小於一萬八千分之一）\n\n'
    '此開放資料依政府資料開放授權條款（第 1 版）進行公眾釋出，使用者於遵守本條款各項規定之前提下，得利用之。\n\n'
    '政府資料開放授權條款：https://data.gov.tw/license';

const _nlscShortCredit = '地圖：內政部國土測繪中心';

/// How long the short credit stays before it folds into the info button, as the OpenStreetMap guideline allows.
const mapCreditDuration = Duration(seconds: 5);

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
  final _north = ValueNotifier<double>(0); // of the government map; the Rudy Map keeps its own
  bool _creditOpen = false; // the short credit is on the map
  bool? _creditedRudy; // the map it was last shown for
  Timer? _creditTimer;

  @override
  void dispose() {
    _creditTimer?.cancel();
    _north.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Shows the short credit when a map comes on screen for the first time, or when the base map changes.
  void _creditFor(bool rudy) {
    if (_creditedRudy == rudy) return;
    _creditedRudy = rudy;
    _creditOpen = true;
    _creditTimer?.cancel();
    _creditTimer = Timer(mapCreditDuration, _foldCredit);
  }

  /// Touching the map or its controls folds the credit away early.
  void _foldCredit() {
    _creditTimer?.cancel();
    if (_creditOpen && mounted) setState(() => _creditOpen = false);
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
    final installed = ref.watch(rudyReadyProvider).value; // unknown until the files have been looked for
    final online = ref.watch(onlineProvider);
    final rudyStyle = ref.watch(shownMapProvider) == MapSource.rudy ? ref.watch(rudyStyleProvider).value : null;
    _usingRudy = rudyStyle != null;
    if (!_usingRudy) {
      _rudy = null;
    }

    final routeTripId = ref.watch(mapRouteProvider);
    final routeTrip = routeTripId == null ? null : ref.watch(tripProvider(routeTripId)).value;
    final route = [for (final p in decodeTrack(routeTrip?.track)) (lat: p.lat, lng: p.lng)];
    _drawRoute(routeTrip == null ? null : '${routeTrip.id}:${routeTrip.track.hashCode}', route);

    _creditFor(_usingRudy);

    // The map fills the screen; its controls float over it. The map picture is light in both themes.
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Stack(
          children: [
            Listener(
              onPointerDown: (_) => _foldCredit(),
              child: rudyStyle != null
                ? ref.watch(rudyMapBuilderProvider)(context, rudyStyle, mountains, _onPeaksTapped, (h) {
                  _rudy = h;
                  // the compass follows this map from now on
                  WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? setState(() {}) : null);
                  h.setMe(_me?.latitude, _me?.longitude);
                  if (route.length >= 2) h.setRoute(route);
                })
                : FlutterMap(
                  mapController: _controller,
                  options: MapOptions(
                    initialCenter: const LatLng(23.7, 121.0),
                    initialZoom: 7.5,
                    minZoom: 6,
                    maxZoom: 18,
                    // Peaks are small dots while the whole island is in view and become mountains once you zoom in.
                    onPositionChanged: (camera, _) {
                      _north.value = camera.rotation;
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
            ),
            // top left: what is drawn on the map
            if (routeTrip != null && route.length >= 2)
              Positioned(
                left: 12,
                right: 150,
                top: MediaQuery.paddingOf(context).top + 8,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: InputChip(
                    key: const ValueKey('map-route-chip'),
                    avatar: const Icon(Icons.route_outlined, size: 18),
                    label: Text('路線：${routeTrip.name}', overflow: TextOverflow.ellipsis),
                    deleteButtonTooltipMessage: '不顯示路線',
                    onDeleted: () => ref.read(mapRouteProvider.notifier).clear(),
                  ),
                ),
              ),
            // top right: which map, then the compass
            Positioned(
              right: 12,
              top: MediaQuery.paddingOf(context).top + 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  MapLayerButton(
                    // "離線": standing in for the government map, which was chosen but needs a connection
                    label: !_usingRudy ? '政府底圖' : (source == MapSource.nlsc ? '魯地圖・離線' : '魯地圖'),
                    onPressed: () {
                      _foldCredit();
                      showMapSettings(context, onChoose: _chooseSource, onOfflineMaps: () => context.push(Routes.offlineMaps), onCredit: _showCredit);
                    },
                  ),
                  const SizedBox(height: 10),
                  MapCompass(
                    north: _usingRudy ? (_rudy?.north ?? _north) : _north,
                    onPressed: () {
                      _foldCredit();
                      if (_usingRudy) {
                        _rudy?.resetNorth();
                      } else {
                        _controller.rotate(0);
                      }
                    },
                  ),
                ],
              ),
            ),
            // bottom: the credit and "where am I", over the offer to download the Rudy Map
            Positioned(
              left: 12,
              right: 12,
              bottom: 12 + MediaQuery.paddingOf(context).bottom,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          // Credit required by the data licences: a short line when the map appears, afterwards in
                          // the map settings.
                          child: _creditOpen
                              ? ActionChip(
                                  key: const ValueKey('map-credit'),
                                  backgroundColor: scheme.surfaceContainerLowest.withValues(alpha: 0.92),
                                  label: Text(_usingRudy ? rudyShortCredit : _nlscShortCredit, style: Theme.of(context).textTheme.labelSmall),
                                  onPressed: _showCredit,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      MapRoundButton(
                        tooltip: '我的位置',
                        onPressed: () {
                          _foldCredit();
                          _locate();
                        },
                        icon: _locating
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.my_location),
                      ),
                    ],
                  ),
                  if (source == MapSource.rudy && installed == false)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: RudyPrompt(
                        offline: !online,
                        onDownload: () => context.push(Routes.offlineMaps),
                        onDecline: () => ref.read(mapSourceProvider.notifier).choose(MapSource.nlsc),
                      ),
                    ),
                ],
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
            padding: const EdgeInsets.fromLTRB(48, 120, 48, 140),
            maxZoom: 15,
          ),
        );
      }
    });
  }

  void _showCredit() {
    _foldCredit();
    final rudy = _usingRudy;
    Widget link(String key, String label, String url) => TextButton(
      key: ValueKey(key),
      onPressed: () => ref.read(linkOpenerProvider)(Uri.parse(url)),
      child: Text(label),
    );
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('地圖資料來源'),
        content: SingleChildScrollView(child: Text(rudy ? rudyAttribution : nlscAttribution)),
        actions: [
          if (rudy) ...[
            link('map-attribution-link', '魯地圖官網', rudyHomeUrl),
            link('map-osm-link', 'OpenStreetMap 授權', osmCopyrightUrl),
          ] else ...[
            link('map-attribution-link', '圖資網站', 'https://maps.nlsc.gov.tw'),
            link('map-licence-link', '授權條款', 'https://data.gov.tw/license'),
          ],
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('關閉')),
        ],
      ),
    );
  }

  Future<void> _chooseSource(MapSource s) async {
    final installed = ref.read(rudyReadyProvider).value ?? false;
    if (s == MapSource.rudy && !installed) {
      // Needs a download first: the offline maps page has it.
      await ref.read(mapSourceProvider.notifier).choose(s);
      if (mounted) context.push(Routes.offlineMaps);
      return;
    }
    if (s == MapSource.nlsc && installed && !ref.read(onlineProvider)) _say('沒有網路，暫時顯示魯地圖。');
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
