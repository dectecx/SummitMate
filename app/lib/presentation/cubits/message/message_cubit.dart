import 'package:injectable/injectable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/message.dart';
import '../../../data/repositories/interfaces/i_message_repository.dart';
import '../../../data/repositories/interfaces/i_trip_repository.dart';
import 'package:summitmate/domain/domain.dart';

import 'package:summitmate/infrastructure/infrastructure.dart';
import 'package:summitmate/core/core.dart';
import 'message_state.dart';

@injectable
class MessageCubit extends Cubit<MessageState> {
  final IMessageRepository _repository;
  final ITripRepository _tripRepository;
  final IAuthService _authService;
  final Uuid _uuid = const Uuid();

  static const String _source = 'MessageCubit';

  MessageCubit(this._repository, this._tripRepository, this._authService) : super(const MessageInitial());

  /// 取得當前活動行程 ID
  /// 取得當前活動行程 ID
  Future<String?> get _currentTripId async {
    final result = await _tripRepository.getActiveTrip(_authService.currentUserId ?? 'guest');
    return switch (result) {
      Success(value: final trip) => trip?.id,
      Failure() => null,
    };
  }

  Future<void> loadMessages() async {
    emit(const MessageLoading());
    try {
      await _refreshLocalMessages();
    } catch (e) {
      LogService.error('Failed to load messages: $e', source: _source);
      emit(MessageError(AppErrorHandler.getUserMessage(e)));
    }
  }

  Future<void> _refreshLocalMessages() async {
    final result = await _repository.getAllMessages();

    final List<Message> allMessages = switch (result) {
      Success(value: final m) => m,
      Failure(exception: final e) => throw e,
    };

    // 過濾邏輯：匹配 tripId 或全域 (tripId == null)
    // 且若 _currentTripId 已設定，則顯示該行程的留言
    final currentTripId = await _currentTripId;

    List<Message> filtered;
    if (currentTripId != null) {
      filtered = allMessages.where((msg) => msg.tripId == null || msg.tripId == currentTripId).toList();
    } else {
      // 若無活動行程 (例如首頁)，顯示全部或僅顯示全域？
      // 目前邏輯為顯示全部
      filtered = allMessages;
    }

    if (state is MessageLoaded) {
      emit((state as MessageLoaded).copyWith(allMessages: filtered));
    } else {
      emit(MessageLoaded(allMessages: filtered));
    }
  }

  void selectCategory(String category) {
    if (state is MessageLoaded) {
      emit((state as MessageLoaded).copyWith(selectedCategory: category));
    }
  }

  void setSearchQuery(String query) {
    if (state is MessageLoaded) {
      emit((state as MessageLoaded).copyWith(searchQuery: query));
    }
  }

  /// 新增留言
  ///
  /// [user] 使用者名稱
  /// [avatar] 頭像 URL
  /// [content] 留言內容
  /// [parentId] 父留言 ID (若為回覆)
  Future<void> addMessage({
    required String user,
    required String avatar,
    required String content,
    String? parentId,
  }) async {
    if (state is! MessageLoaded) return;
    final currentState = state as MessageLoaded;

    try {
      // 樂觀更新 (Optimistic Update)
      // 理想情況：建立物件 -> 儲存本地 Repo -> 觸發同步

      final message = Message(
        id: _uuid.v4(),
        parentId: parentId,
        user: user,
        category: currentState.selectedCategory,
        content: content,
        avatar: avatar,
        tripId: await _currentTripId,
        userId: _authService.currentUserId ?? '',
        timestamp: DateTime.now(),
        createdAt: DateTime.now(),
        createdBy: _authService.currentUserId ?? '',
        updatedAt: DateTime.now(),
        updatedBy: _authService.currentUserId ?? '',
      );

      final result = await _repository.addMessage(message);
      if (result is Failure) {
        throw result.exception;
      }

      // 刷新列表
      await _refreshLocalMessages();
    } catch (e) {
      LogService.error('Add message failed: $e', source: _source);
      emit(MessageError(AppErrorHandler.getUserMessage(e)));
      // 若需要，可恢復狀態
      await _refreshLocalMessages();
    }
  }

  /// 刪除留言
  ///
  /// [id] 留言 ID
  Future<void> deleteMessage(String id) async {
    try {
      final result = await _repository.deleteById(id);
      if (result is Failure) {
        throw result.exception;
      }
      await _refreshLocalMessages();
    } catch (e) {
      LogService.error('Delete message failed: $e', source: _source);
      emit(MessageError(AppErrorHandler.getUserMessage(e)));
      await _refreshLocalMessages();
    }
  }

  /// 同步留言
  Future<void> syncMessages({bool isAuto = false}) async {
    if (state is MessageLoaded) {
      emit((state as MessageLoaded).copyWith(isSyncing: true));
    }

    try {
      final tripId = await _currentTripId;
      if (tripId == null) {
        if (!isAuto) emit(const MessageError('找不到活動行程，無法同步'));
        return;
      }

      final result = await _repository.sync(tripId);

      if (result is Failure && !isAuto) {
        emit(MessageError(AppErrorHandler.getUserMessage(result.exception)));
      }

      await _refreshLocalMessages();
    } catch (e) {
      LogService.error('Sync failed: $e', source: _source);
      if (!isAuto) emit(MessageError(AppErrorHandler.getUserMessage(e)));
    } finally {
      if (state is MessageLoaded) {
        emit((state as MessageLoaded).copyWith(isSyncing: false));
      }
    }
  }

  void reset() {
    emit(const MessageInitial());
  }
}
