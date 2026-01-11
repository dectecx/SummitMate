import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../core/gear_helpers.dart';
import '../../infrastructure/tools/toast_service.dart';
import '../cubits/gear/gear_cubit.dart';
import '../cubits/gear/gear_state.dart';
import '../cubits/gear_library/gear_library_cubit.dart';
import '../cubits/gear_library/gear_library_state.dart';
import '../cubits/trip/trip_cubit.dart';
import '../cubits/trip/trip_state.dart';
// import '../providers/meal_provider.dart'; // Removed
import '../cubits/meal/meal_cubit.dart';
import '../cubits/meal/meal_state.dart';
import '../screens/gear_cloud_screen.dart';
import '../screens/gear_library_screen.dart';
import '../screens/meal_planner_screen.dart';
import '../../data/models/gear_item.dart';
import '../../data/models/gear_library_item.dart';

enum GearListMode { view, edit, sort }

class GearTab extends StatefulWidget {
  final String? tripId;
  const GearTab({super.key, this.tripId});

  @override
  State<GearTab> createState() => _GearTabState();
}

class _GearTabState extends State<GearTab> {
  final TextEditingController _searchController = TextEditingController();
  GearListMode _mode = GearListMode.view;

  @override
  void initState() {
    super.initState();
    _loadGear();
  }

  void _loadGear() {
    final tripCubit = context.read<TripCubit>();
    String? targetId = widget.tripId;

    if (targetId == null && tripCubit.state is TripLoaded) {
      targetId = (tripCubit.state as TripLoaded).activeTrip?.id;
    }

    if (targetId != null) {
      context.read<GearCubit>().loadGear(targetId);
    }
  }

  @override
  void didUpdateWidget(GearTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tripId != oldWidget.tripId) {
      _loadGear();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final mealProvider = context.watch<MealProvider>(); // Removed
    final mealState = context.watch<MealCubit>().state;
    final mealWeight = mealState is MealLoaded ? mealState.totalWeightKg : 0.0;

    return MultiBlocListener(
      listeners: [
        BlocListener<TripCubit, TripState>(
          listener: (context, state) {
            if (state is TripLoaded && widget.tripId == null) {
              // If trip changes and we are tracking active trip, reload
              final activeTripId = state.activeTrip?.id;
              if (activeTripId != null && context.read<GearCubit>().currentTripId != activeTripId) {
                context.read<GearCubit>().loadGear(activeTripId);
              }
            }
          },
        ),
      ],
      child: BlocBuilder<GearCubit, GearState>(
        builder: (context, state) {
          final totalWeight = (state is GearLoaded ? state.totalWeightKg : 0.0) + mealWeight;

          // Checking loading state is tricky because we might want to show previous data while reloading?
          // Assuming GearState tracks loading.
          if (state is GearInitial) {
            // Try load again if initial (e.g. came from background)
            _loadGear();
            return const Center(child: CircularProgressIndicator());
          }

          if (state is GearLoading && (state as dynamic).items == null) {
            // Ideally GearLoading shouldn't wipe data if re-loading.
            // Our GearLoading is failing to preserve data in copyWith?
            // No, GearLoading is a separate class.
            // If we want to show loading over content, we need stack or similar.
            // For now, full page loader if items implies empty?
            // Let's just show indicator if Items are empty.
            return const Center(child: CircularProgressIndicator());
          }

          if (state is GearError) {
            return Center(child: Text('Error: ${state.message}'));
          }

          if (state is! GearLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

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
                                context.read<GearCubit>().setSearchQuery('');
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
                      context.read<GearCubit>().setSearchQuery(value);
                      setState(() {});
                    },
                  ),
                ),

                // 模式切換器
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  child: SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<GearListMode>(
                      segments: const [
                        ButtonSegment(
                          value: GearListMode.view,
                          icon: Icon(Icons.visibility_outlined),
                          label: Text('檢視'),
                        ),
                        ButtonSegment(value: GearListMode.edit, icon: Icon(Icons.edit_outlined), label: Text('編輯')),
                        ButtonSegment(value: GearListMode.sort, icon: Icon(Icons.sort), label: Text('排序')),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (Set<GearListMode> newSelection) {
                        setState(() {
                          _mode = newSelection.first;
                        });
                      },
                      showSelectedIcon: false,
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

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
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const GearLibraryScreen()),
                                ),
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
                                        mealWeight > 0 ? '已規劃 ${mealWeight.toStringAsFixed(2)} kg' : '尚未規劃',
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
                      if (state.items.isEmpty)
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
                        ...state.itemsByCategory.entries.map(
                          (entry) => Card(
                            child: ExpansionTile(
                              maintainState: true,
                              initiallyExpanded: true,
                              leading: Icon(GearCategoryHelper.getIcon(entry.key)),
                              title: Text('${GearCategoryHelper.getName(entry.key)} (${entry.value.length}件)'),
                              subtitle: Text(
                                WeightFormatter.format(
                                  entry.value.fold<double>(0, (sum, item) => sum + item.totalWeight),
                                  decimals: 0,
                                ),
                              ),
                              children: [
                                ReorderableListView(
                                  buildDefaultDragHandles: false,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  onReorder: (oldIndex, newIndex) {
                                    context.read<GearCubit>().reorderItem(oldIndex, newIndex, category: entry.key);
                                  },
                                  children: entry.value.map((item) {
                                    return ListTile(
                                      key: ValueKey(item.key),
                                      leading: _mode == GearListMode.view
                                          ? Checkbox(
                                              value: item.isChecked,
                                              onChanged: (_) => context.read<GearCubit>().toggleChecked(item.key),
                                            )
                                          : null,
                                      title: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              item.name,
                                              style: TextStyle(
                                                decoration: item.isChecked ? TextDecoration.lineThrough : null,
                                                color: item.isChecked ? Colors.grey : null,
                                                fontSize: 16,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (item.quantity > 1) ...[
                                            const SizedBox(width: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'x${item.quantity}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.blue,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                          if (item.libraryItemId != null && _mode == GearListMode.view) ...[
                                            const SizedBox(width: 4),
                                            const Icon(Icons.link, size: 16, color: Colors.blue),
                                          ],
                                        ],
                                      ),
                                      subtitle: _mode == GearListMode.view
                                          ? Text(
                                              '${item.totalWeight.toStringAsFixed(0)}g${item.quantity > 1 ? ' (${item.weight.toStringAsFixed(0)}g×${item.quantity})' : ''}',
                                            )
                                          : null,
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (_mode == GearListMode.edit) ...[
                                            IconButton(
                                              icon: const Icon(
                                                Icons.remove_circle_outline,
                                                size: 24,
                                                color: Colors.grey,
                                              ),
                                              onPressed: item.quantity > 1
                                                  ? () => context.read<GearCubit>().updateQuantity(
                                                      item,
                                                      item.quantity - 1,
                                                    )
                                                  : null,
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                            SizedBox(
                                              width: 32,
                                              child: Text(
                                                '${item.quantity}',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.add_circle_outline, size: 24, color: Colors.blue),
                                              onPressed: () =>
                                                  context.read<GearCubit>().updateQuantity(item, item.quantity + 1),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                            const SizedBox(width: 12),
                                            IconButton(
                                              icon: const Icon(Icons.edit, size: 24, color: Colors.blueGrey),
                                              onPressed: () => _showEditGearDialog(context, item),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, size: 24, color: Colors.red),
                                              onPressed: () => _confirmDeleteGearItem(context, item),
                                            ),
                                          ],
                                          if (_mode == GearListMode.sort)
                                            ReorderableDragStartListener(
                                              index: entry.value.indexOf(item),
                                              child: const Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: Icon(Icons.drag_handle, color: Colors.grey, size: 28),
                                              ),
                                            ),
                                        ],
                                      ),
                                      onTap: _mode == GearListMode.view
                                          ? () => context.read<GearCubit>().toggleChecked(item.key)
                                          : null,
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => _showAddGearDialog(context),
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
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

  void _confirmDeleteGearItem(BuildContext context, GearItem item) {
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
              context.read<GearCubit>().deleteItem(item.key);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
  }

  void _showAddGearDialog(BuildContext context) {
    // Need access to GearLibraryCubit state, assume loaded in App.
    final nameController = TextEditingController();
    final weightController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final focusNode = FocusNode();
    String selectedCategory = 'Other';
    GearLibraryItem? linkedItem;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => BlocBuilder<GearLibraryCubit, GearLibraryState>(
        builder: (context, libraryState) {
          List<GearLibraryItem> availableItems = [];
          if (libraryState is GearLibraryLoaded) {
            availableItems = libraryState.availableItems;
          }

          return StatefulBuilder(
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
                onPopInvokedWithResult: (didPop, result) async {
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
                        // 名稱輸入 (支援 Autocomplete)
                        RawAutocomplete<GearLibraryItem>(
                          textEditingController: nameController,
                          focusNode: focusNode,
                          optionsBuilder: (textValue) {
                            if (textValue.text.isEmpty) return const Iterable.empty();
                            return availableItems.where(
                              (e) => e.name.toLowerCase().contains(textValue.text.toLowerCase()),
                            );
                          },
                          displayStringForOption: (item) => item.name,
                          onSelected: (item) {
                            setState(() {
                              weightController.text = item.weight.toStringAsFixed(0);
                              selectedCategory = item.category;
                              linkedItem = item;
                            });
                          },
                          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              onSubmitted: (val) => onFieldSubmitted(),
                              decoration: InputDecoration(
                                labelText: '裝備名稱',
                                hintText: '輸入名稱搜尋裝備庫...',
                                suffixIcon: linkedItem != null
                                    ? IconButton(
                                        icon: const Icon(Icons.link_off, color: Colors.red),
                                        tooltip: '解除連結',
                                        onPressed: () {
                                          setState(() {
                                            linkedItem = null;
                                          });
                                        },
                                      )
                                    : null,
                              ),
                              autofocus: true,
                              onChanged: (val) {
                                if (linkedItem != null && val != linkedItem!.name) {
                                  setState(() => linkedItem = null);
                                }
                              },
                            );
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4,
                                child: SizedBox(
                                  width: 300,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(maxHeight: 200),
                                    child: ListView.builder(
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      itemCount: options.length,
                                      itemBuilder: (context, index) {
                                        final item = options.elementAt(index);
                                        return ListTile(
                                          title: Text(item.name),
                                          subtitle: Text(
                                            '${item.weight.toStringAsFixed(0)}g - ${GearCategoryHelper.getName(item.category)}',
                                          ),
                                          onTap: () => onSelected(item),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: weightController,
                          decoration: const InputDecoration(labelText: '重量 (公克)', hintText: '例如：1200'),
                          keyboardType: TextInputType.number,
                          enabled: linkedItem == null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: selectedCategory,
                          decoration: const InputDecoration(labelText: '分類'),
                          items: const [
                            DropdownMenuItem(value: 'Sleep', child: Text('睡眠系統')),
                            DropdownMenuItem(value: 'Cook', child: Text('炊具與飲食')),
                            DropdownMenuItem(value: 'Wear', child: Text('穿著')),
                            DropdownMenuItem(value: 'Other', child: Text('其他')),
                          ],
                          onChanged: linkedItem == null ? (value) => setState(() => selectedCategory = value!) : null,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: quantityController,
                          decoration: const InputDecoration(labelText: '數量', hintText: '1'),
                          keyboardType: TextInputType.number,
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
                      onPressed: () async {
                        final name = nameController.text.trim();
                        final weight = double.tryParse(weightController.text) ?? 0;

                        if (name.isNotEmpty && weight > 0) {
                          if (linkedItem == null && availableItems.isNotEmpty) {
                            try {
                              final match = availableItems.firstWhere(
                                (item) => item.name.toLowerCase() == name.toLowerCase(),
                              );
                              final wantLink = await showDialog<bool>(
                                context: dialogContext,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('發現庫存裝備'),
                                  content: Text('裝備庫中已有「${match.name}」(${match.weight}g)。\n是否直接連結此項目？'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('建立獨立裝備')),
                                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('連結')),
                                  ],
                                ),
                              );

                              if (wantLink == true) {
                                setState(() {
                                  linkedItem = match;
                                  nameController.text = match.name;
                                  weightController.text = match.weight.toStringAsFixed(0);
                                  selectedCategory = match.category;
                                });
                                return;
                              }
                            } catch (_) {}
                          }

                          if (!context.mounted) return;
                          context.read<GearCubit>().addItem(
                            name: name,
                            weight: weight,
                            category: selectedCategory,
                            libraryItemId: linkedItem?.id,
                            quantity: int.tryParse(quantityController.text) ?? 1,
                          );

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
          );
        }, // BlocBuilder builder
      ), // BlocBuilder
    );
  }

  void _showEditGearDialog(BuildContext context, GearItem item) {
    final nameController = TextEditingController(text: item.name);
    final weightController = TextEditingController(text: item.weight.toStringAsFixed(0));
    int editQuantity = item.quantity;
    String selectedCategory = item.category;
    String? libraryItemId = item.libraryItemId;

    // Access GearLibraryCubit state to check linkage validity
    final libraryState = context.read<GearLibraryCubit>().state;
    // Helper to check linkage
    bool isLinked = false;
    if (libraryItemId != null && libraryState is GearLibraryLoaded) {
      // Check if library item exists
      if (libraryState.items.any((i) => i.id == libraryItemId)) {
        isLinked = true;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (innerContext, setState) {
          return AlertDialog(
            title: const Text('編輯裝備'),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLinked)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.link, size: 20, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text('已連結至裝備庫。規格欄位鎖定，解除連結後可編輯。', style: TextStyle(fontSize: 12, color: Colors.blue)),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                libraryItemId = null;
                                isLinked = false;
                              });
                            },
                            child: const Text('解除連結'),
                          ),
                        ],
                      ),
                    ),

                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: '名稱'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: weightController,
                    decoration: const InputDecoration(labelText: '重量 (公克)'),
                    keyboardType: TextInputType.number,
                    enabled: !isLinked,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(labelText: '分類'),
                    items: const [
                      DropdownMenuItem(value: 'Sleep', child: Text('睡眠系統')),
                      DropdownMenuItem(value: 'Cook', child: Text('炊具與飲食')),
                      DropdownMenuItem(value: 'Wear', child: Text('穿著')),
                      DropdownMenuItem(value: 'Other', child: Text('其他')),
                    ],
                    onChanged: !isLinked ? (value) => setState(() => selectedCategory = value!) : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('數量', style: TextStyle(fontSize: 16)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                        onPressed: editQuantity > 1 ? () => setState(() => editQuantity--) : null,
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '$editQuantity',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                        onPressed: () => setState(() => editQuantity++),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('取消')),
              FilledButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final weight = double.tryParse(weightController.text) ?? 0;

                  if (name.isNotEmpty && weight > 0) {
                    item.name = name;
                    if (!isLinked) {
                      item.weight = weight;
                      item.category = selectedCategory;
                    }
                    item.quantity = editQuantity;
                    item.libraryItemId = libraryItemId;

                    // We need to call updateItem on Cubit to persist and refresh UI
                    context.read<GearCubit>().updateItem(item);

                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  }
                },
                child: const Text('儲存'),
              ),
            ],
          );
        },
      ),
    );
  }
}
