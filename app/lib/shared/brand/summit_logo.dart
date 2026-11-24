import 'package:material_ui/material_ui.dart';

/// The SummitMate mark: mountains, a lake and a stack of stones (a cairn, the trail marker).
/// [progress] 0..1 plays it in: the mountains rise, the lake appears, then the stones stack up one by one.
class SummitLogoPainter extends CustomPainter {
  const SummitLogoPainter({this.progress = 1});
  final double progress;

  static double _span(double t, double from, double to) => ((t - from) / (to - from)).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    const s = 1024.0;
    canvas.save();
    canvas.scale(size.width / s, size.height / s);
    canvas.clipRect(const Rect.fromLTWH(0, 0, s, s));
    Paint fill(int color) => Paint()..color = Color(color);
    Path poly(List<List<double>> p) {
      final path = Path()..moveTo(p[0][0], p[0][1]);
      for (final q in p.skip(1)) {
        path.lineTo(q[0], q[1]);
      }
      return path..close();
    }

    canvas.drawRect(
      const Rect.fromLTWH(0, 0, s, s),
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment(0, 0.4), colors: [Color(0xFFB2F2DF), Color(0xFF38C6D6)]).createShader(const Rect.fromLTWH(0, 0, s, s)),
    );

    // Mountains rise from below the horizon.
    final rise = Curves.easeOutCubic.transform(_span(progress, 0.0, 0.45));
    canvas.save();
    canvas.translate(0, (1 - rise) * 260);
    canvas.drawPath(poly([[-40, 520], [150, 380], [330, 520], [330, 700], [-40, 700]]), fill(0xFF2EC6D2));
    canvas.drawPath(poly([[330, 560], [630, 160], [960, 470], [960, 700], [330, 700]]), fill(0xFF2AB0C8));
    canvas.drawPath(poly([[630, 160], [960, 470], [960, 700], [700, 700], [640, 470], [590, 330]]), fill(0xFF1493B5));
    canvas.drawPath(poly([[630, 160], [590, 330], [640, 470], [720, 560], [740, 430]]), fill(0xFF3FC3D6));
    canvas.drawPath(poly([[760, 400], [830, 270], [1080, 520], [1080, 700], [760, 700]]), fill(0xFF0A9CBF));
    canvas.restore();

    canvas.drawPath(
      Path()
        ..moveTo(-40, 640)
        ..quadraticBezierTo(420, 560, s + 40, 600)
        ..lineTo(s + 40, 800)
        ..lineTo(-40, 800)
        ..close(),
      fill(0xFF0C8FAF),
    );
    final lake = Curves.easeOut.transform(_span(progress, 0.3, 0.6));
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(710, 675), width: 380 * lake, height: 70 * lake),
      fill(0xFF5BDCE0),
    );
    canvas.drawPath(
      Path()
        ..moveTo(-40, 680)
        ..quadraticBezierTo(300, 760, 560, 800)
        ..quadraticBezierTo(800, 700, s + 40, 690)
        ..lineTo(s + 40, s + 40)
        ..lineTo(-40, s + 40)
        ..close(),
      fill(0xFF04436A),
    );

    // The cairn: the bottom stone first.
    const stones = [
      (330.0, 780.0, 330.0, 110.0, 0xFF0B5C84),
      (330.0, 690.0, 280.0, 110.0, 0xFF0A4F78),
      (335.0, 600.0, 240.0, 100.0, 0xFF08486F),
      (340.0, 515.0, 200.0, 90.0, 0xFF0A557C),
      (345.0, 440.0, 150.0, 80.0, 0xFF0B5C84),
      (350.0, 375.0, 100.0, 70.0, 0xFF0A4F78),
    ];
    for (var i = 0; i < stones.length; i++) {
      final (cx, cy, w, h, color) = stones[i];
      final from = 0.5 + i * 0.075;
      final t = _span(progress, from, from + 0.18);
      if (t == 0) continue;
      final pop = Curves.easeOutBack.transform(t);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy - (1 - t) * 60), width: w * pop, height: h * pop),
        Paint()..color = Color(color).withValues(alpha: t),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(SummitLogoPainter old) => old.progress != progress;
}

/// The mark as a widget, at rest or playing in.
class SummitLogo extends StatelessWidget {
  const SummitLogo({super.key, this.size = 120, this.progress = 1, this.rounded = true});
  final double size;
  final double progress;

  /// Clip to an app-icon shaped rounded square.
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    final paint = CustomPaint(size: Size.square(size), painter: SummitLogoPainter(progress: progress));
    return rounded ? ClipRRect(borderRadius: BorderRadius.circular(size * 0.225), child: paint) : paint;
  }
}
