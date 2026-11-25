import 'package:material_ui/material_ui.dart';

import 'brand/art/art_view.dart';
import 'tints.dart';

/// A titled card of rows inside a scroll view that can be put in reorder mode (the sliver form of a
/// group card). Rows move only by their drag handle and only in reorder mode, so ordinary scrolling and
/// tapping can never move anything by accident. Dragging near an edge scrolls the whole page.
class ReorderableGroupSliver extends StatelessWidget {
  const ReorderableGroupSliver({
    super.key,
    required this.title,
    this.trailing,
    required this.reordering,
    required this.ids,
    required this.itemBuilder,
    required this.onReorder,
    this.icon,
    this.tint = Tint.moss,
  });

  final String title;
  final String? trailing;

  /// The picture and pale colour of the group's header.
  final ArtIcon? icon;
  final Tint tint;
  final bool reordering;

  /// The rows' ids in their current order.
  final List<String> ids;

  /// Builds row [index]; in reorder mode it must show [ReorderHandle] with the same index.
  final Widget Function(BuildContext context, int index) itemBuilder;

  /// Called with the ids in their new order.
  final ValueChanged<List<String>> onReorder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    Widget row(BuildContext context, int i) => Column(
      key: ValueKey('row-${ids[i]}'),
      mainAxisSize: MainAxisSize.min,
      children: [
        if (i > 0) Divider(height: 1, indent: 16, endIndent: 16, color: scheme.outlineVariant),
        Material(type: MaterialType.transparency, child: itemBuilder(context, i)),
      ],
    );
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      sliver: DecoratedSliver(
        decoration: BoxDecoration(color: scheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(18), border: Border.all(color: scheme.outlineVariant)),
        sliver: SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(color: tint.of(context), borderRadius: const BorderRadius.vertical(top: Radius.circular(17))),
                padding: const EdgeInsets.fromLTRB(14, 8, 16, 8),
                constraints: const BoxConstraints(minHeight: 52),
                child: Row(
                  children: [
                    if (icon != null) Padding(padding: const EdgeInsets.only(right: 8), child: ArtIconView(icon!, size: 36)),
                    Expanded(child: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: scheme.onSurface))),
                    if (trailing != null) Text(trailing!, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurface)),
                  ],
                ),
              ),
            ),
            if (reordering)
              SliverReorderableList(
                itemCount: ids.length,
                itemBuilder: row,
                proxyDecorator: (child, _, _) => Material(elevation: 6, color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(12), child: child),
                onReorderItem: (from, to) {
                  final next = [...ids];
                  next.insert(to, next.removeAt(from));
                  onReorder(next);
                },
              )
            else
              SliverList.builder(itemCount: ids.length, itemBuilder: row),
            const SliverPadding(padding: EdgeInsets.only(bottom: 4)),
          ],
        ),
      ),
    );
  }
}

/// The grip at the end of a row in reorder mode.
class ReorderHandle extends StatelessWidget {
  const ReorderHandle({super.key, required this.index});
  final int index;

  @override
  Widget build(BuildContext context) => ReorderableDragStartListener(
    index: index,
    child: Tooltip(
      message: '拖曳調整順序',
      child: SizedBox(width: 48, height: 48, child: Icon(Icons.drag_handle, color: Theme.of(context).colorScheme.outline)),
    ),
  );
}

/// The button that enters and leaves reorder mode.
class ReorderToggle extends StatelessWidget {
  const ReorderToggle({super.key, required this.reordering, required this.onChanged});
  final bool reordering;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    key: const ValueKey('reorder-toggle'),
    onPressed: () => onChanged(!reordering),
    icon: Icon(reordering ? Icons.check : Icons.swap_vert, size: 18),
    label: Text(reordering ? '完成排序' : '調整順序'),
  );
}
