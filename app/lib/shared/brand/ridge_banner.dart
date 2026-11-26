import 'cover_image.dart';
import 'package:material_ui/material_ui.dart';


/// The head of a detail screen: a landscape with the title under it. [seed] picks the scene, so different
/// mountains and events do not all look the same. A screen wider than tall shows the text only.
class RidgeBanner extends StatelessWidget {
  const RidgeBanner({super.key, required this.title, this.subtitle, this.trailing, this.seed = 0, this.height = 176});
  final String title;
  final String? subtitle;
  final String? trailing;
  final int seed;

  /// Height of the picture.
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final screen = MediaQuery.sizeOf(context);
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (screen.height > screen.width)
            SizedBox(
              height: height,
              child: CoverImage(cover: seed.abs() % coverCount),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: scheme.onSurface),
                ),
                if (trailing != null)
                  Text(
                    trailing!,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                      height: 1.25,
                    ),
                  ),
                if (subtitle != null)
                  Text(subtitle!, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
