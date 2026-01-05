import 'dart:async';
import 'package:hive/hive.dart';
import '../../models/settings.dart';
import '../interfaces/i_settings_repository.dart';

/// 模擬設定資料庫
/// 用於教學模式，返回靜態假設定，所有寫入操作皆為空實作。
class MockSettingsRepository implements ISettingsRepository {
  final Settings _mockSettings = Settings(
    username: '教學模式使用者',
    avatar: '🦊',
    isOfflineMode: false,
    lastSyncTime: DateTime.now(),
  );

  @override
  Future<void> init() async {}

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
  Stream<BoxEvent> watchSettings() => const Stream.empty();

  @override
  Future<void> resetSettings() async {}
}
