import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../../../domain/enums/group_event_application_status.dart';

class PrivateMessageSection extends StatelessWidget {
  final String privateMessage;
  final GroupEventApplicationStatus? myApplicationStatus;
  final bool isCreator;

  const PrivateMessageSection({
    super.key,
    required this.privateMessage,
    required this.myApplicationStatus,
    required this.isCreator,
  });

  @override
  Widget build(BuildContext context) {
    if (!((myApplicationStatus != null || isCreator) && privateMessage.isNotEmpty)) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                '報名成功訊息',
                style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          (isCreator || myApplicationStatus == GroupEventApplicationStatus.approved)
              ? Text(privateMessage, style: TextStyle(color: colorScheme.onSurface))
              : ClipRect(
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Text(privateMessage, style: TextStyle(color: colorScheme.onSurface)),
                  ),
                ),
          if (!isCreator && myApplicationStatus != GroupEventApplicationStatus.approved)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '※ 此訊息將於審核通過後顯示',
                style: TextStyle(fontSize: 12, color: colorScheme.primary.withValues(alpha: 0.8)),
              ),
            ),
        ],
      ),
    );
  }
}
