import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/gear_set.dart';
import '../../data/models/gear_item.dart';
import '../../data/repositories/gear_repository.dart';
import '../../services/gear_cloud_service.dart';
import '../../services/toast_service.dart';
import '../providers/settings_provider.dart';
import '../widgets/gear_upload_dialog.dart';
import '../widgets/gear_key_dialog.dart';
import '../widgets/gear_key_download_dialog.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchGearSets();
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
    final gearRepo = GearRepository();
    await gearRepo.init();

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
    final result = await _cloudService.downloadGearSet(gearSet.uuid, key: key);

    if (!result.success || result.data?.items == null) {
      ToastService.error(result.errorMessage ?? '下載失敗');
      return;
    }

    if (!mounted) return;
    _showDownloadConfirmDialog(result.data!);
  }

  Future<void> _showDownloadConfirmDialog(GearSet gearSet) async {
    final items = gearSet.items ?? [];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('下載「${gearSet.title}」？'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('作者: @${gearSet.author}'),
            Text('重量: ${gearSet.formattedWeight}'),
            Text('裝備: ${items.length} 件'),
            const SizedBox(height: 16),
            const Text(
              '下載將覆蓋您目前的裝備清單，確定要繼續嗎？',
              style: TextStyle(color: Colors.orange),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('下載並覆蓋'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _importGearItems(items);
    }
  }

  Future<void> _importGearItems(List<GearItem> items) async {
    try {
      final gearRepo = GearRepository();
      await gearRepo.init();

      // 清除現有裝備
      await gearRepo.clearAll();

      // 匯入新裝備
      for (final item in items) {
        await gearRepo.addItem(GearItem(
          name: item.name,
          weight: item.weight,
          category: item.category,
          isChecked: false,
        ));
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
      appBar: AppBar(
        title: const Text('☁️ 雲端裝備庫'),
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
            OutlinedButton(
              onPressed: _fetchGearSets,
              child: const Text('重試'),
            ),
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
            Text(
              '尚無公開的裝備組合',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '成為第一個分享的人！',
              style: TextStyle(color: Colors.grey.shade500),
            ),
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
        itemCount: _gearSets.length + 1, // +1 for the toolbar card
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildToolbarCard(isOffline);
          }
          final gearSet = _gearSets[index - 1];
          return _GearSetCard(
            gearSet: gearSet,
            onDownload: () => _onDownloadPressed(gearSet),
          );
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
            // 第一行：同步、我的 Keys
            Row(
              children: [
                // 同步按鈕
                Expanded(
                  child: _ToolButton(
                    icon: Icons.refresh,
                    label: '同步',
                    onTap: _fetchGearSets,
                  ),
                ),
                const SizedBox(width: 8),
                // 我的 Keys
                Expanded(
                  child: _ToolButton(
                    icon: Icons.key,
                    label: '我的 Keys',
                    onTap: _showMyKeysDialog,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 第二行：用 Key 下載、上傳
            Row(
              children: [
                // 用 Key 下載
                Expanded(
                  child: _ToolButton(
                    icon: Icons.download,
                    label: '用 Key 下載',
                    onTap: _showKeyInputDialog,
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
      builder: (context) => AlertDialog(
        title: const Text('🔑 我上傳的 Keys'),
        content: keys.isEmpty
            ? const Text('尚無上傳記錄', style: TextStyle(color: Colors.grey))
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: keys.map((record) => ListTile(
                  leading: Text(
                    record.visibility == 'protected' ? '🔒' : '🔐',
                    style: const TextStyle(fontSize: 20),
                  ),
                  title: Text(record.key, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 20)),
                  subtitle: Text(record.title),
                )).toList(),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
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
  final VoidCallback onDownload;

  const _GearSetCard({
    required this.gearSet,
    required this.onDownload,
  });

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
                Text(
                  gearSet.visibilityIcon,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    gearSet.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '@${gearSet.author}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.fitness_center,
                  label: gearSet.formattedWeight,
                ),
                const SizedBox(width: 12),
                _InfoChip(
                  icon: Icons.backpack,
                  label: '${gearSet.itemCount} items',
                ),
                const Spacer(),
                _buildDownloadButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadButton() {
    if (gearSet.visibility == GearSetVisibility.protected) {
      return OutlinedButton.icon(
        onPressed: onDownload,
        icon: const Icon(Icons.lock, size: 16),
        label: const Text('輸入 Key'),
      );
    }

    return FilledButton.icon(
      onPressed: onDownload,
      icon: const Icon(Icons.download, size: 16),
      label: const Text('下載'),
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
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
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

  const _ToolButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.disabled = false,
  });

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
