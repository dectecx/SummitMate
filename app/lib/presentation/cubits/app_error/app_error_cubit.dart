import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:summitmate/core/error/api_exception.dart';
import 'package:summitmate/core/error/app_error_handler.dart';
import 'app_error_state.dart';

@lazySingleton
class AppErrorCubit extends Cubit<AppErrorState> {
  AppErrorCubit() : super(const AppErrorState.initial());

  /// 回報錯誤。如果是系統級錯誤（Auth, Timeout, Offline），會發送對應狀態並回傳 true。
  /// 如果是局部業務錯誤，會回傳 false，由呼叫端自行處理 UI 反饋。
  bool reportError(Object error) {
    // 檢查特殊錯誤類型
    if (AppErrorHandler.isAuthError(error)) {
      reportAuthExpired();
      return true;
    }

    if (AppErrorHandler.isTimeout(error)) {
      emit(const AppErrorState.networkTimeout());
      return true;
    }

    if (AppErrorHandler.isNetworkError(error)) {
      emit(const AppErrorState.networkOffline());
      return true;
    }

    return false;
  }

  /// 強制顯示 Toast 訊息
  void showToast(String message, {bool isError = true, bool isPersistent = false}) {
    emit(AppErrorState.showToast(message, isError: isError, isPersistent: isPersistent));
  }

  /// 回報重要錯誤，會顯示對話框
  void reportCriticalError(Object error, {String? title}) {
    final message = AppErrorHandler.getUserMessage(error);
    String? detail;

    if (error is ApiException) {
      detail = 'Code: ${error.code}\n${error.message}';
    }

    emit(AppErrorState.showDialog(title: title ?? '發生嚴重錯誤', message: message, errorDetail: detail));
  }

  /// 觸發認證失效狀態
  void reportAuthExpired() {
    emit(const AppErrorState.authenticationExpired());
  }

  /// 觸發網路斷線狀態
  void reportOffline() {
    emit(const AppErrorState.networkOffline());
  }

  /// 清除當前錯誤狀態
  void clearError() {
    emit(const AppErrorState.initial());
  }
}
