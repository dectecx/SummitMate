import 'package:flutter/material.dart';

/// 密碼強度指示器
///
/// 根據 [strength]（0.0 ~ 1.0）顯示進度條與文字標籤。
/// 強度計算邏輯統一由 [Validators.calculatePasswordStrength] 提供，
/// 本 widget 僅負責呈現。
class PasswordStrengthIndicator extends StatelessWidget {
  /// 密碼強度值，範圍 0.0（最弱）到 1.0（最強）。
  final double strength;

  const PasswordStrengthIndicator({super.key, required this.strength});

  /// 進度條填色：保留紅/橙/黃/綠號誌語意，並依亮暗模式選擇對比足夠的色階。
  Color _barColor(bool isDark) {
    if (strength <= 0.2) return isDark ? Colors.red.shade400 : Colors.red;
    if (strength <= 0.4) return isDark ? Colors.orange.shade400 : Colors.orange;
    if (strength <= 0.7) return isDark ? Colors.amber.shade400 : Colors.amber.shade700;
    return isDark ? Colors.green.shade400 : Colors.green;
  }

  /// 標籤文字色：深色模式用較亮色階、淺色模式用較深色階，確保兩種背景皆可讀。
  Color _labelColor(bool isDark) {
    if (strength <= 0.2) return isDark ? Colors.red.shade300 : Colors.red.shade700;
    if (strength <= 0.4) return isDark ? Colors.orange.shade300 : Colors.orange.shade800;
    if (strength <= 0.7) return isDark ? Colors.amber.shade300 : Colors.amber.shade800;
    return isDark ? Colors.green.shade300 : Colors.green.shade700;
  }

  String get _label {
    if (strength <= 0.2) return '太短';
    if (strength <= 0.4) return '弱';
    if (strength <= 0.7) return '中';
    return '強';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: strength,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              color: _barColor(isDark),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _labelColor(isDark)),
        ),
      ],
    );
  }
}
