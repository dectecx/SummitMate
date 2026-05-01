// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'download_task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DownloadTask {

 String get id; String get name; LatLngBounds get bounds; int get minZoom; int get maxZoom; TaskStatus get status; double get progress; int get successfulTiles; int get failedTiles;
/// Create a copy of DownloadTask
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DownloadTaskCopyWith<DownloadTask> get copyWith => _$DownloadTaskCopyWithImpl<DownloadTask>(this as DownloadTask, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloadTask&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.bounds, bounds) || other.bounds == bounds)&&(identical(other.minZoom, minZoom) || other.minZoom == minZoom)&&(identical(other.maxZoom, maxZoom) || other.maxZoom == maxZoom)&&(identical(other.status, status) || other.status == status)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.successfulTiles, successfulTiles) || other.successfulTiles == successfulTiles)&&(identical(other.failedTiles, failedTiles) || other.failedTiles == failedTiles));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,bounds,minZoom,maxZoom,status,progress,successfulTiles,failedTiles);

@override
String toString() {
  return 'DownloadTask(id: $id, name: $name, bounds: $bounds, minZoom: $minZoom, maxZoom: $maxZoom, status: $status, progress: $progress, successfulTiles: $successfulTiles, failedTiles: $failedTiles)';
}


}

/// @nodoc
abstract mixin class $DownloadTaskCopyWith<$Res>  {
  factory $DownloadTaskCopyWith(DownloadTask value, $Res Function(DownloadTask) _then) = _$DownloadTaskCopyWithImpl;
@useResult
$Res call({
 String id, String name, LatLngBounds bounds, int minZoom, int maxZoom, TaskStatus status, double progress, int successfulTiles, int failedTiles
});




}
/// @nodoc
class _$DownloadTaskCopyWithImpl<$Res>
    implements $DownloadTaskCopyWith<$Res> {
  _$DownloadTaskCopyWithImpl(this._self, this._then);

  final DownloadTask _self;
  final $Res Function(DownloadTask) _then;

/// Create a copy of DownloadTask
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? bounds = null,Object? minZoom = null,Object? maxZoom = null,Object? status = null,Object? progress = null,Object? successfulTiles = null,Object? failedTiles = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,bounds: null == bounds ? _self.bounds : bounds // ignore: cast_nullable_to_non_nullable
as LatLngBounds,minZoom: null == minZoom ? _self.minZoom : minZoom // ignore: cast_nullable_to_non_nullable
as int,maxZoom: null == maxZoom ? _self.maxZoom : maxZoom // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TaskStatus,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,successfulTiles: null == successfulTiles ? _self.successfulTiles : successfulTiles // ignore: cast_nullable_to_non_nullable
as int,failedTiles: null == failedTiles ? _self.failedTiles : failedTiles // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DownloadTask].
extension DownloadTaskPatterns on DownloadTask {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DownloadTask value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DownloadTask() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DownloadTask value)  $default,){
final _that = this;
switch (_that) {
case _DownloadTask():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DownloadTask value)?  $default,){
final _that = this;
switch (_that) {
case _DownloadTask() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  LatLngBounds bounds,  int minZoom,  int maxZoom,  TaskStatus status,  double progress,  int successfulTiles,  int failedTiles)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DownloadTask() when $default != null:
return $default(_that.id,_that.name,_that.bounds,_that.minZoom,_that.maxZoom,_that.status,_that.progress,_that.successfulTiles,_that.failedTiles);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  LatLngBounds bounds,  int minZoom,  int maxZoom,  TaskStatus status,  double progress,  int successfulTiles,  int failedTiles)  $default,) {final _that = this;
switch (_that) {
case _DownloadTask():
return $default(_that.id,_that.name,_that.bounds,_that.minZoom,_that.maxZoom,_that.status,_that.progress,_that.successfulTiles,_that.failedTiles);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  LatLngBounds bounds,  int minZoom,  int maxZoom,  TaskStatus status,  double progress,  int successfulTiles,  int failedTiles)?  $default,) {final _that = this;
switch (_that) {
case _DownloadTask() when $default != null:
return $default(_that.id,_that.name,_that.bounds,_that.minZoom,_that.maxZoom,_that.status,_that.progress,_that.successfulTiles,_that.failedTiles);case _:
  return null;

}
}

}

/// @nodoc


class _DownloadTask implements DownloadTask {
  const _DownloadTask({required this.id, required this.name, required this.bounds, required this.minZoom, required this.maxZoom, this.status = TaskStatus.pending, this.progress = 0.0, this.successfulTiles = 0, this.failedTiles = 0});
  

@override final  String id;
@override final  String name;
@override final  LatLngBounds bounds;
@override final  int minZoom;
@override final  int maxZoom;
@override@JsonKey() final  TaskStatus status;
@override@JsonKey() final  double progress;
@override@JsonKey() final  int successfulTiles;
@override@JsonKey() final  int failedTiles;

/// Create a copy of DownloadTask
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DownloadTaskCopyWith<_DownloadTask> get copyWith => __$DownloadTaskCopyWithImpl<_DownloadTask>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DownloadTask&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.bounds, bounds) || other.bounds == bounds)&&(identical(other.minZoom, minZoom) || other.minZoom == minZoom)&&(identical(other.maxZoom, maxZoom) || other.maxZoom == maxZoom)&&(identical(other.status, status) || other.status == status)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.successfulTiles, successfulTiles) || other.successfulTiles == successfulTiles)&&(identical(other.failedTiles, failedTiles) || other.failedTiles == failedTiles));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,bounds,minZoom,maxZoom,status,progress,successfulTiles,failedTiles);

@override
String toString() {
  return 'DownloadTask(id: $id, name: $name, bounds: $bounds, minZoom: $minZoom, maxZoom: $maxZoom, status: $status, progress: $progress, successfulTiles: $successfulTiles, failedTiles: $failedTiles)';
}


}

/// @nodoc
abstract mixin class _$DownloadTaskCopyWith<$Res> implements $DownloadTaskCopyWith<$Res> {
  factory _$DownloadTaskCopyWith(_DownloadTask value, $Res Function(_DownloadTask) _then) = __$DownloadTaskCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, LatLngBounds bounds, int minZoom, int maxZoom, TaskStatus status, double progress, int successfulTiles, int failedTiles
});




}
/// @nodoc
class __$DownloadTaskCopyWithImpl<$Res>
    implements _$DownloadTaskCopyWith<$Res> {
  __$DownloadTaskCopyWithImpl(this._self, this._then);

  final _DownloadTask _self;
  final $Res Function(_DownloadTask) _then;

/// Create a copy of DownloadTask
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? bounds = null,Object? minZoom = null,Object? maxZoom = null,Object? status = null,Object? progress = null,Object? successfulTiles = null,Object? failedTiles = null,}) {
  return _then(_DownloadTask(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,bounds: null == bounds ? _self.bounds : bounds // ignore: cast_nullable_to_non_nullable
as LatLngBounds,minZoom: null == minZoom ? _self.minZoom : minZoom // ignore: cast_nullable_to_non_nullable
as int,maxZoom: null == maxZoom ? _self.maxZoom : maxZoom // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TaskStatus,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,successfulTiles: null == successfulTiles ? _self.successfulTiles : successfulTiles // ignore: cast_nullable_to_non_nullable
as int,failedTiles: null == failedTiles ? _self.failedTiles : failedTiles // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
