import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/ads/ads.dart';
import '../../../shared/coming_soon.dart';
import '../../../shared/open_link.dart';
import '../domain/shop_models.dart';
import '../providers.dart';
import '../../../shared/brand/illustrations.dart';

/// The "用品店" part of the explore tab: outdoor and hiking gear shops, filtered by city and what they sell.
class ShopsView extends ConsumerStatefulWidget {
  const ShopsView({super.key});

  @override
  ConsumerState<ShopsView> createState() => _ShopsViewState();
}

class _ShopsViewState extends ConsumerState<ShopsView> {
  final _search = TextEditingController();
  String? _city;
  String? _category;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shopsProvider).value ?? const ShopsLoading();
    return switch (state) {
      ShopsLoading() => const Center(child: CircularProgressIndicator()),
      ShopsUnavailable() => const ComingSoon(illustration: Illustration.shop, message: '第一次使用需要連上網路載入店家資料。\n連線後再回來看看。'),
      ShopsReady(:final data, :final refreshFailed) => _content(data, refreshFailed),
    };
  }

  Widget _content(ShopList data, bool refreshFailed) {
    final theme = Theme.of(context);
    final results = searchShops(data.shops, query: _search.text, city: _city, category: _category);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('shops-search'),
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: '搜尋店名或地址',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _search.text.isEmpty ? null : IconButton(tooltip: '清除', icon: const Icon(Icons.close), onPressed: () => setState(_search.clear)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String?>(
                key: const ValueKey('shops-city'),
                tooltip: '縣市',
                onSelected: (c) => setState(() => _city = c),
                itemBuilder: (_) => [
                  const PopupMenuItem<String?>(value: null, child: Text('全部縣市')),
                  for (final c in data.cities) PopupMenuItem<String?>(value: c, child: Text(c)),
                ],
                child: Chip(avatar: const Icon(Icons.place_outlined, size: 18), label: Text(_city ?? '全部縣市')),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(key: const ValueKey('shop-cat-all'), label: const Text('全部'), selected: _category == null, onSelected: (_) => setState(() => _category = null))),
              for (final c in shopCategories)
                Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(key: ValueKey('shop-cat-$c'), label: Text(c), selected: _category == c, onSelected: (_) => setState(() => _category = c))),
            ],
          ),
        ),
        if (refreshFailed) Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 4), child: Text('目前無法更新，顯示上次載入的資料。', style: theme.textTheme.bodySmall)),
        Expanded(
          child: results.isEmpty
              ? const Center(child: Text('沒有符合的店家'))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: results.length + 2, // the ad and the closing note
                  itemBuilder: (_, index) {
                    final adAt = results.length < 3 ? results.length : 3;
                    if (index == adAt) return const AdBannerSlot(key: ValueKey('ad-slot'));
                    final i = index < adAt ? index : index - 1;
                    return i == results.length
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: Text('只收錄 Google 評價 4.0 星以上的店家；營業時間與電話可能變動，出發前請先確認。', style: theme.textTheme.bodySmall),
                          )
                        : ShopCard(shop: results[i]);
                  },
                ),
        ),
      ],
    );
  }
}

class ShopCard extends ConsumerWidget {
  const ShopCard({super.key, required this.shop});
  final Shop shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    Future<void> open(Uri uri) async {
      final messenger = ScaffoldMessenger.of(context);
      if (!await ref.read(linkOpenerProvider)(uri)) messenger.showSnackBar(const SnackBar(content: Text('無法開啟')));
    }

    return Card(
      key: ValueKey('shop-${shop.id}'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(shop.name, style: theme.textTheme.titleMedium)),
                const Icon(Icons.star_rounded, size: 18, color: Color(0xFFF2A900)),
                Text(shop.rating.toStringAsFixed(1), style: theme.textTheme.labelLarge),
                if (shop.ratingCount != null) Text(' (${shop.ratingCount})', style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 4),
            Text('${shop.city}${shop.district}  ·  ${shop.address}', style: theme.textTheme.bodyMedium),
            if (shop.hours != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text('營業時間：${shop.hours}', style: theme.textTheme.bodySmall)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [for (final c in shop.categories) Chip(label: Text(c), visualDensity: VisualDensity.compact, padding: EdgeInsets.zero)],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: ValueKey('shop-map-${shop.id}'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                  onPressed: () => open(Uri.parse(shop.googleMapsUrl)),
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('地圖'),
                ),
                if (shop.website != null)
                  OutlinedButton.icon(
                    key: ValueKey('shop-site-${shop.id}'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                    onPressed: () => open(Uri.parse(shop.website!)),
                    icon: const Icon(Icons.language, size: 18),
                    label: const Text('官網'),
                  ),
                if (shop.shopUrl != null)
                  FilledButton.tonalIcon(
                    key: ValueKey('shop-store-${shop.id}'),
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                    onPressed: () => open(Uri.parse(shop.shopUrl!)),
                    icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                    label: Text(shop.shopLabel!),
                  ),
                if (shop.dialNumber != null && shop.dialNumber!.isNotEmpty)
                  OutlinedButton.icon(
                    key: ValueKey('shop-call-${shop.id}'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                    onPressed: () => open(Uri(scheme: 'tel', path: shop.dialNumber)),
                    icon: const Icon(Icons.call_outlined, size: 18),
                    label: Text(shop.phone!),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
