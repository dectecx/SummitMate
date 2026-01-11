import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants.dart';
import '../../core/gear_helpers.dart';
import '../../data/models/gear_library_item.dart';
import '../../infrastructure/services/gear_library_cloud_service.dart';
import '../../infrastructure/tools/toast_service.dart';
import '../cubits/gear_library/gear_library_cubit.dart';
import '../cubits/gear_library/gear_library_state.dart';
import '../cubits/settings/settings_cubit.dart';
import '../cubits/settings/settings_state.dart';

/// 我的裝備庫畫面
///
/// 管理個人的裝備項目 (可新增、編輯、封存、刪除)。
/// 支援從雲端備份與還原。
class GearLibraryScreen extends StatefulWidget {
  const GearLibraryScreen({super.key});

  @override
  State<GearLibraryScreen> createState() => _GearLibraryScreenState();
}

class _GearLibraryScreenState extends State<GearLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎒 我的裝備庫'),
        actions: [IconButton(icon: const Icon(Icons.cloud_sync), tooltip: '雲端備份', onPressed: _showCloudSyncDialog)],
      ),
      body: BlocBuilder<GearLibraryCubit, GearLibraryState>(
        builder: (context, state) {
          if (state is GearLibraryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is GearLibraryError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(state.message, style: TextStyle(color: Colors.red.shade600)),
                  const SizedBox(height: 16),
                  OutlinedButton(onPressed: () => context.read<GearLibraryCubit>().reload(), child: const Text('重試')),
                ],
              ),
            );
          }

          if (state is! GearLibraryLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final itemCount = state.items.length;
          final totalWeightKg =
              state.items.where((i) => !i.isArchived).fold<double>(0, (sum, i) => sum + i.weight) / 1000.0;

          return Column(
            children: [
              _buildStatsCard(itemCount, totalWeightKg),
              _buildSearchBar(context, state),
              Expanded(
                child: state.filteredItems.isEmpty
                    ? _buildEmptyState(state.items.isEmpty)
                    : _buildGearList(context, state),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatsCard(int itemCount, double totalWeightKg) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(icon: Icons.backpack, label: '裝備數量', value: '$itemCount'),
            _StatItem(icon: Icons.fitness_center, label: '總重量', value: '${totalWeightKg.toStringAsFixed(2)} kg'),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, GearLibraryLoaded state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜尋裝備...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<GearLibraryCubit>().setSearchQuery('');
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Theme.of(context).cardColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        ),
        onChanged: (value) {
          context.read<GearLibraryCubit>().setSearchQuery(value);
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isReallyEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.backpack_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(isReallyEmpty ? '尚無裝備' : '找不到相關裝備', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          if (isReallyEmpty) ...[
            const SizedBox(height: 8),
            Text('點擊右下角 + 新增裝備', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ],
      ),
    );
  }

  Widget _buildGearList(BuildContext context, GearLibraryLoaded state) {
    final itemsByCategory = state.itemsByCategory;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemsByCategory.length,
      itemBuilder: (context, index) {
        final category = itemsByCategory.keys.elementAt(index);
        final items = itemsByCategory[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(_getCategoryIcon(category), size: 20, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    GearCategoryHelper.getName(category),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                  ),
                  const SizedBox(width: 8),
                  Text('(${items.length})', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            ...items.map((item) => _buildGearCard(context, item)),
          ],
        );
      },
    );
  }

  Widget _buildGearCard(BuildContext context, GearLibraryItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(item.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${item.weight.toStringAsFixed(0)}g • ${GearCategoryHelper.getName(item.category)}',
              style: TextStyle(color: item.isArchived ? Colors.grey : Colors.grey.shade600, fontSize: 12),
            ),
            if (item.isArchived)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                child: const Text('已封存', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEditDialog(context, item);
                break;
              case 'archive':
                context.read<GearLibraryCubit>().toggleArchive(item.uuid);
                break;
              case 'delete':
                _showDeleteImpactDialog(context, item);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('編輯')]),
            ),
            PopupMenuItem(
              value: 'archive',
              child: Row(
                children: [
                  Icon(item.isArchived ? Icons.unarchive : Icons.archive, size: 20),
                  const SizedBox(width: 8),
                  Text(item.isArchived ? '解除封存' : '封存'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('刪除', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Sleep':
        return Icons.bedtime;
      case 'Cook':
        return Icons.restaurant;
      case 'Wear':
        return Icons.checkroom;
      default:
        return Icons.inventory_2;
    }
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => _GearLibraryItemDialog(
        onSave: (name, weight, category, notes) async {
          await context.read<GearLibraryCubit>().addItem(name: name, weight: weight, category: category, notes: notes);
          if (dialogContext.mounted) Navigator.pop(dialogContext);
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, GearLibraryItem item) {
    showDialog(
      context: context,
      builder: (dialogContext) => _GearLibraryItemDialog(
        item: item,
        onSave: (name, weight, category, notes) async {
          item.name = name;
          item.weight = weight;
          item.category = category;
          item.notes = notes;
          await context.read<GearLibraryCubit>().updateItem(item);
          if (dialogContext.mounted) Navigator.pop(dialogContext);
        },
      ),
    );
  }

  void _showDeleteImpactDialog(BuildContext context, GearLibraryItem item) async {
    final cubit = context.read<GearLibraryCubit>();
    final linkedTrips = cubit.getLinkedTrips(item.uuid);

    if (linkedTrips.isEmpty) {
      _confirmDelete(context, item);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除警告'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '此項目目前被連結至 ${linkedTrips.length} 個行程中。刪除將會解除這些連結（行程中的裝備會保留，但變為獨立項目）。',
                style: const TextStyle(height: 1.5),
              ),
              const SizedBox(height: 16),
              const Text('受影響的行程：', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: linkedTrips.length > 5 ? 5 : linkedTrips.length,
                  itemBuilder: (ctx, index) {
                    final trip = linkedTrips[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.terrain, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text('${trip['tripName']}'),
                          const Spacer(),
                          Text(
                            (trip['startDate'] as DateTime).toString().split(' ')[0],
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await cubit.deleteItem(item.uuid);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('刪除並解除連結'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, GearLibraryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認刪除'),
        content: Text('確定要刪除「${item.name}」嗎？\n(此項目目前未被任何行程連結)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              await context.read<GearLibraryCubit>().deleteItem(item.uuid);
              if (context.mounted) Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
  }

  void _showCloudSyncDialog() {
    showDialog(context: context, builder: (context) => const _CloudSyncDialog());
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }
}

class _GearLibraryItemDialog extends StatefulWidget {
  final GearLibraryItem? item;
  final Future<void> Function(String name, double weight, String category, String? notes) onSave;

  const _GearLibraryItemDialog({this.item, required this.onSave});

  @override
  State<_GearLibraryItemDialog> createState() => _GearLibraryItemDialogState();
}

class _GearLibraryItemDialogState extends State<_GearLibraryItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _weightController;
  late final TextEditingController _notesController;
  late String _selectedCategory;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _weightController = TextEditingController(text: widget.item?.weight.toString() ?? '');
    _notesController = TextEditingController(text: widget.item?.notes ?? '');
    _selectedCategory = widget.item?.category ?? 'Other';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;

    return AlertDialog(
      title: Text(isEdit ? '編輯裝備' : '新增裝備'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '裝備名稱', hintText: '例如：睡袋'),
                validator: (v) => v == null || v.isEmpty ? '請輸入名稱' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(labelText: '重量 (公克)', hintText: '例如：500'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return '請輸入重量';
                  if (double.tryParse(v) == null) return '請輸入有效數字';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(labelText: '分類'),
                items: GearCategory.all
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(GearCategoryHelper.getName(cat))))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: '備註 (選填)', hintText: '例如：品牌、型號'),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isSaving ? null : () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(
          onPressed: _isSaving ? null : _handleSave,
          child: _isSaving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(isEdit ? '更新' : '新增'),
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await widget.onSave(
        _nameController.text.trim(),
        double.parse(_weightController.text),
        _selectedCategory,
        _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _CloudSyncDialog extends StatefulWidget {
  const _CloudSyncDialog();

  @override
  State<_CloudSyncDialog> createState() => _CloudSyncDialogState();
}

class _CloudSyncDialogState extends State<_CloudSyncDialog> {
  final _service = GearLibraryCloudService();
  bool _isLoading = false;
  String? _resultMessage;
  bool? _isSuccess;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('☁️ 雲端備份'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('將個人裝備庫與您的帳號同步。'),
            const SizedBox(height: 16),
            const Text(
              '【同步說明】\n• 上傳：覆蓋雲端資料 (以您的帳號儲存)\n• 下載：覆蓋本地資料',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            if (_resultMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isSuccess == true ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _isSuccess == true ? Colors.green.shade200 : Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSuccess == true ? Icons.check_circle : Icons.error,
                      color: _isSuccess == true ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        _resultMessage!,
                        style: TextStyle(
                          color: _isSuccess == true ? Colors.green.shade800 : Colors.red.shade800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: const Text('關閉')),
        OutlinedButton.icon(
          onPressed: _isLoading ? null : _handleDownload,
          icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.download),
          label: const Text('下載'),
        ),
        FilledButton.icon(
          onPressed: _isLoading ? null : _handleUpload,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.upload),
          label: const Text('上傳'),
        ),
      ],
    );
  }

  Future<void> _handleUpload() async {
    final settingsState = context.read<SettingsCubit>().state;
    final isOffline = settingsState is SettingsLoaded && settingsState.isOfflineMode;
    if (isOffline) {
      ToastService.warning('離線模式，無法上傳');
      return;
    }

    setState(() {
      _isLoading = true;
      _resultMessage = null;
    });

    try {
      final cubit = context.read<GearLibraryCubit>();
      final state = cubit.state;
      if (state is! GearLibraryLoaded) throw Exception('未載入裝備庫');
      final items = state.items;

      if (items.isEmpty) {
        setState(() {
          _isLoading = false;
          _isSuccess = false;
          _resultMessage = '裝備庫是空的，無法上傳';
        });
        return;
      }

      final result = await _service.syncLibrary(items);

      setState(() {
        _isLoading = false;
        _isSuccess = result.isSuccess;
        _resultMessage = result.isSuccess ? '成功上傳 ${result.data} 個裝備' : '上傳失敗: ${result.errorMessage}';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _resultMessage = '上傳失敗: $e';
      });
    }
  }

  Future<void> _handleDownload() async {
    final settingsState = context.read<SettingsCubit>().state;
    final isOffline = settingsState is SettingsLoaded && settingsState.isOfflineMode;
    if (isOffline) {
      ToastService.warning('離線模式，無法下載');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('確認下載'),
        content: const Text('下載將覆蓋本地裝備庫所有資料。\n\n確定要繼續嗎？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('確定下載'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _resultMessage = null;
    });

    try {
      final result = await _service.getLibrary();

      if (!result.isSuccess) {
        setState(() {
          _isLoading = false;
          _isSuccess = false;
          _resultMessage = '下載失敗: ${result.errorMessage}';
        });
        return;
      }

      if (!mounted) return;
      await context.read<GearLibraryCubit>().importItems(result.data!);

      setState(() {
        _isLoading = false;
        _isSuccess = true;
        _resultMessage = '成功下載 ${result.data!.length} 個裝備';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _resultMessage = '下載失敗: $e';
      });
    }
  }
}
