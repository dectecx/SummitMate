import 'package:material_ui/material_ui.dart';

/// The fields few people need, folded away at the end of a form. Starts open when one of them already has a value.
class MoreOptions extends StatelessWidget {
  const MoreOptions({super.key, required this.child, this.open = false});
  final Widget child;
  final bool open;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    key: const ValueKey('more-options'),
    initiallyExpanded: open,
    maintainState: true,
    tilePadding: EdgeInsets.zero,
    childrenPadding: const EdgeInsets.only(top: 8),
    shape: const Border(),
    collapsedShape: const Border(),
    title: Text('更多選項', style: Theme.of(context).textTheme.bodyMedium),
    children: [child],
  );
}
