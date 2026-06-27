import 'package:flutter/material.dart';

/// 危險操作按鈕（刪除、捨棄、登出、強制覆蓋等）
///
/// 統一使用 Material 3 的 `colorScheme.error` / `colorScheme.onError`，
/// 確保深色模式下對比一致，並避免散落各處的 `Colors.red` 硬編碼。
class SummitDestructiveButton extends StatelessWidget {
  const SummitDestructiveButton({super.key, required this.onPressed, required this.child});

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.error,
        foregroundColor: colorScheme.onError,
      ),
      child: child,
    );
  }
}
