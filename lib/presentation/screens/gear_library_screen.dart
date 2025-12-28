import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../data/models/gear_library_item.dart';
import '../providers/gear_library_provider.dart';

/// 個人裝備庫畫面
///
/// 管理個人裝備的 CRUD 操作
/// 可透過 owner_key 備份到雲端
///
/// 【未來規劃】
/// - 會員機制上線後改用 user_id
/// - 自動同步，移除 key 輸入
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
        actions: [
          // 雲端備份按鈕
          IconButton(
            icon: const Icon(Icons.cloud_sync),
            tooltip: '雲端備份',
            onPressed: _showCloudSyncDialog,
          ),
        ],
      ),
      body: Consumer<GearLibraryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(provider.error!, style: TextStyle(color: Colors.red.shade600)),
                  const SizedBox(height: 16),
                  OutlinedButton(onPressed: provider.reload, child: const Text('重試')),
                ],
              ),
            );
          }

          return Column(
            children: [
              // 統計資訊
              _buildStatsCard(provider),

              // 搜尋欄
              _buildSearchBar(provider),

              // 裝備列表
              Expanded(
                child: provider.filteredItems.isEmpty
                    ? _buildEmptyState(provider.allItems.isEmpty)
                    : _buildGearList(provider),
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

  Widget _buildStatsCard(GearLibraryProvider provider) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              icon: Icons.backpack,
              label: '裝備數量',
              value: '${provider.itemCount}',
            ),
            _StatItem(
              icon: Icons.fitness_center,
              label: '總重量',
              value: '${provider.totalWeightKg.toStringAsFixed(2)} kg',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(GearLibraryProvider provider) {
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
                    provider.setSearchQuery('');
                    setState(() {});
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Theme.of(context).cardColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        ),
        onChanged: (value) {
          provider.setSearchQuery(value);
          setState(() {});
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
          Text(
            isReallyEmpty ? '尚無裝備' : '找不到相關裝備',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          if (isReallyEmpty) ...[
            const SizedBox(height: 8),
            Text('點擊右下角 + 新增裝備', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ],
      ),
    );
  }

  Widget _buildGearList(GearLibraryProvider provider) {
    final itemsByCategory = provider.itemsByCategory;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemsByCategory.length,
      itemBuilder: (context, index) {
        final category = itemsByCategory.keys.elementAt(index);
        final items = itemsByCategory[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 分類標題
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(_getCategoryIcon(category), size: 20, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    category,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${items.length})',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            // 裝備列表
            ...items.map((item) => _buildGearCard(item, provider)),
          ],
        );
      },
    );
  }

  Widget _buildGearCard(GearLibraryItem item, GearLibraryProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(item.name),
        subtitle: Text(
          '${item.weight}g • ${item.category}',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => _showEditDialog(context, item),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade400),
              onPressed: () => _confirmDelete(context, item, provider),
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
      builder: (context) => _GearLibraryItemDialog(
        onSave: (name, weight, category, notes) async {
          final provider = context.read<GearLibraryProvider>();
          await provider.addItem(name: name, weight: weight, category: category, notes: notes);
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, GearLibraryItem item) {
    showDialog(
      context: context,
      builder: (context) => _GearLibraryItemDialog(
        item: item,
        onSave: (name, weight, category, notes) async {
          item.name = name;
          item.weight = weight;
          item.category = category;
          item.notes = notes;
          final provider = context.read<GearLibraryProvider>();
          await provider.updateItem(item);
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, GearLibraryItem item, GearLibraryProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認刪除'),
        content: Text('確定要刪除「${item.name}」嗎？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              await provider.deleteItem(item.uuid);
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
    showDialog(
      context: context,
      builder: (context) => const _CloudSyncDialog(),
    );
  }
}

// ============================================================
// 統計項目元件
// ============================================================

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

// ============================================================
// 裝備新增/編輯 Dialog
// ============================================================

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
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: '分類'),
                items: GearCategory.all
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
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
          child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(isEdit ? '更新' : '新增'),
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

// ============================================================
// 雲端同步 Dialog (Placeholder)
// ============================================================

class _CloudSyncDialog extends StatefulWidget {
  const _CloudSyncDialog();

  @override
  State<_CloudSyncDialog> createState() => _CloudSyncDialogState();
}

class _CloudSyncDialogState extends State<_CloudSyncDialog> {
  final _keyController = TextEditingController();

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('☁️ 雲端備份'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('使用 4 位數密碼備份/還原裝備庫'),
          const SizedBox(height: 16),
          TextField(
            controller: _keyController,
            decoration: const InputDecoration(
              labelText: '密碼 (4 位數)',
              hintText: '例如：1234',
              counterText: '',
            ),
            maxLength: 4,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          Text(
            '【未來規劃】會員機制上線後將自動識別帳號',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        OutlinedButton.icon(
          onPressed: () {
            // TODO: 實作下載
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('下載功能開發中...')),
            );
          },
          icon: const Icon(Icons.download),
          label: const Text('下載'),
        ),
        FilledButton.icon(
          onPressed: () {
            // TODO: 實作上傳
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('上傳功能開發中...')),
            );
          },
          icon: const Icon(Icons.upload),
          label: const Text('上傳'),
        ),
      ],
    );
  }
}
