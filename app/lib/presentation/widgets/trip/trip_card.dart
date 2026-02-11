import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/trip.dart';
import 'package:summitmate/core/core.dart';

/// 行程卡片 Widget
///
/// 顯示單一行程的基本資訊，包含名稱、日期、角色、動作按鈕等。
class TripCard extends StatelessWidget {
  /// 行程資料
  final Trip trip;

  /// 是否為當前活動行程
  final bool isActive;

  /// 使用者在此行程的角色標籤
  final String roleLabel;

  /// 點擊卡片時的回調
  final VoidCallback onTap;

  /// 編輯行程回調 (若無權限則為 null)
  final VoidCallback? onEdit;

  /// 刪除行程回調 (若無權限則為 null)
  final VoidCallback? onDelete;

  /// 上傳行程回調 (若無權限則為 null)
  final VoidCallback? onUpload;

  /// 管理成員回調
  final VoidCallback? onManageMembers;

  /// 成員按鈕的 Key (用於教學導覽)
  final Key? memberBtnKey;

  const TripCard({
    super.key,
    required this.trip,
    required this.isActive,
    required this.roleLabel,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.onUpload,
    this.onManageMembers,
    this.memberBtnKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('yyyy/MM/dd');
    final dateText = trip.endDate != null
        ? '${dateFormat.format(trip.startDate)} - ${dateFormat.format(trip.endDate!)}'
        : dateFormat.format(trip.startDate);
    final isLeader = roleLabel == (RoleConstants.displayName[RoleConstants.leader] ?? 'Leader');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isActive ? colorScheme.primaryContainer.withValues(alpha: 0.1) : theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? colorScheme.primary : theme.dividerColor.withValues(alpha: 0.2),
          width: isActive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive ? colorScheme.primary.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.05),
            blurRadius: isActive ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Box
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isActive
                              ? [colorScheme.primary, colorScheme.tertiary]
                              : [Colors.grey.shade400, Colors.grey.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (isActive ? colorScheme.primary : Colors.grey).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.terrain, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  trip.name,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '進行中',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onPrimary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isLeader
                                      ? Colors.orange.withValues(alpha: 0.1)
                                      : Colors.blueGrey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isLeader
                                        ? Colors.orange.withValues(alpha: 0.3)
                                        : Colors.blueGrey.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  roleLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isLeader ? Colors.orange[800] : Colors.blueGrey[700],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.calendar_today, size: 12, color: theme.hintColor),
                              const SizedBox(width: 4),
                              Text(
                                dateText,
                                style: TextStyle(fontSize: 13, color: theme.hintColor, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          if (trip.description?.isNotEmpty == true) ...[
                            const SizedBox(height: 8),
                            Text(
                              trip.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13, color: theme.hintColor.withValues(alpha: 0.8)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.5)),
                const SizedBox(height: 8),
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _ActionButton(
                      icon: Icons.people_outline,
                      label: '成員',
                      onTap: onManageMembers,
                      keey: memberBtnKey,
                      color: colorScheme.primary,
                    ),
                    if (onEdit != null) ...[
                      const SizedBox(width: 8),
                      _ActionButton(
                        icon: Icons.edit_outlined,
                        label: '編輯',
                        onTap: onEdit,
                        color: colorScheme.secondary,
                      ),
                    ],
                    if (onUpload != null) ...[
                      const SizedBox(width: 8),
                      _ActionButton(
                        icon: Icons.cloud_upload_outlined,
                        label: '同步',
                        onTap: onUpload,
                        color: Colors.teal,
                      ),
                    ],
                    if (onDelete != null) ...[
                      const SizedBox(width: 8),
                      _ActionButton(
                        icon: Icons.delete_outline,
                        label: '刪除',
                        onTap: onDelete,
                        color: theme.colorScheme.error,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 行程卡片的動作按鈕
class _ActionButton extends StatelessWidget {
  /// 按鈕圖示
  final IconData icon;

  /// 按鈕標籤
  final String label;

  /// 點擊回調 (若為 null 則不顯示)
  final VoidCallback? onTap;

  /// 按鈕顏色
  final Color? color;

  /// 按鈕 Key (用於教學導覽)
  final Key? keey;

  const _ActionButton({required this.icon, required this.label, this.onTap, this.color, this.keey});

  @override
  Widget build(BuildContext context) {
    if (onTap == null) return const SizedBox.shrink();

    return InkWell(
      key: keey,
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
