import 'package:material_ui/material_ui.dart';

/// The bottom panel for quick entries (gear, a meal, a poll, an invitation).
///
/// It closes only with the ✕ button, a successful save or the system back gesture. Swiping down or tapping
/// outside does nothing, so scrolling a long form never throws away what was typed.
Future<T?> showFormSheet<T>({required BuildContext context, required WidgetBuilder builder}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useRootNavigator: true,
  useSafeArea: true,
  enableDrag: false,
  isDismissible: false,
  showDragHandle: false,
  builder: (context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 8, 0),
          child: IconButton(key: const ValueKey('sheet-close'), tooltip: '關閉', icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        ),
      ),
      Flexible(child: Builder(builder: builder)),
    ],
  ),
);

/// A whole page for the longer forms: creating or editing a trip or an itinerary node. Quick entries use the sheet.
///
/// It closes with the ✕ button, a successful save or the system back button, never by a swipe.
Future<T?> showFormPage<T>({required BuildContext context, required WidgetBuilder builder}) => Navigator.of(context, rootNavigator: true).push<T>(
  MaterialPageRoute<T>(
    fullscreenDialog: true,
    builder: (context) => Scaffold(
      appBar: AppBar(
        leading: IconButton(key: const ValueKey('sheet-close'), tooltip: '關閉', icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(top: false, child: Align(alignment: Alignment.topCenter, child: Builder(builder: builder))),
    ),
  ),
);
