import 'package:equatable/equatable.dart';
import '../../../data/models/message.dart';

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

  const MessageLoaded({
    required this.allMessages,
    this.selectedCategory = 'chat',
    this.isSyncing = false,
    this.searchQuery = '',
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

  MessageLoaded copyWith({List<Message>? allMessages, String? selectedCategory, bool? isSyncing, String? searchQuery}) {
    return MessageLoaded(
      allMessages: allMessages ?? this.allMessages,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isSyncing: isSyncing ?? this.isSyncing,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [allMessages, selectedCategory, isSyncing, searchQuery];
}

class MessageError extends MessageState {
  final String message;

  const MessageError(this.message);

  @override
  List<Object?> get props => [message];
}
