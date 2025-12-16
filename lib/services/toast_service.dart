import 'package:flutter/material.dart';

/// Toast 訊息服務
/// 用於顯示成功、失敗、提示等訊息
class ToastService {
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// 顯示成功訊息
  static void success(String message) {
    _show(message, Colors.green, Icons.check_circle);
  }

  /// 顯示錯誤訊息
  static void error(String message) {
    _show(message, Colors.red, Icons.error);
  }

  /// 顯示警告訊息
  static void warning(String message) {
    _show(message, Colors.orange, Icons.warning);
  }

  /// 顯示一般訊息
  static void info(String message) {
    _show(message, Colors.blue, Icons.info);
  }

  /// 內部方法：顯示 SnackBar
  static void _show(String message, Color color, IconData icon) {
    final messenger = messengerKey.currentState;
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
