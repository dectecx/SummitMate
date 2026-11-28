import 'package:material_ui/material_ui.dart';

/// The hand-drawn line icons of the bottom bar. One colour, taken from the surrounding icon theme.
enum NavGlyph { home, events, map, explore, me }

class NavGlyphIcon extends StatelessWidget {
  const NavGlyphIcon(this.glyph, {super.key});
  final NavGlyph glyph;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    return CustomPaint(size: Size.square(theme.size ?? 24), painter: _GlyphPainter(glyph, theme.color ?? Colors.black));
  }
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter(this.glyph, this.color);
  final NavGlyph glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 28);
    final ink = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final p = Path();
    switch (glyph) {
      case NavGlyph.home: // a house with a pitched roof
        p
          ..moveTo(3, 13)
          ..lineTo(14, 4)
          ..lineTo(25, 13)
          ..moveTo(6, 11.5)
          ..lineTo(6.2, 23.5)
          ..lineTo(21.8, 23.5)
          ..lineTo(22, 11.5)
          ..moveTo(11.5, 23.3)
          ..lineTo(11.5, 17)
          ..lineTo(16.5, 17)
          ..lineTo(16.5, 23.3);
      case NavGlyph.events: // two people
        p
          ..addOval(const Rect.fromLTWH(5.5, 4.8, 8.4, 8.2))
          ..addOval(const Rect.fromLTWH(17, 7.4, 6.4, 6.6))
          ..moveTo(2.8, 23)
          ..cubicTo(3.5, 13.8, 16, 13.8, 16.8, 23)
          ..moveTo(18.5, 17.2)
          ..cubicTo(22.5, 15.6, 25.4, 18, 25.4, 22.4);
      case NavGlyph.map: // folded sheet
        p
          ..moveTo(3, 7)
          ..lineTo(10, 4.3)
          ..lineTo(18, 7.8)
          ..lineTo(25, 5)
          ..lineTo(24.8, 20.8)
          ..lineTo(18, 23.6)
          ..lineTo(10, 20)
          ..lineTo(3.2, 22.8)
          ..close()
          ..moveTo(10, 4.6)
          ..lineTo(10.1, 19.8)
          ..moveTo(18, 8)
          ..lineTo(17.9, 23.2);
      case NavGlyph.explore: // compass
        p
          ..addOval(const Rect.fromLTWH(3, 3.2, 22, 21.8))
          ..moveTo(19, 9)
          ..lineTo(15.4, 15.6)
          ..lineTo(9, 19.2)
          ..lineTo(12.6, 12.4)
          ..close();
      case NavGlyph.me:
        p
          ..addOval(const Rect.fromLTWH(9, 3.5, 10.2, 10))
          ..moveTo(5, 24)
          ..cubicTo(5.6, 13.4, 22.4, 13.4, 23, 24);
    }
    canvas.drawPath(p, ink);
  }

  @override
  bool shouldRepaint(_GlyphPainter old) => old.glyph != glyph || old.color != color;
}
