import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:summitmate/infrastructure/infrastructure.dart';
import '../cubits/sync/sync_cubit.dart';
import '../cubits/sync/sync_state.dart';
import '../cubits/auth/auth_cubit.dart';
import '../cubits/auth/auth_state.dart';
import '../cubits/app_error/app_error_cubit.dart';
import '../cubits/app_error/app_error_state.dart';
import 'common/error_snackbar.dart';
import 'error_dialog.dart';

/// 全域錯誤監聽器
///
/// 負責監聽背景 Cubit 的錯誤狀態並顯示提示 (Toast/Snackbar)
/// 例如: 同步失敗、網路中斷等
class GlobalErrorListener extends StatelessWidget {
  final Widget child;

  const GlobalErrorListener({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // 監聽全局 App 錯誤
        BlocListener<AppErrorCubit, AppErrorState>(
          listener: (context, state) {
            state.whenOrNull(
              showToast: (message, isPersistent, isError) {
                if (isError) {
                  ErrorSnackbar.show(context, message: message, isPersistent: isPersistent);
                } else {
                  ToastService.success(message);
                }
              },
              showDialog: (title, message, retryText, errorDetail) {
                ErrorDialog.show(
                  context,
                  title: title,
                  message: message,
                  // 可以擴展 ErrorDialog 來顯示 errorDetail
                );
              },
              authenticationExpired: () {
                ErrorSnackbar.show(context, message: '登入已過期，請重新登入', isPersistent: true);
                // AuthCubit 會因為 interceptor 調用 logout 而更新 UI
              },
              networkOffline: () {
                ErrorSnackbar.show(context, message: '網路連線中斷，切換至離線模式');
              },
              networkTimeout: () {
                ErrorSnackbar.show(context, message: '連線逾時，請檢查網路狀況');
              },
            );
          },
        ),
        // 監聽同步狀態
        BlocListener<SyncCubit, SyncState>(
          listener: (context, state) {
            if (state is SyncFailure) {
              ErrorSnackbar.show(context, message: '同步失敗: ${state.errorMessage}');
            }
          },
        ),
        // 監聽認證錯誤
        BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              // 登入介面的錯誤通常由介面自己處理，但全域監聽可作為保底
              ErrorSnackbar.show(context, message: state.message);
            } else if (state is AuthRequiresVerification) {
              ToastService.info('請驗證您的 Email: ${state.email}');
            }
          },
        ),
      ],
      child: child,
    );
  }
}
