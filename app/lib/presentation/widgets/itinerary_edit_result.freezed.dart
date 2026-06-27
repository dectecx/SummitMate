// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'itinerary_edit_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ItineraryEditResult {

 String get name; String get estTime; int get altitude; double get distance; String get note;
/// Create a copy of ItineraryEditResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ItineraryEditResultCopyWith<ItineraryEditResult> get copyWith => _$ItineraryEditResultCopyWithImpl<ItineraryEditResult>(this as ItineraryEditResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ItineraryEditResult&&(identical(other.name, name) || other.name == name)&&(identical(other.estTime, estTime) || other.estTime == estTime)&&(identical(other.altitude, altitude) || other.altitude == altitude)&&(identical(other.distance, distance) || other.distance == distance)&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode => Object.hash(runtimeType,name,estTime,altitude,distance,note);

@override
String toString() {
  return 'ItineraryEditResult(name: $name, estTime: $estTime, altitude: $altitude, distance: $distance, note: $note)';
}


}

/// @nodoc
abstract mixin class $ItineraryEditResultCopyWith<$Res>  {
  factory $ItineraryEditResultCopyWith(ItineraryEditResult value, $Res Function(ItineraryEditResult) _then) = _$ItineraryEditResultCopyWithImpl;
@useResult
$Res call({
 String name, String estTime, int altitude, double distance, String note
});




}
/// @nodoc
class _$ItineraryEditResultCopyWithImpl<$Res>
    implements $ItineraryEditResultCopyWith<$Res> {
  _$ItineraryEditResultCopyWithImpl(this._self, this._then);

  final ItineraryEditResult _self;
  final $Res Function(ItineraryEditResult) _then;

/// Create a copy of ItineraryEditResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? estTime = null,Object? altitude = null,Object? distance = null,Object? note = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,estTime: null == estTime ? _self.estTime : estTime // ignore: cast_nullable_to_non_nullable
as String,altitude: null == altitude ? _self.altitude : altitude // ignore: cast_nullable_to_non_nullable
as int,distance: null == distance ? _self.distance : distance // ignore: cast_nullable_to_non_nullable
as double,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ItineraryEditResult].
extension ItineraryEditResultPatterns on ItineraryEditResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ItineraryEditResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ItineraryEditResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ItineraryEditResult value)  $default,){
final _that = this;
switch (_that) {
case _ItineraryEditResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ItineraryEditResult value)?  $default,){
final _that = this;
switch (_that) {
case _ItineraryEditResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String estTime,  int altitude,  double distance,  String note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ItineraryEditResult() when $default != null:
return $default(_that.name,_that.estTime,_that.altitude,_that.distance,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String estTime,  int altitude,  double distance,  String note)  $default,) {final _that = this;
switch (_that) {
case _ItineraryEditResult():
return $default(_that.name,_that.estTime,_that.altitude,_that.distance,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String estTime,  int altitude,  double distance,  String note)?  $default,) {final _that = this;
switch (_that) {
case _ItineraryEditResult() when $default != null:
return $default(_that.name,_that.estTime,_that.altitude,_that.distance,_that.note);case _:
  return null;

}
}

}

/// @nodoc


class _ItineraryEditResult implements ItineraryEditResult {
  const _ItineraryEditResult({required this.name, required this.estTime, required this.altitude, required this.distance, required this.note});
  

@override final  String name;
@override final  String estTime;
@override final  int altitude;
@override final  double distance;
@override final  String note;

/// Create a copy of ItineraryEditResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ItineraryEditResultCopyWith<_ItineraryEditResult> get copyWith => __$ItineraryEditResultCopyWithImpl<_ItineraryEditResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ItineraryEditResult&&(identical(other.name, name) || other.name == name)&&(identical(other.estTime, estTime) || other.estTime == estTime)&&(identical(other.altitude, altitude) || other.altitude == altitude)&&(identical(other.distance, distance) || other.distance == distance)&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode => Object.hash(runtimeType,name,estTime,altitude,distance,note);

@override
String toString() {
  return 'ItineraryEditResult(name: $name, estTime: $estTime, altitude: $altitude, distance: $distance, note: $note)';
}


}

/// @nodoc
abstract mixin class _$ItineraryEditResultCopyWith<$Res> implements $ItineraryEditResultCopyWith<$Res> {
  factory _$ItineraryEditResultCopyWith(_ItineraryEditResult value, $Res Function(_ItineraryEditResult) _then) = __$ItineraryEditResultCopyWithImpl;
@override @useResult
$Res call({
 String name, String estTime, int altitude, double distance, String note
});




}
/// @nodoc
class __$ItineraryEditResultCopyWithImpl<$Res>
    implements _$ItineraryEditResultCopyWith<$Res> {
  __$ItineraryEditResultCopyWithImpl(this._self, this._then);

  final _ItineraryEditResult _self;
  final $Res Function(_ItineraryEditResult) _then;

/// Create a copy of ItineraryEditResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? estTime = null,Object? altitude = null,Object? distance = null,Object? note = null,}) {
  return _then(_ItineraryEditResult(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,estTime: null == estTime ? _self.estTime : estTime // ignore: cast_nullable_to_non_nullable
as String,altitude: null == altitude ? _self.altitude : altitude // ignore: cast_nullable_to_non_nullable
as int,distance: null == distance ? _self.distance : distance // ignore: cast_nullable_to_non_nullable
as double,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
