import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/di.dart';
import '../../data/models/gear_set.dart';
import '../../data/models/gear_item.dart';
import '../../data/repositories/interfaces/i_gear_repository.dart';
import '../../services/gear_cloud_service.dart';
import '../../services/toast_service.dart';
import '../providers/settings_provider.dart';
import '../providers/gear_provider.dart';
import '../providers/gear_library_provider.dart';
import '../providers/trip_provider.dart';
import '../widgets/gear_upload_dialog.dart';
import '../widgets/gear_key_dialog.dart';
import '../widgets/gear_key_download_dialog.dart';
import '../widgets/gear_preview_dialog.dart';

/// 雲端裝備庫畫面
class GearCloudScreen extends StatefulWidget {
  const GearCloudScreen({super.key});

  @override
  State<GearCloudScreen> createState() => _GearCloudScreenState();
}

class _GearCloudScreenState extends State<GearCloudScreen> {
  final GearCloudService _cloudService = GearCloudService();
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

  @override
  void initState() {
    super.initState();
    _fetchGearSets();
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

    final result = await _cloudService.fetchGearSets();

    setState(() {
      _isLoading = false;
      if (result.success) {
        _gearSets = result.data ?? [];
      } else {
        _errorMessage = result.errorMessage;
      }
    });
  }

  Future<void> _showUploadDialog() async {
    final settingsProvider = context.read<SettingsProvider>();
    final gearRepo = getIt<IGearRepository>();

    final items = gearRepo.getAllItems();
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
        author: settingsProvider.username,
        onUpload: (title, visibility, key) async {
          final uploadResult = await _cloudService.uploadGearSet(
            tripId: context.read<TripProvider>().activeTripId ?? '',
            title: title,
            author: settingsProvider.username,
            visibility: visibility,
            items: items,
            key: key,
          );

          if (uploadResult.success) {
            uploadedKey = key;
            uploadedTitle = title;
            uploadedVisibility = visibility;
            ToastService.success('上傳成功！');
            return true;
          } else {
            ToastService.error(uploadResult.errorMessage ?? '上傳失敗');
            return false;
          }
        },
      ),
    );

    if (result == true) {
      // 儲存 Key 到本地 (如果有設定)
      if (uploadedKey != null && uploadedKey!.isNotEmpty) {
        await GearKeyStorage.saveUploadedKey(uploadedKey!, uploadedTitle ?? '', uploadedVisibility?.name ?? '');
      }
      _fetchGearSets();
    }
  }

  Future<void> _showKeyInputDialog() async {
    final result = await showDialog<GearSet?>(
      context: context,
      builder: (context) => GearKeyInputDialog(cloudService: _cloudService),
    );

    if (result != null && mounted) {
      _showDownloadConfirmDialog(result);
    }
  }

  Future<void> _downloadGearSet(GearSet gearSet, {String? key}) async {
    // 防止連續點擊
    if (_busyGearSetId != null) return;
    setState(() => _busyGearSetId = gearSet.uuid);

    final result = await _cloudService.downloadGearSet(gearSet.uuid, key: key);

    if (!mounted) return;
    setState(() => _busyGearSetId = null);

    if (!result.success || result.data?.items == null) {
      ToastService.error(result.errorMessage ?? '查詢失敗');
      return;
    }

    _showDownloadConfirmDialog(result.data!);
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
      await _importGearItems(items);
    }
  }

  /// 將裝備加入我的裝備庫
  Future<void> _addToGearLibrary(List<GearItem> items) async {
    try {
      final libraryProvider = context.read<GearLibraryProvider>();
      int added = 0;
      for (final item in items) {
        await libraryProvider.addItem(name: item.name, weight: item.weight, category: item.category);
        added++;
      }
      ToastService.success('已加入 $added 件裝備到我的庫');
    } catch (e) {
      ToastService.error('加入失敗: $e');
    }
  }

  Future<void> _importGearItems(List<GearItem> items) async {
    try {
      // 使用 DI 容器中的 Repository
      final gearRepo = getIt<IGearRepository>();
      final tripId = context.read<TripProvider>().activeTripId;

      if (tripId == null) {
        ToastService.error('無法匯入：請先選擇行程');
        return;
      }

      // 清除現有裝備 (只清除當前行程的)
      await gearRepo.clearByTripId(tripId);

      // 匯入新裝備 (帶入當前 tripId)
      for (final item in items) {
        await gearRepo.addItem(
          GearItem(
            tripId: tripId,
            name: item.name,
            weight: item.weight,
            category: item.category,
            isChecked: false,
          ),
        );
      }

      // 刷新 GearProvider 以同步 UI
      if (mounted) {
        context.read<GearProvider>().reload();
      }

      ToastService.success('已匯入 ${items.length} 件裝備');
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      ToastService.error('匯入失敗: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = context.watch<SettingsProvider>().isOfflineMode;

    return Scaffold(
      appBar: AppBar(title: const Text('☁️ 雲端裝備庫')),
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
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredGearSets.length + 2, // +1 toolbar, +1 search bar
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildToolbarCard(isOffline);
          }
          if (index == 1) {
            return _buildSearchBar();
          }

          if (_filteredGearSets.isEmpty) {
            return const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(
                child: Text('找不到相關結果', style: TextStyle(color: Colors.grey)),
              ),
            );
          }

          final gearSet = _filteredGearSets[index - 2];
          final isBusy = _busyGearSetId == gearSet.uuid;
          return _GearSetCard(
            gearSet: gearSet,
            isLoading: isBusy,
            onDownload: isBusy ? null : () => _onDownloadPressed(gearSet),
            onDelete: gearSet.visibility == GearSetVisibility.public && !isBusy
                ? () => _confirmDeletePublicGearSet(gearSet)
                : null,
          );
        },
      ),
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
                  child: _ToolButton(icon: Icons.refresh, label: '同步', onTap: _fetchGearSets),
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
                  child: _ToolButton(icon: Icons.download, label: '用 Key 下載', onTap: _showKeyInputDialog),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMyKeysDialog() async {
    final keys = await GearKeyStorage.getUploadedKeys();
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
    final fetchResult = await _cloudService.fetchGearSetByKey(record.key);
    if (!fetchResult.success || fetchResult.data == null) {
      ToastService.error('找不到此組合或已被刪除');
      return;
    }

    final gearSet = fetchResult.data!;
    final deleteResult = await _cloudService.deleteGearSet(gearSet.uuid, record.key);

    if (deleteResult.success) {
      // 從本地儲存中也刪除記錄
      await GearKeyStorage.removeUploadedKey(record.key);
      ToastService.success('已刪除裝備組合');
      _fetchGearSets(); // 刷新列表
    } else {
      ToastService.error(deleteResult.errorMessage ?? '刪除失敗');
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
      final deleteResult = await _cloudService.deleteGearSet(gearSet.uuid, '');
      if (deleteResult.success) {
        ToastService.success('已刪除裝備組合');
        _fetchGearSets(); // 刷新列表
      } else {
        ToastService.error(deleteResult.errorMessage ?? '刪除失敗');
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
