import 'package:flutter/material.dart';
import '../../data/models/gear_set.dart';

/// Key 輸入下載對話框
class GearKeyDownloadDialog extends StatefulWidget {
  final GearSet gearSet;

  const GearKeyDownloadDialog({
    super.key,
    required this.gearSet,
  });

  @override
  State<GearKeyDownloadDialog> createState() => _GearKeyDownloadDialogState();
}

class _GearKeyDownloadDialogState extends State<GearKeyDownloadDialog> {
  final _keyController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _keyController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  bool get _isKeyValid => _keyController.text.length == 4;

  void _handleSubmit() {
    if (_isKeyValid) {
      setState(() => _isSubmitting = true);
      Navigator.pop(context, _keyController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('🔒 ${widget.gearSet.title}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('此組合需要 Key 才能查看'),
          const SizedBox(height: 16),
          TextField(
            controller: _keyController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 8),
            decoration: const InputDecoration(
              hintText: '____',
              counterText: '',
            ),
            enabled: !_isSubmitting,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: (!_isKeyValid || _isSubmitting) ? null : _handleSubmit,
          child: const Text('查看'),
        ),
      ],
    );
  }
}
