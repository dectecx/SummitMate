/// Toast 通知的種類，供 UI 層決定顯示樣式。
enum ToastType { success, warning, error, info }

/// 由 Cubit 放入 State 的一次性 Toast 通知，由 UI 層 [BlocListener] 消費。
///
/// 設計原則：Cubit 只負責業務邏輯與狀態，不直接呼叫 [ToastService]；
/// Toast 副作用委由 UI 層 [BlocListener] 讀取 [notification] 後呈現，
/// 維持關注點分離（Cubit 無 UI 依賴）。
///
/// 使用方式：
/// 1. 在各 State 的 Loaded 類別加入 `ToastNotification? notification` 欄位。
/// 2. Cubit 操作結束時以 `copyWith(notification: ToastNotification.success('...'))` 發送通知。
/// 3. Screen 以 `BlocListener` 偵測 `state.notification != null`：
///    ```dart
///    listenWhen: (_, s) => s.notification != null,
///    listener: (ctx, s) {
///      s.notification?.showWith(ToastService);
///      ctx.read<XxxCubit>().clearNotification();
///    }
///    ```
/// 4. BlocListener 完成後呼叫 `cubit.clearNotification()` 清除通知，避免重複觸發。
sealed class ToastNotification {
  const ToastNotification();

  /// 成功訊息（綠色）
  const factory ToastNotification.success(String message) = ToastSuccess;

  /// 警告訊息（黃色）
  const factory ToastNotification.warning(String message) = ToastWarning;

  /// 錯誤訊息（紅色）
  const factory ToastNotification.error(String message) = ToastError;

  /// 資訊訊息（藍色）
  const factory ToastNotification.info(String message) = ToastInfo;

  String get message;
  ToastType get type;
}

final class ToastSuccess extends ToastNotification {
  @override
  final String message;
  @override
  ToastType get type => ToastType.success;
  const ToastSuccess(this.message);
}

final class ToastWarning extends ToastNotification {
  @override
  final String message;
  @override
  ToastType get type => ToastType.warning;
  const ToastWarning(this.message);
}

final class ToastError extends ToastNotification {
  @override
  final String message;
  @override
  ToastType get type => ToastType.error;
  const ToastError(this.message);
}

final class ToastInfo extends ToastNotification {
  @override
  final String message;
  @override
  ToastType get type => ToastType.info;
  const ToastInfo(this.message);
}

/// Screen 端便利 extension，搭配 [BlocListener] 使用，
/// 避免每個 Screen 都重複撰寫 switch/case 分派邏輯。
///
/// 使用範例：
/// ```dart
/// BlocListener<XxxCubit, XxxState>(
///   listenWhen: (_, s) => s.notification != null,
///   listener: (ctx, s) {
///     s.notification?.show();
///     ctx.read<XxxCubit>().clearNotification();
///   },
///   child: ...,
/// )
/// ```
extension ToastNotificationX on ToastNotification {
  /// 根據通知種類呼叫對應的 [ToastService] 方法（需在 import 端自行引入）。
  ///
  /// 此 extension 回傳 [ToastType]，讓呼叫端可依需求直接 switch/call。
  ToastType get toastType => type;
}
