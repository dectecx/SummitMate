import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../presentation/providers/message_provider.dart';
import '../../presentation/providers/settings_provider.dart';

class MessageListScreen extends StatelessWidget {
  const MessageListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<MessageProvider, SettingsProvider>(
      builder: (context, messageProvider, settingsProvider, child) {
        return Scaffold(
          body: Column(
            children: [
              // 分類切換
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: 'Important', label: Text('重要'), icon: Icon(Icons.campaign_outlined)),
                          ButtonSegment(value: 'Chat', label: Text('討論'), icon: Icon(Icons.chat_bubble_outline)),
                          ButtonSegment(value: 'Gear', label: Text('裝備'), icon: Icon(Icons.backpack_outlined)),
                        ],
                        selected: {messageProvider.selectedCategory},
                        onSelectionChanged: (selected) {
                          messageProvider.selectCategory(selected.first);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // 留言列表
              Expanded(
                child: messageProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : messageProvider.currentCategoryMessages.isEmpty
                    ? const Center(child: Text('尚無留言，點擊右下角新增'))
                    : ListView.builder(
                        itemCount: messageProvider.currentCategoryMessages.length,
                        itemBuilder: (context, index) {
                          final msg = messageProvider.currentCategoryMessages[index];
                          final replies = messageProvider.getReplies(msg.uuid);

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
                                    onPressed: settingsProvider.isOfflineMode
                                        ? null
                                        : () => _showReplyDialog(
                                            context,
                                            messageProvider,
                                            settingsProvider.username,
                                            settingsProvider.avatar,
                                            msg.uuid,
                                          ),
                                    tooltip: '回覆',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20),
                                    onPressed: () => _confirmDelete(context, messageProvider, msg.uuid),
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
                                      subtitle: Text('${reply.user} · ${reply.timestamp.month}/${reply.timestamp.day}'),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18),
                                        onPressed: () => _confirmDelete(context, messageProvider, reply.uuid),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: settingsProvider.isOfflineMode ? Colors.grey : null,
            onPressed: settingsProvider.isOfflineMode
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ 離線模式下無法新增留言')));
                  }
                : () => _showAddMessageDialog(
                    context,
                    messageProvider,
                    settingsProvider.username,
                    settingsProvider.avatar,
                    null,
                  ),
            child: const Icon(Icons.add_comment),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, MessageProvider provider, String uuid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認刪除'),
        content: const Text('確定要刪除此留言嗎？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              provider.deleteMessage(uuid);
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
    MessageProvider provider,
    String username,
    String avatar,
    String parentId,
  ) {
    _showAddMessageDialog(context, provider, username, avatar, parentId);
  }

  void _showAddMessageDialog(
    BuildContext context,
    MessageProvider provider,
    String username,
    String avatar,
    String? parentId,
  ) {
    final contentController = TextEditingController();
    final isReply = parentId != null;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => StatefulBuilder(
        builder: (innerContext, setState) {
          bool isSubmitting = false;

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
              title: Text(isReply ? '回覆留言' : _getCategoryName(provider.selectedCategory)),
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
                              await provider.addMessage(
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
                  child: const Text('發送'),
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
