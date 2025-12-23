import 'package:flutter/material.dart';

import '../../data/models/gear_set.dart';
import '../../data/models/gear_item.dart';

/// 上傳裝備組合對話框
class GearUploadDialog extends StatefulWidget {
  final List<GearItem> items;
  final String author;
  final Future<bool> Function(String title, GearSetVisibility visibility, String? key) onUpload;

  const GearUploadDialog({
    super.key,
    required this.items,
    required this.author,
    required this.onUpload,
  });

  @override
  State<GearUploadDialog> createState() => _GearUploadDialogState();
}

class _GearUploadDialogState extends State<GearUploadDialog> {
  final _titleController = TextEditingController();
  final _keyController = TextEditingController();
  GearSetVisibility _visibility = GearSetVisibility.public;
  bool _isUploading = false;

  double get _totalWeight =>
      widget.items.fold<double>(0, (sum, item) => sum + item.weight);

  String get _formattedWeight {
    if (_totalWeight >= 1000) {
      return '${(_totalWeight / 1000).toStringAsFixed(1)} kg';
    }
    return '${_totalWeight.toStringAsFixed(0)} g';
  }

  bool get _needsKey => _visibility != GearSetVisibility.public;

  bool get _isValid {
    if (_titleController.text.trim().isEmpty) return false;
    if (_needsKey && _keyController.text.length != 4) return false;
    return true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _handleUpload() async {
    if (!_isValid) return;

    setState(() => _isUploading = true);

    final success = await widget.onUpload(
      _titleController.text.trim(),
      _visibility,
      _needsKey ? _keyController.text : null,
    );

    if (mounted) {
      setState(() => _isUploading = false);
      if (success) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Text('⬆️ '),
          Text('上傳裝備組合'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 組合名稱
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '組合名稱',
                hintText: '例如：輕裝三日行程',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),

            // 可見性選擇
            const Text('可見性', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _VisibilityOption(
              icon: '🌐',
              title: '公開',
              subtitle: '任何人可下載',
              value: GearSetVisibility.public,
              groupValue: _visibility,
              onChanged: (v) => setState(() => _visibility = v),
            ),
            _VisibilityOption(
              icon: '🔒',
              title: '保護',
              subtitle: '需輸入 Key 下載',
              value: GearSetVisibility.protected,
              groupValue: _visibility,
              onChanged: (v) => setState(() => _visibility = v),
            ),
            _VisibilityOption(
              icon: '🔐',
              title: '私人',
              subtitle: '需輸入 Key 才能查看',
              value: GearSetVisibility.private,
              groupValue: _visibility,
              onChanged: (v) => setState(() => _visibility = v),
            ),

            // Key 輸入
            if (_needsKey) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _keyController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: const InputDecoration(
                  labelText: '4 位數 Key',
                  hintText: '____',
                  counterText: '',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],

            const SizedBox(height: 16),
            const Divider(),

            // 預覽資訊
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.backpack, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${widget.items.length} items'),
                  const SizedBox(width: 16),
                  const Icon(Icons.fitness_center, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(_formattedWeight),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _isValid && !_isUploading ? _handleUpload : null,
          child: _isUploading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('上傳'),
        ),
      ],
    );
  }
}

class _VisibilityOption extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final GearSetVisibility value;
  final GearSetVisibility groupValue;
  final ValueChanged<GearSetVisibility> onChanged;

  const _VisibilityOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Radio<GearSetVisibility>(
              value: value,
              groupValue: groupValue,
              onChanged: (v) => v != null ? onChanged(v) : null,
            ),
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
