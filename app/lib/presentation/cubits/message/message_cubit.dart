import 'package:injectable/injectable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  static const String _source = 'MessageCubit';

  MessageCubit(this._repository, this._tripRepository, this._authService) : super(const MessageInitial());

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
    final currentTripId = await _currentTripId;
    if (currentTripId == null) {
      emit(const MessageError('尚未選擇行程'));
      return;
    }

    final messages = _repository.getByTripId(currentTripId);

    if (state is MessageLoaded) {
      emit((state as MessageLoaded).copyWith(allMessages: messages));
    } else {
      emit(MessageLoaded(allMessages: messages));
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

    try {
      final tripId = await _currentTripId;
      if (tripId == null) throw Exception('找不到活動行程');

      final result = await _repository.addMessage(tripId: tripId, content: content, replyToId: parentId);

      if (result case Failure(:final exception)) {
        throw exception;
      }

      // 刷新列表 (同步會由 Repository 處理或手動觸發)
      await syncMessages(isAuto: true);
    } catch (e) {
      LogService.error('Add message failed: $e', source: _source);
      emit(MessageError(AppErrorHandler.getUserMessage(e)));
      await _refreshLocalMessages();
    }
  }

  /// 刪除留言
  ///
  /// [id] 留言 ID
  Future<void> deleteMessage(String id) async {
    try {
      final tripId = await _currentTripId;
      if (tripId == null) throw Exception('找不到活動行程');

      final result = await _repository.deleteById(tripId, id);
      if (result case Failure(:final exception)) {
        throw exception;
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
    if (!isAuto && state is MessageLoaded) {
      emit((state as MessageLoaded).copyWith(isSyncing: true));
    }

    try {
      final tripId = await _currentTripId;
      if (tripId == null) {
        if (!isAuto) emit(const MessageError('找不到活動行程，無法同步'));
        return;
      }

      final result = await _repository.getRemoteMessages(tripId);

      if (result case Failure(:final exception) when !isAuto) {
        emit(MessageError(AppErrorHandler.getUserMessage(exception)));
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
