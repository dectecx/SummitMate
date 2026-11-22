import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/app_database.dart';
import '../providers.dart';

/// Chips under a name field: items of the person's library whose name matches what is typed. Tapping one hands it
/// to [onPick] (the form fills in category, weight and so on).
class LibrarySuggestions extends ConsumerWidget {
  const LibrarySuggestions({super.key, required this.kind, required this.controller, required this.onPick});
  final String kind;
  final TextEditingController controller;
  final ValueChanged<LibraryItem> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(libraryItemsProvider(kind)).value ?? const <LibraryItem>[];
    if (items.isEmpty) return const SizedBox.shrink();
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final q = value.text.trim().toLowerCase();
        if (q.isEmpty) return const SizedBox.shrink();
        final shown = items.where((i) => i.name.toLowerCase().contains(q) && i.name.toLowerCase() != q).take(5).toList();
        if (shown.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              children: [for (final i in shown) ActionChip(key: ValueKey('lib-${i.id}'), avatar: const Icon(Icons.bookmark_outline, size: 18), label: Text(i.name), onPressed: () => onPick(i))],
            ),
          ),
        );
      },
    );
  }
}
