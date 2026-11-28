import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../explore/domain/mountain_models.dart';
import '../domain/map_logic.dart';

/// What the map tab needs from a map implementation, so the controls work the same on both maps.
abstract interface class MapHandle {
  double get zoom;
  Future<void> zoomBy(double delta);
  Future<void> moveTo(double lat, double lng, {double? minZoom});
  Future<void> setMe(double? lat, double? lng);

  /// Draws a route over the map (empty removes it) and brings the whole of it into view.
  Future<void> setRoute(List<({double lat, double lng})> points);
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

  var _route = const <({double lat, double lng})>[];

  @override
  double get zoom => _c?.cameraPosition?.zoom ?? 7.5;

  @override
  Future<void> zoomBy(double delta) async {
    await _c?.animateCamera(CameraUpdate.zoomTo((zoom + delta).clamp(5, 20)));
  }

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
  Future<void> setRoute(List<({double lat, double lng})> points) async {
    _route = points;
    if (!_styleReady) return; // drawn when the style is ready
    await _c?.setGeoJsonSource(_routeSource, _routeGeoJson());
    await _frameRoute();
  }

  Future<void> _frameRoute() async {
    if (_route.length < 2) return;
    final lats = _route.map((p) => p.lat), lngs = _route.map((p) => p.lng);
    final bounds = LatLngBounds(
      southwest: LatLng(lats.reduce(math.min), lngs.reduce(math.min)),
      northeast: LatLng(lats.reduce(math.max), lngs.reduce(math.max)),
    );
    await _c?.animateCamera(CameraUpdate.newLatLngBounds(bounds, left: 48, top: 160, right: 80, bottom: 140));
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
      trackCameraPosition: true, // the zoom buttons read the current zoom from the controller
      onMapCreated: (c) {
        _c = c;
        widget.onCreated(this);
      },
      onStyleLoadedCallback: _addOverlays,
      onMapClick: _onClick,
      compassEnabled: false,
      attributionButtonPosition: AttributionButtonPosition.topLeft,
    );
  }
}
