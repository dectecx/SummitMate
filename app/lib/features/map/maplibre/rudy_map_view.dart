import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../explore/domain/mountain_models.dart';
import '../domain/map_logic.dart';

/// What the map tab needs from a map implementation, so the controls work the same on both maps.
abstract interface class MapHandle {
  double get zoom;

  /// Where north points on screen, in degrees clockwise from straight up.
  ValueListenable<double> get north;
  Future<void> resetNorth();
  Future<void> moveTo(double lat, double lng, {double? minZoom});
  Future<void> setMe(double? lat, double? lng);

  /// Draws a route with its named points over the map (empty removes it) and brings the whole of it into view.
  Future<void> setRoute(List<({double lat, double lng})> points, {List<({String name, double lat, double lng})> waypoints = const []});

  /// Marks one place on the route (null removes the mark), keeping it in view.
  Future<void> setCursor(({double lat, double lng})? point);
}

/// The Rudy Map drawn by MapLibre from local files, with the mountains and the person's position on top.
class RudyMapView extends StatefulWidget {
  const RudyMapView({
    super.key,
    required this.styleString,
    required this.mountains,
    required this.onPeaks,
    required this.onCreated,
  });
  final String styleString;
  final List<Mountain> mountains;

  /// The mountains near the tapped place (nearest first is not guaranteed; highest first).
  final void Function(List<Mountain> near) onPeaks;
  final ValueChanged<MapHandle> onCreated;

  @override
  State<RudyMapView> createState() => _RudyMapViewState();
}

class _RudyMapViewState extends State<RudyMapView> implements MapHandle {
  MapLibreMapController? _c;
  bool _styleReady = false;
  ({double lat, double lng})? _me;

  static const _peaksSource = 'summitmate-peaks';
  static const _meSource = 'summitmate-me';
  static const _routeSource = 'summitmate-route';

  static const _waypointSource = 'summitmate-waypoints';
  static const _cursorSource = 'summitmate-cursor';

  var _route = const <({double lat, double lng})>[];
  var _waypoints = const <({String name, double lat, double lng})>[];
  ({double lat, double lng})? _cursor;

  @override
  double get zoom => _c?.cameraPosition?.zoom ?? 7.5;

  final _north = ValueNotifier<double>(0);

  @override
  ValueListenable<double> get north => _north;

  @override
  Future<void> resetNorth() async {
    await _c?.animateCamera(CameraUpdate.bearingTo(0));
  }

  // The bearing is the direction at the top of the screen, so north sits the other way round.
  void _onCamera() => _north.value = -(_c?.cameraPosition?.bearing ?? 0);

  @override
  Future<void> moveTo(double lat, double lng, {double? minZoom}) async {
    await _c?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lng), math.max(zoom, minZoom ?? 0)));
  }

  @override
  Future<void> setMe(double? lat, double? lng) async {
    _me = lat == null || lng == null ? null : (lat: lat, lng: lng);
    if (_styleReady) await _c?.setGeoJsonSource(_meSource, _meGeoJson());
  }

  @override
  Future<void> setRoute(List<({double lat, double lng})> points, {List<({String name, double lat, double lng})> waypoints = const []}) async {
    _route = points;
    _waypoints = waypoints;
    _cursor = null;
    if (!_styleReady) return; // drawn when the style is ready
    await _c?.setGeoJsonSource(_routeSource, _routeGeoJson());
    await _c?.setGeoJsonSource(_waypointSource, _waypointGeoJson());
    await _c?.setGeoJsonSource(_cursorSource, _cursorGeoJson());
    await _frameRoute();
  }

  @override
  Future<void> setCursor(({double lat, double lng})? point) async {
    _cursor = point;
    final c = _c;
    if (!_styleReady || c == null) return;
    await c.setGeoJsonSource(_cursorSource, _cursorGeoJson());
    if (point == null) return;
    // follow the mark only when it leaves the screen, so the map does not swim while dragging
    final seen = await c.getVisibleRegion();
    final inside = point.lat >= seen.southwest.latitude && point.lat <= seen.northeast.latitude && point.lng >= seen.southwest.longitude && point.lng <= seen.northeast.longitude;
    if (!inside) await c.animateCamera(CameraUpdate.newLatLng(LatLng(point.lat, point.lng)));
  }

  Map<String, dynamic> _point(double lat, double lng, [Map<String, dynamic> properties = const {}]) => {
    'type': 'Feature',
    'properties': properties,
    'geometry': {
      'type': 'Point',
      'coordinates': [lng, lat],
    },
  };

  Map<String, dynamic> _waypointGeoJson() => {
    'type': 'FeatureCollection',
    'features': [for (final w in _waypoints) _point(w.lat, w.lng, {'name': w.name})],
  };

  Map<String, dynamic> _cursorGeoJson() => {
    'type': 'FeatureCollection',
    'features': [if (_cursor case final p?) _point(p.lat, p.lng)],
  };

  Future<void> _frameRoute() async {
    if (_route.length < 2) return;
    final lats = _route.map((p) => p.lat), lngs = _route.map((p) => p.lng);
    final bounds = LatLngBounds(
      southwest: LatLng(lats.reduce(math.min), lngs.reduce(math.min)),
      northeast: LatLng(lats.reduce(math.max), lngs.reduce(math.max)),
    );
    await _c?.animateCamera(CameraUpdate.newLatLngBounds(bounds, left: 56, top: 190, right: 100, bottom: 380));
  }

  Map<String, dynamic> _routeGeoJson() => {
    'type': 'FeatureCollection',
    'features': [
      if (_route.length >= 2)
        {
          'type': 'Feature',
          'properties': <String, dynamic>{},
          'geometry': {
            'type': 'LineString',
            'coordinates': [
              for (final p in _route) [p.lng, p.lat],
            ],
          },
        },
    ],
  };

  Map<String, dynamic> _peaksGeoJson() => {
    'type': 'FeatureCollection',
    'features': [
      for (final m in widget.mountains)
        {
          'type': 'Feature',
          'id': m.id,
          'properties': {'id': m.id},
          'geometry': {
            'type': 'Point',
            'coordinates': [m.longitude, m.latitude],
          },
        },
    ],
  };

  Map<String, dynamic> _meGeoJson() => {
    'type': 'FeatureCollection',
    'features': [
      if (_me != null)
        {
          'type': 'Feature',
          'properties': <String, dynamic>{},
          'geometry': {
            'type': 'Point',
            'coordinates': [_me!.lng, _me!.lat],
          },
        },
    ],
  };

  Future<void> _addOverlays() async {
    final c = _c;
    if (c == null) return;
    await c.addGeoJsonSource(_routeSource, _routeGeoJson());
    await c.addLineLayer(
      _routeSource,
      'summitmate-route-layer',
      const LineLayerProperties(lineColor: '#B9532F', lineWidth: 4, lineCap: 'round', lineJoin: 'round'),
    );
    await c.addGeoJsonSource(_peaksSource, _peaksGeoJson());
    await c.addCircleLayer(
      _peaksSource,
      'summitmate-peaks-layer',
      const CircleLayerProperties(
        circleRadius: 6,
        circleColor: '#2E6B45',
        circleStrokeColor: '#FFFFFF',
        circleStrokeWidth: 2,
      ),
    );
    await c.addGeoJsonSource(_waypointSource, _waypointGeoJson());
    await c.addCircleLayer(
      _waypointSource,
      'summitmate-waypoints-layer',
      const CircleLayerProperties(circleRadius: 5, circleColor: '#FFFFFF', circleStrokeColor: '#B9532F', circleStrokeWidth: 3),
    );
    await c.addSymbolLayer(
      _waypointSource,
      'summitmate-waypoints-label',
      const SymbolLayerProperties(
        textField: ['get', 'name'],
        textFont: ['Noto Sans Bold'],
        textSize: 12,
        textOffset: [0, 1.2],
        textAnchor: 'top',
        textColor: '#1D2A27',
        textHaloColor: '#FFFFFF',
        textHaloWidth: 1.5,
      ),
    );
    await c.addGeoJsonSource(_cursorSource, _cursorGeoJson());
    await c.addCircleLayer(
      _cursorSource,
      'summitmate-cursor-layer',
      const CircleLayerProperties(circleRadius: 8, circleColor: '#1D2A27', circleStrokeColor: '#FFFFFF', circleStrokeWidth: 3),
    );
    await c.addGeoJsonSource(_meSource, _meGeoJson());
    await c.addCircleLayer(
      _meSource,
      'summitmate-me-layer',
      const CircleLayerProperties(
        circleRadius: 8,
        circleColor: '#1E88E5',
        circleStrokeColor: '#FFFFFF',
        circleStrokeWidth: 3,
      ),
    );
    _styleReady = true;
    await _frameRoute();
  }

  @override
  void dispose() {
    _c?.removeListener(_onCamera);
    _north.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(RudyMapView old) {
    super.didUpdateWidget(old);
    if (old.styleString != widget.styleString) {
      // The style changed while the map is open (e.g. the elevation tiles finished downloading): load it, and the
      // overlays are added again once it is ready.
      _styleReady = false;
      _c?.setStyle(widget.styleString);
      return;
    }
    if (_styleReady && old.mountains.length != widget.mountains.length) {
      _c?.setGeoJsonSource(_peaksSource, _peaksGeoJson());
    }
  }

  void _onClick(math.Point<double> point, LatLng latLng) {
    final near = peaksNear(widget.mountains, latLng.latitude, latLng.longitude, zoom, radiusPx: 22);
    if (near.isNotEmpty) widget.onPeaks(near);
  }

  @override
  Widget build(BuildContext context) {
    return MapLibreMap(
      styleString: widget.styleString,
      initialCameraPosition: const CameraPosition(target: LatLng(23.7, 121.0), zoom: 7.5),
      minMaxZoomPreference: const MinMaxZoomPreference(5, 20),
      trackCameraPosition: true, // zoom and bearing are read from the controller
      onMapCreated: (c) {
        _c = c;
        c.addListener(_onCamera);
        widget.onCreated(this);
      },
      onStyleLoadedCallback: _addOverlays,
      onMapClick: _onClick,
      compassEnabled: false,
      // The map page shows the credit itself (a short line, then in the map settings): the library's own button
      // is moved out of sight.
      attributionButtonPosition: AttributionButtonPosition.topLeft,
      attributionButtonMargins: const math.Point(-100, -100),
    );
  }
}
