import 'package:material_ui/material_ui.dart';

import 'art/art_view.dart';

/// The SummitMate mark: a trail cairn before the summit, as on the launcher icon.
/// [progress] 0..1 plays it in.
class SummitLogo extends StatelessWidget {
  const SummitLogo({super.key, this.size = 120, this.progress = 1, this.rounded = true});
  final double size;
  final double progress;

  /// Clip to an app-icon shaped rounded square.
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    final paint = RepaintBoundary(child: CustomPaint(size: Size.square(size), painter: MarkPainter(progress: progress)));
    return rounded ? ClipRRect(borderRadius: BorderRadius.circular(size * 0.225), child: paint) : paint;
  }
}
