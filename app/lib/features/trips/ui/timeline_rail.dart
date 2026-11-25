import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// The piece of the hiking route beside one node: a wavy dashed trail with a hand-drawn dot.
/// Neighbouring pieces meet in the middle of the rail, so together they read as one line.
class TimelineRail extends StatelessWidget {
  const TimelineRail({super.key, required this.index, required this.first, required this.last, required this.arrived});
  final int index;
  final bool first;
  final bool last;
  final bool arrived;

  /// Distance from the top of the row to the centre of the dot.
  static const dotY = 28.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return CustomPaint(
      size: const Size(24, double.infinity),
      painter: _RailPainter(
        index: index,
        first: first,
        last: last,
        trail: dark ? const Color(0xFF8F8672) : const Color(0xFF9D7B62),
        ring: scheme.onSurface,
        fill: arrived ? const Color(0xFFF2C94C) : scheme.surfaceContainerLowest,
      ),
    );
  }
}

class _RailPainter extends CustomPainter {
  const _RailPainter({
    required this.index,
    required this.first,
    required this.last,
    required this.trail,
    required this.ring,
    required this.fill,
  });
  final int index;
  final bool first;
  final bool last;
  final Color trail, ring, fill;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    const dot = TimelineRail.dotY;
    final bend = index.isEven ? 6.0 : -6.0;
    final line = Paint()
      ..color = trail
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final path = Path();
    if (!first) {
      path
        ..moveTo(x, 0)
        ..quadraticBezierTo(x + bend * .6, dot / 2, x, dot);
    }
    if (!last) {
      path
        ..moveTo(x, dot)
        ..quadraticBezierTo(x - bend, (dot + size.height) / 2, x, size.height);
    }
    for (final metric in path.computeMetrics()) {
      for (var d = 2.0; d < metric.length; d += 11) {
        canvas.drawPath(metric.extractPath(d, math.min(d + 4, metric.length)), line);
      }
    }

    // a circle that is not quite round, drawn from a different start on every node
    final circle = Path();
    for (var i = 0; i <= 24; i++) {
      final a = index * 1.7 + i / 24 * 2 * math.pi;
      final r = 7 * (1 + .06 * math.sin(2 * a + index));
      final p = Offset(x + r * math.cos(a), dot + r * math.sin(a));
      i == 0 ? circle.moveTo(p.dx, p.dy) : circle.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(circle, Paint()..color = fill);
    canvas.drawPath(
      circle,
      Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RailPainter old) =>
      old.index != index ||
      old.first != first ||
      old.last != last ||
      old.trail != trail ||
      old.ring != ring ||
      old.fill != fill;
}
