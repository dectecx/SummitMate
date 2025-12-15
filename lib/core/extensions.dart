/// DateTime 擴展方法
extension DateTimeExtension on DateTime {
  /// 格式化為 HH:mm
  String toTimeString() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// 格式化為 MM/dd HH:mm
  String toShortDateTimeString() {
    return '${month.toString().padLeft(2, '0')}/${day.toString().padLeft(2, '0')} ${toTimeString()}';
  }

  /// 格式化為 ISO8601 字串
  String toIso8601() {
    return toIso8601String();
  }
}

/// String 擴展方法
extension StringExtension on String {
  /// 首字母大寫
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// 判斷是否為空或空白
  bool get isBlank => trim().isEmpty;

  /// 判斷是否非空且非空白
  bool get isNotBlank => !isBlank;
}

/// double 擴展方法 (用於裝備重量)
extension DoubleExtension on double {
  /// 轉換為公斤字串 (保留兩位小數)
  String toKgString() {
    final kg = this / 1000;
    return '${kg.toStringAsFixed(2)} kg';
  }

  /// 轉換為公克字串
  String toGString() {
    return '${toStringAsFixed(0)} g';
  }
}

/// List 擴展方法
extension ListExtension<T> on List<T> {
  /// 安全取得元素，若超出範圍則返回 null
  T? getOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }
}
