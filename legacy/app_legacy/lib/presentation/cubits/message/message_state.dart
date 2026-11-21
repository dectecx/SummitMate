import 'package:equatable/equatable.dart';
import 'package:summitmate/domain/domain.dart';

// Sentinel used in copyWith to distinguish "not provided" from "explicitly null".
const Object _kNoTransientError = Object();

abstract class MessageState extends Equatable {
  const MessageState();

  @override
  List<Object?> get props => [];
}

class MessageInitial extends MessageState {
  const MessageInitial();
}

class MessageLoading extends MessageState {
  const MessageLoading();
}

class MessageLoaded extends MessageState {
  final List<Message> allMessages;
  final String selectedCategory; // 'chat', 'gear', 'plan', 'misc'
  final bool isSyncing;
  final String searchQuery;

  /// 操作失敗時的一次性錯誤訊息（嵌入 Loaded 態，避免連續 emit 互相抵消）。
  /// UI 層以 BlocListener 偵測並顯示 SnackBar；_refreshLocalMessages 會將其清除。
  final String? transientError;

  /// 建構子
  ///
  /// [allMessages] 所有留言列表
  /// [selectedCategory] 選擇的分類 (預設 'chat')
  /// [isSyncing] 是否正在同步
  /// [searchQuery] 搜尋關鍵字
  /// [transientError] 一次性操作錯誤訊息
  const MessageLoaded({
    required this.allMessages,
    this.selectedCategory = 'chat',
    this.isSyncing = false,
    this.searchQuery = '',
    this.transientError,
  });

  /// Computed: Filtered messages for current view
  List<Message> get currentCategoryMessages =>
      allMessages
          .where(
            (msg) =>
                (msg.category.isEmpty ? 'chat' : msg.category) == selectedCategory &&
                !msg.isReply && // Only main messages
                (searchQuery.isEmpty || msg.content.contains(searchQuery)),
          )
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Newest first

  /// Helper to get replies for a message
  List<Message> getReplies(String parentId) =>
      allMessages.where((msg) => msg.parentId == parentId).toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp)); // Oldest first

  /// [transientError] 預設保留現有值；傳入 null 可明確清除。
  MessageLoaded copyWith({
    List<Message>? allMessages,
    String? selectedCategory,
    bool? isSyncing,
    String? searchQuery,
    Object? transientError = _kNoTransientError,
  }) {
    return MessageLoaded(
      allMessages: allMessages ?? this.allMessages,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isSyncing: isSyncing ?? this.isSyncing,
      searchQuery: searchQuery ?? this.searchQuery,
      transientError: identical(transientError, _kNoTransientError) ? this.transientError : transientError as String?,
    );
  }

  @override
  List<Object?> get props => [allMessages, selectedCategory, isSyncing, searchQuery, transientError];
}

class MessageError extends MessageState {
  final String message;

  const MessageError(this.message);

  @override
  List<Object?> get props => [message];
}
