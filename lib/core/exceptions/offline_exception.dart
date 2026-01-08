/// 離線例外
///
/// 當系統處於離線狀態且嘗試執行需要網路的操作時拋出
class OfflineException implements Exception {
  final String message;
  final String? operationName;

  const OfflineException(this.message, {this.operationName});

  @override
  String toString() => 'OfflineException: $message${operationName != null ? ' (operation: $operationName)' : ''}';
}
