import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/favorite_repository.dart';
import '../providers.dart';

/// The bookmark of a group event: tap to save or remove it from "我的收藏".
/// A bookmark rather than a heart, because the heart on an event is "感興趣" (a like everyone sees).
class FavoriteEventButton extends ConsumerWidget {
  const FavoriteEventButton({super.key, required this.eventId, this.compact = false});
  final String eventId;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(favoriteEventIdsProvider).contains(eventId);
    return IconButton(
      key: ValueKey('fav-event-$eventId'),
      tooltip: on ? '取消收藏' : '收藏',
      visualDensity: compact ? VisualDensity.compact : null,
      isSelected: on,
      icon: const Icon(Icons.bookmark_border),
      selectedIcon: Icon(Icons.bookmark, color: Theme.of(context).colorScheme.primary),
      onPressed: () => ref.read(favoriteRepositoryProvider).toggle(FavoriteKind.groupEvent, eventId),
    );
  }
}
