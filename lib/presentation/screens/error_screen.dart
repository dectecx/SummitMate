import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 應用程式錯誤畫面
///
/// 當 App 啟動失敗時顯示，提供：
/// 1. 錯誤訊息顯示
/// 2. 複製錯誤訊息功能
/// 3. 清除資料重試功能
class ErrorScreen extends StatelessWidget {
  final String title;
  final String message;
  final String? stackTrace;
  final VoidCallback? onRetry;
  final VoidCallback? onClearData;

  const ErrorScreen({
    super.key,
    this.title = '啟動失敗',
    required this.message,
    this.stackTrace,
    this.onRetry,
    this.onClearData,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.grey.shade100,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                // 錯誤圖示
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 24),
                // 標題
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // 錯誤訊息
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.bug_report, size: 20, color: Colors.red.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              message,
                              style: TextStyle(
                                color: Colors.red.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (stackTrace != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          height: 120,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              stackTrace!,
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // 複製錯誤訊息按鈕
                OutlinedButton.icon(
                  onPressed: () => _copyError(context),
                  icon: const Icon(Icons.copy),
                  label: const Text('複製錯誤訊息'),
                ),
                const Spacer(),
                // 操作按鈕
                if (onClearData != null)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _showClearDataDialog(context),
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('清除資料並重試'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                if (onClearData != null) const SizedBox(height: 12),
                if (onRetry != null)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('重試'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                // 說明文字
                Text(
                  '如持續發生此錯誤，請聯繫開發者並提供上方錯誤訊息。',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _copyError(BuildContext context) {
    final fullError = stackTrace != null ? '$message\n\n$stackTrace' : message;
    Clipboard.setData(ClipboardData(text: fullError));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已複製到剪貼簿')),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('確認清除資料'),
        content: const Text(
          '這將清除所有本地資料（行程、裝備、留言等）。\n'
          '雲端資料不會受影響，之後可重新同步。\n\n'
          '確定要繼續嗎？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onClearData?.call();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('確定清除'),
          ),
        ],
      ),
    );
  }
}
