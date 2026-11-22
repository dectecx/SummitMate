import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:summitmate/features/gpx/domain/elevation_profile.dart';

/// Line + filled area chart: distance (km) on x, elevation (m) on y.
class ElevationProfileChart extends StatelessWidget {
  const ElevationProfileChart({super.key, required this.profile, this.height = 160});

  final List<ProfilePoint> profile;
  final double height;

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
    return Semantics(
      label: '海拔剖面圖',
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _ProfilePainter(
            profile: profile,
            line: scheme.primary,
            fill: scheme.primaryContainer.withValues(alpha: 0.6),
            grid: scheme.outlineVariant,
            textStyle: textStyle,
          ),
        ),
      ),
    );
  }
}

class _ProfilePainter extends CustomPainter {
  _ProfilePainter({
    required this.profile,
    required this.line,
    required this.fill,
    required this.grid,
    required this.textStyle,
  });

  final List<ProfilePoint> profile;
  final Color line;
  final Color fill;
  final Color grid;
  final TextStyle textStyle;

  TextPainter _text(String s) =>
      TextPainter(text: TextSpan(text: s, style: textStyle), textDirection: TextDirection.ltr)..layout();

  @override
  void paint(Canvas canvas, Size size) {
    var minE = profile.map((p) => p.ele).reduce(math.min);
    var maxE = profile.map((p) => p.ele).reduce(math.max);
    if (maxE - minE < 10) {
      final mid = (maxE + minE) / 2;
      minE = mid - 5;
      maxE = mid + 5;
    }
    final maxD = profile.last.distanceKm;
    final span = maxD <= 0 ? 1.0 : maxD;

    const gridCount = 4;
    final yLabels = [
      for (var i = 0; i < gridCount; i++) _text('${(minE + (maxE - minE) * i / (gridCount - 1)).round()} m'),
    ];
    final xLabel = _text('${maxD.toStringAsFixed(1)} km');
    final left = yLabels.map((t) => t.width).reduce(math.max) + 6;
    final bottom = xLabel.height + 4;
    final plot = Rect.fromLTRB(left, 4, size.width - xLabel.width / 2 - 2, size.height - bottom);
    if (plot.width <= 0 || plot.height <= 0) return;

    double x(ProfilePoint p) => plot.left + p.distanceKm / span * plot.width;
    double y(double e) => plot.bottom - (e - minE) / (maxE - minE) * plot.height;

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i < gridCount; i++) {
      final gy = plot.bottom - plot.height * i / (gridCount - 1);
      canvas.drawLine(Offset(plot.left, gy), Offset(plot.right, gy), gridPaint);
      final t = yLabels[i];
      t.paint(canvas, Offset(left - 6 - t.width, gy - t.height / 2));
    }
    _text('0').paint(canvas, Offset(plot.left, size.height - xLabel.height));
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
  }

  @override
  bool shouldRepaint(_ProfilePainter old) =>
      old.profile != profile || old.line != line || old.fill != fill || old.grid != grid || old.textStyle != textStyle;
}
