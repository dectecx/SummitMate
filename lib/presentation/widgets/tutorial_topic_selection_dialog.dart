import 'package:flutter/material.dart';
import 'package:summitmate/infrastructure/infrastructure.dart';

/// 教學主題選擇對話框
///
/// 讓使用者選擇要觀看的教學主題
class TutorialTopicSelectionDialog extends StatelessWidget {
  const TutorialTopicSelectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    // 排除 'all'，放到最後單獨處理
    final topics = TutorialTopic.values.where((t) => t != TutorialTopic.all).toList();

    return AlertDialog(
      title: const Text('選擇教學主題'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 完整教學 (置頂且突出顯示)
            ListTile(
              leading: const Icon(Icons.menu_book, color: Colors.blue),
              title: Text(TutorialTopic.all.displayName),
              subtitle: Text(TutorialTopic.all.description),
              tileColor: Colors.blue.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              onTap: () => Navigator.pop(context, TutorialTopic.all),
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            // 個別主題
            ...topics.map(
              (topic) => ListTile(
                leading: _getTopicIcon(topic),
                title: Text(topic.displayName),
                subtitle: Text(topic.description),
                onTap: () => Navigator.pop(context, topic),
              ),
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('取消'))],
    );
  }

  Widget _getTopicIcon(TutorialTopic topic) {
    switch (topic) {
      case TutorialTopic.itinerary:
        return const Icon(Icons.schedule, color: Colors.orange);
      case TutorialTopic.gear:
        return const Icon(Icons.backpack, color: Colors.green);
      case TutorialTopic.interaction:
        return const Icon(Icons.forum, color: Colors.purple);
      case TutorialTopic.info:
        return const Icon(Icons.info, color: Colors.teal);
      case TutorialTopic.groupEvent:
        return const Icon(Icons.groups, color: Colors.indigo);
      case TutorialTopic.all:
        return const Icon(Icons.menu_book, color: Colors.blue);
    }
  }
}

/// 顯示教學主題選擇對話框
///
/// 返回選擇的 [TutorialTopic]，若取消則返回 null
Future<TutorialTopic?> showTutorialTopicSelectionDialog(BuildContext context) {
  return showDialog<TutorialTopic>(context: context, builder: (context) => const TutorialTopicSelectionDialog());
}
