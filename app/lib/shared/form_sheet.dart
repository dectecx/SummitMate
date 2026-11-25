import 'package:material_ui/material_ui.dart';

/// The bottom panel for entering data (a trip, a node, gear, a meal, a poll, an invitation).
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
