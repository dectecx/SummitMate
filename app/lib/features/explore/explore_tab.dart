import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../core/ads/ads.dart';
import '../../shared/coming_soon.dart';
import 'domain/mountain_models.dart';
import 'providers.dart';

/// "探索": browse and search mountains.
class ExploreTab extends ConsumerStatefulWidget {
  const ExploreTab({super.key});

  @override
  ConsumerState<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends ConsumerState<ExploreTab> {
  final _search = TextEditingController();
  MountainFilter _filter = MountainFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mountainsProvider).value ?? const MountainsLoading();
    return Scaffold(
      appBar: AppBar(title: const Text('探索')),
      bottomNavigationBar: const AdBannerSlot(),
      body: switch (state) {
        MountainsLoading() => const Center(child: CircularProgressIndicator()),
        MountainsUnavailable() => ComingSoon(icon: Icons.cloud_off_outlined, message: '第一次使用需要連上網路載入山岳資料。\n連線後再回來看看。'),
        MountainsReady(:final data, :final refreshFailed) => _content(data, refreshFailed),
      },
    );
  }

  Widget _content(MountainList data, bool refreshFailed) {
    final results = searchMountains(data.mountains, query: _search.text, filter: _filter);
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
            ],
          ),
        ),
        if (refreshFailed)
          Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 4), child: Text('目前無法更新，顯示上次載入的資料。', style: theme.textTheme.bodySmall)),
        Expanded(
          child: results.isEmpty
              ? const Center(child: Text('沒有符合的山'))
              : ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (_, i) {
                    final m = results[i];
                    return ListTile(
                      key: ValueKey('mountain-${m.id}'),
                      onTap: () => context.push(Routes.mountain(m.id)),
                      title: Text(m.name),
                      subtitle: Text('${m.region}  ·  ${m.elevation} m'),
                      trailing: Wrap(
                        spacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (m.beginnerFriendly) const _Badge('新手'),
                          if (m.trailGrade != null) _Badge('${m.trailGrade} 級'),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
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
