import 'package:material_ui/material_ui.dart';

/// A line icon on a pale round-cornered tile: the one way categories and list entries get a picture.
class IconBadge extends StatelessWidget {
  const IconBadge(this.icon, {super.key, this.size = 44});
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(size * .3)),
        child: Icon(icon, size: size * .52, color: scheme.primary),
      ),
    );
  }
}
