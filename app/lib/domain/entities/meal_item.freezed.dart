// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'meal_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MealItem {

 String get id; String get name; double get weight; double get calories; int get quantity; String? get note;
/// Create a copy of MealItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MealItemCopyWith<MealItem> get copyWith => _$MealItemCopyWithImpl<MealItem>(this as MealItem, _$identity);

  /// Serializes this MealItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MealItem&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.calories, calories) || other.calories == calories)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,weight,calories,quantity,note);

@override
String toString() {
  return 'MealItem(id: $id, name: $name, weight: $weight, calories: $calories, quantity: $quantity, note: $note)';
}


}

/// @nodoc
abstract mixin class $MealItemCopyWith<$Res>  {
  factory $MealItemCopyWith(MealItem value, $Res Function(MealItem) _then) = _$MealItemCopyWithImpl;
@useResult
$Res call({
 String id, String name, double weight, double calories, int quantity, String? note
});




}
/// @nodoc
class _$MealItemCopyWithImpl<$Res>
    implements $MealItemCopyWith<$Res> {
  _$MealItemCopyWithImpl(this._self, this._then);

  final MealItem _self;
  final $Res Function(MealItem) _then;

/// Create a copy of MealItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? weight = null,Object? calories = null,Object? quantity = null,Object? note = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as double,calories: null == calories ? _self.calories : calories // ignore: cast_nullable_to_non_nullable
as double,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MealItem].
extension MealItemPatterns on MealItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MealItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MealItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MealItem value)  $default,){
final _that = this;
switch (_that) {
case _MealItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MealItem value)?  $default,){
final _that = this;
switch (_that) {
case _MealItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  double weight,  double calories,  int quantity,  String? note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MealItem() when $default != null:
return $default(_that.id,_that.name,_that.weight,_that.calories,_that.quantity,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  double weight,  double calories,  int quantity,  String? note)  $default,) {final _that = this;
switch (_that) {
case _MealItem():
return $default(_that.id,_that.name,_that.weight,_that.calories,_that.quantity,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  double weight,  double calories,  int quantity,  String? note)?  $default,) {final _that = this;
switch (_that) {
case _MealItem() when $default != null:
return $default(_that.id,_that.name,_that.weight,_that.calories,_that.quantity,_that.note);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MealItem implements MealItem {
  const _MealItem({required this.id, required this.name, required this.weight, required this.calories, this.quantity = 1, this.note});
  factory _MealItem.fromJson(Map<String, dynamic> json) => _$MealItemFromJson(json);

@override final  String id;
@override final  String name;
@override final  double weight;
@override final  double calories;
@override@JsonKey() final  int quantity;
@override final  String? note;

/// Create a copy of MealItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MealItemCopyWith<_MealItem> get copyWith => __$MealItemCopyWithImpl<_MealItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MealItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MealItem&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.calories, calories) || other.calories == calories)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,weight,calories,quantity,note);

@override
String toString() {
  return 'MealItem(id: $id, name: $name, weight: $weight, calories: $calories, quantity: $quantity, note: $note)';
}


}

/// @nodoc
abstract mixin class _$MealItemCopyWith<$Res> implements $MealItemCopyWith<$Res> {
  factory _$MealItemCopyWith(_MealItem value, $Res Function(_MealItem) _then) = __$MealItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, double weight, double calories, int quantity, String? note
});




}
/// @nodoc
class __$MealItemCopyWithImpl<$Res>
    implements _$MealItemCopyWith<$Res> {
  __$MealItemCopyWithImpl(this._self, this._then);

  final _MealItem _self;
  final $Res Function(_MealItem) _then;

/// Create a copy of MealItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? weight = null,Object? calories = null,Object? quantity = null,Object? note = freezed,}) {
  return _then(_MealItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as double,calories: null == calories ? _self.calories : calories // ignore: cast_nullable_to_non_nullable
as double,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
