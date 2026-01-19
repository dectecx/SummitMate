import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/gear_item.dart';
import '../../../cubits/gear/gear_cubit.dart';
import '../../../cubits/gear_library/gear_library_cubit.dart';
import '../../../cubits/gear_library/gear_library_state.dart';

/// 編輯裝備對話框
///
/// 支援:
/// - 編輯裝備名稱、重量、分類、數量
/// - 管理與裝備庫的連結狀態
class EditGearDialog extends StatefulWidget {
  final GearItem item;

  const EditGearDialog({super.key, required this.item});

  /// 顯示編輯裝備對話框
  static Future<void> show(BuildContext context, GearItem item) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<GearLibraryCubit>(),
        child: BlocProvider.value(
          value: context.read<GearCubit>(),
          child: EditGearDialog(item: item),
        ),
      ),
    );
  }

  @override
  State<EditGearDialog> createState() => _EditGearDialogState();
}

class _EditGearDialogState extends State<EditGearDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _weightController;
  late int _quantity;
  late String _selectedCategory;
  String? _libraryItemId;
  late bool _isLinked;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _weightController = TextEditingController(text: widget.item.weight.toStringAsFixed(0));
    _quantity = widget.item.quantity;
    _selectedCategory = widget.item.category;
    _libraryItemId = widget.item.libraryItemId;

    // 檢查連結是否有效
    _isLinked = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLinkValidity();
    });
  }

  void _checkLinkValidity() {
    if (_libraryItemId == null) return;

    final libraryState = context.read<GearLibraryCubit>().state;
    if (libraryState is GearLibraryLoaded) {
      final isValid = libraryState.items.any((i) => i.id == _libraryItemId);
      setState(() => _isLinked = isValid);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  /// 解除與裝備庫的連結
  void _unlinkFromLibrary() {
    setState(() {
      _libraryItemId = null;
      _isLinked = false;
    });
  }

  /// 儲存變更
  void _save() {
    final name = _nameController.text.trim();
    final weight = double.tryParse(_weightController.text) ?? 0;

    if (name.isEmpty || weight <= 0) return;

    // 更新 item 屬性
    widget.item.name = name;
    if (!_isLinked) {
      widget.item.weight = weight;
      widget.item.category = _selectedCategory;
    }
    widget.item.quantity = _quantity;
    widget.item.libraryItemId = _libraryItemId;

    context.read<GearCubit>().updateItem(widget.item);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('編輯裝備'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 連結狀態提示
            if (_isLinked) _buildLinkedBanner(),

            // 名稱輸入
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '名稱'),
            ),
            const SizedBox(height: 16),

            // 重量輸入
            TextField(
              controller: _weightController,
              decoration: const InputDecoration(labelText: '重量 (公克)'),
              keyboardType: TextInputType.number,
              enabled: !_isLinked,
            ),
            const SizedBox(height: 16),

            // 分類選擇
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(labelText: '分類'),
              items: const [
                DropdownMenuItem(value: 'Sleep', child: Text('睡眠系統')),
                DropdownMenuItem(value: 'Cook', child: Text('炊具與飲食')),
                DropdownMenuItem(value: 'Wear', child: Text('穿著')),
                DropdownMenuItem(value: 'Other', child: Text('其他')),
              ],
              onChanged: !_isLinked ? (value) => setState(() => _selectedCategory = value!) : null,
            ),
            const SizedBox(height: 16),

            // 數量調整
            _buildQuantityRow(),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(onPressed: _save, child: const Text('儲存')),
      ],
    );
  }

  /// 建立連結狀態提示橫幅
  Widget _buildLinkedBanner() {
    return Container(
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
          TextButton(onPressed: _unlinkFromLibrary, child: const Text('解除連結')),
        ],
      ),
    );
  }

  /// 建立數量調整列
  Widget _buildQuantityRow() {
    return Row(
      children: [
        const Text('數量', style: TextStyle(fontSize: 16)),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
          onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
        ),
        SizedBox(
          width: 40,
          child: Text(
            '$_quantity',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
          onPressed: () => setState(() => _quantity++),
        ),
      ],
    );
  }
}
