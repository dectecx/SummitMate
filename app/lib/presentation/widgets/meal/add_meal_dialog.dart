import 'package:flutter/material.dart';
import '../../../domain/domain.dart';

class AddMealDialog extends StatefulWidget {
  final MealType mealType;
  final Function(String name, double weight, double calories) onAdd;

  const AddMealDialog({super.key, required this.mealType, required this.onAdd});

  static void show(
    BuildContext context, {
    required MealType mealType,
    required Function(String name, double weight, double calories) onAdd,
  }) {
    showDialog(
      context: context,
      builder: (context) => AddMealDialog(mealType: mealType, onAdd: onAdd),
    );
  }

  @override
  State<AddMealDialog> createState() => _AddMealDialogState();
}

class _AddMealDialogState extends State<AddMealDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _calCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _weightCtrl = TextEditingController(text: '100'); // 預設常見重量
    _calCtrl = TextEditingController(text: '350'); // 預設熱量
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _weightCtrl.dispose();
    _calCtrl.dispose();
    super.dispose();
  }

  void _adjustWeight(double delta) {
    final current = double.tryParse(_weightCtrl.text) ?? 0;
    final newValue = (current + delta).clamp(0.0, 9999.0);
    _weightCtrl.text = newValue.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text('新增 ${widget.mealType.label}', style: const TextStyle(fontWeight: FontWeight.bold)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: '食物名稱',
                hintText: '例如：乾燥飯、能量棒',
                prefixIcon: const Icon(Icons.restaurant),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _weightCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: '重量 (g)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          suffixIcon: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () => _adjustWeight(10),
                                child: const Icon(Icons.arrow_drop_up, size: 20),
                              ),
                              GestureDetector(
                                onTap: () => _adjustWeight(-10),
                                child: const Icon(Icons.arrow_drop_down, size: 20),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _calCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: '熱量 (kcal)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('取消', style: TextStyle(color: theme.colorScheme.outline)),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            final weight = double.tryParse(_weightCtrl.text) ?? 0;
            final cal = double.tryParse(_calCtrl.text) ?? 0;
            if (name.isNotEmpty) {
              widget.onAdd(name, weight, cal);
              Navigator.pop(context);
            }
          },
          child: const Text('確認新增'),
        ),
      ],
    );
  }
}
