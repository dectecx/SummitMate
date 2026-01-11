import 'dart:async';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../core/di.dart';
import '../../data/repositories/interfaces/i_settings_repository.dart';
import '../../domain/interfaces/i_connectivity_service.dart';
import '../tools/log_service.dart';

/// Connectivity Service
/// 統一管理網路連線狀態與離線模式
///
/// 整合：
/// - 實際網路狀態 (InternetConnectionChecker) - 具備防抖動 (Debounce) 機制
/// - App 離線模式設定 (settings.isOfflineMode) - 具備即時監聽機制
class ConnectivityService implements IConnectivityService {
  static const String _source = 'Connectivity';
  static const Duration _debounceDuration = Duration(seconds: 2);

  final InternetConnectionChecker _checker;
  final ISettingsRepository _settingsRepo;

  StreamSubscription<InternetConnectionStatus>? _netSubscription;
  StreamSubscription<dynamic>? _settingsSubscription;

  // 內部狀態
  bool _isNetworkConnected = true; // 硬體連線狀態
  bool _isOfflineMode = false; // 軟體設定狀態
  Timer? _debounceTimer;

  // 公開串流 (合併後的最終狀態: true=Online, false=Offline)
  final StreamController<bool> _onlineController = StreamController<bool>.broadcast();

  ConnectivityService({InternetConnectionChecker? checker, ISettingsRepository? settingsRepo})
    : _checker = checker ?? InternetConnectionChecker.createInstance(),
      _settingsRepo = settingsRepo ?? getIt<ISettingsRepository>() {
    _init();
  }

  /// 初始化：開始監聽
  void _init() {
    // 1. 初始化當前設定
    try {
      _isOfflineMode = _settingsRepo.getSettings().isOfflineMode;
    } catch (_) {
      _isOfflineMode = false;
    }

    // 2. 監聽設定變更 (即時回應離線模式切換)
    _settingsSubscription = _settingsRepo.watchSettings().listen((event) {
      final newOfflineMode = _settingsRepo.getSettings().isOfflineMode;
      if (_isOfflineMode != newOfflineMode) {
        _isOfflineMode = newOfflineMode;
        LogService.info('離線模式切換: ${_isOfflineMode ? "開啟" : "關閉"}', source: _source);
        _emitStatus();
      }
    });

    // 3. 監聽網路變更 (Debounce Filter)
    _netSubscription = _checker.onStatusChange.listen((status) {
      final isConnected = status == InternetConnectionStatus.connected;

      // 若狀態相同，忽略
      if (_isNetworkConnected == isConnected) return;

      // 若狀態改變，啟動/重置 Debounce Timer
      _debounceTimer?.cancel();
      _debounceTimer = Timer(_debounceDuration, () {
        if (_isNetworkConnected != isConnected) {
          _isNetworkConnected = isConnected;
          LogService.info('網路狀態變更 (已確認): ${_isNetworkConnected ? "連線" : "斷線"}', source: _source);
          _emitStatus();
        }
      });
    });

    // 4. 初始檢查
    checkConnectivity();
  }

  /// 發送最終狀態 (Online = 有網路 AND 未開啟離線模式)
  void _emitStatus() {
    _onlineController.add(isOnline);
  }

  /// 是否有實際網路連線 (硬體)
  @override
  bool get hasConnection => _isNetworkConnected;

  /// App 是否啟用離線模式 (軟體)
  @override
  bool get isOfflineModeEnabled => _isOfflineMode;

  /// 是否處於離線狀態 (無網路 OR 啟用離線模式)
  @override
  bool get isOffline => !_isNetworkConnected || _isOfflineMode;

  /// 是否處於線上狀態
  @override
  bool get isOnline => !isOffline;

  /// 主動檢查連線狀態 (更新內部狀態)
  @override
  Future<bool> checkConnectivity() async {
    // 同步更新設定狀態
    try {
      _isOfflineMode = _settingsRepo.getSettings().isOfflineMode;
    } catch (_) {}

    // 檢查實際網路
    final currentNetStatus = await _checker.hasConnection;

    // 若與當前紀錄不同，直接更新 (主動檢查不走 Debounce，假設當下即時需求)
    if (_isNetworkConnected != currentNetStatus) {
      _isNetworkConnected = currentNetStatus;
      LogService.info('主動檢查更新: ${_isNetworkConnected ? "有網路" : "無網路"}', source: _source);
    }

    // 不論有無變更，都確認一次狀態判定
    // (但只在有監聽者時發送，避免非預期觸發)
    // _emitStatus();

    LogService.debug(
      '連線檢查: ${_isNetworkConnected ? "有網路" : "無網路"}, 離線模式: ${_isOfflineMode ? "開" : "關"} => ${isOnline ? "線上" : "離線"}',
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
    _netSubscription?.cancel();
    _settingsSubscription?.cancel();
    _debounceTimer?.cancel();
    _onlineController.close();
  }
}
