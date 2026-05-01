import 'package:flutter/material.dart';

import '../../core/error/result.dart';
import '../../data/models/gear_set.dart';

import '../../domain/repositories/i_gear_set_repository.dart';
import 'package:summitmate/infrastructure/infrastructure.dart';

/// Key 輸入對話框
class GearKeyInputDialog extends StatefulWidget {
  final IGearSetRepository repository;

  const GearKeyInputDialog({super.key, required this.repository});

  @override
  State<GearKeyInputDialog> createState() => _GearKeyInputDialogState();
}

class _GearKeyInputDialogState extends State<GearKeyInputDialog> {
  final _keyController = TextEditingController();
  bool _isLoading = false;

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

  Future<void> _handleSubmit() async {
    final key = _keyController.text;
    if (!_isKeyValid) {
      ToastService.error('請輸入 4 位數 Key');
      return;
    }

    setState(() => _isLoading = true);

    final result = await widget.repository.getGearSetByKey(key);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result is Success<GearSet, Exception>) {
      Navigator.pop(context, result.value);
    } else if (result is Failure<GearSet, Exception>) {
      ToastService.error(result.exception.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('🔐 用 Key 查看私人組合'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _keyController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 8),
            decoration: const InputDecoration(hintText: '____', counterText: ''),
            enabled: !_isLoading,
          ),
          const SizedBox(height: 8),
          Text('輸入 4 位數 Key 以查看私人組合', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ],
      ),
      actions: [
        TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(
          onPressed: (!_isKeyValid || _isLoading) ? null : _handleSubmit,
          child: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('查詢'),
        ),
      ],
    );
  }
}
