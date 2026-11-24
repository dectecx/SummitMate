import 'package:material_ui/material_ui.dart';

/// The small flat pictures used on empty screens and in the help. They share the logo's shapes and the app palette
/// (pine, moss, clay, paper) so empty screens feel like part of the same place.
enum Illustration { trip, gear, meal, chat, map, friends, shop, search, help, star }

class IllustrationView extends StatelessWidget {
  const IllustrationView(this.kind, {super.key, this.width = 168});
  final Illustration kind;
  final double width;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      height: width * 0.75,
      child: CustomPaint(painter: _Painter(kind, _Palette.of(scheme))),
    );
  }
}

class _Palette {
  const _Palette({required this.backdrop, required this.pine, required this.pineDark, required this.moss, required this.clay, required this.paper, required this.ink});
  final Color backdrop, pine, pineDark, moss, clay, paper, ink;

  static _Palette of(ColorScheme s) => s.brightness == Brightness.light
      ? const _Palette(backdrop: Color(0xFFE8EFE6), pine: Color(0xFF3F8C97), pineDark: Color(0xFF1F6F7A), moss: Color(0xFF8DAE86), clay: Color(0xFFC98B4F), paper: Color(0xFFFFFCF6), ink: Color(0xFF2B3A3D))
      : const _Palette(backdrop: Color(0xFF1E2C2E), pine: Color(0xFF4F9AA5), pineDark: Color(0xFF8CCBD2), moss: Color(0xFF6E8F68), clay: Color(0xFFE0A76B), paper: Color(0xFF2A393C), ink: Color(0xFFD6E3E4));
}

class _Painter extends CustomPainter {
  const _Painter(this.kind, this.c);
  final Illustration kind;
  final _Palette c;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 160, size.height / 120);
    Paint f(Color color) => Paint()..color = color;
    Paint stroke(Color color, double w) => Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = w..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    RRect rr(double x, double y, double w, double h, double r) => RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r));
    Path poly(List<double> p) {
      final path = Path()..moveTo(p[0], p[1]);
      for (var i = 2; i < p.length; i += 2) {
        path.lineTo(p[i], p[i + 1]);
      }
      return path..close();
    }

    canvas.drawOval(const Rect.fromLTWH(14, 18, 132, 92), f(c.backdrop));
    canvas.drawOval(const Rect.fromLTWH(30, 98, 100, 10), f(c.ink.withValues(alpha: 0.08)));
    switch (kind) {
      case Illustration.trip: // tent under mountains
        canvas.drawPath(poly([22, 92, 62, 40, 100, 92]), f(c.pine));
        canvas.drawPath(poly([62, 40, 78, 62, 70, 66, 62, 56, 54, 70, 46, 64]), f(c.paper));
        canvas.drawPath(poly([80, 92, 112, 52, 142, 92]), f(c.moss));
        canvas.drawPath(poly([86, 96, 108, 70, 130, 96]), f(c.clay));
        canvas.drawPath(poly([108, 70, 108, 96, 99, 96]), f(c.clay.withValues(alpha: 0.7)));
        canvas.drawPath(poly([108, 74, 118, 96, 98, 96]), f(c.paper.withValues(alpha: 0.35)));
      case Illustration.gear: // backpack
        canvas.drawRRect(rr(52, 36, 56, 62, 14), f(c.pineDark));
        canvas.drawRRect(rr(60, 24, 40, 20, 10), f(c.pine));
        canvas.drawRRect(rr(60, 64, 40, 28, 8), f(c.pine));
        canvas.drawRRect(rr(66, 70, 28, 4, 2), f(c.paper));
        canvas.drawRRect(rr(46, 52, 8, 30, 4), f(c.clay));
        canvas.drawRRect(rr(106, 52, 8, 30, 4), f(c.clay));
        canvas.drawCircle(const Offset(80, 50), 5, f(c.paper));
      case Illustration.meal: // cooking pot with steam
        canvas.drawRRect(rr(48, 58, 64, 36, 10), f(c.pineDark));
        canvas.drawRRect(rr(44, 54, 72, 8, 4), f(c.pine));
        canvas.drawRRect(rr(34, 66, 12, 6, 3), f(c.clay));
        canvas.drawRRect(rr(114, 66, 12, 6, 3), f(c.clay));
        for (final x in [64.0, 80.0, 96.0]) {
          canvas.drawPath(Path()..moveTo(x, 46)..cubicTo(x - 8, 38, x + 8, 32, x, 22), stroke(c.ink.withValues(alpha: 0.35), 3));
        }
      case Illustration.chat: // two speech bubbles
        canvas.drawRRect(rr(34, 34, 66, 38, 14), f(c.pine));
        canvas.drawPath(poly([46, 70, 46, 84, 62, 70]), f(c.pine));
        canvas.drawRRect(rr(64, 52, 62, 36, 14), f(c.paper));
        canvas.drawPath(poly([112, 86, 116, 98, 100, 86]), f(c.paper));
        for (final x in [48.0, 64.0, 80.0]) {
          canvas.drawCircle(Offset(x, 53), 3.5, f(c.paper));
        }
        for (final x in [82.0, 96.0, 110.0]) {
          canvas.drawCircle(Offset(x, 70), 3, f(c.clay));
        }
      case Illustration.map: // folded map with a pin
        canvas.drawPath(poly([32, 44, 64, 36, 96, 46, 128, 38, 128, 90, 96, 98, 64, 88, 32, 96]), f(c.paper));
        canvas.drawPath(poly([64, 36, 96, 46, 96, 98, 64, 88]), f(c.moss.withValues(alpha: 0.5)));
        canvas.drawPath(Path()..moveTo(40, 80)..quadraticBezierTo(60, 60, 80, 74)..quadraticBezierTo(100, 86, 118, 58), stroke(c.pineDark, 2.4)..strokeCap = StrokeCap.butt);
        canvas.drawCircle(const Offset(104, 44), 11, f(c.clay));
        canvas.drawPath(poly([97, 51, 111, 51, 104, 64]), f(c.clay));
        canvas.drawCircle(const Offset(104, 44), 4.4, f(c.paper));
      case Illustration.friends: // two people
        for (final (x, col) in [(60.0, c.pineDark), (100.0, c.clay)]) {
          canvas.drawCircle(Offset(x, 48), 13, f(col));
          canvas.drawPath(Path()..moveTo(x - 24, 98)..quadraticBezierTo(x - 24, 66, x, 66)..quadraticBezierTo(x + 24, 66, x + 24, 98)..close(), f(col));
        }
        canvas.drawCircle(const Offset(80, 78), 9, f(c.paper));
        canvas.drawPath(Path()..moveTo(75, 78)..lineTo(79, 82)..lineTo(86, 74), stroke(c.pineDark, 2.4));
      case Illustration.shop: // storefront
        canvas.drawRRect(rr(38, 52, 84, 46, 6), f(c.paper));
        canvas.drawPath(poly([34, 52, 42, 32, 118, 32, 126, 52]), f(c.pineDark));
        for (var i = 0; i < 4; i++) {
          canvas.drawPath(poly([34 + i * 23.0, 52, 42 + i * 19.0, 32, 61 + i * 19.0, 32, 57 + i * 23.0, 52]), f(i.isEven ? c.pineDark : c.pine));
        }
        canvas.drawRRect(rr(70, 66, 20, 32, 4), f(c.clay));
        canvas.drawRRect(rr(46, 62, 16, 16, 3), f(c.moss.withValues(alpha: 0.6)));
        canvas.drawRRect(rr(98, 62, 16, 16, 3), f(c.moss.withValues(alpha: 0.6)));
      case Illustration.search: // magnifier over mountains
        canvas.drawPath(poly([28, 94, 58, 56, 82, 94]), f(c.moss));
        canvas.drawPath(poly([66, 94, 94, 62, 128, 94]), f(c.pine));
        canvas.drawCircle(const Offset(80, 54), 22, f(c.paper.withValues(alpha: 0.9)));
        canvas.drawCircle(const Offset(80, 54), 22, stroke(c.pineDark, 5));
        canvas.drawPath(Path()..moveTo(96, 70)..lineTo(112, 88), stroke(c.clay, 7));
      case Illustration.help: // signpost
        canvas.drawRRect(rr(76, 28, 8, 70, 3), f(c.ink.withValues(alpha: 0.7)));
        canvas.drawPath(poly([44, 38, 104, 38, 114, 48, 104, 58, 44, 58]), f(c.pineDark));
        canvas.drawPath(poly([116, 64, 56, 64, 46, 74, 56, 84, 116, 84]), f(c.clay));
        canvas.drawRRect(rr(54, 46, 36, 4, 2), f(c.paper));
        canvas.drawRRect(rr(70, 72, 36, 4, 2), f(c.paper));
      case Illustration.star: // bookmark with a star
        canvas.drawPath(poly([52, 28, 108, 28, 108, 98, 80, 80, 52, 98]), f(c.pineDark));
        canvas.drawPath(
          Path()
            ..moveTo(80, 40)
            ..lineTo(85, 54)
            ..lineTo(100, 54)
            ..lineTo(88, 63)
            ..lineTo(93, 77)
            ..lineTo(80, 68)
            ..lineTo(67, 77)
            ..lineTo(72, 63)
            ..lineTo(60, 54)
            ..lineTo(75, 54)
            ..close(),
          f(c.clay),
        );
    }
  }

  @override
  bool shouldRepaint(_Painter old) => old.kind != kind || old.c.pine != c.pine;
}
