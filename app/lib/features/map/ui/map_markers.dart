import 'package:material_ui/material_ui.dart';

// The map picture is light in both themes, so the markers keep one set of colours.
const _ink = Color(0xFF3D342D);
const _snow = Color(0xFFFBF9F3);
const _rock = Color(0xFFA9856C);
const _teal = Color(0xFF2B6863);
const _coral = Color(0xFFD9705A);

/// A mountain on the map: a dot while the whole island is in view, a small drawn summit when zoomed in.
/// Painted with a few shapes because a hundred of them can be on screen.
class PeakMarker extends StatelessWidget {
  const PeakMarker({super.key, required this.far});
  final bool far;

  @override
  Widget build(BuildContext context) => CustomPaint(size: const Size.square(32), painter: _PeakPainter(far));
}

class _PeakPainter extends CustomPainter {
  const _PeakPainter(this.far);
  final bool far;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (far) {
      final c = size.center(Offset.zero);
      canvas.drawCircle(c, 5.5, Paint()..color = _snow);
      canvas.drawCircle(c, 3.8, Paint()..color = _teal);
      return;
    }
    // drawn smaller than the tap target, so the names printed on the map stay readable around it
    canvas
      ..translate(16, 17)
      ..scale(.8)
      ..translate(-16, -17);
    final peak = Path()
      ..moveTo(3, 26)
      ..lineTo(14, 8)
      ..quadraticBezierTo(16, 5.5, 18, 8)
      ..lineTo(29, 26)
      ..close();
    // a pale halo keeps the drawing readable over contour lines
    canvas.drawPath(
      peak,
      Paint()
        ..color = _snow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(peak, Paint()..color = _rock);
    canvas.drawPath(
      Path()
        ..moveTo(10.2, 14.2)
        ..lineTo(14, 8)
        ..quadraticBezierTo(16, 5.5, 18, 8)
        ..lineTo(21.8, 14.2)
        ..lineTo(18.6, 13)
        ..lineTo(16, 16.4)
        ..lineTo(13.4, 13)
        ..close(),
      Paint()..color = _snow,
    );
    canvas.drawPath(peak, line);
  }

  @override
  bool shouldRepaint(_PeakPainter old) => old.far != far;
}

/// Where the person is.
class MeMarker extends StatelessWidget {
  const MeMarker({super.key});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: _coral,
      shape: BoxShape.circle,
      border: Border.all(color: _snow, width: 3),
      boxShadow: const [BoxShadow(color: Color(0x66D9705A), blurRadius: 8, spreadRadius: 3)],
    ),
  );
}
