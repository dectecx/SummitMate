import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/injection.dart';
import '../../core/error/result.dart';
import '../../data/models/gear_set.dart';
import '../../domain/entities/gear_item.dart';
import '../../domain/repositories/i_gear_repository.dart';
import '../../domain/repositories/i_gear_set_repository.dart';
import '../../data/models/gear_key_record.dart';
import '../../data/models/meal_item.dart';
import 'package:summitmate/infrastructure/infrastructure.dart';
import '../cubits/settings/settings_cubit.dart';
import '../cubits/settings/settings_state.dart';
import '../cubits/meal/meal_cubit.dart';
import '../cubits/meal/meal_state.dart';
import '../cubits/gear/gear_cubit.dart';
import '../cubits/gear/gear_state.dart';
import '../cubits/gear_library/gear_library_cubit.dart';
import '../cubits/trip/trip_cubit.dart';
import '../cubits/trip/trip_state.dart';
import '../widgets/gear_upload_dialog.dart';
import '../widgets/gear_key_dialog.dart';
import '../widgets/gear_key_download_dialog.dart';
import '../widgets/gear_preview_dialog.dart';
import '../widgets/common/summit_app_bar.dart';
import '../widgets/responsive_layout.dart';

/// 雲端裝備庫畫面
class GearCloudScreen extends StatefulWidget {
  const GearCloudScreen({super.key});

  @override
  State<GearCloudScreen> createState() => _GearCloudScreenState();
}

class _GearCloudScreenState extends State<GearCloudScreen> {
  final IGearSetRepository _repository = getIt<IGearSetRepository>();
  List<GearSet> _gearSets = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _busyGearSetId; // 防止連續點擊的狀態
  final TextEditingController _searchController = TextEditingController();

  List<GearSet> get _filteredGearSets {
    if (_searchController.text.isEmpty) {
      return _gearSets;
    }
    final query = _searchController.text.toLowerCase();
    return _gearSets.where((g) {
      return g.title.toLowerCase().contains(query) || g.author.toLowerCase().contains(query);
    }).toList();
  }

  bool _hasFetched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasFetched) {
      final state = context.read<SettingsCubit>().state;
      final isOffline = state is SettingsLoaded && state.isOfflineMode;
      if (!isOffline) {
        _hasFetched = true;
        _fetchGearSets();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchGearSets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _repository.getGearSets();

    if (!mounted) return;

    if (result is Success<List<GearSet>, Exception>) {
      setState(() {
        _gearSets = result.value;
        _isLoading = false;
      });
    } else if (result is Failure<List<GearSet>, Exception>) {
      setState(() {
        _isLoading = false;
        _errorMessage = result.exception.toString();
      });
    }
  }

  Future<void> _showUploadDialog() async {
    final settingsState = context.read<SettingsCubit>().state;
    final String username = settingsState is SettingsLoaded ? settingsState.settings.username : 'Anonymous';

    // We can get items from GearCubit active state or simpler getting from repo for current trip
    final tripState = context.read<TripCubit>().state;
    String? currentTripId;
    if (tripState is TripLoaded) {
      currentTripId = tripState.activeTrip?.id;
    }

    if (currentTripId == null) {
      ToastService.warning('請先選擇行程');
      return;
    }

    // Get items for current trip
    final gearRepo = getIt<IGearRepository>();
    // Note: gearRepo.getAllItems() might return ALL. We should filter.
    // Assuming gearRepo has method to get by trip or we filter manually.
    // If we look at GearCubit logic, it filters loadGear(tripId).
    // Let's rely on GearCubit state if it matches active trip, else manual fetch.
    final gearCubit = context.read<GearCubit>();
    // List<GearItem> items; // Removed unused declaration
    List<GearItem> items = []; // Initialize to empty list to be safe or just use local var in branches
    // Actually, items is used later in line 137 check and 151.
    // So it logic must be accessible.
    // The previous code had:
    // List<GearItem> items;
    // if (...) { ... items = ... } else { ... items = ... }
    // If analyzer says 'Dead code' at 115, maybe it thinks initialization is guaranteed or not needed?
    // Let's just initialize it.
    if (gearCubit.currentTripId == currentTripId && gearCubit.state is GearLoaded) {
      // Use loaded items
      try {
        items = (gearCubit.state as GearLoaded).items;
      } catch (e) {
        // Fallback
        final all = gearRepo.getAllItems();
        items = all.where((i) => i.tripId == currentTripId).toList();
      }
    } else {
      final all = gearRepo.getAllItems();
      items = all.where((i) => i.tripId == currentTripId).toList();
    }

    if (items.isEmpty) {
      ToastService.info('請先新增裝備再上傳');
      return;
    }

    if (!mounted) return;

    String? uploadedKey;
    String? uploadedTitle;
    GearSetVisibility? uploadedVisibility;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => GearUploadDialog(
        items: items,
        author: username,
        onUpload: (title, visibility, key) async {
          final uploadResult = await _repository.uploadGearSet(
            tripId: currentTripId ?? '',
            title: title,
            author: username,
            visibility: visibility,
            items: items,
            meals: context.read<MealCubit>().state is MealLoaded
                ? (context.read<MealCubit>().state as MealLoaded).dailyPlans
                : [],
            key: key,
          );

          if (uploadResult is Success<GearSet, Exception>) {
            uploadedKey = key;
            uploadedTitle = title;
            uploadedVisibility = visibility;
            ToastService.success('上傳成功！');
            return true;
          } else if (uploadResult is Failure<GearSet, Exception>) {
            ToastService.error(uploadResult.exception.toString());
            return false;
          }
          return false;
        },
      ),
    );

    if (result == true) {
      // 儲存 Key 到本地 (如果有設定)
      if (uploadedKey != null && uploadedKey!.isNotEmpty) {
        await _repository.saveUploadedKey(uploadedKey!, uploadedTitle ?? '', uploadedVisibility?.name ?? '');
      }
      _fetchGearSets();
    }
  }

  Future<void> _showKeyInputDialog() async {
    final result = await showDialog<GearSet?>(
      context: context,
      builder: (context) => GearKeyInputDialog(repository: _repository),
    );

    if (result != null && mounted) {
      _showDownloadConfirmDialog(result);
    }
  }

  Future<void> _downloadGearSet(GearSet gearSet, {String? key}) async {
    // 防止連續點擊
    if (_busyGearSetId != null) return;
    setState(() => _busyGearSetId = gearSet.id);

    final result = await _repository.downloadGearSet(gearSet.id, key: key);

    if (!mounted) return;
    setState(() => _busyGearSetId = null);

    if (result is Failure<GearSet, Exception>) {
      ToastService.error(result.exception.toString());
      return;
    }

    if (result is Success<GearSet, Exception>) {
      if (result.value.items == null) {
        ToastService.error('組合內容空白');
        return;
      }
      _showDownloadConfirmDialog(result.value);
    }
  }

  Future<void> _showDownloadConfirmDialog(GearSet gearSet) async {
    final items = gearSet.items ?? [];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => GearPreviewDialog(
        gearSet: gearSet,
        onAddToLibrary: (gearItems) async {
          await _addToGearLibrary(gearItems);
        },
      ),
    );

    if (confirmed == true) {
      final domainItems = items.map((m) => m.toDomain()).toList();
      await _importGearItems(domainItems);
      if (gearSet.meals != null && gearSet.meals!.isNotEmpty) {
        _importMeals(gearSet.meals!);
      }
    }
  }

  Future<void> _importMeals(List<DailyMealPlan> meals) async {
    try {
      context.read<MealCubit>().setDailyPlans(meals);
      ToastService.success('已匯入糧食計畫');
    } catch (e) {
      ToastService.error('匯入糧食失敗: $e');
    }
  }

  /// 將裝備加入我的裝備庫
  Future<void> _addToGearLibrary(List<GearItem> items) async {
    try {
      final libraryCubit = context.read<GearLibraryCubit>();
      int added = 0;
      for (final item in items) {
        await libraryCubit.addItem(
          name: item.name,
          weight: item.weight,
          category: item.category,
          // assuming library add item doesn't need ID, generates new one
        );
        added++;
      }
      ToastService.success('已加入 $added 件裝備到我的庫');
    } catch (e) {
      ToastService.error('加入失敗: $e');
    }
  }

  Future<void> _importGearItems(List<GearItem> items) async {
    try {
      final tripCubit = context.read<TripCubit>();
      final tripState = tripCubit.state;
      String? tripId;
      if (tripState is TripLoaded) {
        tripId = tripState.activeTrip?.id;
      }

      if (tripId == null) {
        ToastService.error('無法匯入：請先選擇行程');
        return;
      }

      // Use GearCubit to replace items
      await context.read<GearCubit>().replaceItems(items);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      ToastService.error('匯入失敗: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsCubit>().state;
    final isOffline = settingsState is SettingsLoaded && settingsState.isOfflineMode;

    return Scaffold(
      appBar: SummitAppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('☁️ 雲端裝備庫'),
            if (isOffline) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(12)),
                child: const Text('離線', style: TextStyle(fontSize: 12, color: Colors.white)),
              ),
            ],
          ],
        ),
      ),
      body: _buildBody(isOffline),
    );
  }

  Widget _buildBody(bool isOffline) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: TextStyle(color: Colors.red.shade600)),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _fetchGearSets, child: const Text('重試')),
          ],
        ),
      );
    }

    if (_gearSets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('尚無公開的裝備組合', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
            const SizedBox(height: 8),
            Text('成為第一個分享的人！', style: TextStyle(color: Colors.grey.shade500)),
            const SizedBox(height: 24),
            _buildToolbarCard(isOffline),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchGearSets,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildToolbarCard(isOffline),
                _buildSearchBar(),
                if (_filteredGearSets.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text('找不到相關結果', style: TextStyle(color: Colors.grey)),
                    ),
                  ),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: ResponsiveLayout.isDesktop(context)
                ? SliverGrid(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 500,
                      mainAxisExtent: 140,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildGearSetCard(index, isOffline),
                      childCount: _filteredGearSets.length,
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildGearSetCard(index, isOffline),
                      ),
                      childCount: _filteredGearSets.length,
                    ),
                  ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildGearSetCard(int index, bool isOffline) {
    final gearSet = _filteredGearSets[index];
    final isBusy = _busyGearSetId == gearSet.id;
    return _GearSetCard(
      gearSet: gearSet,
      isLoading: isBusy,
      onDownload: isBusy || isOffline ? null : () => _onDownloadPressed(gearSet),
      onDelete: gearSet.visibility == GearSetVisibility.public && !isBusy
          ? () => _confirmDeletePublicGearSet(gearSet)
          : null,
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜尋標題或作者...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Theme.of(context).cardColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        ),
        onChanged: (_) {
          setState(() {});
        },
      ),
    );
  }

  /// 工具列卡片 (包含所有操作)
  Widget _buildToolbarCard(bool isOffline) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // 第一行：同步、上傳
            Row(
              children: [
                // 同步按鈕
                Expanded(
                  child: _ToolButton(
                    icon: Icons.refresh,
                    label: '同步',
                    onTap: isOffline ? null : _fetchGearSets,
                    disabled: isOffline,
                  ),
                ),
                const SizedBox(width: 8),
                // 上傳
                Expanded(
                  child: _ToolButton(
                    icon: Icons.upload,
                    label: '上傳我的裝備',
                    onTap: isOffline ? null : _showUploadDialog,
                    disabled: isOffline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 第二行：我的 Keys、用 Key 下載
            Row(
              children: [
                // 我的 Keys
                Expanded(
                  child: _ToolButton(icon: Icons.key, label: '我的 Keys', onTap: _showMyKeysDialog),
                ),
                const SizedBox(width: 8),
                // 用 Key 下載
                Expanded(
                  child: _ToolButton(
                    icon: Icons.download,
                    label: '用 Key 下載',
                    onTap: isOffline ? null : _showKeyInputDialog,
                    disabled: isOffline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMyKeysDialog() async {
    final keys = await _repository.getUploadedKeys();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('🔑 我上傳的 Keys'),
        content: keys.isEmpty
            ? const Text('尚無上傳記錄', style: TextStyle(color: Colors.grey))
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: keys
                    .map(
                      (record) => ListTile(
                        leading: Text(
                          record.visibility == 'protected' ? '🔒' : '🔐',
                          style: const TextStyle(fontSize: 20),
                        ),
                        title: Text(
                          record.key,
                          style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                        subtitle: Text(record.title),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          tooltip: '刪除此組合',
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            _confirmDeleteGearSet(record);
                          },
                        ),
                      ),
                    )
                    .toList(),
              ),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('關閉'))],
      ),
    );
  }

  Future<void> _confirmDeleteGearSet(GearKeyRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ 確認刪除'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('確定要刪除「${record.title}」嗎？'),
            const SizedBox(height: 8),
            const Text(
              '此操作無法復原！',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('刪除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteGearSet(record);
    }
  }

  Future<void> _deleteGearSet(GearKeyRecord record) async {
    // 嘗試從雲端刪除 (需要透過 key 查詢 uuid)
    final fetchResult = await _repository.getGearSetByKey(record.key);

    // Check if fetch failed or data is null
    if (fetchResult is Failure<GearSet, Exception>) {
      ToastService.error('找不到此組合或已被刪除');
      return;
    }

    // Now we know it is Success due to flow, but safe cast
    if (fetchResult is Success<GearSet, Exception>) {
      // Safe to access value
    } else {
      // Fallback for analysis
      return;
    }

    // At this point we can access fetchResult.value
    final gearSet = fetchResult.value;
    final deleteResult = await _repository.deleteGearSet(gearSet.id, record.key);

    if (deleteResult is Success<bool, Exception>) {
      // 從本地儲存中也刪除記錄
      await _repository.removeUploadedKey(record.key);
      ToastService.success('已刪除裝備組合');
      _fetchGearSets(); // 刷新列表
    } else if (deleteResult is Failure<bool, Exception>) {
      ToastService.error(deleteResult.exception.toString());
    }
  }

  /// 確認刪除 public 裝備組合
  Future<void> _confirmDeletePublicGearSet(GearSet gearSet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ 確認刪除'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('確定要刪除「${gearSet.title}」嗎？'),
            const SizedBox(height: 8),
            const Text(
              '此操作無法復原！',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('刪除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // public 組合不需要 key
      final deleteResult = await _repository.deleteGearSet(gearSet.id, '');
      if (deleteResult is Success<bool, Exception>) {
        ToastService.success('已刪除裝備組合');
        _fetchGearSets(); // 刷新列表
      } else if (deleteResult is Failure<bool, Exception>) {
        ToastService.error(deleteResult.exception.toString());
      }
    }
  }

  void _onDownloadPressed(GearSet gearSet) {
    if (gearSet.visibility == GearSetVisibility.protected) {
      _showKeyInputForDownload(gearSet);
    } else {
      _downloadGearSet(gearSet);
    }
  }

  Future<void> _showKeyInputForDownload(GearSet gearSet) async {
    final key = await showDialog<String>(
      context: context,
      builder: (context) => GearKeyDownloadDialog(gearSet: gearSet),
    );

    if (key != null) {
      _downloadGearSet(gearSet, key: key);
    }
  }
}

/// 裝備組合卡片
class _GearSetCard extends StatelessWidget {
  final GearSet gearSet;
  final VoidCallback? onDownload;
  final VoidCallback? onDelete;
  final bool isLoading;

  const _GearSetCard({required this.gearSet, this.onDownload, this.onDelete, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(gearSet.visibilityIcon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(gearSet.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                Text('@${gearSet.author}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _InfoChip(icon: Icons.fitness_center, label: gearSet.formattedWeight),
                const SizedBox(width: 12),
                _InfoChip(icon: Icons.backpack, label: '${gearSet.itemCount} items'),
                const Spacer(),
                // public 組合顯示刪除按鈕
                if (gearSet.visibility == GearSetVisibility.public && onDelete != null) ...[
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    tooltip: '刪除此組合',
                    onPressed: onDelete,
                  ),
                  const SizedBox(width: 4),
                ],
                _buildDownloadButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadButton() {
    if (isLoading) {
      return const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (gearSet.visibility == GearSetVisibility.protected) {
      return OutlinedButton.icon(
        onPressed: onDownload,
        icon: const Icon(Icons.lock, size: 16),
        label: const Text('輸入 Key'),
      );
    }

    return FilledButton.icon(
      onPressed: onDownload,
      icon: const Icon(Icons.visibility, size: 16),
      label: const Text('查看'),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ],
    );
  }
}

/// 工具按鈕
class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool disabled;

  const _ToolButton({required this.icon, required this.label, this.onTap, this.disabled = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Opacity(
        opacity: disabled ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
