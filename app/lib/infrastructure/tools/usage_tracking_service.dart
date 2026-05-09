import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/enums/app_view.dart';
import '../../domain/interfaces/i_api_client.dart';
import 'log_service.dart';

/// 使用狀態追蹤服務 (僅 Web)
/// 每 2 小時發送一次心跳到伺服器
@lazySingleton
class UsageTrackingService {
  static const String _source = 'UsageTracking';
  static const Duration _heartbeatInterval = Duration(hours: 2);
  static const Duration _debounceDuration = Duration(seconds: 10);
  static const String _storageKey = 'usage_view_counts';

  Timer? _heartbeatTimer;
  Timer? _debounceTimer;

  String? _username;
  String? _userId;
  String? _userType;
  AppView? _currentView;

  // 記錄每個畫面的累計進入次數
  Map<AppView, int> _viewCounts = {};

  final IApiClient _apiClient;

  UsageTrackingService(this._apiClient);

  /// 啟動追蹤 (僅 Web 平台)
  void start(String username, {String? userId}) {
    if (!kIsWeb) {
      LogService.debug('跳過心跳追蹤 (非 Web 平台)', source: _source);
      return;
    }

    if (_username == username && _userId == userId && _heartbeatTimer != null) {
      LogService.debug('心跳追蹤已在執行中, User: $username', source: _source);
      return;
    }

    // 先停止現有的追蹤 (如有)
    stop();

    _username = username;
    _userId = userId;
    _userType = userId != null ? 'member' : 'guest';

    LogService.info('啟動心跳追蹤 (每 2 小時), User: $username ($_userType)', source: _source);

    // 載入本地累計數據
    _loadLocalStats().then((_) {
      // 立即發送一次初始同步
      _sendHeartbeat();
    });

    // 設定定時器
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      _sendHeartbeat();
    });
  }

  /// 更新目前畫面名稱
  void updateView(AppView view) {
    if (_currentView == view) return;
    _currentView = view;

    // 增加該畫面的計數
    _viewCounts[view] = (_viewCounts[view] ?? 0) + 1;
    _saveLocalStats();

    LogService.debug('更新目前畫面: ${view.name}, 累計次數: ${_viewCounts[view]}', source: _source);

    // 防抖動處理：避免頻繁發送 API
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      _sendHeartbeat(isDebounced: true);
    });
  }

  Future<void> _loadLocalStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null) {
        final Map<String, dynamic> data = json.decode(jsonStr);
        _viewCounts = data.map((key, value) => MapEntry(AppView.fromString(key), value as int));
      }
    } catch (e) {
      LogService.error('載入本地統計數據失敗: $e', source: _source);
    }
  }

  Future<void> _saveLocalStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = _viewCounts.map((key, value) => MapEntry(key.name, value));
      await prefs.setString(_storageKey, json.encode(data));
    } catch (e) {
      LogService.error('儲存本地統計數據失敗: $e', source: _source);
    }
  }

  /// 發送心跳
  Future<void> _sendHeartbeat({bool isDebounced = false}) async {
    if (_username == null || _username!.isEmpty) {
      LogService.debug('跳過心跳 (使用者名稱為空)', source: _source);
      return;
    }

    try {
      if (!isDebounced) {
        LogService.info('發送定期心跳...', source: _source);
      }

      final viewStats = _viewCounts.map((key, value) => MapEntry(key.name, value));

      final response = await _apiClient.post(
        '/system/heartbeat',
        data: {
          'user_name': _username,
          if (_userId != null) 'user_id': _userId,
          'user_type': _userType,
          'view': _currentView?.name ?? 'unknown',
          'view_stats': viewStats,
          'timestamp': DateTime.now().toIso8601String(),
          'platform': 'web',
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        // 處理同步回傳的數據 (Server-side win logic)
        final Map<String, dynamic>? serverStats = response.data['view_stats'] as Map<String, dynamic>?;
        if (serverStats != null) {
          bool updated = false;
          serverStats.forEach((key, value) {
            final view = AppView.fromString(key);
            final serverCount = value as int;
            final localCount = _viewCounts[view] ?? 0;

            if (serverCount > localCount) {
              _viewCounts[view] = serverCount;
              updated = true;
            }
          });

          if (updated) {
            _saveLocalStats();
            LogService.info('已與伺服器同步統計數據', source: _source);
          }
        }
        LogService.debug('心跳發送成功', source: _source);
      } else if (response.statusCode != 200 && response.statusCode != 204) {
        LogService.warning('心跳發送失敗: HTTP ${response.statusCode}', source: _source);
      }
    } catch (e) {
      LogService.error('心跳發送異常: $e', source: _source);
    }
  }

  /// 停止追蹤
  void stop() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    LogService.info('心跳追蹤已停止', source: _source);
  }

  /// 釋放服務資源
  void dispose() {
    stop();
  }
}
