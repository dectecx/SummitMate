import 'package:material_ui/material_ui.dart';

/// The selected tab's mark: a short hand-drawn stroke.
class BrushTabIndicator extends Decoration {
  const BrushTabIndicator(this.color);
  final Color color;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _BrushPainter(color);
}

class _BrushPainter extends BoxPainter {
  _BrushPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size!;
    final x = offset.dx + size.width / 2;
    final y = offset.dy + size.height - 6;
    canvas.drawPath(
      Path()
        ..moveTo(x - 17, y + 1)
        ..quadraticBezierTo(x - 2, y - 3.5, x + 18, y - .5),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round,
    );
  }
}
