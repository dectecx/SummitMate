import 'package:equatable/equatable.dart';
import '../../../data/models/settings.dart';

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

  /// 建構子
  ///
  /// [settings] 設定資料模型
  /// [hasSeenOnboarding] 是否已看過導覽
  const SettingsLoaded({required this.settings, required this.hasSeenOnboarding});

  String get username => settings.username;
  String get avatar => settings.avatar;
  bool get isOfflineMode => settings.isOfflineMode;
  DateTime? get lastSyncTime => settings.lastSyncTime;

  SettingsLoaded copyWith({Settings? settings, bool? hasSeenOnboarding}) {
    return SettingsLoaded(
      settings: settings ?? this.settings,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
    );
  }

  @override
  List<Object?> get props => [settings, hasSeenOnboarding];
}

class SettingsError extends SettingsState {
  final String message;

  const SettingsError(this.message);

  @override
  List<Object?> get props => [message];
}
