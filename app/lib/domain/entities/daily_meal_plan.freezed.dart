// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_meal_plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DailyMealPlan {

 String get day; Map<MealType, List<MealItem>> get meals;
/// Create a copy of DailyMealPlan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyMealPlanCopyWith<DailyMealPlan> get copyWith => _$DailyMealPlanCopyWithImpl<DailyMealPlan>(this as DailyMealPlan, _$identity);

  /// Serializes this DailyMealPlan to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyMealPlan&&(identical(other.day, day) || other.day == day)&&const DeepCollectionEquality().equals(other.meals, meals));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,day,const DeepCollectionEquality().hash(meals));

@override
String toString() {
  return 'DailyMealPlan(day: $day, meals: $meals)';
}


}

/// @nodoc
abstract mixin class $DailyMealPlanCopyWith<$Res>  {
  factory $DailyMealPlanCopyWith(DailyMealPlan value, $Res Function(DailyMealPlan) _then) = _$DailyMealPlanCopyWithImpl;
@useResult
$Res call({
 String day, Map<MealType, List<MealItem>> meals
});




}
/// @nodoc
class _$DailyMealPlanCopyWithImpl<$Res>
    implements $DailyMealPlanCopyWith<$Res> {
  _$DailyMealPlanCopyWithImpl(this._self, this._then);

  final DailyMealPlan _self;
  final $Res Function(DailyMealPlan) _then;

/// Create a copy of DailyMealPlan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? day = null,Object? meals = null,}) {
  return _then(_self.copyWith(
day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as String,meals: null == meals ? _self.meals : meals // ignore: cast_nullable_to_non_nullable
as Map<MealType, List<MealItem>>,
  ));
}

}


/// Adds pattern-matching-related methods to [DailyMealPlan].
extension DailyMealPlanPatterns on DailyMealPlan {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DailyMealPlan value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DailyMealPlan() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DailyMealPlan value)  $default,){
final _that = this;
switch (_that) {
case _DailyMealPlan():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DailyMealPlan value)?  $default,){
final _that = this;
switch (_that) {
case _DailyMealPlan() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String day,  Map<MealType, List<MealItem>> meals)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DailyMealPlan() when $default != null:
return $default(_that.day,_that.meals);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String day,  Map<MealType, List<MealItem>> meals)  $default,) {final _that = this;
switch (_that) {
case _DailyMealPlan():
return $default(_that.day,_that.meals);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String day,  Map<MealType, List<MealItem>> meals)?  $default,) {final _that = this;
switch (_that) {
case _DailyMealPlan() when $default != null:
return $default(_that.day,_that.meals);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DailyMealPlan extends DailyMealPlan {
  const _DailyMealPlan({required this.day, final  Map<MealType, List<MealItem>> meals = const {}}): _meals = meals,super._();
  factory _DailyMealPlan.fromJson(Map<String, dynamic> json) => _$DailyMealPlanFromJson(json);

@override final  String day;
 final  Map<MealType, List<MealItem>> _meals;
@override@JsonKey() Map<MealType, List<MealItem>> get meals {
  if (_meals is EqualUnmodifiableMapView) return _meals;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_meals);
}


/// Create a copy of DailyMealPlan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DailyMealPlanCopyWith<_DailyMealPlan> get copyWith => __$DailyMealPlanCopyWithImpl<_DailyMealPlan>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DailyMealPlanToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DailyMealPlan&&(identical(other.day, day) || other.day == day)&&const DeepCollectionEquality().equals(other._meals, _meals));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,day,const DeepCollectionEquality().hash(_meals));

@override
String toString() {
  return 'DailyMealPlan(day: $day, meals: $meals)';
}


}

/// @nodoc
abstract mixin class _$DailyMealPlanCopyWith<$Res> implements $DailyMealPlanCopyWith<$Res> {
  factory _$DailyMealPlanCopyWith(_DailyMealPlan value, $Res Function(_DailyMealPlan) _then) = __$DailyMealPlanCopyWithImpl;
@override @useResult
$Res call({
 String day, Map<MealType, List<MealItem>> meals
});




}
/// @nodoc
class __$DailyMealPlanCopyWithImpl<$Res>
    implements _$DailyMealPlanCopyWith<$Res> {
  __$DailyMealPlanCopyWithImpl(this._self, this._then);

  final _DailyMealPlan _self;
  final $Res Function(_DailyMealPlan) _then;

/// Create a copy of DailyMealPlan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? day = null,Object? meals = null,}) {
  return _then(_DailyMealPlan(
day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as String,meals: null == meals ? _self._meals : meals // ignore: cast_nullable_to_non_nullable
as Map<MealType, List<MealItem>>,
  ));
}


}

// dart format on
