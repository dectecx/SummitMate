import 'package:flutter/material.dart';
import '../../data/models/gear_set.dart';
import '../../data/models/gear_item.dart';

class GearUploadDialog extends StatefulWidget {
  final List<GearItem> items;
  final String author;
  final Future<bool> Function(String title, GearSetVisibility visibility, String? key) onUpload;

  const GearUploadDialog({super.key, required this.items, required this.author, required this.onUpload});

  @override
  State<GearUploadDialog> createState() => _GearUploadDialogState();
}

class _GearUploadDialogState extends State<GearUploadDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();
  GearSetVisibility _visibility = GearSetVisibility.public;
  bool _isUploading = false;

  bool get _needsKey => _visibility == GearSetVisibility.protected;

  @override
  void dispose() {
    _titleController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _handleUpload() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請輸入組合名稱')));
      return;
    }
    if (_needsKey && _keyController.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保護模式需要 4 位數 Key')));
      return;
    }

    setState(() => _isUploading = true);

    final isSuccess = await widget.onUpload(
      _titleController.text.trim(),
      _visibility,
      _needsKey ? _keyController.text : null,
    );

    if (mounted) {
      setState(() => _isUploading = false);
      if (isSuccess) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(children: [Text('⬆️ '), Text('上傳裝備組合')]),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
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
              _RadioGroup(
                value: _visibility,
                onChanged: (v) => setState(() => _visibility = v),
                child: Column(
                  children: [
                    _VisibilityOption(icon: '🌐', title: '公開', subtitle: '任何人可下載', value: GearSetVisibility.public),
                    _VisibilityOption(
                      icon: '🔒',
                      title: '保護',
                      subtitle: '需輸入 Key 下載',
                      value: GearSetVisibility.protected,
                    ),
                    _VisibilityOption(icon: '👤', title: '私有', subtitle: '僅限自己使用', value: GearSetVisibility.private),
                  ],
                ),
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
                    const SizedBox(width: 8),
                    Text('即將上傳 ${widget.items.length} 項裝備', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isUploading ? null : () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(
          onPressed: _isUploading ? null : _handleUpload,
          child: _isUploading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('確認上傳'),
        ),
      ],
    );
  }
}

class _RadioGroup extends InheritedWidget {
  final GearSetVisibility value;
  final ValueChanged<GearSetVisibility> onChanged;

  const _RadioGroup({required this.value, required this.onChanged, required super.child});

  static _RadioGroup of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<_RadioGroup>();
    assert(result != null, 'No _RadioGroup found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(_RadioGroup oldWidget) => value != oldWidget.value;
}

class _VisibilityOption extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final GearSetVisibility value;

  const _VisibilityOption({required this.icon, required this.title, required this.subtitle, required this.value});

  @override
  Widget build(BuildContext context) {
    final group = _RadioGroup.of(context);
    final isSelected = value == group.value;

    return InkWell(
      onTap: () => group.onChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // ignore: deprecated_member_use
            Radio<GearSetVisibility>(
              value: value,
              // ignore: deprecated_member_use
              groupValue: group.value,
              // ignore: deprecated_member_use
              onChanged: (v) => v != null ? group.onChanged(v) : null,
            ),
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
