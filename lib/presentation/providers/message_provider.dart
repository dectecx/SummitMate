import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants.dart';
import '../../core/di.dart';
import '../../data/models/message.dart';
import '../../data/repositories/interfaces/i_message_repository.dart';
import '../../data/repositories/interfaces/i_trip_repository.dart';
import '../../services/sync_service.dart';
import '../../services/toast_service.dart';
import '../../services/log_service.dart';

/// 留言狀態管理
class MessageProvider extends ChangeNotifier {
  final IMessageRepository _repository;
  final ITripRepository _tripRepository;
  final SyncService _syncService;
  final Uuid _uuid = const Uuid();

  List<Message> _allMessages = [];
  String _selectedCategory = MessageCategory.chat;
  bool _isLoading = true;
  bool _isSyncing = false;
  String? _error;

  /// 行程同步完成回調 (供 UI 調用以通知 ItineraryProvider)
  VoidCallback? onItinerarySynced;

  /// 同步完成回調 (供 UI 調用以更新 lastSyncTime)
  void Function(DateTime)? onSyncComplete;

  MessageProvider({IMessageRepository? repository, ITripRepository? tripRepository})
    : _repository = repository ?? getIt<IMessageRepository>(),
      _tripRepository = tripRepository ?? getIt<ITripRepository>(),
      _syncService = getIt<SyncService>() {
    _loadMessages();
  }

  /// 當前行程 ID
  String? get _currentTripId => _tripRepository.getActiveTrip()?.id;

  /// 所有留言
  List<Message> get allMessages => _allMessages;

  /// 當前分類的主留言 (非回覆)
  List<Message> get currentCategoryMessages =>
      _allMessages.where((msg) => msg.category == _selectedCategory && !msg.isReply).toList()
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

      final allMessages = _repository.getAllMessages();
      // 篩選當前行程的留言 (或全域留言 tripId == null)
      if (_currentTripId != null) {
        _allMessages = allMessages.where((msg) => msg.tripId == null || msg.tripId == _currentTripId).toList();
      } else {
        _allMessages = allMessages;
      }
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
    return _allMessages.where((msg) => msg.parentId == parentUuid).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// 新增留言
  Future<void> addMessage({
    required String user,
    required String avatar,
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
        avatar: avatar,
        tripId: _currentTripId,
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

  /// 同步留言 (支援 isAuto 冷卻)
  Future<void> sync({bool isAuto = false}) async {
    try {
      _isSyncing = true;
      _error = null;
      notifyListeners();

      LogService.info('開始同步留言...', source: 'Message');

      // 只同步留言
      final result = await _syncService.syncMessages(isAuto: isAuto);

      if (result.success) {
        if (result.messagesSynced) {
          LogService.info('留言同步成功', source: 'Message');
          ToastService.success('留言同步成功！');
        } else {
          LogService.debug('留言同步跳過 (節流或無需更新)', source: 'Message');
        }
      } else {
        LogService.error('留言同步失敗: ${result.errors.first}', source: 'Message');
        ToastService.error('同步失敗：${result.errors.first}');
        _error = result.errors.join(', ');
      }

      // 重新載入留言
      _loadMessages();
      LogService.debug('載入 ${_allMessages.length} 則留言', source: 'Message');

      // 通知同步完成以更新 lastSyncTime
      if (result.success && onSyncComplete != null) {
        onSyncComplete!(result.syncedAt);
      }

      _isSyncing = false;
      notifyListeners();
    } catch (e) {
      LogService.error('留言同步異常: $e', source: 'Message');
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
