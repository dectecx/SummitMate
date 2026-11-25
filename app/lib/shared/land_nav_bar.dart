import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'nav_glyph.dart';

/// One destination of the bottom bar.
typedef LandDestination = ({NavGlyph glyph, String label, int badge});

/// The bottom bar drawn as the ground of the landscape: a hill's edge on top, and the current place marked by a
/// coral stone that slides along it.
class LandNavBar extends StatelessWidget {
  const LandNavBar({super.key, required this.destinations, required this.selected, required this.onSelected, this.animate = true});
  final List<LandDestination> destinations;
  final int selected;
  final ValueChanged<int> onSelected;
  final bool animate;

  static const _stone = 46.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final night = scheme.brightness == Brightness.dark;
    final ground = night ? const Color(0xFF17302A) : const Color(0xFF47735A);
    final ink = night ? const Color(0xFF0B1413) : const Color(0xFF3D342D);
    const text = Color(0xFFF4F6EC);
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);
    final height = 51 + scaler.scale(12) * 1.4; // 68 at normal text size

    return CustomPaint(
      // above the ground's edge the bar shows the same meadow the page ends with, so there is no seam
      painter: _GroundPainter(sky: night ? const Color(0xFF22392F) : const Color(0xFF9DB592), ground: ground, ink: ink),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: height,
          child: LayoutBuilder(
            builder: (context, box) {
              final slot = box.maxWidth / destinations.length;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedPositioned(
                    duration: Duration(milliseconds: animate ? 260 : 0),
                    curve: Curves.easeOutBack,
                    left: slot * selected + (slot - _stone) / 2,
                    top: 2,
                    width: _stone,
                    height: _stone,
                    child: CustomPaint(painter: _StonePainter(fill: night ? const Color(0xFFB4604F) : scheme.tertiary, ink: ink)),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < destinations.length; i++)
                        Expanded(
                          child: Semantics(
                            button: true,
                            selected: i == selected,
                            child: InkResponse(
                              onTap: () => onSelected(i),
                              radius: slot / 2,
                              child: Column(
                                children: [
                                  SizedBox(height: i == selected ? 11 : 18),
                                  Badge.count(
                                    count: destinations[i].badge,
                                    isLabelVisible: destinations[i].badge > 0,
                                    child: IconTheme(
                                      data: IconThemeData(color: text, size: i == selected ? 27 : 24),
                                      child: NavGlyphIcon(destinations[i].glyph),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    destinations[i].label,
                                    textScaler: scaler,
                                    maxLines: 1,
                                    style: TextStyle(fontSize: 12, height: 1.3, color: text, fontWeight: i == selected ? FontWeight.w700 : FontWeight.w500),
                                  ),
                                  const SizedBox(height: 2),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GroundPainter extends CustomPainter {
  const _GroundPainter({required this.sky, required this.ground, required this.ink});
  final Color sky, ground, ink;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width / 390;
    final edge = Path()
      ..moveTo(0, 22)
      ..cubicTo(50 * w, 4, 96 * w, 28, 150 * w, 16)
      ..cubicTo(210 * w, 3, 262 * w, 28, 318 * w, 13)
      ..cubicTo(346 * w, 6, 372 * w, 11, size.width, 16);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 30), Paint()..color = sky);
    canvas.drawPath(
      Path.from(edge)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      Paint()..color = ground,
    );
    canvas.drawPath(
      edge,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_GroundPainter old) => old.sky != sky || old.ground != ground || old.ink != ink;
}

class _StonePainter extends CustomPainter {
  const _StonePainter({required this.fill, required this.ink});
  final Color fill, ink;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final stone = Path();
    for (var i = 0; i <= 36; i++) {
      final a = i / 36 * 2 * math.pi;
      final r = size.width / 2 * (1 + .035 * math.sin(2 * a + 1.3));
      final p = c + Offset(math.cos(a), math.sin(a)) * r;
      i == 0 ? stone.moveTo(p.dx, p.dy) : stone.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(stone, Paint()..color = fill);
    canvas.drawPath(
      stone,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
  }

  @override
  bool shouldRepaint(_StonePainter old) => old.fill != fill || old.ink != ink;
}
