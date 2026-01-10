import 'package:flutter/material.dart';
// import 'package:provider/provider.dart'; // Removed
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/sync/sync_cubit.dart';
import '../cubits/sync/sync_state.dart';
import '../cubits/message/message_cubit.dart';
import '../cubits/message/message_state.dart';
import '../cubits/settings/settings_cubit.dart';
import '../cubits/settings/settings_state.dart';

class MessageListScreen extends StatefulWidget {
  const MessageListScreen({super.key});

  @override
  State<MessageListScreen> createState() => _MessageListScreenState();
}

class _MessageListScreenState extends State<MessageListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<MessageCubit>().loadMessages();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SyncCubit, SyncState>(
          listener: (context, state) {
            if (state is SyncSuccess) {
              context.read<MessageCubit>().loadMessages();
            }
          },
        ),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settingsState) {
          // Default values
          String username = '';
          String avatar = '🐻';
          bool isOfflineMode = false;

          if (settingsState is SettingsLoaded) {
            username = settingsState.username;
            avatar = settingsState.avatar;
            isOfflineMode = settingsState.isOfflineMode;
          }

          return BlocBuilder<MessageCubit, MessageState>(
            builder: (context, messageState) {
              // Default values for initial/loading state
              String selectedCategory = 'Important';
              List<dynamic> currentMessages = [];
              bool isLoading = true;

              if (messageState is MessageLoaded) {
                selectedCategory = messageState.selectedCategory;
                currentMessages = messageState.currentCategoryMessages;
                isLoading = false;
              } else if (messageState is MessageLoading) {
                isLoading = true;
              } else if (messageState is MessageError) {
                isLoading = false;
              }

              // Determine if specific category messages are empty
              final isListEmpty = !isLoading && currentMessages.isEmpty;

              return Scaffold(
                body: Column(
                  children: [
                    // 分類切換
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: SegmentedButton<String>(
                              showSelectedIcon: false,
                              segments: const [
                                ButtonSegment(value: 'Important', label: Text('📢 重要')),
                                ButtonSegment(value: 'Chat', label: Text('💬 討論')),
                                ButtonSegment(value: 'Gear', label: Text('🎒 裝備')),
                              ],
                              selected: {selectedCategory},
                              onSelectionChanged: (selected) {
                                context.read<MessageCubit>().selectCategory(selected.first);
                              },
                              style: ButtonStyle(
                                visualDensity: VisualDensity.compact,
                                textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12)),
                                padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 4)),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                side: WidgetStateProperty.all(const BorderSide(color: Colors.grey, width: 0.5)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Last Updated Timestamp & Refresh
                          BlocBuilder<SyncCubit, SyncState>(
                            builder: (context, syncState) {
                              DateTime? lastSync;
                              bool isSyncing = false;

                              if (syncState is SyncInitial) {
                                lastSync = syncState.lastSyncTime;
                              } else if (syncState is SyncSuccess) {
                                lastSync = syncState.timestamp;
                              } else if (syncState is SyncInProgress) {
                                isSyncing = true;
                              } else if (syncState is SyncFailure) {
                                lastSync = syncState.lastSuccessTime;
                              }

                              final timeStr = lastSync != null
                                  ? DateFormat('MM/dd HH:mm').format(lastSync.toLocal())
                                  : '未同步';

                              return Material(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                child: InkWell(
                                  onTap: () => context.read<SyncCubit>().syncAll(force: true),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(timeStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                        const SizedBox(width: 4),
                                        if (isSyncing)
                                          const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        else
                                          const Icon(Icons.sync, size: 16, color: Colors.grey),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    // 留言列表
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : isListEmpty
                          ? const Center(child: Text('尚無留言，點擊右下角新增'))
                          : RefreshIndicator(
                              onRefresh: () async => context.read<SyncCubit>().syncAll(force: true),
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: currentMessages.length,
                                itemBuilder: (context, index) {
                                  // Explicit cast to Message if needed, but dynamic should work or type check
                                  // messageState is MessageLoaded, so filteredMessages is List<Message>
                                  final msg = (messageState as MessageLoaded).currentCategoryMessages[index];
                                  final replies = messageState.getReplies(msg.uuid);

                                  return Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: ExpansionTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                        child: Text(msg.avatar),
                                      ),
                                      title: Text(msg.content),
                                      subtitle: Text('${msg.user} · ${msg.timestamp.month}/${msg.timestamp.day}'),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (replies.isNotEmpty)
                                            Text('${replies.length}', style: Theme.of(context).textTheme.bodySmall),
                                          IconButton(
                                            icon: const Icon(Icons.reply, size: 20),
                                            onPressed: isOfflineMode
                                                ? null
                                                : () => _showReplyDialog(
                                                    context,
                                                    context.read<MessageCubit>(),
                                                    selectedCategory, // pass category for title logic
                                                    username,
                                                    avatar,
                                                    msg.uuid,
                                                  ),
                                            tooltip: '回覆',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 20),
                                            onPressed: () =>
                                                _confirmDelete(context, context.read<MessageCubit>(), msg.uuid),
                                            tooltip: '刪除',
                                          ),
                                        ],
                                      ),
                                      children: replies
                                          .map(
                                            (reply) => ListTile(
                                              leading: CircleAvatar(
                                                radius: 12,
                                                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                                child: Text(reply.avatar, style: const TextStyle(fontSize: 12)),
                                              ),
                                              title: Text(reply.content),
                                              subtitle: Text(
                                                '${reply.user} · ${reply.timestamp.month}/${reply.timestamp.day}',
                                              ),
                                              trailing: IconButton(
                                                icon: const Icon(Icons.delete_outline, size: 18),
                                                onPressed: () =>
                                                    _confirmDelete(context, context.read<MessageCubit>(), reply.uuid),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
                floatingActionButton: FloatingActionButton(
                  backgroundColor: isOfflineMode ? Colors.grey : null,
                  onPressed: isOfflineMode
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ 離線模式下無法新增留言')));
                        }
                      : () => _showAddMessageDialog(
                          context,
                          context.read<MessageCubit>(),
                          selectedCategory,
                          username,
                          avatar,
                          null,
                        ),
                  child: const Icon(Icons.add_comment),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, MessageCubit cubit, String uuid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認刪除'),
        content: const Text('確定要刪除此留言嗎？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              cubit.deleteMessage(uuid);
              Navigator.pop(context);
            },
            child: const Text('刪除'),
          ),
        ],
      ),
    );
  }

  void _showReplyDialog(
    BuildContext context,
    MessageCubit cubit,
    String category,
    String username,
    String avatar,
    String parentId,
  ) {
    _showAddMessageDialog(context, cubit, category, username, avatar, parentId);
  }

  void _showAddMessageDialog(
    BuildContext context,
    MessageCubit cubit,
    String category,
    String username,
    String avatar,
    String? parentId,
  ) {
    final contentController = TextEditingController();
    final isReply = parentId != null;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => StatefulBuilder(
        builder: (innerContext, setState) {
          Future<bool> checkDismiss() async {
            if (contentController.text.trim().isEmpty) return true;
            final confirm = await showDialog<bool>(
              context: dialogContext,
              builder: (ctx) => AlertDialog(
                title: const Text('捨棄留言？'),
                content: const Text('您有未發送的內容，確定要離開嗎？'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('繼續編輯')),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('捨棄'),
                  ),
                ],
              ),
            );
            return confirm ?? false;
          }

          return PopScope(
            canPop: false,
            onPopInvoked: (didPop) async {
              if (didPop) return;
              if (isSubmitting) return;
              final shouldPop = await checkDismiss();
              if (shouldPop && dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: AlertDialog(
              title: Text(isReply ? '回覆留言' : _getCategoryName(category)),
              content: SizedBox(
                width: 600,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isReply)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            CircleAvatar(child: Text(avatar)),
                            const SizedBox(width: 8),
                            Text('以 $username 的身分發言'),
                          ],
                        ),
                      ),
                    TextField(
                      controller: contentController,
                      enabled: !isSubmitting,
                      decoration: InputDecoration(
                        labelText: isReply ? '回覆內容' : '留言內容',
                        hintText: isReply ? '輸入您的回覆...' : '輸入您的留言...',
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 5,
                      minLines: 3,
                      textInputAction: TextInputAction.newline,
                      autofocus: true,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final shouldPop = await checkDismiss();
                          if (shouldPop && dialogContext.mounted) Navigator.pop(dialogContext);
                        },
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final content = contentController.text.trim();
                          if (content.isNotEmpty) {
                            setState(() => isSubmitting = true);
                            try {
                              await cubit.addMessage(
                                user: username.isNotEmpty ? username : 'Anonymous',
                                avatar: avatar,
                                content: content,
                                parentId: parentId,
                              );
                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('留言傳送成功！'), backgroundColor: Colors.green),
                                  );
                                }
                              }
                            } catch (e) {
                              if (innerContext.mounted) {
                                setState(() => isSubmitting = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(SnackBar(content: Text('傳送失敗: $e'), backgroundColor: Colors.red));
                                }
                              }
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('發送'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'Important':
        return '重要公告';
      case 'Chat':
        return '討論區';
      case 'Gear':
        return '裝備協調';
      default:
        return category;
    }
  }
}
