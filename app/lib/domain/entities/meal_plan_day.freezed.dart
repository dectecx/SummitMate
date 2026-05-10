// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'meal_plan_day.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MealPlanDay {

 String get id; String get name; String? get linkedItineraryDay;
/// Create a copy of MealPlanDay
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MealPlanDayCopyWith<MealPlanDay> get copyWith => _$MealPlanDayCopyWithImpl<MealPlanDay>(this as MealPlanDay, _$identity);

  /// Serializes this MealPlanDay to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MealPlanDay&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.linkedItineraryDay, linkedItineraryDay) || other.linkedItineraryDay == linkedItineraryDay));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,linkedItineraryDay);

@override
String toString() {
  return 'MealPlanDay(id: $id, name: $name, linkedItineraryDay: $linkedItineraryDay)';
}


}

/// @nodoc
abstract mixin class $MealPlanDayCopyWith<$Res>  {
  factory $MealPlanDayCopyWith(MealPlanDay value, $Res Function(MealPlanDay) _then) = _$MealPlanDayCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? linkedItineraryDay
});




}
/// @nodoc
class _$MealPlanDayCopyWithImpl<$Res>
    implements $MealPlanDayCopyWith<$Res> {
  _$MealPlanDayCopyWithImpl(this._self, this._then);

  final MealPlanDay _self;
  final $Res Function(MealPlanDay) _then;

/// Create a copy of MealPlanDay
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? linkedItineraryDay = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,linkedItineraryDay: freezed == linkedItineraryDay ? _self.linkedItineraryDay : linkedItineraryDay // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MealPlanDay].
extension MealPlanDayPatterns on MealPlanDay {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MealPlanDay value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MealPlanDay() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MealPlanDay value)  $default,){
final _that = this;
switch (_that) {
case _MealPlanDay():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MealPlanDay value)?  $default,){
final _that = this;
switch (_that) {
case _MealPlanDay() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? linkedItineraryDay)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MealPlanDay() when $default != null:
return $default(_that.id,_that.name,_that.linkedItineraryDay);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? linkedItineraryDay)  $default,) {final _that = this;
switch (_that) {
case _MealPlanDay():
return $default(_that.id,_that.name,_that.linkedItineraryDay);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? linkedItineraryDay)?  $default,) {final _that = this;
switch (_that) {
case _MealPlanDay() when $default != null:
return $default(_that.id,_that.name,_that.linkedItineraryDay);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MealPlanDay implements MealPlanDay {
  const _MealPlanDay({required this.id, required this.name, this.linkedItineraryDay});
  factory _MealPlanDay.fromJson(Map<String, dynamic> json) => _$MealPlanDayFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? linkedItineraryDay;

/// Create a copy of MealPlanDay
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MealPlanDayCopyWith<_MealPlanDay> get copyWith => __$MealPlanDayCopyWithImpl<_MealPlanDay>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MealPlanDayToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MealPlanDay&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.linkedItineraryDay, linkedItineraryDay) || other.linkedItineraryDay == linkedItineraryDay));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,linkedItineraryDay);

@override
String toString() {
  return 'MealPlanDay(id: $id, name: $name, linkedItineraryDay: $linkedItineraryDay)';
}


}

/// @nodoc
abstract mixin class _$MealPlanDayCopyWith<$Res> implements $MealPlanDayCopyWith<$Res> {
  factory _$MealPlanDayCopyWith(_MealPlanDay value, $Res Function(_MealPlanDay) _then) = __$MealPlanDayCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? linkedItineraryDay
});




}
/// @nodoc
class __$MealPlanDayCopyWithImpl<$Res>
    implements _$MealPlanDayCopyWith<$Res> {
  __$MealPlanDayCopyWithImpl(this._self, this._then);

  final _MealPlanDay _self;
  final $Res Function(_MealPlanDay) _then;

/// Create a copy of MealPlanDay
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? linkedItineraryDay = freezed,}) {
  return _then(_MealPlanDay(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,linkedItineraryDay: freezed == linkedItineraryDay ? _self.linkedItineraryDay : linkedItineraryDay // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
