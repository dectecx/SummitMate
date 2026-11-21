import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../shared/coming_soon.dart';
import '../../weather/ui/weather_card.dart';
import '../domain/mountain_models.dart';
import '../providers.dart';

class MountainDetailPage extends ConsumerWidget {
  const MountainDetailPage({super.key, required this.mountainId});
  final String mountainId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mountainsProvider).value;
    final mountain = state is MountainsReady ? state.data.byId(mountainId) : null;
    if (mountain == null) {
      return Scaffold(
        appBar: AppBar(),
        body: state is MountainsReady || state is MountainsUnavailable
            ? const ComingSoon(icon: Icons.search_off, message: '找不到這座山')
            : const Center(child: CircularProgressIndicator()),
      );
    }
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(mountain.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (mountain.nameEn != null) Text(mountain.nameEn!, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Fact(icon: Icons.landscape_outlined, text: '${mountain.elevation} m'),
              _Fact(icon: Icons.place_outlined, text: mountain.region),
              if (mountain.category == MountainCategory.baiyue) const _Fact(icon: Icons.flag_outlined, text: '台灣百岳'),
              if (mountain.trailGrade != null) _Fact(icon: Icons.speed, text: '步道分級 ${mountain.trailGrade} 級'),
              if (mountain.beginnerFriendly) const _Fact(icon: Icons.thumb_up_outlined, text: '新手推薦'),
            ],
          ),
          if (mountain.trailGrade != null) ...[
            const SizedBox(height: 8),
            Text('步道分級為國家公園署公布的 0 至 6 級，數字越大越困難；級數定義請見資料來源。', style: theme.textTheme.bodySmall),
          ],
          if (mountain.summary.isNotEmpty) ...[const SizedBox(height: 16), Text(mountain.summary, style: theme.textTheme.bodyLarge)],
          if (mountain.permit != null) ...[
            const SizedBox(height: 16),
            Text('入山規定', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(mountain.permit!),
          ],
          const SizedBox(height: 16),
          Card(
            color: theme.colorScheme.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: theme.colorScheme.onTertiaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      mountain.verified ? '資料整理自公開來源，出發前請再確認路況與入山規定。' : '這筆資料整理自公開來源，尚未經人工核實。出發前請務必再確認海拔、路況與入山規定。',
                      style: TextStyle(color: theme.colorScheme.onTertiaryContainer),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('天氣預報', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          PlaceWeather(query: (lat: mountain.latitude, lng: mountain.longitude, elevation: mountain.elevation)),
          if (mountain.sources.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('資料來源', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            for (final s in mountain.sources) SelectableText(s, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(16)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16), const SizedBox(width: 6), Text(text)]),
    );
  }
}
