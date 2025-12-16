import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

/// 日誌等級
enum LogLevel { debug, info, warning, error }

/// 日誌條目
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? source;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.source,
  });

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
    level: LogLevel.values.firstWhere(
      (e) => e.name == json['level'],
      orElse: () => LogLevel.info,
    ),
    message: json['message'],
    source: json['source'],
  );
}

/// 本地日誌服務
/// 
/// 功能：
/// - 記錄各級別日誌 (debug/info/warning/error)
/// - 自動限制日誌數量 (最多 1000 條)
/// - 持久化存儲到 Hive
/// - 提供查閱介面
class LogService {
  static const String _boxName = 'app_logs';
  static const int _maxLogCount = 1000;  // 最多保留 1000 條

  static Box<String>? _box;
  static final Queue<LogEntry> _memoryLogs = Queue<LogEntry>();

  /// 初始化日誌服務
  static Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
    _loadFromStorage();
  }

  /// 從存儲載入日誌
  static void _loadFromStorage() {
    if (_box == null) return;
    
    _memoryLogs.clear();
    for (var i = 0; i < _box!.length; i++) {
      try {
        final jsonStr = _box!.getAt(i);
        if (jsonStr != null) {
          final json = _parseJson(jsonStr);
          if (json != null) {
            _memoryLogs.add(LogEntry.fromJson(json));
          }
        }
      } catch (e) {
        debugPrint('解析日誌失敗: $e');
      }
    }
  }

  /// 簡易 JSON 解析
  static Map<String, dynamic>? _parseJson(String jsonStr) {
    try {
      // 使用 dart:convert
      return Map<String, dynamic>.from(
        (jsonStr.startsWith('{') ? _simpleJsonDecode(jsonStr) : null) ?? {},
      );
    } catch (e) {
      return null;
    }
  }

  /// 簡易 JSON 解碼
  static Map<String, dynamic>? _simpleJsonDecode(String jsonStr) {
    try {
      // 簡易實作：用正則解析基本 JSON
      final timestampMatch = RegExp(r'"timestamp"\s*:\s*"([^"]+)"').firstMatch(jsonStr);
      final levelMatch = RegExp(r'"level"\s*:\s*"([^"]+)"').firstMatch(jsonStr);
      final messageMatch = RegExp(r'"message"\s*:\s*"([^"]*)"').firstMatch(jsonStr);
      final sourceMatch = RegExp(r'"source"\s*:\s*"?([^",}]*)"?').firstMatch(jsonStr);
      
      if (timestampMatch != null && levelMatch != null && messageMatch != null) {
        return {
          'timestamp': timestampMatch.group(1),
          'level': levelMatch.group(1),
          'message': messageMatch.group(1),
          'source': sourceMatch?.group(1),
        };
      }
    } catch (e) {
      debugPrint('JSON 解析錯誤: $e');
    }
    return null;
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
  static void error(String message, {String? source}) {
    _log(LogLevel.error, message, source: source);
  }

  /// 內部記錄方法
  static void _log(LogLevel level, String message, {String? source}) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      source: source,
    );

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

  /// 存儲到 Hive
  static Future<void> _saveToStorage(LogEntry entry) async {
    if (_box == null) return;

    try {
      final json = entry.toJson();
      final jsonStr = '{"timestamp":"${json['timestamp']}","level":"${json['level']}","message":"${json['message']}","source":"${json['source'] ?? ''}"}';
      await _box!.add(jsonStr);

      // 超過上限時清理舊日誌
      if (_box!.length > _maxLogCount) {
        final deleteCount = _box!.length - _maxLogCount;
        for (var i = 0; i < deleteCount; i++) {
          await _box!.deleteAt(0);
        }
        await _box!.compact();
      }
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
    await _box?.clear();
  }

  /// 日誌數量
  static int get count => _memoryLogs.length;

  /// 匯出日誌為文字
  static String exportAsText() {
    return getAllLogs().map((e) => e.formatted).join('\n');
  }
}
