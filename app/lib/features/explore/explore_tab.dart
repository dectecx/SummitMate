import '../../shared/page_accents.dart';
import '../../shared/page_bar.dart';
import '../../shared/brand/cover_image.dart';
import '../favorites/providers.dart';
import '../favorites/ui/favorite_heart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../core/ads/ads.dart';
import '../../shared/coming_soon.dart';
import 'domain/mountain_models.dart';
import 'providers.dart';
import 'ui/shops_view.dart';
import '../../shared/icon_badge.dart';
import '../trips/domain/trip_art.dart';
import '../../../shared/brand/illustrations.dart';

enum _Segment { mountains, shops }

/// "探索": browse and search mountains and outdoor shops.
class ExploreTab extends ConsumerStatefulWidget {
  const ExploreTab({super.key});

  @override
  ConsumerState<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends ConsumerState<ExploreTab> {
  final _search = TextEditingController();
  MountainFilter _filter = MountainFilter.all;
  bool _onlyFavorites = false;
  _Segment _segment = _Segment.mountains;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageAccents(child: Scaffold(
      appBar: pageBar(context, '探索'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SegmentedButton<_Segment>(
              key: const ValueKey('explore-segment'),
              expandedInsets: EdgeInsets.zero,
              showSelectedIcon: false,
              segments: const [ButtonSegment(value: _Segment.mountains, label: Text('山岳')), ButtonSegment(value: _Segment.shops, label: Text('用品店'))],
              selected: {_segment},
              onSelectionChanged: (s) => setState(() => _segment = s.first),
            ),
          ),
          Expanded(
            child: switch (_segment) {
              _Segment.mountains => _mountains(),
              _Segment.shops => const ShopsView(),
            },
          ),
        ],
      ),
    ));
  }

  Widget _mountains() {
    final state = ref.watch(mountainsProvider).value ?? const MountainsLoading();
    return switch (state) {
      MountainsLoading() => const Center(child: CircularProgressIndicator()),
      MountainsUnavailable() => ComingSoon(illustration: Illustration.map, message: '第一次使用需要連上網路載入山岳資料。\n連線後再回來看看。'),
      MountainsReady(:final data, :final refreshFailed) => _content(data, refreshFailed),
    };
  }

  Widget _content(MountainList data, bool refreshFailed) {
    final favorites = ref.watch(favoriteMountainIdsProvider);
    final found = searchMountains(data.mountains, query: _search.text, filter: _filter);
    final results = _onlyFavorites ? [for (final m in found) if (favorites.contains(m.id)) m] : found;
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '搜尋山名或地區',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.text.isEmpty ? null : IconButton(tooltip: '清除', icon: const Icon(Icons.close), onPressed: () => setState(_search.clear)),
            ),
          ),
        ),
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              for (final (f, label) in [(MountainFilter.all, '全部'), (MountainFilter.beginner, '新手推薦'), (MountainFilter.baiyue, '百岳')])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(label: Text(label), selected: _filter == f, onSelected: (_) => setState(() => _filter = f)),
                ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  key: const ValueKey('filter-favorites'),
                  avatar: const Icon(Icons.favorite, size: 16),
                  label: const Text('已收藏'),
                  selected: _onlyFavorites,
                  onSelected: (v) => setState(() => _onlyFavorites = v),
                ),
              ),
            ],
          ),
        ),
        if (refreshFailed)
          Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 4), child: Text('目前無法更新，顯示上次載入的資料。', style: theme.textTheme.bodySmall)),
        Expanded(
          child: results.isEmpty
              ? Center(child: Text(_onlyFavorites && favorites.isEmpty ? '還沒有收藏的山，點山岳右邊的愛心就能收藏。' : '沒有符合的山'))
              : ListView.builder(
                  padding: EdgeInsets.only(top: 2, bottom: 12 + MediaQuery.paddingOf(context).bottom),
                  itemCount: results.length + 1, // one extra place for the ad
                  itemBuilder: (context, index) {
                    final adAt = results.length < 3 ? results.length : 3;
                    if (index == adAt) return const AdBannerSlot(key: ValueKey('ad-slot'));
                    final i = index < adAt ? index : index - 1;
                    final screen = MediaQuery.sizeOf(context);
                    return _MountainCard(
                      key: ValueKey('mountain-${results[i].id}'),
                      mountain: results[i],
                      featured: i == 0 && screen.height > screen.width,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// One mountain of the list. The featured one (the first result) carries a landscape.
class _MountainCard extends StatelessWidget {
  const _MountainCard({super.key, required this.mountain, required this.featured});
  final Mountain mountain;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final m = mountain;
    final row = Row(
      children: [
        if (!featured) ...[
          IconBadge(m.beginnerFriendly ? Icons.forest_outlined : Icons.terrain_outlined, size: 56),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              Text('${m.region}  ·  ${m.elevation} m', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              if (m.beginnerFriendly || m.trailGrade != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Wrap(spacing: 6, children: [if (m.beginnerFriendly) const _Badge('新手'), if (m.trailGrade != null) _Badge('${m.trailGrade} 級')]),
                ),
            ],
          ),
        ),
        FavoriteHeart(mountainId: m.id, compact: true),
      ],
    );
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: InkWell(
        onTap: () => context.push(Routes.mountain(m.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (featured) SizedBox(height: 132, child: CoverImage(cover: coverFor(m.id, coverCount))),
            Padding(padding: const EdgeInsets.fromLTRB(14, 10, 8, 12), child: row),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: scheme.secondaryContainer, borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: TextStyle(fontSize: 12, color: scheme.onSecondaryContainer)),
    );
  }
}
