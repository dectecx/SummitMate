import 'package:material_ui/material_ui.dart';

/// The quiet decoration behind the top-level pages: a soft, blurred watercolour wash in two corners
/// (`tool/art/accents.py`). It stays put while the page scrolls. A screen wider than tall gets none.
class PageAccents extends StatelessWidget {
  const PageAccents({super.key, required this.child});

  /// The page's [Scaffold]; its background and app bar become transparent here.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screen = MediaQuery.sizeOf(context);
    final k = screen.width / 390;
    // positions and sizes are those of a 390 wide page
    Widget piece(
      String name, {
      required double width,
      required double height,
      double? left,
      double? right,
      double? top,
      double? bottom,
    }) => Positioned(
      left: left == null ? null : left * k,
      right: right == null ? null : right * k,
      top: top == null ? null : top * k,
      bottom: bottom == null ? null : bottom * k,
      width: width * k,
      height: height * k,
      child: Image.asset(
        'assets/accents/$name.png',
        fit: BoxFit.fill,
        excludeFromSemantics: true,
        gaplessPlayback: true,
      ),
    );
    return ColoredBox(
      color: theme.colorScheme.surface,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (screen.height > screen.width)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              // The page shrinks when the keyboard opens; the decoration keeps the screen's height.
              height: screen.height,
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: Opacity(
                    opacity: theme.brightness == Brightness.dark ? .3 : 1,
                    child: Stack(
                      children: [
                        piece('wash_top', right: 0, top: 0, width: 240, height: 250),
                        piece('wash_bottom', left: 0, bottom: 0, width: 200, height: 280),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Theme(
            data: theme.copyWith(
              scaffoldBackgroundColor: Colors.transparent,
              appBarTheme: theme.appBarTheme.copyWith(backgroundColor: Colors.transparent),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
