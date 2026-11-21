import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/providers.dart';
import '../core/settings/app_settings.dart';

/// Ids of the contextual hints the person has already dismissed.
final seenHintsProvider = StreamProvider<Set<String>>((ref) {
  return ref.watch(settingsStoreProvider).watch(SettingsStore.seenHints).map(
    (raw) => raw == null ? <String>{} : (jsonDecode(raw) as List).cast<String>().toSet(),
  );
});

/// A one-time tip. Dismissing it only ever hides this tip; it never starts anything else.
class HintBanner extends ConsumerWidget {
  const HintBanner({super.key, required this.hintId, required this.icon, required this.text, this.actionLabel, this.onAction});
  final String hintId;
  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seen = ref.watch(seenHintsProvider).value;
    if (seen == null || seen.contains(hintId)) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.secondaryContainer,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Icon(icon, color: scheme.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: TextStyle(color: scheme.onSecondaryContainer))),
            if (actionLabel != null) TextButton(onPressed: onAction, child: Text(actionLabel!)),
            IconButton(
              tooltip: '知道了',
              icon: Icon(Icons.close, color: scheme.onSecondaryContainer),
              onPressed: () => ref.read(settingsStoreProvider).markHintSeen(hintId),
            ),
          ],
        ),
      ),
    );
  }
}
