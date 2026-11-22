import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../shared/coming_soon.dart';
import '../../explore/domain/mountain_models.dart';
import '../../explore/providers.dart';
import '../providers.dart';
import 'favorite_heart.dart';

/// "我的收藏": the starred mountains.
class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(favoriteMountainIdsProvider);
    final state = ref.watch(mountainsProvider).value;
    final all = state is MountainsReady ? state.data.mountains : const <Mountain>[];
    final starred = [for (final m in all) if (ids.contains(m.id)) m];
    final body = ids.isEmpty
        ? const ComingSoon(icon: Icons.favorite_border, message: '還沒有收藏。在「探索」或山岳頁點愛心，就會收在這裡，沒有網路也看得到。')
        : starred.isEmpty
            ? Center(child: Text(state is MountainsReady ? '收藏的山岳資料暫時找不到。' : '山岳資料載入中…'))
            : ListView(
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
    return Scaffold(appBar: AppBar(title: const Text('我的收藏')), body: body);
  }
}
