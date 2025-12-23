import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/gear_cloud_service.dart';
import '../../services/toast_service.dart';

/// Key 輸入對話框
class GearKeyInputDialog extends StatefulWidget {
  final GearCloudService cloudService;

  const GearKeyInputDialog({
    super.key,
    required this.cloudService,
  });

  @override
  State<GearKeyInputDialog> createState() => _GearKeyInputDialogState();
}

class _GearKeyInputDialogState extends State<GearKeyInputDialog> {
  final _keyController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final key = _keyController.text;
    if (key.length != 4) {
      ToastService.error('請輸入 4 位數 Key');
      return;
    }

    setState(() => _isLoading = true);

    final result = await widget.cloudService.fetchGearSetByKey(key);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success && result.data != null) {
      Navigator.pop(context, result.data);
    } else {
      ToastService.error(result.errorMessage ?? '找不到組合');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('🔐 用 Key 下載私人組合'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
            enabled: !_isLoading,
          ),
          const SizedBox(height: 8),
          Text(
            '輸入 4 位數 Key 以查看私人組合',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _handleSubmit,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('確認'),
        ),
      ],
    );
  }
}

/// 本地 Key 記錄管理
class GearKeyStorage {
  static const String _keyPrefix = 'gear_uploaded_keys';

  /// 取得已儲存的 Keys
  static Future<List<GearKeyRecord>> getUploadedKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final keysJson = prefs.getStringList(_keyPrefix) ?? [];
    return keysJson.map((json) => GearKeyRecord.fromStorageString(json)).toList();
  }

  /// 儲存新的 Key
  static Future<void> saveUploadedKey(String key, String title, String visibility) async {
    final prefs = await SharedPreferences.getInstance();
    final keysJson = prefs.getStringList(_keyPrefix) ?? [];

    final record = GearKeyRecord(
      key: key,
      title: title,
      visibility: visibility,
      uploadedAt: DateTime.now(),
    );

    keysJson.add(record.toStorageString());
    await prefs.setStringList(_keyPrefix, keysJson);
  }

  /// 移除已上傳的 Key
  static Future<void> removeUploadedKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final keysJson = prefs.getStringList(_keyPrefix) ?? [];

    // 過濾掉指定的 key
    final filtered = keysJson.where((json) {
      final record = GearKeyRecord.fromStorageString(json);
      return record.key != key;
    }).toList();

    await prefs.setStringList(_keyPrefix, filtered);
  }
}

/// Key 記錄
class GearKeyRecord {
  final String key;
  final String title;
  final String visibility;
  final DateTime uploadedAt;

  GearKeyRecord({
    required this.key,
    required this.title,
    required this.visibility,
    required this.uploadedAt,
  });

  /// 從儲存字串建立
  factory GearKeyRecord.fromStorageString(String str) {
    final parts = str.split('|');
    return GearKeyRecord(
      key: parts.isNotEmpty ? parts[0] : '',
      title: parts.length > 1 ? parts[1] : '',
      visibility: parts.length > 2 ? parts[2] : '',
      uploadedAt: parts.length > 3 ? DateTime.tryParse(parts[3]) ?? DateTime.now() : DateTime.now(),
    );
  }

  /// 轉為儲存字串
  String toStorageString() => '$key|$title|$visibility|${uploadedAt.toIso8601String()}';
}
