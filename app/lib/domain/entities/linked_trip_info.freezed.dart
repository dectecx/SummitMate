// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'linked_trip_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LinkedTripInfo {

 String get tripId; String get tripName; DateTime get startDate;
/// Create a copy of LinkedTripInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LinkedTripInfoCopyWith<LinkedTripInfo> get copyWith => _$LinkedTripInfoCopyWithImpl<LinkedTripInfo>(this as LinkedTripInfo, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LinkedTripInfo&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.tripName, tripName) || other.tripName == tripName)&&(identical(other.startDate, startDate) || other.startDate == startDate));
}


@override
int get hashCode => Object.hash(runtimeType,tripId,tripName,startDate);

@override
String toString() {
  return 'LinkedTripInfo(tripId: $tripId, tripName: $tripName, startDate: $startDate)';
}


}

/// @nodoc
abstract mixin class $LinkedTripInfoCopyWith<$Res>  {
  factory $LinkedTripInfoCopyWith(LinkedTripInfo value, $Res Function(LinkedTripInfo) _then) = _$LinkedTripInfoCopyWithImpl;
@useResult
$Res call({
 String tripId, String tripName, DateTime startDate
});




}
/// @nodoc
class _$LinkedTripInfoCopyWithImpl<$Res>
    implements $LinkedTripInfoCopyWith<$Res> {
  _$LinkedTripInfoCopyWithImpl(this._self, this._then);

  final LinkedTripInfo _self;
  final $Res Function(LinkedTripInfo) _then;

/// Create a copy of LinkedTripInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tripId = null,Object? tripName = null,Object? startDate = null,}) {
  return _then(_self.copyWith(
tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,tripName: null == tripName ? _self.tripName : tripName // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [LinkedTripInfo].
extension LinkedTripInfoPatterns on LinkedTripInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LinkedTripInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LinkedTripInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LinkedTripInfo value)  $default,){
final _that = this;
switch (_that) {
case _LinkedTripInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LinkedTripInfo value)?  $default,){
final _that = this;
switch (_that) {
case _LinkedTripInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String tripId,  String tripName,  DateTime startDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LinkedTripInfo() when $default != null:
return $default(_that.tripId,_that.tripName,_that.startDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String tripId,  String tripName,  DateTime startDate)  $default,) {final _that = this;
switch (_that) {
case _LinkedTripInfo():
return $default(_that.tripId,_that.tripName,_that.startDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String tripId,  String tripName,  DateTime startDate)?  $default,) {final _that = this;
switch (_that) {
case _LinkedTripInfo() when $default != null:
return $default(_that.tripId,_that.tripName,_that.startDate);case _:
  return null;

}
}

}

/// @nodoc


class _LinkedTripInfo implements LinkedTripInfo {
  const _LinkedTripInfo({required this.tripId, required this.tripName, required this.startDate});
  

@override final  String tripId;
@override final  String tripName;
@override final  DateTime startDate;

/// Create a copy of LinkedTripInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LinkedTripInfoCopyWith<_LinkedTripInfo> get copyWith => __$LinkedTripInfoCopyWithImpl<_LinkedTripInfo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LinkedTripInfo&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.tripName, tripName) || other.tripName == tripName)&&(identical(other.startDate, startDate) || other.startDate == startDate));
}


@override
int get hashCode => Object.hash(runtimeType,tripId,tripName,startDate);

@override
String toString() {
  return 'LinkedTripInfo(tripId: $tripId, tripName: $tripName, startDate: $startDate)';
}


}

/// @nodoc
abstract mixin class _$LinkedTripInfoCopyWith<$Res> implements $LinkedTripInfoCopyWith<$Res> {
  factory _$LinkedTripInfoCopyWith(_LinkedTripInfo value, $Res Function(_LinkedTripInfo) _then) = __$LinkedTripInfoCopyWithImpl;
@override @useResult
$Res call({
 String tripId, String tripName, DateTime startDate
});




}
/// @nodoc
class __$LinkedTripInfoCopyWithImpl<$Res>
    implements _$LinkedTripInfoCopyWith<$Res> {
  __$LinkedTripInfoCopyWithImpl(this._self, this._then);

  final _LinkedTripInfo _self;
  final $Res Function(_LinkedTripInfo) _then;

/// Create a copy of LinkedTripInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tripId = null,Object? tripName = null,Object? startDate = null,}) {
  return _then(_LinkedTripInfo(
tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,tripName: null == tripName ? _self.tripName : tripName // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
