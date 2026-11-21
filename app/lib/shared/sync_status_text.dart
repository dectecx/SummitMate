import 'package:material_ui/material_ui.dart';

import '../core/sync/sync_status.dart';

/// Words and icon for a [SyncStatus]. Kept in one place so every screen says the same thing.
({IconData icon, String title, String? detail}) describeSyncStatus(SyncStatus s) => switch (s) {
  GuestLocalOnly() => (icon: Icons.phone_android, title: '資料只存在這支手機', detail: '登入後會自動備份到雲端'),
  Synced() => (icon: Icons.cloud_done_outlined, title: '已同步', detail: null),
  Syncing() => (icon: Icons.sync, title: '同步中…', detail: null),
  Pending(:final count) => (icon: Icons.cloud_upload_outlined, title: '$count 筆變更等待上傳', detail: null),
  Offline(:final pending) => (icon: Icons.cloud_off_outlined, title: '目前離線', detail: '$pending 筆變更會在連線後上傳'),
  Failed(:final count) => (icon: Icons.error_outline, title: '$count 筆變更同步失敗', detail: '需要你處理'),
  SessionExpired() => (icon: Icons.lock_outline, title: '登入已過期', detail: '重新登入後才會繼續同步'),
};
