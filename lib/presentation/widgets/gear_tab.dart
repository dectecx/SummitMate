import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import '../../core/gear_helpers.dart';
import '../../services/toast_service.dart';
import '../providers/gear_provider.dart';
import '../providers/meal_provider.dart';
import '../screens/gear_cloud_screen.dart';
import '../screens/gear_library_screen.dart';
import '../screens/meal_planner_screen.dart';
import '../../data/models/gear_item.dart';

/// Tab 3: 裝備頁 (獨立頁籤)
class GearTab extends StatefulWidget {
  const GearTab({super.key});

  @override
  State<GearTab> createState() => _GearTabState();
}

class _GearTabState extends State<GearTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GearProvider>(
      builder: (context, provider, child) {
        final mealProvider = Provider.of<MealProvider>(context);
        final totalWeight = provider.totalWeightKg + mealProvider.totalWeightKg;

        return Scaffold(
          body: Column(
            children: [
              // 搜尋欄
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜尋本地裝備...',
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
              ),

              // 列表內容
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    // 官方建議裝備 + 雲端裝備庫 + 我的裝備庫 (並排)
                    Row(
                      children: [
                        // 官方建議裝備清單
                        Expanded(
                          child: Card(
                            child: InkWell(
                              onTap: () => _launchUrl(ExternalLinks.gearPdfUrl),
                              borderRadius: BorderRadius.circular(12),
                              child: const Padding(
                                padding: EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    Icon(Icons.description, color: Colors.green, size: 28),
                                    SizedBox(height: 8),
                                    Text('官方清單', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 雲端裝備庫 (分享用)
                        Expanded(
                          child: Card(
                            child: InkWell(
                              onTap: () =>
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const GearCloudScreen())),
                              borderRadius: BorderRadius.circular(12),
                              child: const Padding(
                                padding: EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    Icon(Icons.cloud, color: Colors.blue, size: 28),
                                    SizedBox(height: 8),
                                    Text('雲端庫', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 我的裝備庫 (個人)
                        Expanded(
                          child: Card(
                            child: InkWell(
                              onTap: () =>
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const GearLibraryScreen())),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    Icon(Icons.backpack, color: Colors.orange.shade700, size: 28),
                                    const SizedBox(height: 8),
                                    const Text('我的庫', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 總重量
                    Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('總重量 (含糧食)', style: TextStyle(fontSize: 18)),
                            Text(
                              '${totalWeight.toStringAsFixed(2)} kg',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 糧食計畫卡片
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () =>
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const MealPlannerScreen())),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.bento, color: Colors.orange, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('糧食計畫', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    Text(
                                      mealProvider.totalWeightKg > 0
                                          ? '已規劃 ${mealProvider.totalWeightKg.toStringAsFixed(2)} kg'
                                          : '尚未規劃',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 分類清單
                    if (provider.allItems.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.backpack_outlined, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('目前沒有自定義裝備', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      )
                    else
                      ...provider.itemsByCategory.entries.map(
                        (entry) => Card(
                          child: ExpansionTile(
                            maintainState: true,
                            initiallyExpanded: true,
                            leading: Icon(GearCategoryHelper.getIcon(entry.key)),
                            title: Text('${GearCategoryHelper.getName(entry.key)} (${entry.value.length}件)'),
                            subtitle: Text(
                              WeightFormatter.format(
                                entry.value.fold<double>(0, (sum, item) => sum + item.weight),
                                decimals: 0,
                              ),
                            ),
                            children: [
                              ReorderableListView(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                onReorder: (oldIndex, newIndex) {
                                  provider.reorderItem(oldIndex, newIndex, category: entry.key);
                                },
                                children: entry.value.map((item) {
                                  return ListTile(
                                    key: ValueKey(item.key),
                                    leading: Checkbox(
                                      value: item.isChecked,
                                      onChanged: (_) => provider.toggleChecked(item.key),
                                    ),
                                    title: Text(
                                      item.name,
                                      style: TextStyle(
                                        decoration: item.isChecked ? TextDecoration.lineThrough : null,
                                        color: item.isChecked ? Colors.grey : null,
                                      ),
                                    ),
                                    subtitle: Text('${item.weight.toStringAsFixed(0)}g'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                                          onPressed: () => _confirmDeleteGearItem(context, provider, item),
                                        ),
                                        const Icon(Icons.drag_handle, color: Colors.grey),
                                      ],
                                    ),
                                    onTap: () => provider.toggleChecked(item.key),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 80), // 底部留白
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddGearDialog(context, provider),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (e) {
      debugPrint('無法開啟連結: $e');
    }
  }

  void _confirmDeleteGearItem(BuildContext context, GearProvider provider, GearItem item) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('確認刪除'),
        content: Text('確定要刪除「${item.name}」嗎？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              provider.deleteItem(item.key);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
  }

  void _showAddGearDialog(BuildContext context, GearProvider provider) {
    final nameController = TextEditingController();
    final weightController = TextEditingController();
    String selectedCategory = 'Other';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => StatefulBuilder(
        builder: (innerContext, setState) {
          Future<bool> checkDismiss() async {
            final hasContent = nameController.text.isNotEmpty || weightController.text.isNotEmpty;
            if (!hasContent) return true;

            final confirm = await showDialog<bool>(
              context: dialogContext,
              builder: (ctx) => AlertDialog(
                title: const Text('捨棄裝備？'),
                content: const Text('您有未儲存的內容，確定要離開嗎？'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('繼續編輯')),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('捨棄'),
                  ),
                ],
              ),
            );
            return confirm ?? false;
          }

          return PopScope(
            canPop: false,
            onPopInvoked: (didPop) async {
              if (didPop) return;
              final shouldPop = await checkDismiss();
              if (shouldPop && dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: AlertDialog(
              title: const Text('新增裝備'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: '裝備名稱', hintText: '例如：睡袋'),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: weightController,
                      decoration: const InputDecoration(labelText: '重量 (公克)', hintText: '例如：1200'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(labelText: '分類'),
                      items: const [
                        DropdownMenuItem(value: 'Sleep', child: Text('睡眠系統')),
                        DropdownMenuItem(value: 'Cook', child: Text('炊具與飲食')),
                        DropdownMenuItem(value: 'Wear', child: Text('穿著')),
                        DropdownMenuItem(value: 'Other', child: Text('其他')),
                      ],
                      onChanged: (value) => setState(() => selectedCategory = value!),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    final shouldPop = await checkDismiss();
                    if (shouldPop && dialogContext.mounted) Navigator.pop(dialogContext);
                  },
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final weight = double.tryParse(weightController.text) ?? 0;
                    if (name.isNotEmpty && weight > 0) {
                      provider.addItem(name: name, weight: weight, category: selectedCategory);
                      if (context.mounted) ToastService.success('已新增：$name');
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('新增'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
