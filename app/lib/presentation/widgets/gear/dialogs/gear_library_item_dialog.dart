import 'package:flutter/material.dart';

import 'package:summitmate/core/core.dart';
import 'package:summitmate/domain/domain.dart';

import '../../../utils/gear_utils.dart';

/// 裝備庫新增 / 編輯 Dialog
///
/// 供 [GearLibraryScreen] 呼叫，封裝表單欄位、驗證與存取邏輯。
class GearLibraryItemDialog extends StatefulWidget {
  final GearLibraryItem? item;
  final Future<void> Function(String name, double weight, String category, String? notes) onSave;

  const GearLibraryItemDialog({super.key, this.item, required this.onSave});

  @override
  State<GearLibraryItemDialog> createState() => _GearLibraryItemDialogState();
}

class _GearLibraryItemDialogState extends State<GearLibraryItemDialog> {
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
