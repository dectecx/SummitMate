import 'package:material_ui/material_ui.dart';

/// The head of a top-level page: a large title, in line with the trip list.
AppBar pageBar(BuildContext context, String title, {List<Widget>? actions}) {
  final theme = Theme.of(context);
  // a screen wider than tall keeps the ordinary bar, so the list keeps its room
  final tall = MediaQuery.orientationOf(context) == Orientation.portrait;
  return AppBar(
    toolbarHeight: tall ? 72 : kToolbarHeight,
    titleSpacing: 24,
    title: Text(title, style: theme.textTheme.headlineMedium?.copyWith(fontSize: tall ? 30 : 22, color: theme.colorScheme.onSurface)),
    actions: actions,
  );
}
