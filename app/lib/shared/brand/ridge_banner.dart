import 'package:material_ui/material_ui.dart';

/// A soft banner of layered ridgelines with a title on top, used as the head of detail screens.
/// [seed] changes the ridge shape so different mountains do not look the same.
class RidgeBanner extends StatelessWidget {
  const RidgeBanner({super.key, required this.title, this.subtitle, this.trailing, this.seed = 0, this.height = 176});
  final String title;
  final String? subtitle;
  final String? trailing;
  final int seed;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: dark ? const [Color(0xFF1B3A40), Color(0xFF223033)] : const [Color(0xFFCFE6E3), Color(0xFFEFF1E4)],
                ),
              ),
            ),
            CustomPaint(painter: _RidgePainter(seed: seed, dark: dark)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if (trailing != null) Text(trailing!, style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700, color: dark ? Colors.white : const Color(0xFF12383F), height: 1.05)),
                  Text(title, style: theme.textTheme.titleLarge?.copyWith(color: dark ? Colors.white : const Color(0xFF12383F))),
                  if (subtitle != null) Text(subtitle!, style: theme.textTheme.bodyMedium?.copyWith(color: dark ? Colors.white70 : const Color(0xFF3D5A5F))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RidgePainter extends CustomPainter {
  const _RidgePainter({required this.seed, required this.dark});
  final int seed;
  final bool dark;

  double _h(int i, int layer) {
    final v = ((i * 7919 + layer * 104729 + seed * 15485863) % 1000) / 1000;
    return v;
  }

  Path _ridge(Size size, int layer, double base, double amp, int points) {
    final path = Path()..moveTo(0, size.height);
    path.lineTo(0, size.height * base);
    for (var i = 1; i <= points; i++) {
      final x = size.width * i / points;
      final y = size.height * base - amp * size.height * _h(i, layer);
      path.lineTo(x, y);
    }
    return path..lineTo(size.width, size.height)..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final colors = dark
        ? const [Color(0x40356A73), Color(0x66356A73), Color(0xAA2A5A62)]
        : const [Color(0x553F8C97), Color(0x881F6F7A), Color(0xCC1B5A63)];
    canvas.drawPath(_ridge(size, 1, 0.80, 0.26, 6), Paint()..color = colors[0]);
    canvas.drawPath(_ridge(size, 2, 0.89, 0.20, 7), Paint()..color = colors[1]);
    canvas.drawPath(_ridge(size, 3, 0.97, 0.12, 9), Paint()..color = colors[2]);
  }

  @override
  bool shouldRepaint(_RidgePainter old) => old.seed != seed || old.dark != dark;
}
