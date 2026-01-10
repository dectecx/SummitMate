import 'dart:async';
import '../../domain/interfaces/i_connectivity_service.dart';

/// Mock 連線服務
class MockConnectivityService implements IConnectivityService {
  @override
  bool get hasConnection => true;

  @override
  bool get isOfflineModeEnabled => false;

  @override
  bool get isOffline => false;

  @override
  bool get isOnline => true;

  @override
  Future<bool> checkConnectivity() async => true;

  @override
  Stream<bool> get onConnectivityChanged => Stream.value(true);

  @override
  void dispose() {}
}
