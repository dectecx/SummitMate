import 'package:equatable/equatable.dart';
import 'package:summitmate/domain/domain.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final Settings settings;
  final bool hasSeenOnboarding;

  /// 一次性錯誤訊息（局部更新失敗時使用）
  ///
  /// 用於在「不離開 [SettingsLoaded]」的前提下，向 UI 傳遞一次性的錯誤提示，
  /// 避免整個設定畫面卡在 [SettingsError] 而導致後續操作全部失效。
  /// 採 transient 語意：任何未明確帶入 [transientError] 的 [copyWith] 都會將其清空，
  /// 因此一次成功的更新即可自動消除前一次的錯誤。
  final String? transientError;

  /// 建構子
  ///
  /// [settings] 設定資料模型
  /// [hasSeenOnboarding] 是否已看過導覽
  /// [transientError] 一次性錯誤訊息
  const SettingsLoaded({required this.settings, required this.hasSeenOnboarding, this.transientError});

  String get username => settings.username;
  String get avatar => settings.avatar;
  bool get isOfflineMode => settings.isOfflineMode;
  DateTime? get lastSyncTime => settings.lastSyncTime;

  SettingsLoaded copyWith({Settings? settings, bool? hasSeenOnboarding, String? transientError}) {
    return SettingsLoaded(
      settings: settings ?? this.settings,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
      transientError: transientError,
    );
  }

  @override
  List<Object?> get props => [settings, hasSeenOnboarding, transientError];
}

class SettingsError extends SettingsState {
  final String message;

  const SettingsError(this.message);

  @override
  List<Object?> get props => [message];
}
