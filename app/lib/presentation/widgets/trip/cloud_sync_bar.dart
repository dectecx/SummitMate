import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/infrastructure/infrastructure.dart';

import '../../cubits/trip/trip_cubit.dart';
import '../../cubits/trip/trip_state.dart';
import '../../cubits/settings/settings_cubit.dart';
import '../../cubits/settings/settings_state.dart';

/// 雲端同步狀態橫幅
///
/// 根據行程的雲端同步狀態顯示不同風格的橫幅：
/// - **未上傳** (`pendingCreate`): amber 底色，提示使用者上傳
/// - **有待更新** (`pendingUpdate`): 藍色底色，提示有本地修改未上傳
/// - **已同步** (`synced`): 隱藏 (依靠 AppBar SyncStatusIndicator)
///
/// 放置於 MainNavigationScreen body 最上方。
class CloudSyncBanner extends StatefulWidget {
  const CloudSyncBanner({super.key});

  @override
  State<CloudSyncBanner> createState() => _CloudSyncBannerState();
}

class _CloudSyncBannerState extends State<CloudSyncBanner> {
  bool _isUploading = false;
  bool _isExpanded = false;

  Future<void> _handleUpload() async {
    setState(() => _isUploading = true);
    try {
      final success = await context.read<TripCubit>().uploadActiveTrip();
      if (!mounted) return;
      if (success) {
        ToastService.success('行程已上傳至雲端');
      } else {
        ToastService.error('上傳失敗，請稍後再試');
      }
    } catch (e) {
      if (mounted) ToastService.error('上傳錯誤: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripCubit, TripState>(
      builder: (context, state) {
        if (state is! TripLoaded || state.activeTrip == null) {
          return const SizedBox.shrink();
        }

        final trip = state.activeTrip!;
        final syncStatus = trip.syncStatus;

        final settingsState = context.watch<SettingsCubit>().state;
        final isOffline = settingsState is SettingsLoaded && settingsState.isOfflineMode;

        // 判斷狀態
        final isLocalOnly = trip.isLocalOnly;
        final isPendingUpdate = syncStatus == SyncStatus.pendingUpdate;
        final isSynced = syncStatus == SyncStatus.synced;

        // 顏色與文字
        final Color bgColor;
        final Color textColor;
        final IconData icon;
        final String message;
        final String? subMessage;
        final String buttonText;
        final bool showButton;

        if (isLocalOnly) {
          bgColor = Colors.amber.shade50;
          textColor = Colors.amber.shade900;
          icon = Icons.cloud_off_outlined;
          message = '此行程尚未上傳至雲端';
          subMessage = '留言板與投票等功能需上傳後才可使用';
          buttonText = '立即上傳';
          showButton = true;
        } else if (isPendingUpdate) {
          bgColor = Colors.blue.shade50;
          textColor = Colors.blue.shade900;
          icon = Icons.cloud_upload_outlined;
          message = '本地有修改尚未上傳';
          subMessage = trip.cloudSyncedAt != null
              ? '上次同步: ${DateFormat('MM/dd HH:mm').format(trip.cloudSyncedAt!)}'
              : null;
          buttonText = '上傳更新';
          showButton = true;
        } else if (isSynced) {
          // 已同步狀態：顯示簡短資訊，點擊可展開
          bgColor = Theme.of(context).colorScheme.surface;
          textColor = Theme.of(context).colorScheme.onSurfaceVariant;
          icon = Icons.cloud_done_outlined;
          message = '行程已與雲端同步';
          subMessage = trip.cloudSyncedAt != null
              ? '最後同步時間: ${DateFormat('MM/dd HH:mm').format(trip.cloudSyncedAt!)}'
              : null;
          buttonText = '重新同步';
          showButton = false; // 已同步時預設不顯示按鈕，除非展開或有需要
        } else {
          bgColor = Colors.grey.shade100;
          textColor = Colors.grey.shade700;
          icon = Icons.sync_problem_outlined;
          message = '同步狀態異常';
          subMessage = null;
          buttonText = '重新上傳';
          showButton = true;
        }

        return InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(bottom: BorderSide(color: textColor.withValues(alpha: 0.1), width: 1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: textColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isExpanded && subMessage != null ? '$message · $subMessage' : message,
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor,
                          fontWeight: isSynced ? FontWeight.normal : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (showButton && !isOffline)
                      SizedBox(
                        height: 28,
                        child: TextButton(
                          onPressed: _isUploading ? null : _handleUpload,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: _isUploading
                              ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                              : Text(buttonText, style: const TextStyle(fontSize: 11)),
                        ),
                      )
                    else if (isOffline && !isSynced)
                      Text('離線模式', style: TextStyle(fontSize: 11, color: Colors.grey.shade600))
                    else
                      Icon(
                        _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 16,
                        color: textColor.withValues(alpha: 0.5),
                      ),
                  ],
                ),
                if (_isExpanded && isSynced && !isOffline) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isUploading ? null : _handleUpload,
                      icon: const Icon(Icons.sync, size: 14),
                      label: const Text('手動重新同步', style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
