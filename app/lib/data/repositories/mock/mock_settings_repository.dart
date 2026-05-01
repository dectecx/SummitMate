import 'dart:async';
import 'package:hive_ce/hive.dart';
import 'package:summitmate/core/theme.dart';
import 'package:summitmate/domain/domain.dart';
import '../../../domain/repositories/i_settings_repository.dart';

/// 模擬設定資料倉庫
///
/// 用於教學模式，返回靜態假設定，所有寫入操作皆為空實作。
class MockSettingsRepository implements ISettingsRepository {
  final Settings _mockSettings = Settings(
    username: '教學模式使用者',
    avatar: '🦊',
    isOfflineMode: false,
    lastSyncTime: DateTime.now(),
  );

  // ========== Data Operations ==========

  @override
  Settings getSettings() => _mockSettings;

  @override
  Future<void> updateUsername(String username) async {}

  @override
  Future<void> updateLastSyncTime(DateTime? time) async {}

  @override
  Future<void> updateAvatar(String avatar) async {}

  @override
  Future<void> updateOfflineMode(bool isOffline) async {}

  @override
  Future<void> updateTheme(AppThemeType theme) async {}

  @override
  Future<void> resetSettings() async {}

  // ========== Watch ==========

  @override
  Stream<BoxEvent> watchSettings() => const Stream.empty();
}
