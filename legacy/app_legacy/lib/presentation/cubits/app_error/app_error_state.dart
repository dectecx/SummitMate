import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_error_state.freezed.dart';

@freezed
class AppErrorState with _$AppErrorState {
  const factory AppErrorState.initial() = _Initial;

  /// 顯示 Toast/Snackbar 訊息
  const factory AppErrorState.showToast(
    String message, {
    @Default(false) bool isPersistent,
    @Default(true) bool isError,
  }) = _ShowToast;

  /// 顯示對話框訊息
  const factory AppErrorState.showDialog({
    @Default('發生錯誤') String title,
    required String message,
    String? retryText,
    String? errorDetail,
  }) = _ShowDialog;

  /// 認證過期，需要重新登入
  const factory AppErrorState.authenticationExpired() = _AuthenticationExpired;

  /// 網路連線中斷
  const factory AppErrorState.networkOffline() = _NetworkOffline;

  /// 網路請求逾時
  const factory AppErrorState.networkTimeout() = _NetworkTimeout;
}
