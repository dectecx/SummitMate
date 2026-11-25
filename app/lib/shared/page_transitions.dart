import 'package:material_ui/material_ui.dart';

import 'brand/art/art_view.dart';

/// Puts the landscape behind every page. It travels with the page during transitions, so two pages never show
/// through each other even though their scaffolds are transparent.
class BackdropTransitionsBuilder extends PageTransitionsBuilder {
  const BackdropTransitionsBuilder(this.base);

  /// The platform's own transition.
  final PageTransitionsBuilder base;

  static PageTransitionsTheme theme() {
    const standard = PageTransitionsTheme();
    return PageTransitionsTheme(
      builders: {
        for (final platform in TargetPlatform.values)
          platform: BackdropTransitionsBuilder(standard.builders[platform] ?? const ZoomPageTransitionsBuilder()),
      },
    );
  }

  @override
  Duration get transitionDuration => base.transitionDuration;

  @override
  Duration get reverseTransitionDuration => base.reverseTransitionDuration;

  @override
  DelegatedTransitionBuilder? get delegatedTransition => base.delegatedTransition;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => base.buildTransitions(route, context, animation, secondaryAnimation, PageBackdrop(child: child));
}
