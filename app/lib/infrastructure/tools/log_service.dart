import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../core/di/injection.dart';
import '../clients/network_aware_client.dart';
import '../../data/datasources/local/log_dao.dart';

/// 日誌等級
enum LogLevel { debug, info, warning, error }

/// 日誌條目
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? source;

  LogEntry({required this.timestamp, required this.level, required this.message, this.source});

  String get formatted {
    final time = DateFormat('HH:mm:ss').format(timestamp);
    final levelStr = level.name.toUpperCase().padRight(7);
    final src = source != null ? '[$source] ' : '';
    return '$time [$levelStr] $src$message';
  }

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'level': level.name,
    'message': message,
    'source': source,
  };

  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry(
    timestamp: DateTime.parse(json['timestamp']),
    level: LogLevel.values.firstWhere((e) => e.name == json['level'], orElse: () => LogLevel.info),
    message: json['message'],
    source: json['source'],
  );
}

/// 本地日誌服務
///
/// 功能：
/// - 記錄各級別日誌 (debug/info/warning/error)
/// - 自動限制日誌數量 (最多 1000 條)
/// - 持久化存儲到 Drift
/// - 提供查閱介面
/// - 上傳到雲端
class LogService {
  static const int _maxLogCount = 1000; // 最多保留 1000 條

  static final Queue<LogEntry> _memoryLogs = Queue<LogEntry>();
  static LogDao? _logDao;

  /// 初始化日誌服務
  static Future<void> init() async {
    try {
      _logDao = getIt<LogDao>();
      final logs = await _logDao!.getAllLogs();
      _memoryLogs.clear();
      _memoryLogs.addAll(logs.reversed); // reversed because LogDao returns desc, Queue needs asc for removeFirst
    } catch (e) {
      debugPrint('初始化 LogService 失敗: $e');
    }
  }

  /// 記錄 Debug 訊息
  static void debug(String message, {String? source}) {
    _log(LogLevel.debug, message, source: source);
  }

  /// 記錄 Info 訊息
  static void info(String message, {String? source}) {
    _log(LogLevel.info, message, source: source);
  }

  /// 記錄 Warning 訊息
  static void warning(String message, {String? source}) {
    _log(LogLevel.warning, message, source: source);
  }

  /// 記錄 Error 訊息
  static void error(String message, {String? source, StackTrace? stackTrace}) {
    final fullMessage = stackTrace != null ? '$message\nStackTrace:\n$stackTrace' : message;
    _log(LogLevel.error, fullMessage, source: source);
  }

  /// 內部記錄方法
  static void _log(LogLevel level, String message, {String? source}) {
    final entry = LogEntry(timestamp: DateTime.now(), level: level, message: message, source: source);

    // 記憶體快取
    _memoryLogs.add(entry);

    // 超過上限時移除舊日誌
    while (_memoryLogs.length > _maxLogCount) {
      _memoryLogs.removeFirst();
    }

    // 持久化存儲
    _saveToStorage(entry);

    // Debug 模式同時輸出到控制台
    if (kDebugMode) {
      debugPrint(entry.formatted);
    }
  }

  /// 存儲到 Drift
  static Future<void> _saveToStorage(LogEntry entry) async {
    if (_logDao == null) return;

    try {
      await _logDao!.addLog(entry);
      await _logDao!.deleteOldLogs(_maxLogCount);
    } catch (e) {
      debugPrint('存儲日誌失敗: $e');
    }
  }

  /// 取得所有日誌 (最新在前)
  static List<LogEntry> getAllLogs() {
    return _memoryLogs.toList().reversed.toList();
  }

  /// 取得最近 N 條日誌
  static List<LogEntry> getRecentLogs({int count = 100}) {
    final all = getAllLogs();
    return all.take(count).toList();
  }

  /// 依等級篩選日誌
  static List<LogEntry> getLogsByLevel(LogLevel level) {
    return getAllLogs().where((e) => e.level == level).toList();
  }

  /// 清除所有日誌
  static Future<void> clearAll() async {
    _memoryLogs.clear();
    await _logDao?.clearAll();
  }

  /// 日誌數量
  static int get count => _memoryLogs.length;

  /// 匯出日誌為文字
  static String exportAsText() {
    return getAllLogs().map((e) => e.formatted).join('\n');
  }

  /// 上傳日誌到雲端
  static Future<(bool, String)> uploadToCloud({String? deviceName}) async {
    if (_memoryLogs.isEmpty) {
      return (true, '沒有日誌需要上傳');
    }

    try {
      final apiClient = getIt<NetworkAwareClient>();
      final logEntries = _memoryLogs.map((e) => e.toJson()).toList();

      final payload = {
        'device_name': deviceName ?? 'Unknown Device',
        'device_id': 'app-client',
        'logs': logEntries
      };

      final response = await apiClient.post('/logs', data: payload);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 上傳成功後不一定要清除，視需求而定
        // 如果要清除：
        // await clearAll();
        return (true, '成功上傳 ${logEntries.length} 條日誌');
      } else {
        return (false, '上傳失敗: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('上傳日誌例外: $e');
      return (false, '上傳失敗: $e');
    }
  }
}
