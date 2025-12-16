import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants.dart';
import '../../core/di.dart';
import '../../data/models/message.dart';
import '../../data/repositories/message_repository.dart';
import '../../services/sync_service.dart';
import '../../services/toast_service.dart';

/// 留言狀態管理
class MessageProvider extends ChangeNotifier {
  final MessageRepository _repository;
  final SyncService _syncService;
  final Uuid _uuid = const Uuid();

  List<Message> _allMessages = [];
  String _selectedCategory = MessageCategory.gear;
  bool _isLoading = true;
  bool _isSyncing = false;
  String? _error;

  /// 行程同步完成回調 (供 UI 調用以通知 ItineraryProvider)
  VoidCallback? onItinerarySynced;

  /// 同步完成回調 (供 UI 調用以更新 lastSyncTime)
  void Function(DateTime)? onSyncComplete;

  MessageProvider()
      : _repository = getIt<MessageRepository>(),
        _syncService = getIt<SyncService>() {
    _loadMessages();
  }

  /// 所有留言
  List<Message> get allMessages => _allMessages;

  /// 當前分類的主留言 (非回覆)
  List<Message> get currentCategoryMessages => _allMessages
      .where((msg) => msg.category == _selectedCategory && !msg.isReply)
      .toList()
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  /// 當前選擇的分類
  String get selectedCategory => _selectedCategory;

  /// 是否正在載入
  bool get isLoading => _isLoading;

  /// 是否正在同步
  bool get isSyncing => _isSyncing;

  /// 錯誤訊息
  String? get error => _error;

  /// 載入留言
  void _loadMessages() {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _allMessages = _repository.getAllMessages();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 切換分類
  void selectCategory(String category) {
    if (MessageCategory.all.contains(category)) {
      _selectedCategory = category;
      notifyListeners();
    }
  }

  /// 取得留言的回覆
  List<Message> getReplies(String parentUuid) {
    return _allMessages
        .where((msg) => msg.parentId == parentUuid)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// 新增留言
  Future<void> addMessage({
    required String user,
    required String content,
    String? parentId,
  }) async {
    try {
      final message = Message(
        uuid: _uuid.v4(),
        parentId: parentId,
        user: user,
        category: _selectedCategory,
        content: content,
        timestamp: DateTime.now(),
      );

      await _syncService.addMessageAndSync(message);
      _loadMessages();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 刪除留言
  Future<void> deleteMessage(String uuid) async {
    try {
      await _syncService.deleteMessageAndSync(uuid);
      _loadMessages();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 完整同步 (行程 + 留言)
  Future<void> sync() async {
    try {
      _isSyncing = true;
      _error = null;
      notifyListeners();

      debugPrint('📡 開始同步...');

      // 使用 syncAll 同時同步行程和留言
      final result = await _syncService.syncAll();

      debugPrint('📡 同步結果: success=${result.success}, itinerary=${result.itinerarySynced}, messages=${result.messagesSynced}');
      if (result.errors.isNotEmpty) {
        debugPrint('📡 同步錯誤: ${result.errors}');
      }

      // 顯示同步結果 Toast
      if (result.success) {
        ToastService.success('同步成功！');
      } else {
        ToastService.error('同步失敗：${result.errors.first}');
        _error = result.errors.join(', ');
      }

      // 重新載入留言
      _loadMessages();
      debugPrint('📡 留言數量: ${_allMessages.length}');

      // 通知行程需要重載
      if (result.itinerarySynced && onItinerarySynced != null) {
        debugPrint('📡 通知行程重載');
        onItinerarySynced!();
      }

      // 通知同步完成以更新 lastSyncTime
      if (result.success && onSyncComplete != null) {
        debugPrint('📡 更新同步時間: ${result.syncedAt}');
        onSyncComplete!(result.syncedAt);
      }

      _isSyncing = false;
      notifyListeners();
    } catch (e, stack) {
      debugPrint('📡 同步異常: $e');
      debugPrint('📡 堆疊: $stack');
      ToastService.error('同步錯誤：$e');
      _error = e.toString();
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// 重新載入
  void reload() {
    _loadMessages();
  }
}
