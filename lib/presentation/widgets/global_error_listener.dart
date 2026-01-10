import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../infrastructure/tools/toast_service.dart';
import '../cubits/sync/sync_cubit.dart';
import '../cubits/sync/sync_state.dart';

/// 全域錯誤監聽器
/// 
/// 負責監聽背景 Cubit 的錯誤狀態並顯示提示 (Toast/Snackbar)
/// 例如: 同步失敗、網路中斷等
class GlobalErrorListener extends StatelessWidget {
  final Widget child;

  const GlobalErrorListener({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // 監聽同步狀態
        BlocListener<SyncCubit, SyncState>(
          listener: (context, state) {
            if (state is SyncFailure) {
              ToastService.error('同步失敗: ${state.errorMessage}');
            } else if (state is SyncSuccess) {
              // 選擇性顯示成功訊息，避免太頻繁
              // ToastService.success(state.message);
            }
          },
        ),
        // 如果未來有其他全域錯誤 (如 Auth session 過期) 可在此加入
      ],
      child: child,
    );
  }
}
