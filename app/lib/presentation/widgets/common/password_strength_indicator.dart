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

  Color get _color {
    if (strength <= 0.2) return Colors.red;
    if (strength <= 0.4) return Colors.orange;
    if (strength <= 0.7) return Colors.yellow.shade700;
    return Colors.green;
  }

  Color get _labelColor {
    if (strength <= 0.2) return Colors.red;
    if (strength <= 0.4) return Colors.orange;
    if (strength <= 0.7) return Colors.yellow.shade800;
    return Colors.green;
  }

  String get _label {
    if (strength <= 0.2) return '太短';
    if (strength <= 0.4) return '弱';
    if (strength <= 0.7) return '中';
    return '強';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: strength,
              backgroundColor: Colors.grey.shade200,
              color: _color,
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _labelColor),
        ),
      ],
    );
  }
}
