import 'dart:async';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../core/di.dart';
import '../data/repositories/interfaces/i_settings_repository.dart';
import 'log_service.dart';
import 'interfaces/i_connectivity_service.dart';

/// Connectivity Service
/// 統一管理網路連線狀態與離線模式
///
/// 整合：
/// - 實際網路狀態 (InternetConnectionChecker)
/// - App 離線模式設定 (settings.isOfflineMode)
class ConnectivityService implements IConnectivityService {
  static const String _source = 'Connectivity';

  final InternetConnectionChecker _checker;
  final ISettingsRepository _settingsRepo;

  StreamSubscription<InternetConnectionStatus>? _subscription;
  bool _hasConnection = true;

  final StreamController<bool> _onlineController = StreamController<bool>.broadcast();

  ConnectivityService({InternetConnectionChecker? checker, ISettingsRepository? settingsRepo})
    : _checker = checker ?? InternetConnectionChecker.createInstance(),
      _settingsRepo = settingsRepo ?? getIt<ISettingsRepository>() {
    _init();
  }

  /// 初始化：開始監聽網路變化
  void _init() {
    _subscription = _checker.onStatusChange.listen((status) {
      final wasOnline = _hasConnection;
      _hasConnection = status == InternetConnectionStatus.connected;

      if (wasOnline != _hasConnection) {
        LogService.info('網路狀態變更: ${_hasConnection ? "連線" : "斷線"}', source: _source);
        _onlineController.add(isOnline);
      }
    });

    // 初始檢查
    checkConnectivity();
  }

  /// 是否有實際網路連線
  @override
  bool get hasConnection => _hasConnection;

  /// App 是否啟用離線模式
  @override
  bool get isOfflineModeEnabled {
    try {
      return _settingsRepo.getSettings().isOfflineMode;
    } catch (e) {
      return false;
    }
  }

  /// 是否處於離線狀態 (無網路 OR 啟用離線模式)
  @override
  bool get isOffline => !_hasConnection || isOfflineModeEnabled;

  /// 是否處於線上狀態
  @override
  bool get isOnline => !isOffline;

  /// 主動檢查連線狀態
  @override
  Future<bool> checkConnectivity() async {
    _hasConnection = await _checker.hasConnection;
    LogService.debug(
      '連線檢查: ${_hasConnection ? "有網路" : "無網路"}, 離線模式: ${isOfflineModeEnabled ? "開" : "關"}',
      source: _source,
    );
    return isOnline;
  }

  /// 連線狀態變化串流
  @override
  Stream<bool> get onConnectivityChanged => _onlineController.stream;

  /// 釋放資源
  @override
  void dispose() {
    _subscription?.cancel();
    _onlineController.close();
  }
}
