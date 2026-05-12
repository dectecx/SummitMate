import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:summitmate/infrastructure/infrastructure.dart';

import '../cubits/trip/trip_cubit.dart';
import '../cubits/trip/trip_state.dart';
import '../cubits/settings/settings_cubit.dart';
import '../cubits/settings/settings_state.dart';

/// 雲端功能防呆元件
///
/// 包裹需要行程已上傳至雲端才能使用的頁面或區塊。
/// 當行程尚未上傳時，顯示引導使用者上傳的畫面，避免操作 API 時收到「無權限」錯誤。
///
/// 使用範例：
/// ```dart
/// CloudGuard(
///   featureName: '留言板',
///   child: MessageListScreen(),
/// )
/// ```
class CloudGuard extends StatelessWidget {
  /// 被保護的子元件 (行程已同步時顯示)
  final Widget child;

  /// 功能名稱 (用於提示文字，如「留言板」、「投票活動」)
  final String featureName;

  /// 自訂圖示 (預設為 cloud_off)
  final IconData icon;

  const CloudGuard({super.key, required this.child, required this.featureName, this.icon = Icons.cloud_off_outlined});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripCubit, TripState>(
      builder: (context, state) {
        // 未載入行程 → 不攔截，讓子元件自行處理
        if (state is! TripLoaded) return child;

        // 行程已上傳雲端 → 放行
        if (state.isActiveTripCloudReady) return child;

        // 行程尚未上傳雲端 → 顯示攔截畫面
        return _buildBlockedView(context);
      },
    );
  }

  Widget _buildBlockedView(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final settingsState = context.watch<SettingsCubit>().state;
    final isOffline = settingsState is SettingsLoaded && settingsState.isOfflineMode;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, shape: BoxShape.circle),
              child: Icon(icon, size: 48, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              '需要先上傳行程至雲端',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              '$featureName 需要行程存在於雲端才能使用。\n請先將行程上傳至雲端後再進入此功能。',
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Upload button
            if (!isOffline)
              _UploadButton(featureName: featureName)
            else
              Column(
                children: [
                  Icon(Icons.wifi_off, color: Colors.grey, size: 20),
                  const SizedBox(height: 8),
                  Text('目前為離線模式，無法上傳', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// 上傳按鈕 (含 loading 狀態)
class _UploadButton extends StatefulWidget {
  final String featureName;

  const _UploadButton({required this.featureName});

  @override
  State<_UploadButton> createState() => _UploadButtonState();
}

class _UploadButtonState extends State<_UploadButton> {
  bool _isUploading = false;

  Future<void> _handleUpload() async {
    setState(() => _isUploading = true);

    try {
      final tripCubit = context.read<TripCubit>();
      final success = await tripCubit.uploadActiveTrip();

      if (!mounted) return;

      if (success) {
        ToastService.success('行程已上傳至雲端，${widget.featureName}已可使用');
      } else {
        ToastService.error('上傳失敗，請稍後再試');
      }
    } catch (e) {
      if (mounted) {
        ToastService.error('上傳發生錯誤: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: _isUploading ? null : _handleUpload,
      icon: _isUploading
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.cloud_upload),
      label: Text(_isUploading ? '上傳中...' : '立即上傳行程'),
      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
    );
  }
}
