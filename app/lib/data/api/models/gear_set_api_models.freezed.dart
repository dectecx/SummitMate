// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gear_set_api_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GearSetItemDto {

 String get id; String get name; String get category; double get weight; int get quantity;@JsonKey(name: 'order_index') int get orderIndex;
/// Create a copy of GearSetItemDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GearSetItemDtoCopyWith<GearSetItemDto> get copyWith => _$GearSetItemDtoCopyWithImpl<GearSetItemDto>(this as GearSetItemDto, _$identity);

  /// Serializes this GearSetItemDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GearSetItemDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.category, category) || other.category == category)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.orderIndex, orderIndex) || other.orderIndex == orderIndex));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,category,weight,quantity,orderIndex);

@override
String toString() {
  return 'GearSetItemDto(id: $id, name: $name, category: $category, weight: $weight, quantity: $quantity, orderIndex: $orderIndex)';
}


}

/// @nodoc
abstract mixin class $GearSetItemDtoCopyWith<$Res>  {
  factory $GearSetItemDtoCopyWith(GearSetItemDto value, $Res Function(GearSetItemDto) _then) = _$GearSetItemDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name, String category, double weight, int quantity,@JsonKey(name: 'order_index') int orderIndex
});




}
/// @nodoc
class _$GearSetItemDtoCopyWithImpl<$Res>
    implements $GearSetItemDtoCopyWith<$Res> {
  _$GearSetItemDtoCopyWithImpl(this._self, this._then);

  final GearSetItemDto _self;
  final $Res Function(GearSetItemDto) _then;

/// Create a copy of GearSetItemDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? category = null,Object? weight = null,Object? quantity = null,Object? orderIndex = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as double,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,orderIndex: null == orderIndex ? _self.orderIndex : orderIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [GearSetItemDto].
extension GearSetItemDtoPatterns on GearSetItemDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GearSetItemDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GearSetItemDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GearSetItemDto value)  $default,){
final _that = this;
switch (_that) {
case _GearSetItemDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GearSetItemDto value)?  $default,){
final _that = this;
switch (_that) {
case _GearSetItemDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String category,  double weight,  int quantity, @JsonKey(name: 'order_index')  int orderIndex)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GearSetItemDto() when $default != null:
return $default(_that.id,_that.name,_that.category,_that.weight,_that.quantity,_that.orderIndex);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String category,  double weight,  int quantity, @JsonKey(name: 'order_index')  int orderIndex)  $default,) {final _that = this;
switch (_that) {
case _GearSetItemDto():
return $default(_that.id,_that.name,_that.category,_that.weight,_that.quantity,_that.orderIndex);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String category,  double weight,  int quantity, @JsonKey(name: 'order_index')  int orderIndex)?  $default,) {final _that = this;
switch (_that) {
case _GearSetItemDto() when $default != null:
return $default(_that.id,_that.name,_that.category,_that.weight,_that.quantity,_that.orderIndex);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GearSetItemDto implements GearSetItemDto {
  const _GearSetItemDto({required this.id, required this.name, required this.category, required this.weight, this.quantity = 1, @JsonKey(name: 'order_index') this.orderIndex = 0});
  factory _GearSetItemDto.fromJson(Map<String, dynamic> json) => _$GearSetItemDtoFromJson(json);

@override final  String id;
@override final  String name;
@override final  String category;
@override final  double weight;
@override@JsonKey() final  int quantity;
@override@JsonKey(name: 'order_index') final  int orderIndex;

/// Create a copy of GearSetItemDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GearSetItemDtoCopyWith<_GearSetItemDto> get copyWith => __$GearSetItemDtoCopyWithImpl<_GearSetItemDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GearSetItemDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GearSetItemDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.category, category) || other.category == category)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.orderIndex, orderIndex) || other.orderIndex == orderIndex));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,category,weight,quantity,orderIndex);

@override
String toString() {
  return 'GearSetItemDto(id: $id, name: $name, category: $category, weight: $weight, quantity: $quantity, orderIndex: $orderIndex)';
}


}

/// @nodoc
abstract mixin class _$GearSetItemDtoCopyWith<$Res> implements $GearSetItemDtoCopyWith<$Res> {
  factory _$GearSetItemDtoCopyWith(_GearSetItemDto value, $Res Function(_GearSetItemDto) _then) = __$GearSetItemDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String category, double weight, int quantity,@JsonKey(name: 'order_index') int orderIndex
});




}
/// @nodoc
class __$GearSetItemDtoCopyWithImpl<$Res>
    implements _$GearSetItemDtoCopyWith<$Res> {
  __$GearSetItemDtoCopyWithImpl(this._self, this._then);

  final _GearSetItemDto _self;
  final $Res Function(_GearSetItemDto) _then;

/// Create a copy of GearSetItemDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? category = null,Object? weight = null,Object? quantity = null,Object? orderIndex = null,}) {
  return _then(_GearSetItemDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as double,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,orderIndex: null == orderIndex ? _self.orderIndex : orderIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$GearSetMealDto {

 String get id; String get day;@JsonKey(name: 'meal_type') String get mealType; String get name; double get calories; String? get note;
/// Create a copy of GearSetMealDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GearSetMealDtoCopyWith<GearSetMealDto> get copyWith => _$GearSetMealDtoCopyWithImpl<GearSetMealDto>(this as GearSetMealDto, _$identity);

  /// Serializes this GearSetMealDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GearSetMealDto&&(identical(other.id, id) || other.id == id)&&(identical(other.day, day) || other.day == day)&&(identical(other.mealType, mealType) || other.mealType == mealType)&&(identical(other.name, name) || other.name == name)&&(identical(other.calories, calories) || other.calories == calories)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,day,mealType,name,calories,note);

@override
String toString() {
  return 'GearSetMealDto(id: $id, day: $day, mealType: $mealType, name: $name, calories: $calories, note: $note)';
}


}

/// @nodoc
abstract mixin class $GearSetMealDtoCopyWith<$Res>  {
  factory $GearSetMealDtoCopyWith(GearSetMealDto value, $Res Function(GearSetMealDto) _then) = _$GearSetMealDtoCopyWithImpl;
@useResult
$Res call({
 String id, String day,@JsonKey(name: 'meal_type') String mealType, String name, double calories, String? note
});




}
/// @nodoc
class _$GearSetMealDtoCopyWithImpl<$Res>
    implements $GearSetMealDtoCopyWith<$Res> {
  _$GearSetMealDtoCopyWithImpl(this._self, this._then);

  final GearSetMealDto _self;
  final $Res Function(GearSetMealDto) _then;

/// Create a copy of GearSetMealDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? day = null,Object? mealType = null,Object? name = null,Object? calories = null,Object? note = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as String,mealType: null == mealType ? _self.mealType : mealType // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,calories: null == calories ? _self.calories : calories // ignore: cast_nullable_to_non_nullable
as double,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [GearSetMealDto].
extension GearSetMealDtoPatterns on GearSetMealDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GearSetMealDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GearSetMealDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GearSetMealDto value)  $default,){
final _that = this;
switch (_that) {
case _GearSetMealDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GearSetMealDto value)?  $default,){
final _that = this;
switch (_that) {
case _GearSetMealDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String day, @JsonKey(name: 'meal_type')  String mealType,  String name,  double calories,  String? note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GearSetMealDto() when $default != null:
return $default(_that.id,_that.day,_that.mealType,_that.name,_that.calories,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String day, @JsonKey(name: 'meal_type')  String mealType,  String name,  double calories,  String? note)  $default,) {final _that = this;
switch (_that) {
case _GearSetMealDto():
return $default(_that.id,_that.day,_that.mealType,_that.name,_that.calories,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String day, @JsonKey(name: 'meal_type')  String mealType,  String name,  double calories,  String? note)?  $default,) {final _that = this;
switch (_that) {
case _GearSetMealDto() when $default != null:
return $default(_that.id,_that.day,_that.mealType,_that.name,_that.calories,_that.note);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GearSetMealDto implements GearSetMealDto {
  const _GearSetMealDto({required this.id, required this.day, @JsonKey(name: 'meal_type') required this.mealType, required this.name, this.calories = 0.0, this.note});
  factory _GearSetMealDto.fromJson(Map<String, dynamic> json) => _$GearSetMealDtoFromJson(json);

@override final  String id;
@override final  String day;
@override@JsonKey(name: 'meal_type') final  String mealType;
@override final  String name;
@override@JsonKey() final  double calories;
@override final  String? note;

/// Create a copy of GearSetMealDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GearSetMealDtoCopyWith<_GearSetMealDto> get copyWith => __$GearSetMealDtoCopyWithImpl<_GearSetMealDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GearSetMealDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GearSetMealDto&&(identical(other.id, id) || other.id == id)&&(identical(other.day, day) || other.day == day)&&(identical(other.mealType, mealType) || other.mealType == mealType)&&(identical(other.name, name) || other.name == name)&&(identical(other.calories, calories) || other.calories == calories)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,day,mealType,name,calories,note);

@override
String toString() {
  return 'GearSetMealDto(id: $id, day: $day, mealType: $mealType, name: $name, calories: $calories, note: $note)';
}


}

/// @nodoc
abstract mixin class _$GearSetMealDtoCopyWith<$Res> implements $GearSetMealDtoCopyWith<$Res> {
  factory _$GearSetMealDtoCopyWith(_GearSetMealDto value, $Res Function(_GearSetMealDto) _then) = __$GearSetMealDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String day,@JsonKey(name: 'meal_type') String mealType, String name, double calories, String? note
});




}
/// @nodoc
class __$GearSetMealDtoCopyWithImpl<$Res>
    implements _$GearSetMealDtoCopyWith<$Res> {
  __$GearSetMealDtoCopyWithImpl(this._self, this._then);

  final _GearSetMealDto _self;
  final $Res Function(_GearSetMealDto) _then;

/// Create a copy of GearSetMealDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? day = null,Object? mealType = null,Object? name = null,Object? calories = null,Object? note = freezed,}) {
  return _then(_GearSetMealDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as String,mealType: null == mealType ? _self.mealType : mealType // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,calories: null == calories ? _self.calories : calories // ignore: cast_nullable_to_non_nullable
as double,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$GearSetItemRequest {

 String get name; String get category; double get weight; int get quantity;@JsonKey(name: 'order_index') int get orderIndex;
/// Create a copy of GearSetItemRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GearSetItemRequestCopyWith<GearSetItemRequest> get copyWith => _$GearSetItemRequestCopyWithImpl<GearSetItemRequest>(this as GearSetItemRequest, _$identity);

  /// Serializes this GearSetItemRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GearSetItemRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.category, category) || other.category == category)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.orderIndex, orderIndex) || other.orderIndex == orderIndex));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,category,weight,quantity,orderIndex);

@override
String toString() {
  return 'GearSetItemRequest(name: $name, category: $category, weight: $weight, quantity: $quantity, orderIndex: $orderIndex)';
}


}

/// @nodoc
abstract mixin class $GearSetItemRequestCopyWith<$Res>  {
  factory $GearSetItemRequestCopyWith(GearSetItemRequest value, $Res Function(GearSetItemRequest) _then) = _$GearSetItemRequestCopyWithImpl;
@useResult
$Res call({
 String name, String category, double weight, int quantity,@JsonKey(name: 'order_index') int orderIndex
});




}
/// @nodoc
class _$GearSetItemRequestCopyWithImpl<$Res>
    implements $GearSetItemRequestCopyWith<$Res> {
  _$GearSetItemRequestCopyWithImpl(this._self, this._then);

  final GearSetItemRequest _self;
  final $Res Function(GearSetItemRequest) _then;

/// Create a copy of GearSetItemRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? category = null,Object? weight = null,Object? quantity = null,Object? orderIndex = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as double,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,orderIndex: null == orderIndex ? _self.orderIndex : orderIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [GearSetItemRequest].
extension GearSetItemRequestPatterns on GearSetItemRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GearSetItemRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GearSetItemRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GearSetItemRequest value)  $default,){
final _that = this;
switch (_that) {
case _GearSetItemRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GearSetItemRequest value)?  $default,){
final _that = this;
switch (_that) {
case _GearSetItemRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String category,  double weight,  int quantity, @JsonKey(name: 'order_index')  int orderIndex)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GearSetItemRequest() when $default != null:
return $default(_that.name,_that.category,_that.weight,_that.quantity,_that.orderIndex);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String category,  double weight,  int quantity, @JsonKey(name: 'order_index')  int orderIndex)  $default,) {final _that = this;
switch (_that) {
case _GearSetItemRequest():
return $default(_that.name,_that.category,_that.weight,_that.quantity,_that.orderIndex);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String category,  double weight,  int quantity, @JsonKey(name: 'order_index')  int orderIndex)?  $default,) {final _that = this;
switch (_that) {
case _GearSetItemRequest() when $default != null:
return $default(_that.name,_that.category,_that.weight,_that.quantity,_that.orderIndex);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GearSetItemRequest implements GearSetItemRequest {
  const _GearSetItemRequest({required this.name, required this.category, required this.weight, this.quantity = 1, @JsonKey(name: 'order_index') this.orderIndex = 0});
  factory _GearSetItemRequest.fromJson(Map<String, dynamic> json) => _$GearSetItemRequestFromJson(json);

@override final  String name;
@override final  String category;
@override final  double weight;
@override@JsonKey() final  int quantity;
@override@JsonKey(name: 'order_index') final  int orderIndex;

/// Create a copy of GearSetItemRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GearSetItemRequestCopyWith<_GearSetItemRequest> get copyWith => __$GearSetItemRequestCopyWithImpl<_GearSetItemRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GearSetItemRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GearSetItemRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.category, category) || other.category == category)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.orderIndex, orderIndex) || other.orderIndex == orderIndex));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,category,weight,quantity,orderIndex);

@override
String toString() {
  return 'GearSetItemRequest(name: $name, category: $category, weight: $weight, quantity: $quantity, orderIndex: $orderIndex)';
}


}

/// @nodoc
abstract mixin class _$GearSetItemRequestCopyWith<$Res> implements $GearSetItemRequestCopyWith<$Res> {
  factory _$GearSetItemRequestCopyWith(_GearSetItemRequest value, $Res Function(_GearSetItemRequest) _then) = __$GearSetItemRequestCopyWithImpl;
@override @useResult
$Res call({
 String name, String category, double weight, int quantity,@JsonKey(name: 'order_index') int orderIndex
});




}
/// @nodoc
class __$GearSetItemRequestCopyWithImpl<$Res>
    implements _$GearSetItemRequestCopyWith<$Res> {
  __$GearSetItemRequestCopyWithImpl(this._self, this._then);

  final _GearSetItemRequest _self;
  final $Res Function(_GearSetItemRequest) _then;

/// Create a copy of GearSetItemRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? category = null,Object? weight = null,Object? quantity = null,Object? orderIndex = null,}) {
  return _then(_GearSetItemRequest(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as double,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,orderIndex: null == orderIndex ? _self.orderIndex : orderIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$GearSetMealRequest {

 String get day;@JsonKey(name: 'meal_type') String get mealType; String get name; double get calories; String? get note;
/// Create a copy of GearSetMealRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GearSetMealRequestCopyWith<GearSetMealRequest> get copyWith => _$GearSetMealRequestCopyWithImpl<GearSetMealRequest>(this as GearSetMealRequest, _$identity);

  /// Serializes this GearSetMealRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GearSetMealRequest&&(identical(other.day, day) || other.day == day)&&(identical(other.mealType, mealType) || other.mealType == mealType)&&(identical(other.name, name) || other.name == name)&&(identical(other.calories, calories) || other.calories == calories)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,day,mealType,name,calories,note);

@override
String toString() {
  return 'GearSetMealRequest(day: $day, mealType: $mealType, name: $name, calories: $calories, note: $note)';
}


}

/// @nodoc
abstract mixin class $GearSetMealRequestCopyWith<$Res>  {
  factory $GearSetMealRequestCopyWith(GearSetMealRequest value, $Res Function(GearSetMealRequest) _then) = _$GearSetMealRequestCopyWithImpl;
@useResult
$Res call({
 String day,@JsonKey(name: 'meal_type') String mealType, String name, double calories, String? note
});




}
/// @nodoc
class _$GearSetMealRequestCopyWithImpl<$Res>
    implements $GearSetMealRequestCopyWith<$Res> {
  _$GearSetMealRequestCopyWithImpl(this._self, this._then);

  final GearSetMealRequest _self;
  final $Res Function(GearSetMealRequest) _then;

/// Create a copy of GearSetMealRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? day = null,Object? mealType = null,Object? name = null,Object? calories = null,Object? note = freezed,}) {
  return _then(_self.copyWith(
day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as String,mealType: null == mealType ? _self.mealType : mealType // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,calories: null == calories ? _self.calories : calories // ignore: cast_nullable_to_non_nullable
as double,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [GearSetMealRequest].
extension GearSetMealRequestPatterns on GearSetMealRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GearSetMealRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GearSetMealRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GearSetMealRequest value)  $default,){
final _that = this;
switch (_that) {
case _GearSetMealRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GearSetMealRequest value)?  $default,){
final _that = this;
switch (_that) {
case _GearSetMealRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String day, @JsonKey(name: 'meal_type')  String mealType,  String name,  double calories,  String? note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GearSetMealRequest() when $default != null:
return $default(_that.day,_that.mealType,_that.name,_that.calories,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String day, @JsonKey(name: 'meal_type')  String mealType,  String name,  double calories,  String? note)  $default,) {final _that = this;
switch (_that) {
case _GearSetMealRequest():
return $default(_that.day,_that.mealType,_that.name,_that.calories,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String day, @JsonKey(name: 'meal_type')  String mealType,  String name,  double calories,  String? note)?  $default,) {final _that = this;
switch (_that) {
case _GearSetMealRequest() when $default != null:
return $default(_that.day,_that.mealType,_that.name,_that.calories,_that.note);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GearSetMealRequest implements GearSetMealRequest {
  const _GearSetMealRequest({required this.day, @JsonKey(name: 'meal_type') required this.mealType, required this.name, this.calories = 0.0, this.note});
  factory _GearSetMealRequest.fromJson(Map<String, dynamic> json) => _$GearSetMealRequestFromJson(json);

@override final  String day;
@override@JsonKey(name: 'meal_type') final  String mealType;
@override final  String name;
@override@JsonKey() final  double calories;
@override final  String? note;

/// Create a copy of GearSetMealRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GearSetMealRequestCopyWith<_GearSetMealRequest> get copyWith => __$GearSetMealRequestCopyWithImpl<_GearSetMealRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GearSetMealRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GearSetMealRequest&&(identical(other.day, day) || other.day == day)&&(identical(other.mealType, mealType) || other.mealType == mealType)&&(identical(other.name, name) || other.name == name)&&(identical(other.calories, calories) || other.calories == calories)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,day,mealType,name,calories,note);

@override
String toString() {
  return 'GearSetMealRequest(day: $day, mealType: $mealType, name: $name, calories: $calories, note: $note)';
}


}

/// @nodoc
abstract mixin class _$GearSetMealRequestCopyWith<$Res> implements $GearSetMealRequestCopyWith<$Res> {
  factory _$GearSetMealRequestCopyWith(_GearSetMealRequest value, $Res Function(_GearSetMealRequest) _then) = __$GearSetMealRequestCopyWithImpl;
@override @useResult
$Res call({
 String day,@JsonKey(name: 'meal_type') String mealType, String name, double calories, String? note
});




}
/// @nodoc
class __$GearSetMealRequestCopyWithImpl<$Res>
    implements _$GearSetMealRequestCopyWith<$Res> {
  __$GearSetMealRequestCopyWithImpl(this._self, this._then);

  final _GearSetMealRequest _self;
  final $Res Function(_GearSetMealRequest) _then;

/// Create a copy of GearSetMealRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? day = null,Object? mealType = null,Object? name = null,Object? calories = null,Object? note = freezed,}) {
  return _then(_GearSetMealRequest(
day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as String,mealType: null == mealType ? _self.mealType : mealType // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,calories: null == calories ? _self.calories : calories // ignore: cast_nullable_to_non_nullable
as double,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$GearSetResponse {

 String get id; String get title; String get author;@JsonKey(name: 'total_weight') double get totalWeight;@JsonKey(name: 'item_count') int get itemCount; String get visibility;@JsonKey(name: 'download_key') String? get downloadKey; List<GearSetItemDto> get items; List<GearSetMealDto>? get meals;@JsonKey(name: 'created_at')@DateTimeUtcConverter() DateTime get createdAt;@JsonKey(name: 'created_by') String get createdBy;@JsonKey(name: 'updated_at')@DateTimeUtcConverter() DateTime get updatedAt;@JsonKey(name: 'updated_by') String get updatedBy;
/// Create a copy of GearSetResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GearSetResponseCopyWith<GearSetResponse> get copyWith => _$GearSetResponseCopyWithImpl<GearSetResponse>(this as GearSetResponse, _$identity);

  /// Serializes this GearSetResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GearSetResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.author, author) || other.author == author)&&(identical(other.totalWeight, totalWeight) || other.totalWeight == totalWeight)&&(identical(other.itemCount, itemCount) || other.itemCount == itemCount)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.downloadKey, downloadKey) || other.downloadKey == downloadKey)&&const DeepCollectionEquality().equals(other.items, items)&&const DeepCollectionEquality().equals(other.meals, meals)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,author,totalWeight,itemCount,visibility,downloadKey,const DeepCollectionEquality().hash(items),const DeepCollectionEquality().hash(meals),createdAt,createdBy,updatedAt,updatedBy);

@override
String toString() {
  return 'GearSetResponse(id: $id, title: $title, author: $author, totalWeight: $totalWeight, itemCount: $itemCount, visibility: $visibility, downloadKey: $downloadKey, items: $items, meals: $meals, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy)';
}


}

/// @nodoc
abstract mixin class $GearSetResponseCopyWith<$Res>  {
  factory $GearSetResponseCopyWith(GearSetResponse value, $Res Function(GearSetResponse) _then) = _$GearSetResponseCopyWithImpl;
@useResult
$Res call({
 String id, String title, String author,@JsonKey(name: 'total_weight') double totalWeight,@JsonKey(name: 'item_count') int itemCount, String visibility,@JsonKey(name: 'download_key') String? downloadKey, List<GearSetItemDto> items, List<GearSetMealDto>? meals,@JsonKey(name: 'created_at')@DateTimeUtcConverter() DateTime createdAt,@JsonKey(name: 'created_by') String createdBy,@JsonKey(name: 'updated_at')@DateTimeUtcConverter() DateTime updatedAt,@JsonKey(name: 'updated_by') String updatedBy
});




}
/// @nodoc
class _$GearSetResponseCopyWithImpl<$Res>
    implements $GearSetResponseCopyWith<$Res> {
  _$GearSetResponseCopyWithImpl(this._self, this._then);

  final GearSetResponse _self;
  final $Res Function(GearSetResponse) _then;

/// Create a copy of GearSetResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? author = null,Object? totalWeight = null,Object? itemCount = null,Object? visibility = null,Object? downloadKey = freezed,Object? items = null,Object? meals = freezed,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,totalWeight: null == totalWeight ? _self.totalWeight : totalWeight // ignore: cast_nullable_to_non_nullable
as double,itemCount: null == itemCount ? _self.itemCount : itemCount // ignore: cast_nullable_to_non_nullable
as int,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as String,downloadKey: freezed == downloadKey ? _self.downloadKey : downloadKey // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<GearSetItemDto>,meals: freezed == meals ? _self.meals : meals // ignore: cast_nullable_to_non_nullable
as List<GearSetMealDto>?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [GearSetResponse].
extension GearSetResponsePatterns on GearSetResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GearSetResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GearSetResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GearSetResponse value)  $default,){
final _that = this;
switch (_that) {
case _GearSetResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GearSetResponse value)?  $default,){
final _that = this;
switch (_that) {
case _GearSetResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String author, @JsonKey(name: 'total_weight')  double totalWeight, @JsonKey(name: 'item_count')  int itemCount,  String visibility, @JsonKey(name: 'download_key')  String? downloadKey,  List<GearSetItemDto> items,  List<GearSetMealDto>? meals, @JsonKey(name: 'created_at')@DateTimeUtcConverter()  DateTime createdAt, @JsonKey(name: 'created_by')  String createdBy, @JsonKey(name: 'updated_at')@DateTimeUtcConverter()  DateTime updatedAt, @JsonKey(name: 'updated_by')  String updatedBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GearSetResponse() when $default != null:
return $default(_that.id,_that.title,_that.author,_that.totalWeight,_that.itemCount,_that.visibility,_that.downloadKey,_that.items,_that.meals,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String author, @JsonKey(name: 'total_weight')  double totalWeight, @JsonKey(name: 'item_count')  int itemCount,  String visibility, @JsonKey(name: 'download_key')  String? downloadKey,  List<GearSetItemDto> items,  List<GearSetMealDto>? meals, @JsonKey(name: 'created_at')@DateTimeUtcConverter()  DateTime createdAt, @JsonKey(name: 'created_by')  String createdBy, @JsonKey(name: 'updated_at')@DateTimeUtcConverter()  DateTime updatedAt, @JsonKey(name: 'updated_by')  String updatedBy)  $default,) {final _that = this;
switch (_that) {
case _GearSetResponse():
return $default(_that.id,_that.title,_that.author,_that.totalWeight,_that.itemCount,_that.visibility,_that.downloadKey,_that.items,_that.meals,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String author, @JsonKey(name: 'total_weight')  double totalWeight, @JsonKey(name: 'item_count')  int itemCount,  String visibility, @JsonKey(name: 'download_key')  String? downloadKey,  List<GearSetItemDto> items,  List<GearSetMealDto>? meals, @JsonKey(name: 'created_at')@DateTimeUtcConverter()  DateTime createdAt, @JsonKey(name: 'created_by')  String createdBy, @JsonKey(name: 'updated_at')@DateTimeUtcConverter()  DateTime updatedAt, @JsonKey(name: 'updated_by')  String updatedBy)?  $default,) {final _that = this;
switch (_that) {
case _GearSetResponse() when $default != null:
return $default(_that.id,_that.title,_that.author,_that.totalWeight,_that.itemCount,_that.visibility,_that.downloadKey,_that.items,_that.meals,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GearSetResponse implements GearSetResponse {
  const _GearSetResponse({required this.id, required this.title, required this.author, @JsonKey(name: 'total_weight') this.totalWeight = 0.0, @JsonKey(name: 'item_count') this.itemCount = 0, required this.visibility, @JsonKey(name: 'download_key') this.downloadKey, final  List<GearSetItemDto> items = const [], final  List<GearSetMealDto>? meals, @JsonKey(name: 'created_at')@DateTimeUtcConverter() required this.createdAt, @JsonKey(name: 'created_by') required this.createdBy, @JsonKey(name: 'updated_at')@DateTimeUtcConverter() required this.updatedAt, @JsonKey(name: 'updated_by') required this.updatedBy}): _items = items,_meals = meals;
  factory _GearSetResponse.fromJson(Map<String, dynamic> json) => _$GearSetResponseFromJson(json);

@override final  String id;
@override final  String title;
@override final  String author;
@override@JsonKey(name: 'total_weight') final  double totalWeight;
@override@JsonKey(name: 'item_count') final  int itemCount;
@override final  String visibility;
@override@JsonKey(name: 'download_key') final  String? downloadKey;
 final  List<GearSetItemDto> _items;
@override@JsonKey() List<GearSetItemDto> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

 final  List<GearSetMealDto>? _meals;
@override List<GearSetMealDto>? get meals {
  final value = _meals;
  if (value == null) return null;
  if (_meals is EqualUnmodifiableListView) return _meals;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey(name: 'created_at')@DateTimeUtcConverter() final  DateTime createdAt;
@override@JsonKey(name: 'created_by') final  String createdBy;
@override@JsonKey(name: 'updated_at')@DateTimeUtcConverter() final  DateTime updatedAt;
@override@JsonKey(name: 'updated_by') final  String updatedBy;

/// Create a copy of GearSetResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GearSetResponseCopyWith<_GearSetResponse> get copyWith => __$GearSetResponseCopyWithImpl<_GearSetResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GearSetResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GearSetResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.author, author) || other.author == author)&&(identical(other.totalWeight, totalWeight) || other.totalWeight == totalWeight)&&(identical(other.itemCount, itemCount) || other.itemCount == itemCount)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.downloadKey, downloadKey) || other.downloadKey == downloadKey)&&const DeepCollectionEquality().equals(other._items, _items)&&const DeepCollectionEquality().equals(other._meals, _meals)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,author,totalWeight,itemCount,visibility,downloadKey,const DeepCollectionEquality().hash(_items),const DeepCollectionEquality().hash(_meals),createdAt,createdBy,updatedAt,updatedBy);

@override
String toString() {
  return 'GearSetResponse(id: $id, title: $title, author: $author, totalWeight: $totalWeight, itemCount: $itemCount, visibility: $visibility, downloadKey: $downloadKey, items: $items, meals: $meals, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy)';
}


}

/// @nodoc
abstract mixin class _$GearSetResponseCopyWith<$Res> implements $GearSetResponseCopyWith<$Res> {
  factory _$GearSetResponseCopyWith(_GearSetResponse value, $Res Function(_GearSetResponse) _then) = __$GearSetResponseCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String author,@JsonKey(name: 'total_weight') double totalWeight,@JsonKey(name: 'item_count') int itemCount, String visibility,@JsonKey(name: 'download_key') String? downloadKey, List<GearSetItemDto> items, List<GearSetMealDto>? meals,@JsonKey(name: 'created_at')@DateTimeUtcConverter() DateTime createdAt,@JsonKey(name: 'created_by') String createdBy,@JsonKey(name: 'updated_at')@DateTimeUtcConverter() DateTime updatedAt,@JsonKey(name: 'updated_by') String updatedBy
});




}
/// @nodoc
class __$GearSetResponseCopyWithImpl<$Res>
    implements _$GearSetResponseCopyWith<$Res> {
  __$GearSetResponseCopyWithImpl(this._self, this._then);

  final _GearSetResponse _self;
  final $Res Function(_GearSetResponse) _then;

/// Create a copy of GearSetResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? author = null,Object? totalWeight = null,Object? itemCount = null,Object? visibility = null,Object? downloadKey = freezed,Object? items = null,Object? meals = freezed,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,}) {
  return _then(_GearSetResponse(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,totalWeight: null == totalWeight ? _self.totalWeight : totalWeight // ignore: cast_nullable_to_non_nullable
as double,itemCount: null == itemCount ? _self.itemCount : itemCount // ignore: cast_nullable_to_non_nullable
as int,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as String,downloadKey: freezed == downloadKey ? _self.downloadKey : downloadKey // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<GearSetItemDto>,meals: freezed == meals ? _self._meals : meals // ignore: cast_nullable_to_non_nullable
as List<GearSetMealDto>?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$GearSetListResponse {

 List<GearSetResponse> get data;
/// Create a copy of GearSetListResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GearSetListResponseCopyWith<GearSetListResponse> get copyWith => _$GearSetListResponseCopyWithImpl<GearSetListResponse>(this as GearSetListResponse, _$identity);

  /// Serializes this GearSetListResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GearSetListResponse&&const DeepCollectionEquality().equals(other.data, data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(data));

@override
String toString() {
  return 'GearSetListResponse(data: $data)';
}


}

/// @nodoc
abstract mixin class $GearSetListResponseCopyWith<$Res>  {
  factory $GearSetListResponseCopyWith(GearSetListResponse value, $Res Function(GearSetListResponse) _then) = _$GearSetListResponseCopyWithImpl;
@useResult
$Res call({
 List<GearSetResponse> data
});




}
/// @nodoc
class _$GearSetListResponseCopyWithImpl<$Res>
    implements $GearSetListResponseCopyWith<$Res> {
  _$GearSetListResponseCopyWithImpl(this._self, this._then);

  final GearSetListResponse _self;
  final $Res Function(GearSetListResponse) _then;

/// Create a copy of GearSetListResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? data = null,}) {
  return _then(_self.copyWith(
data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as List<GearSetResponse>,
  ));
}

}


/// Adds pattern-matching-related methods to [GearSetListResponse].
extension GearSetListResponsePatterns on GearSetListResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GearSetListResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GearSetListResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GearSetListResponse value)  $default,){
final _that = this;
switch (_that) {
case _GearSetListResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GearSetListResponse value)?  $default,){
final _that = this;
switch (_that) {
case _GearSetListResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<GearSetResponse> data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GearSetListResponse() when $default != null:
return $default(_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<GearSetResponse> data)  $default,) {final _that = this;
switch (_that) {
case _GearSetListResponse():
return $default(_that.data);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<GearSetResponse> data)?  $default,) {final _that = this;
switch (_that) {
case _GearSetListResponse() when $default != null:
return $default(_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GearSetListResponse implements GearSetListResponse {
  const _GearSetListResponse({final  List<GearSetResponse> data = const []}): _data = data;
  factory _GearSetListResponse.fromJson(Map<String, dynamic> json) => _$GearSetListResponseFromJson(json);

 final  List<GearSetResponse> _data;
@override@JsonKey() List<GearSetResponse> get data {
  if (_data is EqualUnmodifiableListView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_data);
}


/// Create a copy of GearSetListResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GearSetListResponseCopyWith<_GearSetListResponse> get copyWith => __$GearSetListResponseCopyWithImpl<_GearSetListResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GearSetListResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GearSetListResponse&&const DeepCollectionEquality().equals(other._data, _data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'GearSetListResponse(data: $data)';
}


}

/// @nodoc
abstract mixin class _$GearSetListResponseCopyWith<$Res> implements $GearSetListResponseCopyWith<$Res> {
  factory _$GearSetListResponseCopyWith(_GearSetListResponse value, $Res Function(_GearSetListResponse) _then) = __$GearSetListResponseCopyWithImpl;
@override @useResult
$Res call({
 List<GearSetResponse> data
});




}
/// @nodoc
class __$GearSetListResponseCopyWithImpl<$Res>
    implements _$GearSetListResponseCopyWith<$Res> {
  __$GearSetListResponseCopyWithImpl(this._self, this._then);

  final _GearSetListResponse _self;
  final $Res Function(_GearSetListResponse) _then;

/// Create a copy of GearSetListResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? data = null,}) {
  return _then(_GearSetListResponse(
data: null == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as List<GearSetResponse>,
  ));
}


}

// dart format on
