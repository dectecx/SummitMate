import 'package:flutter/material.dart';

class ErrorSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    bool isPersistent = false,
    VoidCallback? onRetry,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colorScheme.onErrorContainer),
              ),
            ),
          ],
        ),
        backgroundColor: colorScheme.errorContainer,
        behavior: SnackBarBehavior.floating,
        duration: isPersistent ? const Duration(days: 1) : const Duration(seconds: 4),
        action: onRetry != null
            ? SnackBarAction(
                label: '重試',
                textColor: colorScheme.error,
                onPressed: onRetry,
              )
            : SnackBarAction(
                label: '關閉',
                textColor: colorScheme.onErrorContainer.withOpacity(0.7),
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
      ),
    );
  }
}
