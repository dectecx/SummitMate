import 'package:material_ui/material_ui.dart';

import 'art_data.g.dart';
import 'art_model.dart';
import 'art_palette.dart';

export 'art_model.dart' show ArtScene;

/// The app's mark on its 400 x 400 artwork. [progress] 0..1 plays it in: the sky appears, the sun and the summit
/// rise, the ground slides in, then the stones stack up one by one.
class MarkPainter extends CustomPainter {
  const MarkPainter({this.progress = 1});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    canvas.scale(size.width / 400, size.height / 400);
    // sky, sun, peak, ground, four stones: when each starts and how far it travels (negative: drops from above)
    const moves = [(0.0, 0.0), (0.05, 80.0), (0.1, 150.0), (0.2, 90.0), (0.42, -70.0), (0.53, -70.0), (0.64, -70.0), (0.75, -70.0)];
    for (var i = 0; i < artMark.length; i++) {
      final (from, travel) = moves[i];
      final t = ((progress - from) / (i < 4 ? .35 : .2)).clamp(0.0, 1.0);
      if (t == 0) continue;
      final eased = (i < 4 ? Curves.easeOutCubic : Curves.easeOutBack).transform(t);
      canvas.save();
      canvas.translate(0, travel * (1 - eased));
      if (t < 1) canvas.saveLayer(null, Paint()..color = Colors.black.withValues(alpha: t));
      _paintDrawing(canvas, artMark[i], ArtPalette.mark);
      if (t < 1) canvas.restore();
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(MarkPainter old) => old.progress != progress;
}

/// The picture of an empty screen, 4:3.
class ArtSceneView extends StatelessWidget {
  const ArtSceneView(this.scene, {super.key, this.width = 168});
  final ArtScene scene;
  final double width;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: CustomPaint(
        size: Size(width, width * .75),
        painter: _ScenePainter(scene, ArtPalette.object(Theme.of(context).colorScheme), Theme.of(context).brightness),
      ),
    ),
  );
}

class _ScenePainter extends CustomPainter {
  const _ScenePainter(this.scene, this.palette, this.brightness);
  final ArtScene scene;
  final ArtPalette palette;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 160);
    canvas.translate(80, 60);
    _paintDrawing(canvas, artScenes[scene]!, palette);
  }

  @override
  bool shouldRepaint(_ScenePainter old) => old.scene != scene || old.brightness != brightness;
}

Path _path(List<double> p, {required bool close}) {
  final path = Path()..moveTo(p[0], p[1]);
  for (var i = 2; i < p.length; i += 2) {
    path.lineTo(p[i], p[i + 1]);
  }
  if (close) path.close();
  return path;
}

void _paintDrawing(Canvas canvas, ArtDrawing drawing, ArtPalette palette) {
  final clips = [for (final c in drawing.clips) _path(c, close: true)];
  var clip = -1;
  for (final op in drawing.ops) {
    if (op.clip != clip) {
      if (clip >= 0) canvas.restore();
      clip = op.clip;
      if (clip >= 0) {
        canvas.save();
        canvas.clipPath(clips[clip]);
      }
    }
    final base = palette[op.color];
    final color = base.withValues(alpha: base.a * op.alpha * (op.color == ArtColor.edge ? .1 : 1));
    final bloom = op.bloom;
    if (bloom != null) {
      final [x, y, rx, ry, angle] = bloom;
      final unit = Rect.fromCircle(center: Offset.zero, radius: 1);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      canvas.scale(rx, ry);
      canvas.drawCircle(
        Offset.zero,
        1,
        Paint()
          ..shader = RadialGradient(
            colors: [color, color, color.withValues(alpha: 0)],
            stops: const [0, .35, 1],
          ).createShader(unit),
      );
      canvas.restore();
    } else if (op.stroke > 0) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = op.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      for (final ring in op.rings) {
        canvas.drawPath(_path(ring, close: false), paint);
      }
    } else {
      final path = Path();
      for (final ring in op.rings) {
        path.addPath(_path(ring, close: true), Offset.zero);
      }
      canvas.drawPath(path, Paint()..color = color);
    }
  }
  if (clip >= 0) canvas.restore();
}
