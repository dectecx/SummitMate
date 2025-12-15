import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants.dart';
import '../../core/di.dart';
import '../../data/models/message.dart';
import '../../data/repositories/message_repository.dart';
import '../../services/sync_service.dart';

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

  /// 同步留言
  Future<void> sync() async {
    try {
      _isSyncing = true;
      _error = null;
      notifyListeners();

      final result = await _syncService.syncMessages();
      
      if (!result.success) {
        _error = result.errors.join(', ');
      }

      _loadMessages();
      _isSyncing = false;
      notifyListeners();
    } catch (e) {
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
