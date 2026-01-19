import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/gear_helpers.dart';
import '../../../../data/models/gear_library_item.dart';
import '../../../../infrastructure/tools/toast_service.dart';
import '../../../cubits/gear/gear_cubit.dart';
import '../../../cubits/gear_library/gear_library_cubit.dart';
import '../../../cubits/gear_library/gear_library_state.dart';

/// 新增裝備對話框
///
/// 支援:
/// - 從裝備庫自動完成選擇
/// - 手動輸入裝備資訊
/// - 連結至裝備庫項目
class AddGearDialog extends StatefulWidget {
  const AddGearDialog({super.key});

  /// 顯示新增裝備對話框
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => BlocProvider.value(
        value: context.read<GearLibraryCubit>(),
        child: BlocProvider.value(value: context.read<GearCubit>(), child: const AddGearDialog()),
      ),
    );
  }

  @override
  State<AddGearDialog> createState() => _AddGearDialogState();
}

class _AddGearDialogState extends State<AddGearDialog> {
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _focusNode = FocusNode();

  String _selectedCategory = 'Other';
  GearLibraryItem? _linkedItem;

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _quantityController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 檢查是否應該關閉 (有未儲存內容時詢問)
  Future<bool> _checkDismiss() async {
    final hasContent = _nameController.text.isNotEmpty || _weightController.text.isNotEmpty;
    if (!hasContent) return true;

    final confirm = await showDialog<bool>(
      context: context,
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

  /// 處理新增按鈕
  Future<void> _handleAdd(List<GearLibraryItem> availableItems) async {
    final name = _nameController.text.trim();
    final weight = double.tryParse(_weightController.text) ?? 0;

    if (name.isEmpty || weight <= 0) return;

    // 檢查是否要連結已存在的庫存裝備
    if (_linkedItem == null && availableItems.isNotEmpty) {
      try {
        final match = availableItems.firstWhere((item) => item.name.toLowerCase() == name.toLowerCase());
        final wantLink = await showDialog<bool>(
          context: context,
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
            _linkedItem = match;
            _nameController.text = match.name;
            _weightController.text = match.weight.toStringAsFixed(0);
            _selectedCategory = match.category;
          });
          return;
        }
      } catch (_) {
        // 沒有找到匹配項，繼續新增
      }
    }

    if (!mounted) return;

    context.read<GearCubit>().addItem(
      name: name,
      weight: weight,
      category: _selectedCategory,
      libraryItemId: _linkedItem?.id,
      quantity: int.tryParse(_quantityController.text) ?? 1,
    );

    if (mounted) ToastService.success('已新增：$name');
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GearLibraryCubit, GearLibraryState>(
      builder: (context, libraryState) {
        List<GearLibraryItem> availableItems = [];
        if (libraryState is GearLibraryLoaded) {
          availableItems = libraryState.availableItems;
        }

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final shouldPop = await _checkDismiss();
            if (shouldPop && mounted) Navigator.pop(context);
          },
          child: AlertDialog(
            title: const Text('新增裝備'),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 名稱輸入 (支援 Autocomplete)
                  _buildNameField(availableItems),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _weightController,
                    decoration: const InputDecoration(labelText: '重量 (公克)', hintText: '例如：1200'),
                    keyboardType: TextInputType.number,
                    enabled: _linkedItem == null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(labelText: '分類'),
                    items: const [
                      DropdownMenuItem(value: 'Sleep', child: Text('睡眠系統')),
                      DropdownMenuItem(value: 'Cook', child: Text('炊具與飲食')),
                      DropdownMenuItem(value: 'Wear', child: Text('穿著')),
                      DropdownMenuItem(value: 'Other', child: Text('其他')),
                    ],
                    onChanged: _linkedItem == null ? (value) => setState(() => _selectedCategory = value!) : null,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _quantityController,
                    decoration: const InputDecoration(labelText: '數量', hintText: '1'),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final shouldPop = await _checkDismiss();
                  if (shouldPop && mounted) Navigator.pop(context);
                },
                child: const Text('取消'),
              ),
              FilledButton(onPressed: () => _handleAdd(availableItems), child: const Text('新增')),
            ],
          ),
        );
      },
    );
  }

  /// 建立名稱輸入欄位 (含自動完成)
  Widget _buildNameField(List<GearLibraryItem> availableItems) {
    return RawAutocomplete<GearLibraryItem>(
      textEditingController: _nameController,
      focusNode: _focusNode,
      optionsBuilder: (textValue) {
        if (textValue.text.isEmpty) return const Iterable.empty();
        return availableItems.where((e) => e.name.toLowerCase().contains(textValue.text.toLowerCase()));
      },
      displayStringForOption: (item) => item.name,
      onSelected: (item) {
        setState(() {
          _weightController.text = item.weight.toStringAsFixed(0);
          _selectedCategory = item.category;
          _linkedItem = item;
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
            suffixIcon: _linkedItem != null
                ? IconButton(
                    icon: const Icon(Icons.link_off, color: Colors.red),
                    tooltip: '解除連結',
                    onPressed: () => setState(() => _linkedItem = null),
                  )
                : null,
          ),
          autofocus: true,
          onChanged: (val) {
            if (_linkedItem != null && val != _linkedItem!.name) {
              setState(() => _linkedItem = null);
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
    );
  }
}
