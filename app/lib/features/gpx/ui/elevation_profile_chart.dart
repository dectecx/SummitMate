import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:summitmate/features/gpx/domain/elevation_profile.dart';

/// Line + filled area chart: distance (km) on x, elevation (m) on y. With [onScrub] it can be dragged along, and
/// [cursorKm] marks a place on it.
class ElevationProfileChart extends StatelessWidget {
  const ElevationProfileChart({super.key, required this.profile, this.height = 160, this.cursorKm, this.onScrub});

  final List<ProfilePoint> profile;
  final double height;
  final double? cursorKm;

  /// Called with the distance under the finger while the chart is touched.
  final ValueChanged<double>? onScrub;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textStyle = (Theme.of(context).textTheme.labelSmall ?? const TextStyle(fontSize: 11)).copyWith(
      color: scheme.onSurfaceVariant,
    );
    if (profile.length < 2) {
      return SizedBox(
        height: height,
        child: Center(child: Text('沒有海拔資料', style: textStyle)),
      );
    }
    final chart = SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _ProfilePainter(
          profile: profile,
          line: scheme.primary,
          fill: scheme.primaryContainer.withValues(alpha: 0.6),
          grid: scheme.outlineVariant,
          textStyle: textStyle,
          cursorKm: cursorKm,
          cursor: scheme.onSurface,
        ),
      ),
    );
    final scrub = onScrub;
    if (scrub == null) return Semantics(label: '海拔剖面圖', child: chart);
    return Semantics(
      label: '海拔剖面圖，左右拖曳查看路線上的位置',
      child: LayoutBuilder(
        builder: (context, box) {
          void at(Offset local) {
            final plot = _plot(Size(box.maxWidth, height), profile, textStyle);
            if (plot.width <= 0) return;
            scrub(((local.dx - plot.left) / plot.width).clamp(0.0, 1.0) * profile.last.distanceKm);
          }

          return GestureDetector(
            key: const ValueKey('elevation-scrub'),
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => at(d.localPosition),
            onHorizontalDragStart: (d) => at(d.localPosition),
            onHorizontalDragUpdate: (d) => at(d.localPosition),
            child: chart,
          );
        },
      ),
    );
  }
}

TextPainter _label(String s, TextStyle style) => TextPainter(text: TextSpan(text: s, style: style), textDirection: TextDirection.ltr)..layout();

/// The elevation range shown: at least 10 m, so a flat route is not drawn as mountains.
(double, double) _range(List<ProfilePoint> profile) {
  var minE = profile.map((p) => p.ele).reduce(math.min);
  var maxE = profile.map((p) => p.ele).reduce(math.max);
  if (maxE - minE < 10) {
    final mid = (maxE + minE) / 2;
    minE = mid - 5;
    maxE = mid + 5;
  }
  return (minE, maxE);
}

const _gridCount = 4;

List<TextPainter> _yLabels(List<ProfilePoint> profile, TextStyle style) {
  final (minE, maxE) = _range(profile);
  return [for (var i = 0; i < _gridCount; i++) _label('${(minE + (maxE - minE) * i / (_gridCount - 1)).round()} m', style)];
}

/// Where the line is drawn inside a chart of [size]; the labels take the rest.
Rect _plot(Size size, List<ProfilePoint> profile, TextStyle style) {
  final x = _label('${profile.last.distanceKm.toStringAsFixed(1)} km', style);
  final left = _yLabels(profile, style).map((t) => t.width).reduce(math.max) + 6;
  return Rect.fromLTRB(left, 4, size.width - x.width / 2 - 2, size.height - x.height - 4);
}

class _ProfilePainter extends CustomPainter {
  _ProfilePainter({
    required this.profile,
    required this.line,
    required this.fill,
    required this.grid,
    required this.textStyle,
    required this.cursorKm,
    required this.cursor,
  });

  final List<ProfilePoint> profile;
  final Color line;
  final Color fill;
  final Color grid;
  final TextStyle textStyle;
  final double? cursorKm;
  final Color cursor;

  @override
  void paint(Canvas canvas, Size size) {
    final (minE, maxE) = _range(profile);
    final maxD = profile.last.distanceKm;
    final span = maxD <= 0 ? 1.0 : maxD;
    final yLabels = _yLabels(profile, textStyle);
    final xLabel = _label('${maxD.toStringAsFixed(1)} km', textStyle);
    final plot = _plot(size, profile, textStyle);
    if (plot.width <= 0 || plot.height <= 0) return;
    final left = plot.left;

    double x(ProfilePoint p) => plot.left + p.distanceKm / span * plot.width;
    double y(double e) => plot.bottom - (e - minE) / (maxE - minE) * plot.height;

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i < _gridCount; i++) {
      final gy = plot.bottom - plot.height * i / (_gridCount - 1);
      canvas.drawLine(Offset(plot.left, gy), Offset(plot.right, gy), gridPaint);
      final t = yLabels[i];
      t.paint(canvas, Offset(left - 6 - t.width, gy - t.height / 2));
    }
    _label('0', textStyle).paint(canvas, Offset(plot.left, size.height - xLabel.height));
    xLabel.paint(canvas, Offset(plot.right - xLabel.width / 2, size.height - xLabel.height));

    final path = Path()..moveTo(x(profile.first), y(profile.first.ele));
    for (final p in profile.skip(1)) {
      path.lineTo(x(p), y(p.ele));
    }
    final area = Path.from(path)
      ..lineTo(x(profile.last), plot.bottom)
      ..lineTo(x(profile.first), plot.bottom)
      ..close();
    canvas.drawPath(area, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );

    if (cursorKm case final km?) {
      final next = profile.firstWhere((p) => p.distanceKm >= km, orElse: () => profile.last);
      final cx = plot.left + (km / span).clamp(0.0, 1.0) * plot.width;
      canvas
        ..drawLine(Offset(cx, plot.top), Offset(cx, plot.bottom), Paint()..color = cursor)
        ..drawCircle(Offset(cx, y(next.ele)), 5, Paint()..color = cursor);
    }
  }

  @override
  bool shouldRepaint(_ProfilePainter old) =>
      old.profile != profile || old.line != line || old.fill != fill || old.grid != grid || old.textStyle != textStyle || old.cursorKm != cursorKm;
}
