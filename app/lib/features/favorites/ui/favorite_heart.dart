import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/favorite_repository.dart';
import '../providers.dart';

/// The heart of a mountain: tap to star or unstar it (works offline, syncs when signed in).
class FavoriteHeart extends ConsumerWidget {
  const FavoriteHeart({super.key, required this.mountainId, this.compact = false});
  final String mountainId;

  /// Smaller hit area for list rows.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(favoriteMountainIdsProvider).contains(mountainId);
    return IconButton(
      key: ValueKey('fav-$mountainId'),
      tooltip: on ? '取消收藏' : '收藏',
      visualDensity: compact ? VisualDensity.compact : null,
      isSelected: on,
      icon: const Icon(Icons.favorite_border),
      selectedIcon: Icon(Icons.favorite, color: Theme.of(context).colorScheme.tertiary),
      onPressed: () => ref.read(favoriteRepositoryProvider).toggle(FavoriteKind.mountain, mountainId),
    );
  }
}
