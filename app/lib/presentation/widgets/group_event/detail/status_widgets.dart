import 'package:flutter/material.dart';
import '../../../../data/models/enums/group_event_status.dart';
import '../../../../data/models/enums/group_event_application_status.dart';

class StatusChip extends StatelessWidget {
  final GroupEventStatus status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color bg;
    Color text;
    String label;

    switch (status) {
      case GroupEventStatus.open:
        bg = theme.colorScheme.primary;
        text = theme.colorScheme.onPrimary;
        label = '招募中';
        break;
      case GroupEventStatus.closed:
        bg = theme.colorScheme.onSurfaceVariant;
        text = theme.colorScheme.surface;
        label = '已截止';
        break;
      case GroupEventStatus.cancelled:
        bg = theme.colorScheme.error;
        text = theme.colorScheme.onError;
        label = '已取消';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class StatusCard extends StatelessWidget {
  final GroupEventApplicationStatus status;

  const StatusCard({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color color;
    IconData icon;
    String text;

    switch (status) {
      case GroupEventApplicationStatus.pending:
        color = Colors.orange;
        icon = Icons.hourglass_empty;
        text = '審核中';
        break;
      case GroupEventApplicationStatus.approved:
        color = theme.colorScheme.primary;
        icon = Icons.check_circle;
        text = '已通過';
        break;
      case GroupEventApplicationStatus.rejected:
        color = theme.colorScheme.error;
        icon = Icons.cancel;
        text = '未通過';
        break;
      default:
        color = theme.colorScheme.outline;
        icon = Icons.info;
        text = '未知';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
