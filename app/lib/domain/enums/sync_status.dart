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

  /// 衝突：本地有未同步修改，但遠端版本較新，本地勝出待推送
  ///
  /// 下一輪 Push 時應優先推送此狀態的資料
  conflict,

  /// 同步中
  syncing,

  /// 同步錯誤
  error,
}
