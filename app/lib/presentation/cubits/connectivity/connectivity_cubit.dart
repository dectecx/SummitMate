import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:summitmate/presentation/cubits/base/safe_emit_mixin.dart';
import 'package:injectable/injectable.dart';
import 'package:summitmate/domain/domain.dart';

import 'connectivity_state.dart';

/// 管理連線與離線狀態的 Cubit
@injectable
class ConnectivityCubit extends Cubit<ConnectivityState> with SafeEmitMixin<ConnectivityState> {
  final IConnectivityService _connectivityService;
  StreamSubscription<bool>? _connectivitySubscription;

  ConnectivityCubit(this._connectivityService)
      : super(ConnectivityInitial(isOffline: _connectivityService.isOffline)) {
    _init();
  }

  void _init() {
    _connectivitySubscription = _connectivityService.onConnectivityChanged.listen((isOnline) {
      safeEmit(ConnectivityUpdated(isOffline: !isOnline));
    });
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
