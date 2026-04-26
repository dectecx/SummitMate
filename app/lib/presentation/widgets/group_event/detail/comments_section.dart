import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/group_event.dart';
import '../group_event_comment_sheet.dart';

class CommentsSection extends StatelessWidget {
  final GroupEvent event;

  const CommentsSection({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('留言板 (${event.commentCount})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => GroupEventCommentSheet.show(context, event.id),
              child: Text('查看全部', style: TextStyle(color: colorScheme.primary)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (event.latestComments.isNotEmpty)
          Column(
            children: event.latestComments
                .map(
                  (comment) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: colorScheme.secondaryContainer,
                          child: Text(comment.userAvatar, style: const TextStyle(fontSize: 14)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    comment.userName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    DateFormat('MM/dd HH:mm').format(comment.createdAt),
                                    style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                comment.content,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withValues(alpha: 0.8)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        InkWell(
          onTap: () => GroupEventCommentSheet.show(context, event.id),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                event.latestComments.isEmpty ? '尚無留言，成為第一個留言者！' : '查看更多留言...',
                style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
