import 'package:flutter/material.dart';

/// Toast 訊息服務介面 (方便測試時 Mock)
abstract class IToastService {
  void success(String message);
  void error(String message);
  void warning(String message);
  void info(String message);
}

/// Toast 訊息服務門面
/// 保持靜態調用介面，底層透過代理實作解耦，支援測試期 Mock 替換
class ToastService {
  /// 允許在測試或特定環境下被替換為 Mock 實作
  static IToastService instance = SnackBarToastService();

  /// 顯示成功訊息
  static void success(String message) => instance.success(message);

  /// 顯示錯誤訊息
  static void error(String message) => instance.error(message);

  /// 顯示警告訊息
  static void warning(String message) => instance.warning(message);

  /// 顯示一般訊息
  static void info(String message) => instance.info(message);

  /// 暴露原有的 ScaffoldMessengerKey，供 MaterialApp 初始化使用
  static GlobalKey<ScaffoldMessengerState> get messengerKey => SnackBarToastService.messengerKey;
}

/// 預設基於 ScaffoldMessenger SnackBar 的實作
class SnackBarToastService implements IToastService {
  static final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void success(String message) {
    _show(message, Colors.green, Icons.check_circle);
  }

  @override
  void error(String message) {
    _show(message, Colors.red, Icons.error);
  }

  @override
  void warning(String message) {
    _show(message, Colors.orange, Icons.warning);
  }

  @override
  void info(String message) {
    _show(message, Colors.blue, Icons.info);
  }

  void _show(String message, Color color, IconData icon) {
    final messenger = messengerKey.currentState;
    if (messenger == null) {
      debugPrint('ToastService failed to show message: $message (messenger is null)');
      return;
    }

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
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
