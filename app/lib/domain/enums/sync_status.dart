/// 資料同步狀態
enum SyncStatus {
  /// 已同步
  synced,

  /// 等待建立 (本地新增)
  pendingCreate,

  /// 等待更新 (本地修改)
  pendingUpdate,

  /// 等待刪除 (本地刪除)
  pendingDelete,

  /// 同步錯誤
  error,
}
