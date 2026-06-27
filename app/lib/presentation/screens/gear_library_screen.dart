import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../utils/gear_utils.dart';

import 'package:summitmate/domain/domain.dart';

import '../cubits/gear_library/gear_library_cubit.dart';
import '../cubits/gear_library/gear_library_state.dart';
import '../widgets/ads/banner_ad_widget.dart';
import '../widgets/common/summit_app_bar.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/gear/dialogs/gear_library_item_dialog.dart';
import '../widgets/gear/dialogs/gear_library_cloud_sync_dialog.dart';

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
      appBar: SummitAppBar(
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

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                children: [
                  _buildStatsCard(itemCount, totalWeightKg),
                  _buildSearchBar(context, state),
                  Expanded(
                    child: state.filteredItems.isEmpty
                        ? _buildEmptyState(state.items.isEmpty)
                        : _buildGearList(context, state),
                  ),
                  const SizedBox(height: 8),
                  const BannerAdWidget(location: 'gear_library'),
                  const SizedBox(height: 8),
                ],
              ),
            ),
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

    return ResponsiveLayout(
      mobile: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: itemsByCategory.length,
        itemBuilder: (context, index) {
          final category = itemsByCategory.keys.elementAt(index);
          final items = itemsByCategory[category]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCategoryHeader(category, items.length),
              ...items.map((item) => _buildGearCard(context, item)),
            ],
          );
        },
      ),
      desktop: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: itemsByCategory.entries.map((entry) {
            final category = entry.key;
            final items = entry.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCategoryHeader(category, items.length),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: items.map((item) => SizedBox(width: 360, child: _buildGearCard(context, item))).toList(),
                ),
                const SizedBox(height: 24),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(String category, int count) {
    return Padding(
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
          Text('($count)', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ],
      ),
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
                context.read<GearLibraryCubit>().toggleArchive(item.id);
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
      builder: (dialogContext) => GearLibraryItemDialog(
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
      builder: (dialogContext) => GearLibraryItemDialog(
        item: item,
        onSave: (name, weight, category, notes) async {
          final updatedItem = item.copyWith(name: name, weight: weight, category: category, notes: notes);
          await context.read<GearLibraryCubit>().updateItem(updatedItem);
          if (dialogContext.mounted) Navigator.pop(dialogContext);
        },
      ),
    );
  }

  void _showDeleteImpactDialog(BuildContext context, GearLibraryItem item) async {
    final cubit = context.read<GearLibraryCubit>();
    final linkedTrips = await cubit.getLinkedTrips(item.id);

    if (!context.mounted) return;

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
              await cubit.deleteItem(item.id);
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
              await context.read<GearLibraryCubit>().deleteItem(item.id);
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
    showDialog(context: context, builder: (context) => const GearLibraryCloudSyncDialog());
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
