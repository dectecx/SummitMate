import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/constants.dart';
import 'gas_api_client.dart';
import '../core/env_config.dart';
import 'log_service.dart';

/// 使用狀態追蹤服務 (僅 Web)
/// 每 2 小時發送一次心跳到 Google Sheets
class UsageTrackingService {
  static const String _source = 'UsageTracking';
  static const Duration _heartbeatInterval = Duration(hours: 2);

  Timer? _heartbeatTimer;
  String? _username;
  final GasApiClient _apiClient;

  UsageTrackingService({GasApiClient? apiClient})
    : _apiClient = apiClient ?? GasApiClient(baseUrl: EnvConfig.gasBaseUrl);

  /// 啟動追蹤 (僅 Web 平台)
  void start(String username) {
    if (!kIsWeb) {
      LogService.debug('跳過心跳追蹤 (非 Web 平台)', source: _source);
      return;
    }

    _username = username;
    LogService.info('啟動心跳追蹤 (每 2 小時), 使用者: $username', source: _source);

    // 立即發送一次
    _sendHeartbeat();

    // 設定定時器
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      _sendHeartbeat();
    });
  }

  /// 發送心跳
  Future<void> _sendHeartbeat() async {
    if (_username == null || _username!.isEmpty) {
      LogService.debug('跳過心跳 (使用者名稱為空)', source: _source);
      return;
    }

    try {
      LogService.info('發送心跳...', source: _source);
      final response = await _apiClient.post({
        'action': ApiConfig.actionHeartbeat,
        'username': _username,
        'timestamp': DateTime.now().toIso8601String(),
        'platform': 'web',
      });

      if (response.statusCode == 200) {
        final gasResponse = GasApiResponse.fromJsonString(response.body);
        if (gasResponse.isSuccess) {
          LogService.info('心跳發送成功', source: _source);
        } else {
          LogService.warning('心跳發送失敗: ${gasResponse.message}', source: _source);
        }
      } else {
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
    LogService.info('心跳追蹤已停止', source: _source);
  }

  /// 釋放資源
  void dispose() {
    stop();
  }
}
