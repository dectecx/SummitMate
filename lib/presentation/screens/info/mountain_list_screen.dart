import 'package:flutter/material.dart';
import 'package:summitmate/core/core.dart';
import 'package:summitmate/data/models/mountain_location.dart';
import 'package:summitmate/presentation/widgets/info/mountain_card.dart';
import 'mountain_detail_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:summitmate/presentation/cubits/favorites/mountain/mountain_favorites_cubit.dart';
import 'package:summitmate/presentation/cubits/favorites/mountain/mountain_favorites_state.dart';

/// 山岳列表與搜尋頁面
///
/// 提供完整山岳資料庫的瀏覽功能，支援：
/// - 關鍵字搜尋 (名稱/ID)
/// - 多維度篩選 (區域/分類/新手友善/收藏)
/// - 列表展示 (使用 [MountainCard])
class MountainListScreen extends StatefulWidget {
  const MountainListScreen({super.key});

  @override
  State<MountainListScreen> createState() => _MountainListScreenState();
}

class _MountainListScreenState extends State<MountainListScreen> {
  String _searchQuery = '';
  MountainRegion? _selectedRegion;
  MountainCategory? _selectedCategory;
  bool _onlyBeginnerFriendly = false;
  bool _onlyFavorites = false;

  final TextEditingController _searchController = TextEditingController();

  List<MountainLocation> get _filteredMountains {
    final favoritesCubit = context.read<MountainFavoritesCubit>();

    return MountainData.all.where((m) {
      final matchesSearch = m.name.contains(_searchQuery) || m.id.contains(_searchQuery);
      final matchesRegion = _selectedRegion == null || m.region == _selectedRegion;
      final matchesCategory = _selectedCategory == null || m.category == _selectedCategory;
      final matchesBeginner = !_onlyBeginnerFriendly || m.isBeginnerFriendly;
      final matchesFavorites = !_onlyFavorites || favoritesCubit.isFavorite(m.id);

      return matchesSearch && matchesRegion && matchesCategory && matchesBeginner && matchesFavorites;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // 使用 CustomScrollView 營造現代感
    return BlocBuilder<MountainFavoritesCubit, MountainFavoritesState>(
      builder: (context, favoritesState) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: CustomScrollView(
            slivers: [
              // 1. 大型標題 App Bar
              SliverAppBar(
                pinned: true,
                expandedHeight: 120.0,
                backgroundColor: theme.appBarTheme.backgroundColor ?? theme.canvasColor,
                surfaceTintColor: theme.appBarTheme.surfaceTintColor,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                  title: Text(
                    '台灣山岳百科',
                    style: TextStyle(
                      color: theme.appBarTheme.foregroundColor ?? colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 20, // Collapsed size
                    ),
                  ),
                  background: Container(
                    alignment: Alignment.bottomRight,
                    padding: const EdgeInsets.all(24),
                    // 這裡可以放一個淡淡的背景圖案
                    child: Icon(Icons.terrain, size: 100, color: colorScheme.primary.withValues(alpha: 0.1)),
                  ),
                ),
              ),

              // 2. 搜尋與過濾器區域 (固定在頂部下方)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 搜尋欄
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isDark
                              ? []
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() => _searchQuery = value),
                          style: theme.textTheme.bodyLarge,
                          decoration: InputDecoration(
                            hintText: '搜尋山岳名稱...',
                            hintStyle: TextStyle(color: theme.hintColor),
                            prefixIcon: Icon(Icons.search, color: theme.hintColor),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 分類過濾 (Pills design)
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildCategoryPill(context, null, '全部'),
                            const SizedBox(width: 8),
                            ...MountainCategory.values
                                .map(
                                  (c) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: _buildCategoryPill(context, c, c.label),
                                  ),
                                )
                                .toList(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 第二排過濾器 (區域 + 新手開關)
                      Row(
                        children: [
                          // 區域選擇 (Drop-down or Horizontal list) - 這裡用精簡的按鈕觸發
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildRegionFilterButton(context),
                                  if (_selectedRegion != null) ...[
                                    const SizedBox(width: 8),
                                    Chip(
                                      label: Text(_selectedRegion!.label),
                                      onDeleted: () => setState(() => _selectedRegion = null),
                                      backgroundColor: colorScheme.secondaryContainer,
                                      labelStyle: TextStyle(color: colorScheme.onSecondaryContainer),
                                      deleteIconColor: colorScheme.onSecondaryContainer,
                                      side: BorderSide.none,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          // 新手友善開關 (獨立)
                          InkWell(
                            onTap: () => setState(() => _onlyBeginnerFriendly = !_onlyBeginnerFriendly),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: _onlyBeginnerFriendly
                                    ? Colors.green.withValues(alpha: 0.2)
                                    : theme.disabledColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _onlyBeginnerFriendly ? Colors.green : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.eco,
                                    size: 16,
                                    color: _onlyBeginnerFriendly
                                        ? (isDark ? Colors.greenAccent : Colors.green.shade800)
                                        : theme.disabledColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '新手推薦',
                                    style: TextStyle(
                                      color: _onlyBeginnerFriendly
                                          ? (isDark ? Colors.greenAccent : Colors.green.shade800)
                                          : theme.disabledColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 收藏篩選開關
                          InkWell(
                            onTap: () => setState(() => _onlyFavorites = !_onlyFavorites),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: _onlyFavorites
                                    ? Colors.red.withValues(alpha: 0.2)
                                    : theme.disabledColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _onlyFavorites ? Colors.red : Colors.transparent, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _onlyFavorites ? Icons.favorite : Icons.favorite_border,
                                    size: 16,
                                    color: _onlyFavorites
                                        ? (isDark ? Colors.redAccent : Colors.red.shade800)
                                        : theme.disabledColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '我的收藏',
                                    style: TextStyle(
                                      color: _onlyFavorites
                                          ? (isDark ? Colors.redAccent : Colors.red.shade800)
                                          : theme.disabledColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 3. 列表內容
              _filteredMountains.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.landscape_outlined, size: 64, color: theme.disabledColor),
                            const SizedBox(height: 16),
                            Text('沒有符合條件的山岳', style: TextStyle(color: theme.disabledColor)),
                          ],
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final mountain = _filteredMountains[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: MountainCard(
                              mountain: mountain,
                              isFavorite: context.read<MountainFavoritesCubit>().isFavorite(mountain.id),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => MountainDetailScreen(mountain: mountain)),
                                );
                              },
                            ),
                          );
                        }, childCount: _filteredMountains.length),
                      ),
                    ),
              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        );
      },
    );
  }

  /// 自訂樣式 Pill (無 Checkmark，避免抖動)
  Widget _buildCategoryPill(BuildContext context, MountainCategory? category, String label) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedCategory == category;

    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? colorScheme.primary : theme.dividerColor),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// 區域篩選按鈕 (BottomSheet)
  Widget _buildRegionFilterButton(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
          builder: (context) => Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('選擇區域', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: MountainRegion.values.map((region) {
                    final isSelected = _selectedRegion == region;
                    return FilterChip(
                      label: Text(region.label),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedRegion = selected ? region : null;
                        });
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Icon(Icons.tune, size: 16, color: theme.iconTheme.color),
            const SizedBox(width: 4),
            Text('區域篩選', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
          ],
        ),
      ),
    );
  }
}
