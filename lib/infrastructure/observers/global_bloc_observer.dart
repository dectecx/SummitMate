import 'package:flutter_bloc/flutter_bloc.dart';
import '../tools/log_service.dart';

class GlobalBlocObserver extends BlocObserver {
  final String _source = 'BlocObserver';

  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    LogService.debug('onCreate: ${bloc.runtimeType}', source: _source);
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    LogService.debug('onEvent: ${bloc.runtimeType}, event: $event', source: _source);
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    // 記錄狀態變更。
    // 若 nextState 太過冗長，可考慮限制長度。
    // 暫時記錄簡化的變更資訊。
    LogService.debug(
      'onChange: ${bloc.runtimeType}, current: ${change.currentState.runtimeType}, next: ${change.nextState.runtimeType}',
      source: _source,
    );
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    LogService.debug(
      'onTransition: ${bloc.runtimeType}, event: ${transition.event}, nextState: ${transition.nextState.runtimeType}',
      source: _source,
    );
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    LogService.error('onError: ${bloc.runtimeType} - $error', source: _source, stackTrace: stackTrace);
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    LogService.debug('onClose: ${bloc.runtimeType}', source: _source);
  }
}
