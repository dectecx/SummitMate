import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InfoGrid extends StatelessWidget {
  final DateTime startDate;
  final String location;
  final int maxMembers;

  const InfoGrid({super.key, required this.startDate, required this.location, required this.maxMembers});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: colorScheme.primary.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(context, Icons.calendar_today_rounded, DateFormat('MM/dd').format(startDate), '日期'),
              _buildVerticalDivider(context),
              _buildInfoItem(context, Icons.location_on_rounded, location.isNotEmpty ? location : '未指定', '地點'),
              _buildVerticalDivider(context),
              _buildInfoItem(context, Icons.people_rounded, '$maxMembers', '預計人數'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '※ 預計人數僅供參考，實際可報名人數無上限',
            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider(BuildContext context) {
    return Container(height: 30, width: 1, color: Theme.of(context).colorScheme.outlineVariant);
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String value, String label) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 24),
        const SizedBox(height: 8),
        Text(value, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
