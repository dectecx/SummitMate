import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../shared/coming_soon.dart';
import '../../events/data/events_api.dart';
import '../../events/providers.dart';
import '../../events/ui/event_widgets.dart';
import '../../explore/domain/mountain_models.dart';
import '../../explore/providers.dart';
import '../providers.dart';
import 'favorite_event_button.dart';
import 'favorite_heart.dart';
import '../../../shared/brand/illustrations.dart';

/// "我的收藏": the starred mountains and group events.
class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('我的收藏'),
          bottom: const TabBar(tabs: [Tab(text: '山岳'), Tab(text: '揪團')]),
        ),
        body: const TabBarView(children: [_MountainFavorites(), _EventFavorites()]),
      ),
    );
  }
}

class _MountainFavorites extends ConsumerWidget {
  const _MountainFavorites();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(favoriteMountainIdsProvider);
    final state = ref.watch(mountainsProvider).value;
    final all = state is MountainsReady ? state.data.mountains : const <Mountain>[];
    final starred = [for (final m in all) if (ids.contains(m.id)) m];
    if (ids.isEmpty) {
      return const ComingSoon(
        illustration: Illustration.star,
        message: '還沒有收藏的山岳。在「探索」或山岳頁點愛心，就會收在這裡，沒有網路也看得到。',
      );
    }
    if (starred.isEmpty) {
      return Center(child: Text(state is MountainsReady ? '收藏的山岳資料暫時找不到。' : '山岳資料載入中…'));
    }
    return ListView(
      children: [
        for (final m in starred)
          ListTile(
            key: ValueKey('favorite-${m.id}'),
            title: Text(m.name),
            subtitle: Text('${m.region}  ·  ${m.elevation} m'),
            trailing: FavoriteHeart(mountainId: m.id),
            onTap: () => context.push(Routes.mountain(m.id)),
          ),
      ],
    );
  }
}

/// Only the ids are stored, so the events themselves are fetched when this tab opens (needs a connection).
final _favoriteEventsProvider = FutureProvider.autoDispose<List<_FavoriteEvent>>((ref) async {
  final ids = ref.watch(favoriteEventIdsProvider).toList();
  final api = ref.watch(eventsApiProvider);
  return Future.wait([
    for (final id in ids)
      api.get(id).then<_FavoriteEvent>(_FavoriteEvent.found).catchError((Object e) {
        // A deleted event is gone for good; any other failure (usually offline) is shown as "can't load".
        return e is EventsException && e.notFound
            ? _FavoriteEvent.gone(id)
            : _FavoriteEvent.unavailable(id);
      }),
  ]);
});

class _FavoriteEvent {
  _FavoriteEvent.found(EventDetail d) : id = d.id, event = d, gone = false;
  _FavoriteEvent.gone(this.id) : event = null, gone = true;
  _FavoriteEvent.unavailable(this.id) : event = null, gone = false;
  final String id;
  final EventDetail? event;
  final bool gone;
}

class _EventFavorites extends ConsumerWidget {
  const _EventFavorites();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(favoriteEventIdsProvider);
    if (ids.isEmpty) {
      return const ComingSoon(
        illustration: Illustration.star,
        message: '還沒有收藏的揪團。在揪團頁點書籤，就會收在這裡。',
      );
    }
    final items = ref.watch(_favoriteEventsProvider);
    return items.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('暫時載入不了，請確認網路後再試')),
      data: (list) {
        final today = DateTime.now();
        return RefreshIndicator(
          onRefresh: () async => ref.refresh(_favoriteEventsProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              for (final f in list)
                if (f.event != null)
                  EventCard(
                    event: f.event!,
                    today: DateTime(today.year, today.month, today.day),
                    onTap: () => context.push(Routes.event(f.id)),
                  )
                else
                  ListTile(
                    key: ValueKey('favorite-event-${f.id}'),
                    leading: const Icon(Icons.cloud_off_outlined),
                    title: Text(f.gone ? '這個揪團已不存在' : '目前載入不了這個揪團'),
                    subtitle: Text(f.gone ? '可以把它從收藏移除' : '需要網路'),
                    trailing: f.gone ? FavoriteEventButton(eventId: f.id) : null,
                  ),
            ],
          ),
        );
      },
    );
  }
}
