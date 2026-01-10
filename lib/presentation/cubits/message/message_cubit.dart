import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/di.dart';
import '../../../data/models/message.dart';
import '../../../data/repositories/interfaces/i_message_repository.dart';
import '../../../data/repositories/interfaces/i_trip_repository.dart';
import '../../../domain/interfaces/i_sync_service.dart';
import '../../../infrastructure/tools/log_service.dart';
import 'message_state.dart';

class MessageCubit extends Cubit<MessageState> {
  final IMessageRepository _repository;
  final ITripRepository _tripRepository;
  final ISyncService _syncService;
  final Uuid _uuid = const Uuid();

  static const String _source = 'MessageCubit';

  MessageCubit({IMessageRepository? repository, ITripRepository? tripRepository, ISyncService? syncService})
    : _repository = repository ?? getIt<IMessageRepository>(),
      _tripRepository = tripRepository ?? getIt<ITripRepository>(),
      _syncService = syncService ?? getIt<ISyncService>(),
      super(const MessageInitial());

  /// Get active trip ID currently
  String? get _currentTripId => _tripRepository.getActiveTrip()?.id;

  Future<void> loadMessages() async {
    emit(const MessageLoading());
    try {
      _refreshLocalMessages();
    } catch (e) {
      LogService.error('Failed to load messages: $e', source: _source);
      emit(MessageError(e.toString()));
    }
  }

  void _refreshLocalMessages() {
    final allMessages = _repository.getAllMessages();
    // Filter logic: match tripId OR global (tripId == null)
    // AND if _currentTripId is set, show messages for that trip.

    List<Message> filtered;
    if (_currentTripId != null) {
      filtered = allMessages.where((msg) => msg.tripId == null || msg.tripId == _currentTripId).toList();
    } else {
      // If no trip active (e.g. home screen?), maybe show only global?
      // Or show all? Provider showed all if tripId was null in provider but logic was:
      // if (currentTripId != null) filter... else all.
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

  Future<void> addMessage({
    required String user,
    required String avatar,
    required String content,
    String? parentId,
  }) async {
    if (state is! MessageLoaded) return;
    final currentState = state as MessageLoaded;

    try {
      // Optimistic update?
      // Ideally we create object, save local repo, then trigger sync.

      final message = Message(
        uuid: _uuid.v4(),
        parentId: parentId,
        user: user,
        category: currentState.selectedCategory,
        content: content,
        avatar: avatar,
        tripId: _currentTripId,
        timestamp: DateTime.now(),
      );

      // Using SyncService to add and sync
      // It likely saves to repo internally
      await _syncService.addMessageAndSync(message);

      // Refresh
      _refreshLocalMessages();
    } catch (e) {
      LogService.error('Add message failed: $e', source: _source);
      emit(MessageError(e.toString()));
      // Recover state if needed
      _refreshLocalMessages();
    }
  }

  Future<void> deleteMessage(String uuid) async {
    try {
      await _syncService.deleteMessageAndSync(uuid);
      _refreshLocalMessages();
    } catch (e) {
      LogService.error('Delete message failed: $e', source: _source);
      emit(MessageError(e.toString()));
      _refreshLocalMessages();
    }
  }

  Future<void> syncMessages({bool isAuto = false}) async {
    if (state is MessageLoaded) {
      emit((state as MessageLoaded).copyWith(isSyncing: true));
    }

    try {
      final result = await _syncService.syncMessages(isAuto: isAuto);

      if (!result.isSuccess && !isAuto) {
        emit(MessageError(result.errors.join(', ')));
      }

      _refreshLocalMessages();
    } catch (e) {
      LogService.error('Sync failed: $e', source: _source);
      if (!isAuto) emit(MessageError(e.toString()));
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
