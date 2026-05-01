// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Settings {

 String get username; String get avatar; AppThemeType get theme; bool get isOfflineMode; bool get enableNotifications; String get language; bool get darkMode; DateTime? get lastSyncTime;
/// Create a copy of Settings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsCopyWith<Settings> get copyWith => _$SettingsCopyWithImpl<Settings>(this as Settings, _$identity);

  /// Serializes this Settings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Settings&&(identical(other.username, username) || other.username == username)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.theme, theme) || other.theme == theme)&&(identical(other.isOfflineMode, isOfflineMode) || other.isOfflineMode == isOfflineMode)&&(identical(other.enableNotifications, enableNotifications) || other.enableNotifications == enableNotifications)&&(identical(other.language, language) || other.language == language)&&(identical(other.darkMode, darkMode) || other.darkMode == darkMode)&&(identical(other.lastSyncTime, lastSyncTime) || other.lastSyncTime == lastSyncTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,username,avatar,theme,isOfflineMode,enableNotifications,language,darkMode,lastSyncTime);

@override
String toString() {
  return 'Settings(username: $username, avatar: $avatar, theme: $theme, isOfflineMode: $isOfflineMode, enableNotifications: $enableNotifications, language: $language, darkMode: $darkMode, lastSyncTime: $lastSyncTime)';
}


}

/// @nodoc
abstract mixin class $SettingsCopyWith<$Res>  {
  factory $SettingsCopyWith(Settings value, $Res Function(Settings) _then) = _$SettingsCopyWithImpl;
@useResult
$Res call({
 String username, String avatar, AppThemeType theme, bool isOfflineMode, bool enableNotifications, String language, bool darkMode, DateTime? lastSyncTime
});




}
/// @nodoc
class _$SettingsCopyWithImpl<$Res>
    implements $SettingsCopyWith<$Res> {
  _$SettingsCopyWithImpl(this._self, this._then);

  final Settings _self;
  final $Res Function(Settings) _then;

/// Create a copy of Settings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? username = null,Object? avatar = null,Object? theme = null,Object? isOfflineMode = null,Object? enableNotifications = null,Object? language = null,Object? darkMode = null,Object? lastSyncTime = freezed,}) {
  return _then(_self.copyWith(
username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,avatar: null == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as String,theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as AppThemeType,isOfflineMode: null == isOfflineMode ? _self.isOfflineMode : isOfflineMode // ignore: cast_nullable_to_non_nullable
as bool,enableNotifications: null == enableNotifications ? _self.enableNotifications : enableNotifications // ignore: cast_nullable_to_non_nullable
as bool,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,darkMode: null == darkMode ? _self.darkMode : darkMode // ignore: cast_nullable_to_non_nullable
as bool,lastSyncTime: freezed == lastSyncTime ? _self.lastSyncTime : lastSyncTime // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Settings].
extension SettingsPatterns on Settings {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Settings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Settings() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Settings value)  $default,){
final _that = this;
switch (_that) {
case _Settings():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Settings value)?  $default,){
final _that = this;
switch (_that) {
case _Settings() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String username,  String avatar,  AppThemeType theme,  bool isOfflineMode,  bool enableNotifications,  String language,  bool darkMode,  DateTime? lastSyncTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Settings() when $default != null:
return $default(_that.username,_that.avatar,_that.theme,_that.isOfflineMode,_that.enableNotifications,_that.language,_that.darkMode,_that.lastSyncTime);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String username,  String avatar,  AppThemeType theme,  bool isOfflineMode,  bool enableNotifications,  String language,  bool darkMode,  DateTime? lastSyncTime)  $default,) {final _that = this;
switch (_that) {
case _Settings():
return $default(_that.username,_that.avatar,_that.theme,_that.isOfflineMode,_that.enableNotifications,_that.language,_that.darkMode,_that.lastSyncTime);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String username,  String avatar,  AppThemeType theme,  bool isOfflineMode,  bool enableNotifications,  String language,  bool darkMode,  DateTime? lastSyncTime)?  $default,) {final _that = this;
switch (_that) {
case _Settings() when $default != null:
return $default(_that.username,_that.avatar,_that.theme,_that.isOfflineMode,_that.enableNotifications,_that.language,_that.darkMode,_that.lastSyncTime);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Settings extends Settings {
  const _Settings({this.username = '', this.avatar = '🐻', this.theme = AppThemeType.nature, this.isOfflineMode = true, this.enableNotifications = true, this.language = 'zh', this.darkMode = false, this.lastSyncTime}): super._();
  factory _Settings.fromJson(Map<String, dynamic> json) => _$SettingsFromJson(json);

@override@JsonKey() final  String username;
@override@JsonKey() final  String avatar;
@override@JsonKey() final  AppThemeType theme;
@override@JsonKey() final  bool isOfflineMode;
@override@JsonKey() final  bool enableNotifications;
@override@JsonKey() final  String language;
@override@JsonKey() final  bool darkMode;
@override final  DateTime? lastSyncTime;

/// Create a copy of Settings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SettingsCopyWith<_Settings> get copyWith => __$SettingsCopyWithImpl<_Settings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SettingsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Settings&&(identical(other.username, username) || other.username == username)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.theme, theme) || other.theme == theme)&&(identical(other.isOfflineMode, isOfflineMode) || other.isOfflineMode == isOfflineMode)&&(identical(other.enableNotifications, enableNotifications) || other.enableNotifications == enableNotifications)&&(identical(other.language, language) || other.language == language)&&(identical(other.darkMode, darkMode) || other.darkMode == darkMode)&&(identical(other.lastSyncTime, lastSyncTime) || other.lastSyncTime == lastSyncTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,username,avatar,theme,isOfflineMode,enableNotifications,language,darkMode,lastSyncTime);

@override
String toString() {
  return 'Settings(username: $username, avatar: $avatar, theme: $theme, isOfflineMode: $isOfflineMode, enableNotifications: $enableNotifications, language: $language, darkMode: $darkMode, lastSyncTime: $lastSyncTime)';
}


}

/// @nodoc
abstract mixin class _$SettingsCopyWith<$Res> implements $SettingsCopyWith<$Res> {
  factory _$SettingsCopyWith(_Settings value, $Res Function(_Settings) _then) = __$SettingsCopyWithImpl;
@override @useResult
$Res call({
 String username, String avatar, AppThemeType theme, bool isOfflineMode, bool enableNotifications, String language, bool darkMode, DateTime? lastSyncTime
});




}
/// @nodoc
class __$SettingsCopyWithImpl<$Res>
    implements _$SettingsCopyWith<$Res> {
  __$SettingsCopyWithImpl(this._self, this._then);

  final _Settings _self;
  final $Res Function(_Settings) _then;

/// Create a copy of Settings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? username = null,Object? avatar = null,Object? theme = null,Object? isOfflineMode = null,Object? enableNotifications = null,Object? language = null,Object? darkMode = null,Object? lastSyncTime = freezed,}) {
  return _then(_Settings(
username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,avatar: null == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as String,theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as AppThemeType,isOfflineMode: null == isOfflineMode ? _self.isOfflineMode : isOfflineMode // ignore: cast_nullable_to_non_nullable
as bool,enableNotifications: null == enableNotifications ? _self.enableNotifications : enableNotifications // ignore: cast_nullable_to_non_nullable
as bool,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,darkMode: null == darkMode ? _self.darkMode : darkMode // ignore: cast_nullable_to_non_nullable
as bool,lastSyncTime: freezed == lastSyncTime ? _self.lastSyncTime : lastSyncTime // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
