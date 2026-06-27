import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:summitmate/core/core.dart';
import 'package:summitmate/infrastructure/infrastructure.dart';

import '../../../cubits/gear_library/gear_library_cubit.dart';
import '../../../cubits/gear_library/gear_library_state.dart';
import '../../../cubits/connectivity/connectivity_cubit.dart';

/// 裝備庫雲端備份 Dialog
///
/// 提供上傳（覆蓋雲端）與下載（覆蓋本地）兩種操作，
/// 供 [GearLibraryScreen] 透過 `showDialog` 呼叫。
class GearLibraryCloudSyncDialog extends StatefulWidget {
  const GearLibraryCloudSyncDialog({super.key});

  @override
  State<GearLibraryCloudSyncDialog> createState() => _GearLibraryCloudSyncDialogState();
}

class _GearLibraryCloudSyncDialogState extends State<GearLibraryCloudSyncDialog> {
  bool _isLoading = false;
  String? _resultMessage;
  bool? _isSuccess;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('☁️ 雲端備份'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('將個人裝備庫與您的帳號同步。'),
            const SizedBox(height: 16),
            const Text(
              '【同步說明】\n• 上傳：覆蓋雲端資料 (以您的帳號儲存)\n• 下載：覆蓋本地資料',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            if (_resultMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isSuccess == true ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _isSuccess == true ? Colors.green.shade200 : Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSuccess == true ? Icons.check_circle : Icons.error,
                      color: _isSuccess == true ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _resultMessage!,
                        style: TextStyle(
                          color: _isSuccess == true ? Colors.green.shade800 : Colors.red.shade800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: const Text('關閉')),
        OutlinedButton.icon(
          onPressed: _isLoading ? null : _handleDownload,
          icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.download),
          label: const Text('下載'),
        ),
        FilledButton.icon(
          onPressed: _isLoading ? null : _handleUpload,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.upload),
          label: const Text('上傳'),
        ),
      ],
    );
  }

  Future<void> _handleUpload() async {
    final isOffline = context.read<ConnectivityCubit>().state.isOffline;
    if (isOffline) {
      ToastService.warning('離線模式，無法上傳');
      return;
    }

    setState(() {
      _isLoading = true;
      _resultMessage = null;
    });

    try {
      final cubit = context.read<GearLibraryCubit>();
      final state = cubit.state;
      if (state is! GearLibraryLoaded) throw Exception('未載入裝備庫');
      final items = state.items;

      if (items.isEmpty) {
        setState(() {
          _isLoading = false;
          _isSuccess = false;
          _resultMessage = '裝備庫是空的，無法上傳';
        });
        return;
      }

      final result = await cubit.uploadLibrary();

      setState(() {
        _isLoading = false;
        if (result is Success<int, Exception>) {
          _isSuccess = true;
          _resultMessage = '成功上傳 ${result.value} 個裝備';
        } else {
          _isSuccess = false;
          _resultMessage = '上傳失敗: ${(result as Failure).exception}';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _resultMessage = '上傳失敗: $e';
      });
    }
  }

  Future<void> _handleDownload() async {
    final isOffline = context.read<ConnectivityCubit>().state.isOffline;
    if (isOffline) {
      ToastService.warning('離線模式，無法下載');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('確認下載'),
        content: const Text('下載將覆蓋本地裝備庫所有資料。\n\n確定要繼續嗎？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('確定下載'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _resultMessage = null;
    });

    try {
      final result = await context.read<GearLibraryCubit>().downloadLibrary();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        if (result is Success<int, Exception>) {
          _isSuccess = true;
          _resultMessage = '成功下載 ${result.value} 個裝備';
        } else {
          _isSuccess = false;
          _resultMessage = '下載失敗: ${(result as Failure).exception}';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _resultMessage = '下載失敗: $e';
      });
    }
  }
}
