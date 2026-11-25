import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'art_data.g.dart';
import 'art_model.dart';
import 'art_palette.dart';

export 'art_model.dart' show ArtIcon, ArtScene;

/// How many cover scenes there are to pick from.
int get coverCount => artCovers.length;

/// A full-bleed landscape: day in light mode, night in dark mode. Its bottom edge is the page's paper, so the
/// page content can start right under it. Painted once and cached by its own layer, so moving or fading it while
/// scrolling costs no repaint.
class CoverArt extends StatelessWidget {
  const CoverArt({super.key, required this.cover});

  /// Index of the scene, below [coverCount].
  final int cover;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final night = scheme.brightness == Brightness.dark;
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _CoverPainter(cover, night, ArtPalette.scene(scheme), scheme.surface),
        ),
      ),
    );
  }
}

/// A small hand-drawn picture for a card.
class ArtIconView extends StatelessWidget {
  const ArtIconView(this.icon, {super.key, this.size = 40});
  final ArtIcon icon;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: CustomPaint(
        size: Size.square(size),
        painter: _IconPainter(icon, ArtPalette.object(Theme.of(context).colorScheme), Theme.of(context).brightness),
      ),
    ),
  );
}

/// A card's picture: the same four subjects as the covers, small and whole, on a pale tint.
class VignetteArt extends StatelessWidget {
  const VignetteArt({super.key, required this.cover});

  /// Index of the scene, below [coverCount].
  final int cover;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final night = scheme.brightness == Brightness.dark;
    const light = [Color(0xFFE0EDEC), Color(0xFFE6EFE4), Color(0xFFF8EBD6), Color(0xFFF5E4DC)];
    const dark = [Color(0xFF223A40), Color(0xFF26382E), Color(0xFF3A3326), Color(0xFF3A2C2A)];
    final i = cover % artVignettes.length;
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _VignettePainter(i, (night ? dark : light)[i], ArtPalette.object(scheme), scheme.brightness),
        ),
      ),
    );
  }
}

class _VignettePainter extends CustomPainter {
  const _VignettePainter(this.index, this.tint, this.palette, this.brightness);
  final int index;
  final Color tint;
  final ArtPalette palette;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..color = tint);
    final scale = math.min(size.width / 250, size.height / 156);
    canvas.translate(size.width / 2, size.height);
    canvas.scale(scale);
    canvas.translate(-196, -156);
    _paintDrawing(canvas, brightness == Brightness.dark ? artVignetteNight : artVignetteDay, palette);
    _paintDrawing(canvas, artVignettes[index], palette);
  }

  @override
  bool shouldRepaint(_VignettePainter old) => old.index != index || old.brightness != brightness;
}

/// The landscape behind every screen: a washed sky at the top, hills along the bottom, and paper grain over the
/// whole sheet. A screen wider than tall keeps the paper only.
class PageBackdrop extends StatelessWidget {
  const PageBackdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final night = scheme.brightness == Brightness.dark;
    return ColoredBox(
      color: scheme.surface,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            child: ExcludeSemantics(
              child: RepaintBoundary(
                child: CustomPaint(painter: _PagePainter(night, ArtPalette.scene(scheme), scheme.surface)),
              ),
            ),
          ),
          Positioned.fill(
            child: ExcludeSemantics(
              child: Image.asset(
                'assets/art/grain.png',
                repeat: ImageRepeat.repeat,
                scale: 2,
                color: scheme.onSurface.withValues(alpha: night ? .06 : .16),
                colorBlendMode: BlendMode.srcIn,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _PagePainter extends CustomPainter {
  const _PagePainter(this.night, this.palette, this.paper);
  final bool night;
  final ArtPalette palette;
  final Color paper;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width >= size.height) return;
    final scale = size.width / 390;
    canvas.clipRect(Offset.zero & size);
    canvas.save();
    canvas.scale(scale);
    _paintDrawing(canvas, artPageSky, palette);
    _paintDrawing(canvas, night ? artPageSkyNight : artPageSkyDay, palette);
    canvas.restore();
    canvas.translate(0, size.height - 130 * scale);
    canvas.scale(scale);
    _paintDrawing(canvas, artPageHills, palette);
  }

  @override
  bool shouldRepaint(_PagePainter old) => old.night != night || old.paper != paper;
}

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

class _CoverPainter extends CustomPainter {
  const _CoverPainter(this.cover, this.night, this.palette, this.paper);
  final int cover;
  final bool night;
  final ArtPalette palette;
  final Color paper;

  static const _art = Size(390, 380);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.max(size.width / _art.width, size.height / _art.height);
    // When the box is wider than the art, keep the summits (about 200 down) in view and never leave a gap below.
    final spare = size.height - _art.height * scale;
    final dy = (size.height * .45 - 200 * scale).clamp(math.min(spare, 0.0), 0.0).toDouble();
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate((size.width - _art.width * scale) / 2, dy);
    canvas.scale(scale);
    for (final drawing in [
      artSky,
      night ? artNightSky : artDaySky,
      artCovers[cover % artCovers.length],
      artPaperEdge,
    ]) {
      _paintDrawing(canvas, drawing, palette);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CoverPainter old) => old.cover != cover || old.night != night || old.paper != paper;
}

class _IconPainter extends CustomPainter {
  const _IconPainter(this.icon, this.palette, this.brightness);
  final ArtIcon icon;
  final ArtPalette palette;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 80);
    canvas.translate(40, 40);
    _paintDrawing(canvas, artIcons[icon]!, palette);
  }

  @override
  bool shouldRepaint(_IconPainter old) => old.icon != icon || old.brightness != brightness;
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
