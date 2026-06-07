import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/connectivity/connectivity_cubit.dart';

/// 離線功能攔截保護元件
///
/// 當處於離線狀態時，會自動將子元件變為半透明並停用所有互動。
/// 可設定 [hideWhenOffline] 來完全隱藏子元件，或設定 [onOfflineTap] 在離線點擊時觸發自訂行為 (如 Toast 提示)。
class OfflineGate extends StatelessWidget {
  final Widget child;
  final VoidCallback? onOfflineTap;
  final bool hideWhenOffline;

  const OfflineGate({required this.child, this.onOfflineTap, this.hideWhenOffline = false, super.key});

  @override
  Widget build(BuildContext context) {
    final isOffline = context.watch<ConnectivityCubit>().state.isOffline;

    if (isOffline && hideWhenOffline) {
      return const SizedBox.shrink();
    }

    if (isOffline) {
      final gatedChild = Opacity(opacity: 0.5, child: IgnorePointer(ignoring: true, child: child));

      if (onOfflineTap != null) {
        return GestureDetector(onTap: onOfflineTap, behavior: HitTestBehavior.opaque, child: gatedChild);
      }
      return gatedChild;
    }

    return child;
  }
}
