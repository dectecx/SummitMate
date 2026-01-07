import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/constants.dart';
import 'gas_api_client.dart';
import '../core/di.dart';
import 'log_service.dart';

/// 使用狀態追蹤服務 (僅 Web)
/// 每 2 小時發送一次心跳到 Google Sheets
class UsageTrackingService {
  static const String _source = 'UsageTracking';
  static const Duration _heartbeatInterval = Duration(hours: 2);

  Timer? _heartbeatTimer;
  String? _username;
  String? _userId;
  String? _userType;

  final GasApiClient _apiClient;
  final bool _forceWeb;

  UsageTrackingService({GasApiClient? apiClient, bool forceWeb = false}) 
      : _apiClient = apiClient ?? getIt<GasApiClient>(),
        _forceWeb = forceWeb;

  /// 啟動追蹤 (僅 Web 平台)
  /// [username] 顯示名稱
  /// [userId] 使用者 ID (若為 null 則視為訪客)
  void start(String username, {String? userId}) {
    if (!kIsWeb && !_forceWeb) {
      LogService.debug('跳過心跳追蹤 (非 Web 平台)', source: _source);
      return;
    }

    _username = username;
    _userId = userId;
    _userType = userId != null ? 'member' : 'guest';

    LogService.info('啟動心跳追蹤 (每 2 小時), User: $username ($_userType)', source: _source);

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
        'action': ApiConfig.actionSystemHeartbeat,
        'user_name': _username,
        if (_userId != null) 'user_id': _userId,
        // 若 api_heartbeat.gs 沒收到 user_id 會自動補 Guest- 前綴
        'user_type': _userType,
        'timestamp': DateTime.now().toIso8601String(),
        'platform': 'web',
      });

      if (response.statusCode == 200) {
        final apiResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
        if (apiResponse.isSuccess) {
          LogService.info('心跳發送成功', source: _source);
        } else {
          LogService.warning('心跳發送失敗: ${apiResponse.message}', source: _source);
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
