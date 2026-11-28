import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/favorite_repository.dart';
import '../providers.dart';

/// The heart of a group event, like a mountain's: tap to save or remove it from "我的收藏". Only the person sees it.
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
      icon: const Icon(Icons.favorite_border),
      selectedIcon: Icon(Icons.favorite, color: Theme.of(context).colorScheme.tertiary),
      onPressed: () => ref.read(favoriteRepositoryProvider).toggle(FavoriteKind.groupEvent, eventId),
    );
  }
}
