import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// 為 [Cubit] 提供受保護的 [safeEmit]，在 cubit 已關閉時跳過 emit，
/// 避免 async 回呼或 Stream listener 在 widget 卸載 / `close()` 之後
/// 觸發「Cannot emit new states after calling close」錯誤。
///
/// 用法：`class FooCubit extends Cubit<FooState> with SafeEmitMixin<FooState>`，
/// 並以 [safeEmit] 取代直接呼叫 `emit`。
mixin SafeEmitMixin<S> on Cubit<S> {
  @protected
  void safeEmit(S state) {
    if (!isClosed) emit(state);
  }
}
