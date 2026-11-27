import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:material_ui/material_ui.dart';

/// One place of the bottom bar.
typedef AppNavItem = ({Widget icon, String label});

/// The floating bottom bar: a frosted capsule above the page. The current place has one pale pill behind both its
/// icon and its name. See docs/ui/DESIGN_SYSTEM.md.
class AppNavBar extends StatelessWidget {
  const AppNavBar({super.key, required this.items, required this.selected, required this.onSelected, required this.animate});

  final List<AppNavItem> items;
  final int selected;
  final ValueChanged<int> onSelected;
  final bool animate;

  static const height = 60.0;
  static const _itemWidth = 64.0;
  static const _inset = 5.0;

  /// How far the capsule stays from the bottom edge: a little into the home indicator's room, never under it.
  static double bottomGap(BuildContext context) => math.max(MediaQuery.viewPaddingOf(context).bottom - 12, 10);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final solid = MediaQuery.highContrastOf(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 4, 12, bottomGap(context)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: DecoratedBox(
              decoration: const ShapeDecoration(
                shape: StadiumBorder(),
                shadows: [BoxShadow(color: Color(0x1F192823), blurRadius: 16, offset: Offset(0, 4))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(height / 2),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Material(
                    color: scheme.surfaceContainerLowest.withValues(alpha: solid ? 1 : .78),
                    shape: StadiumBorder(side: BorderSide(color: scheme.outlineVariant)),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: _itemWidth * items.length + _inset * 2),
                      child: Padding(
                        padding: const EdgeInsets.all(_inset),
                        child: SizedBox(
                          height: height - _inset * 2,
                          child: Row(
                            children: [
                              for (var i = 0; i < items.length; i++)
                                Expanded(child: _Item(item: items[i], selected: i == selected, animate: animate, onTap: () => onSelected(i))),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.item, required this.selected, required this.animate, required this.onTap});

  final AppNavItem item;
  final bool selected;
  final bool animate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: AnimatedContainer(
          duration: animate ? const Duration(milliseconds: 200) : Duration.zero,
          decoration: ShapeDecoration(shape: const StadiumBorder(), color: scheme.primaryContainer.withValues(alpha: selected ? 1 : 0)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconTheme(data: IconThemeData(size: 22, color: color), child: item.icon),
              const SizedBox(height: 1),
              // The bar has a fixed height: very large text stops growing here, as in the system's own bars.
              MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.2,
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: TextStyle(fontSize: 11, height: 1.2, fontWeight: FontWeight.w600, color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
