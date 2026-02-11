import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/di.dart';
import '../../../../data/models/group_event_comment.dart';
import '../../cubits/group_event/comment/group_event_comment_cubit.dart';
import '../../cubits/group_event/comment/group_event_comment_state.dart';

class GroupEventCommentSheet extends StatefulWidget {
  final String eventId;

  const GroupEventCommentSheet({super.key, required this.eventId});

  static void show(BuildContext context, String eventId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GroupEventCommentSheet(eventId: eventId),
    );
  }

  @override
  State<GroupEventCommentSheet> createState() => _GroupEventCommentSheetState();
}

class _GroupEventCommentSheetState extends State<GroupEventCommentSheet> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<GroupEventCommentCubit>(param1: widget.eventId)..loadComments(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.comment, size: 20),
                  const SizedBox(width: 8),
                  Text('留言板', style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            const Divider(height: 1),

            // Content
            Expanded(
              child: BlocConsumer<GroupEventCommentCubit, GroupEventCommentState>(
                listener: (context, state) {
                  if (state is GroupEventCommentError) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
                  }
                },
                builder: (context, state) {
                  if (state is GroupEventCommentLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is GroupEventCommentLoaded) {
                    if (state.comments.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('尚無留言，搶頭香！', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: state.comments.length,
                      itemBuilder: (context, index) {
                        final comment = state.comments[index];
                        return _CommentItem(
                          comment: comment,
                          isMe: comment.userId == context.read<GroupEventCommentCubit>().currentUserId,
                          onDelete: () => _confirmDelete(context, comment),
                        );
                      },
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),

            // Input Area
            BlocBuilder<GroupEventCommentCubit, GroupEventCommentState>(
              builder: (context, state) {
                final isSending = state is GroupEventCommentLoaded && state.isSending;
                return Container(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 12,
                    bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), offset: const Offset(0, -2), blurRadius: 10),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          enabled: !isSending,
                          decoration: InputDecoration(
                            hintText: '輸入留言...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        icon: isSending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send),
                        onPressed: isSending ? null : () => _sendMessage(context),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(BuildContext context) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<GroupEventCommentCubit>().addComment(text);
    _controller.clear();
    // Scroll to bottom after slight delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _confirmDelete(BuildContext context, GroupEventComment comment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除留言'),
        content: const Text('確定要刪除這則留言嗎？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<GroupEventCommentCubit>().deleteComment(comment.id);
            },
            child: const Text('刪除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _CommentItem extends StatelessWidget {
  final GroupEventComment comment;
  final bool isMe;
  final VoidCallback onDelete;

  const _CommentItem({required this.comment, required this.isMe, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            child: Text(comment.userAvatar.isNotEmpty ? comment.userAvatar : comment.userName.substring(0, 1)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(comment.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MM/dd HH:mm').format(comment.createdAt),
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onLongPress: isMe ? onDelete : null,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(0),
                        topRight: const Radius.circular(12),
                        bottomLeft: const Radius.circular(12),
                        bottomRight: const Radius.circular(12),
                      ).resolve(Directionality.of(context)),
                    ),
                    child: Text(comment.content),
                  ),
                ),
                if (isMe)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: InkWell(
                      onTap: onDelete,
                      child: const Text('刪除', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
