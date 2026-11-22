import 'package:summitmate/features/gpx/domain/gpx_models.dart';
import 'package:xml/xml.dart';

/// Parses GPX 1.0 / 1.1. Namespaces and extensions are ignored.
GpxDocument parseGpx(String xml) {
  final XmlDocument doc;
  try {
    doc = XmlDocument.parse(xml);
  } on XmlException catch (e) {
    throw GpxFormatException('Not valid XML: ${e.message}');
  }
  final root = doc.rootElement;
  if (root.name.local != 'gpx') {
    throw GpxFormatException('Unexpected root element <${root.name.local}>');
  }

  final metaName = _childText(_local(root, 'metadata'), 'name');
  final name = metaName.isNotEmpty ? metaName : _childText(root, 'name');

  final waypoints = <GpxWaypoint>[];
  for (final w in _locals(root, 'wpt')) {
    final pos = _position(w);
    if (pos == null) continue;
    final desc = _childText(w, 'desc');
    waypoints.add(
      GpxWaypoint(
        name: _childText(w, 'name'),
        lat: pos.$1,
        lng: pos.$2,
        ele: _ele(w),
        description: desc.isNotEmpty ? desc : _childText(w, 'cmt'),
      ),
    );
  }

  final tracks = <GpxTrack>[];
  for (final trk in _locals(root, 'trk')) {
    final points = <GpxPoint>[
      for (final seg in _locals(trk, 'trkseg'))
        for (final p in _locals(seg, 'trkpt')) ?_point(p),
    ];
    if (points.isNotEmpty) tracks.add(GpxTrack(name: _childText(trk, 'name'), points: points));
  }
  for (final rte in _locals(root, 'rte')) {
    final points = <GpxPoint>[for (final p in _locals(rte, 'rtept')) ?_point(p)];
    if (points.isNotEmpty) tracks.add(GpxTrack(name: _childText(rte, 'name'), points: points));
  }

  if (waypoints.isEmpty && tracks.isEmpty) {
    throw const GpxFormatException('No waypoints or track points found');
  }
  return GpxDocument(name: name, waypoints: waypoints, tracks: tracks);
}

/// Builds a GPX 1.1 document.
String buildGpx(GpxDocument doc, {String creator = 'SummitMate'}) {
  final b = XmlBuilder();
  b.processing('xml', 'version="1.0" encoding="UTF-8"');
  b.element(
    'gpx',
    attributes: {
      'version': '1.1',
      'creator': creator,
      'xmlns': 'http://www.topografix.com/GPX/1/1',
    },
    nest: () {
      if (doc.name.isNotEmpty) {
        b.element('metadata', nest: () => b.element('name', nest: doc.name));
      }
      for (final w in doc.waypoints) {
        b.element(
          'wpt',
          attributes: {'lat': _num(w.lat, 6), 'lon': _num(w.lng, 6)},
          nest: () {
            if (w.ele != null) b.element('ele', nest: _num(w.ele!, 2));
            b.element('name', nest: w.name);
            if (w.description.isNotEmpty) b.element('desc', nest: w.description);
          },
        );
      }
      for (final t in doc.tracks) {
        b.element(
          'trk',
          nest: () {
            b.element('name', nest: t.name);
            b.element(
              'trkseg',
              nest: () {
                for (final p in t.points) {
                  b.element(
                    'trkpt',
                    attributes: {'lat': _num(p.lat, 6), 'lon': _num(p.lng, 6)},
                    nest: () {
                      if (p.ele != null) b.element('ele', nest: _num(p.ele!, 2));
                      if (p.time != null) b.element('time', nest: _time(p.time!));
                    },
                  );
                }
              },
            );
          },
        );
      }
    },
  );
  return b.buildDocument().toXmlString(pretty: true, indent: '  ');
}

Iterable<XmlElement> _locals(XmlElement parent, String name) => parent.childElements.where((e) => e.name.local == name);

XmlElement? _local(XmlElement parent, String name) {
  for (final e in parent.childElements) {
    if (e.name.local == name) return e;
  }
  return null;
}

String _childText(XmlElement? parent, String name) {
  if (parent == null) return '';
  final e = _local(parent, name);
  return e == null ? '' : e.innerText.trim();
}

double? _ele(XmlElement e) {
  final v = double.tryParse(_childText(e, 'ele'));
  return v != null && v.isFinite ? v : null;
}

(double, double)? _position(XmlElement e) {
  final lat = double.tryParse(e.getAttribute('lat')?.trim() ?? '');
  final lng = double.tryParse(e.getAttribute('lon')?.trim() ?? '');
  if (lat == null || lng == null || !lat.isFinite || !lng.isFinite) return null;
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
  return (lat, lng);
}

GpxPoint? _point(XmlElement e) {
  final pos = _position(e);
  if (pos == null) return null;
  final t = _childText(e, 'time');
  return GpxPoint(lat: pos.$1, lng: pos.$2, ele: _ele(e), time: t.isEmpty ? null : DateTime.tryParse(t)?.toUtc());
}

/// Fixed decimals with trailing zeros removed.
String _num(double v, int decimals) {
  var s = v.toStringAsFixed(decimals);
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
  return s == '-0' ? '0' : s;
}

String _time(DateTime t) => t.toUtc().toIso8601String().replaceFirst('.000Z', 'Z');
