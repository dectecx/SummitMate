import 'package:flutter/material.dart';

class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryText;
  final VoidCallback? onDismiss;

  const ErrorDialog({
    super.key,
    this.title = '發生錯誤',
    required this.message,
    this.onRetry,
    this.retryText = '重試',
    this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    String title = '發生錯誤',
    required String message,
    VoidCallback? onRetry,
    String retryText = '重試',
    VoidCallback? onDismiss,
  }) {
    return showDialog(
      context: context,
      builder: (context) =>
          ErrorDialog(title: title, message: message, onRetry: onRetry, retryText: retryText, onDismiss: onDismiss),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: Text(message),
      actions: [
        if (onDismiss != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDismiss!();
            },
            child: const Text('取消'),
          )
        else
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('關閉')),
        if (onRetry != null)
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry!();
            },
            child: Text(retryText),
          ),
      ],
    );
  }
}
