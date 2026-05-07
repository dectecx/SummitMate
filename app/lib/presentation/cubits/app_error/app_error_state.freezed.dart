// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_error_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppErrorState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppErrorState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AppErrorState()';
}


}

/// @nodoc
class $AppErrorStateCopyWith<$Res>  {
$AppErrorStateCopyWith(AppErrorState _, $Res Function(AppErrorState) __);
}


/// Adds pattern-matching-related methods to [AppErrorState].
extension AppErrorStatePatterns on AppErrorState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Initial value)?  initial,TResult Function( _ShowToast value)?  showToast,TResult Function( _ShowDialog value)?  showDialog,TResult Function( _AuthenticationExpired value)?  authenticationExpired,TResult Function( _NetworkOffline value)?  networkOffline,TResult Function( _NetworkTimeout value)?  networkTimeout,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _ShowToast() when showToast != null:
return showToast(_that);case _ShowDialog() when showDialog != null:
return showDialog(_that);case _AuthenticationExpired() when authenticationExpired != null:
return authenticationExpired(_that);case _NetworkOffline() when networkOffline != null:
return networkOffline(_that);case _NetworkTimeout() when networkTimeout != null:
return networkTimeout(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Initial value)  initial,required TResult Function( _ShowToast value)  showToast,required TResult Function( _ShowDialog value)  showDialog,required TResult Function( _AuthenticationExpired value)  authenticationExpired,required TResult Function( _NetworkOffline value)  networkOffline,required TResult Function( _NetworkTimeout value)  networkTimeout,}){
final _that = this;
switch (_that) {
case _Initial():
return initial(_that);case _ShowToast():
return showToast(_that);case _ShowDialog():
return showDialog(_that);case _AuthenticationExpired():
return authenticationExpired(_that);case _NetworkOffline():
return networkOffline(_that);case _NetworkTimeout():
return networkTimeout(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Initial value)?  initial,TResult? Function( _ShowToast value)?  showToast,TResult? Function( _ShowDialog value)?  showDialog,TResult? Function( _AuthenticationExpired value)?  authenticationExpired,TResult? Function( _NetworkOffline value)?  networkOffline,TResult? Function( _NetworkTimeout value)?  networkTimeout,}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _ShowToast() when showToast != null:
return showToast(_that);case _ShowDialog() when showDialog != null:
return showDialog(_that);case _AuthenticationExpired() when authenticationExpired != null:
return authenticationExpired(_that);case _NetworkOffline() when networkOffline != null:
return networkOffline(_that);case _NetworkTimeout() when networkTimeout != null:
return networkTimeout(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function( String message,  bool isPersistent,  bool isError)?  showToast,TResult Function( String title,  String message,  String? retryText,  String? errorDetail)?  showDialog,TResult Function()?  authenticationExpired,TResult Function()?  networkOffline,TResult Function()?  networkTimeout,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _ShowToast() when showToast != null:
return showToast(_that.message,_that.isPersistent,_that.isError);case _ShowDialog() when showDialog != null:
return showDialog(_that.title,_that.message,_that.retryText,_that.errorDetail);case _AuthenticationExpired() when authenticationExpired != null:
return authenticationExpired();case _NetworkOffline() when networkOffline != null:
return networkOffline();case _NetworkTimeout() when networkTimeout != null:
return networkTimeout();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function( String message,  bool isPersistent,  bool isError)  showToast,required TResult Function( String title,  String message,  String? retryText,  String? errorDetail)  showDialog,required TResult Function()  authenticationExpired,required TResult Function()  networkOffline,required TResult Function()  networkTimeout,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _ShowToast():
return showToast(_that.message,_that.isPersistent,_that.isError);case _ShowDialog():
return showDialog(_that.title,_that.message,_that.retryText,_that.errorDetail);case _AuthenticationExpired():
return authenticationExpired();case _NetworkOffline():
return networkOffline();case _NetworkTimeout():
return networkTimeout();case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function( String message,  bool isPersistent,  bool isError)?  showToast,TResult? Function( String title,  String message,  String? retryText,  String? errorDetail)?  showDialog,TResult? Function()?  authenticationExpired,TResult? Function()?  networkOffline,TResult? Function()?  networkTimeout,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _ShowToast() when showToast != null:
return showToast(_that.message,_that.isPersistent,_that.isError);case _ShowDialog() when showDialog != null:
return showDialog(_that.title,_that.message,_that.retryText,_that.errorDetail);case _AuthenticationExpired() when authenticationExpired != null:
return authenticationExpired();case _NetworkOffline() when networkOffline != null:
return networkOffline();case _NetworkTimeout() when networkTimeout != null:
return networkTimeout();case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements AppErrorState {
  const _Initial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AppErrorState.initial()';
}


}




/// @nodoc


class _ShowToast implements AppErrorState {
  const _ShowToast(this.message, {this.isPersistent = false, this.isError = true});
  

 final  String message;
@JsonKey() final  bool isPersistent;
@JsonKey() final  bool isError;

/// Create a copy of AppErrorState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShowToastCopyWith<_ShowToast> get copyWith => __$ShowToastCopyWithImpl<_ShowToast>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShowToast&&(identical(other.message, message) || other.message == message)&&(identical(other.isPersistent, isPersistent) || other.isPersistent == isPersistent)&&(identical(other.isError, isError) || other.isError == isError));
}


@override
int get hashCode => Object.hash(runtimeType,message,isPersistent,isError);

@override
String toString() {
  return 'AppErrorState.showToast(message: $message, isPersistent: $isPersistent, isError: $isError)';
}


}

/// @nodoc
abstract mixin class _$ShowToastCopyWith<$Res> implements $AppErrorStateCopyWith<$Res> {
  factory _$ShowToastCopyWith(_ShowToast value, $Res Function(_ShowToast) _then) = __$ShowToastCopyWithImpl;
@useResult
$Res call({
 String message, bool isPersistent, bool isError
});




}
/// @nodoc
class __$ShowToastCopyWithImpl<$Res>
    implements _$ShowToastCopyWith<$Res> {
  __$ShowToastCopyWithImpl(this._self, this._then);

  final _ShowToast _self;
  final $Res Function(_ShowToast) _then;

/// Create a copy of AppErrorState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,Object? isPersistent = null,Object? isError = null,}) {
  return _then(_ShowToast(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,isPersistent: null == isPersistent ? _self.isPersistent : isPersistent // ignore: cast_nullable_to_non_nullable
as bool,isError: null == isError ? _self.isError : isError // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class _ShowDialog implements AppErrorState {
  const _ShowDialog({this.title = '發生錯誤', required this.message, this.retryText, this.errorDetail});
  

@JsonKey() final  String title;
 final  String message;
 final  String? retryText;
 final  String? errorDetail;

/// Create a copy of AppErrorState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShowDialogCopyWith<_ShowDialog> get copyWith => __$ShowDialogCopyWithImpl<_ShowDialog>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShowDialog&&(identical(other.title, title) || other.title == title)&&(identical(other.message, message) || other.message == message)&&(identical(other.retryText, retryText) || other.retryText == retryText)&&(identical(other.errorDetail, errorDetail) || other.errorDetail == errorDetail));
}


@override
int get hashCode => Object.hash(runtimeType,title,message,retryText,errorDetail);

@override
String toString() {
  return 'AppErrorState.showDialog(title: $title, message: $message, retryText: $retryText, errorDetail: $errorDetail)';
}


}

/// @nodoc
abstract mixin class _$ShowDialogCopyWith<$Res> implements $AppErrorStateCopyWith<$Res> {
  factory _$ShowDialogCopyWith(_ShowDialog value, $Res Function(_ShowDialog) _then) = __$ShowDialogCopyWithImpl;
@useResult
$Res call({
 String title, String message, String? retryText, String? errorDetail
});




}
/// @nodoc
class __$ShowDialogCopyWithImpl<$Res>
    implements _$ShowDialogCopyWith<$Res> {
  __$ShowDialogCopyWithImpl(this._self, this._then);

  final _ShowDialog _self;
  final $Res Function(_ShowDialog) _then;

/// Create a copy of AppErrorState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? title = null,Object? message = null,Object? retryText = freezed,Object? errorDetail = freezed,}) {
  return _then(_ShowDialog(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,retryText: freezed == retryText ? _self.retryText : retryText // ignore: cast_nullable_to_non_nullable
as String?,errorDetail: freezed == errorDetail ? _self.errorDetail : errorDetail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class _AuthenticationExpired implements AppErrorState {
  const _AuthenticationExpired();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthenticationExpired);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AppErrorState.authenticationExpired()';
}


}




/// @nodoc


class _NetworkOffline implements AppErrorState {
  const _NetworkOffline();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NetworkOffline);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AppErrorState.networkOffline()';
}


}




/// @nodoc


class _NetworkTimeout implements AppErrorState {
  const _NetworkTimeout();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NetworkTimeout);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AppErrorState.networkTimeout()';
}


}




// dart format on
