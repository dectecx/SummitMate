import 'dart:math' as math;

import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';

/// One place of the bottom bar.
typedef AppNavItem = ({Widget icon, String label});

/// The floating bottom bar: a glass capsule above the page that bends what passes behind it. The current place has
/// one tinted pill behind both its icon and its name. With "increase contrast" on, the package draws it frosted.
/// See docs/ui/DESIGN_SYSTEM.md.
class AppNavBar extends StatelessWidget {
  const AppNavBar({super.key, required this.items, required this.selected, required this.onSelected, required this.animate});

  final List<AppNavItem> items;
  final int selected;
  final ValueChanged<int> onSelected;
  final bool animate;

  static const _height = 60.0;
  static const _maxWidth = 340.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final media = MediaQuery.of(context);
    // A little into the home indicator's room, never under it.
    final bottomGap = math.max(media.viewPadding.bottom - 12, 10.0);
    final bar = Padding(
      padding: EdgeInsets.fromLTRB(12, 4, 12, bottomGap),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxWidth),
              child: GlassTabBar.bottom(
                tabs: [for (final i in items) GlassTab(icon: i.icon, label: i.label)],
                selectedIndex: selected,
                onTabSelected: onSelected,
                barHeight: _height,
                horizontalPadding: 0,
                verticalPadding: 0,
                iconSize: 22,
                iconLabelSpacing: 1,
                labelFontSize: 11,
                selectedIconColor: scheme.primary,
                selectedLabelColor: scheme.primary,
                // Full-strength ink: grey is lost where a blue map or a dark picture shows through.
                unselectedIconColor: scheme.onSurface,
                unselectedLabelColor: scheme.onSurface,
                indicatorColor: scheme.primary.withValues(alpha: dark ? .4 : .22),
                // Milky enough for the names to stay readable over pictures and the map.
                settings: LiquidGlassSettings(glassColor: scheme.surfaceContainerLowest.withValues(alpha: .8), blur: 8),
                quality: GlassQuality.premium,
              ),
            ),
          ),
        ],
      ),
    );
    // The package reads the system's "reduce motion"; the app's own animation switch says the same thing to it.
    return MediaQuery(data: media.copyWith(disableAnimations: media.disableAnimations || !animate), child: bar);
  }
}
