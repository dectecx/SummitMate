// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trip_meal_api_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TripMealItemResponse {

 String get id;@JsonKey(name: 'trip_id') String get tripId;@JsonKey(name: 'library_item_id') String? get libraryItemId; String get day;@JsonKey(name: 'meal_type') String get mealType; String get name;@JsonKey(defaultValue: 0.0) double get weight;@JsonKey(defaultValue: 0.0) double get calories;@JsonKey(defaultValue: 1) int get quantity; String? get note;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime get updatedAt;
/// Create a copy of TripMealItemResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripMealItemResponseCopyWith<TripMealItemResponse> get copyWith => _$TripMealItemResponseCopyWithImpl<TripMealItemResponse>(this as TripMealItemResponse, _$identity);

  /// Serializes this TripMealItemResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripMealItemResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.libraryItemId, libraryItemId) || other.libraryItemId == libraryItemId)&&(identical(other.day, day) || other.day == day)&&(identical(other.mealType, mealType) || other.mealType == mealType)&&(identical(other.name, name) || other.name == name)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.calories, calories) || other.calories == calories)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.note, note) || other.note == note)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,libraryItemId,day,mealType,name,weight,calories,quantity,note,createdAt,updatedAt);

@override
String toString() {
  return 'TripMealItemResponse(id: $id, tripId: $tripId, libraryItemId: $libraryItemId, day: $day, mealType: $mealType, name: $name, weight: $weight, calories: $calories, quantity: $quantity, note: $note, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $TripMealItemResponseCopyWith<$Res>  {
  factory $TripMealItemResponseCopyWith(TripMealItemResponse value, $Res Function(TripMealItemResponse) _then) = _$TripMealItemResponseCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'trip_id') String tripId,@JsonKey(name: 'library_item_id') String? libraryItemId, String day,@JsonKey(name: 'meal_type') String mealType, String name,@JsonKey(defaultValue: 0.0) double weight,@JsonKey(defaultValue: 0.0) double calories,@JsonKey(defaultValue: 1) int quantity, String? note,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt
});




}
/// @nodoc
class _$TripMealItemResponseCopyWithImpl<$Res>
    implements $TripMealItemResponseCopyWith<$Res> {
  _$TripMealItemResponseCopyWithImpl(this._self, this._then);

  final TripMealItemResponse _self;
  final $Res Function(TripMealItemResponse) _then;

/// Create a copy of TripMealItemResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tripId = null,Object? libraryItemId = freezed,Object? day = null,Object? mealType = null,Object? name = null,Object? weight = null,Object? calories = null,Object? quantity = null,Object? note = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,libraryItemId: freezed == libraryItemId ? _self.libraryItemId : libraryItemId // ignore: cast_nullable_to_non_nullable
as String?,day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as String,mealType: null == mealType ? _self.mealType : mealType // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as double,calories: null == calories ? _self.calories : calories // ignore: cast_nullable_to_non_nullable
as double,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [TripMealItemResponse].
extension TripMealItemResponsePatterns on TripMealItemResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripMealItemResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripMealItemResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripMealItemResponse value)  $default,){
final _that = this;
switch (_that) {
case _TripMealItemResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripMealItemResponse value)?  $default,){
final _that = this;
switch (_that) {
case _TripMealItemResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'trip_id')  String tripId, @JsonKey(name: 'library_item_id')  String? libraryItemId,  String day, @JsonKey(name: 'meal_type')  String mealType,  String name, @JsonKey(defaultValue: 0.0)  double weight, @JsonKey(defaultValue: 0.0)  double calories, @JsonKey(defaultValue: 1)  int quantity,  String? note, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripMealItemResponse() when $default != null:
return $default(_that.id,_that.tripId,_that.libraryItemId,_that.day,_that.mealType,_that.name,_that.weight,_that.calories,_that.quantity,_that.note,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'trip_id')  String tripId, @JsonKey(name: 'library_item_id')  String? libraryItemId,  String day, @JsonKey(name: 'meal_type')  String mealType,  String name, @JsonKey(defaultValue: 0.0)  double weight, @JsonKey(defaultValue: 0.0)  double calories, @JsonKey(defaultValue: 1)  int quantity,  String? note, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _TripMealItemResponse():
return $default(_that.id,_that.tripId,_that.libraryItemId,_that.day,_that.mealType,_that.name,_that.weight,_that.calories,_that.quantity,_that.note,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'trip_id')  String tripId, @JsonKey(name: 'library_item_id')  String? libraryItemId,  String day, @JsonKey(name: 'meal_type')  String mealType,  String name, @JsonKey(defaultValue: 0.0)  double weight, @JsonKey(defaultValue: 0.0)  double calories, @JsonKey(defaultValue: 1)  int quantity,  String? note, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _TripMealItemResponse() when $default != null:
return $default(_that.id,_that.tripId,_that.libraryItemId,_that.day,_that.mealType,_that.name,_that.weight,_that.calories,_that.quantity,_that.note,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TripMealItemResponse implements TripMealItemResponse {
  const _TripMealItemResponse({required this.id, @JsonKey(name: 'trip_id') required this.tripId, @JsonKey(name: 'library_item_id') this.libraryItemId, required this.day, @JsonKey(name: 'meal_type') required this.mealType, required this.name, @JsonKey(defaultValue: 0.0) required this.weight, @JsonKey(defaultValue: 0.0) required this.calories, @JsonKey(defaultValue: 1) required this.quantity, this.note, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt});
  factory _TripMealItemResponse.fromJson(Map<String, dynamic> json) => _$TripMealItemResponseFromJson(json);

@override final  String id;
@override@JsonKey(name: 'trip_id') final  String tripId;
@override@JsonKey(name: 'library_item_id') final  String? libraryItemId;
@override final  String day;
@override@JsonKey(name: 'meal_type') final  String mealType;
@override final  String name;
@override@JsonKey(defaultValue: 0.0) final  double weight;
@override@JsonKey(defaultValue: 0.0) final  double calories;
@override@JsonKey(defaultValue: 1) final  int quantity;
@override final  String? note;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;

/// Create a copy of TripMealItemResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripMealItemResponseCopyWith<_TripMealItemResponse> get copyWith => __$TripMealItemResponseCopyWithImpl<_TripMealItemResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripMealItemResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripMealItemResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.libraryItemId, libraryItemId) || other.libraryItemId == libraryItemId)&&(identical(other.day, day) || other.day == day)&&(identical(other.mealType, mealType) || other.mealType == mealType)&&(identical(other.name, name) || other.name == name)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.calories, calories) || other.calories == calories)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.note, note) || other.note == note)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,libraryItemId,day,mealType,name,weight,calories,quantity,note,createdAt,updatedAt);

@override
String toString() {
  return 'TripMealItemResponse(id: $id, tripId: $tripId, libraryItemId: $libraryItemId, day: $day, mealType: $mealType, name: $name, weight: $weight, calories: $calories, quantity: $quantity, note: $note, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$TripMealItemResponseCopyWith<$Res> implements $TripMealItemResponseCopyWith<$Res> {
  factory _$TripMealItemResponseCopyWith(_TripMealItemResponse value, $Res Function(_TripMealItemResponse) _then) = __$TripMealItemResponseCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'trip_id') String tripId,@JsonKey(name: 'library_item_id') String? libraryItemId, String day,@JsonKey(name: 'meal_type') String mealType, String name,@JsonKey(defaultValue: 0.0) double weight,@JsonKey(defaultValue: 0.0) double calories,@JsonKey(defaultValue: 1) int quantity, String? note,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt
});




}
/// @nodoc
class __$TripMealItemResponseCopyWithImpl<$Res>
    implements _$TripMealItemResponseCopyWith<$Res> {
  __$TripMealItemResponseCopyWithImpl(this._self, this._then);

  final _TripMealItemResponse _self;
  final $Res Function(_TripMealItemResponse) _then;

/// Create a copy of TripMealItemResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tripId = null,Object? libraryItemId = freezed,Object? day = null,Object? mealType = null,Object? name = null,Object? weight = null,Object? calories = null,Object? quantity = null,Object? note = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_TripMealItemResponse(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,libraryItemId: freezed == libraryItemId ? _self.libraryItemId : libraryItemId // ignore: cast_nullable_to_non_nullable
as String?,day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as String,mealType: null == mealType ? _self.mealType : mealType // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as double,calories: null == calories ? _self.calories : calories // ignore: cast_nullable_to_non_nullable
as double,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$TripMealItemRequest {

@JsonKey(name: 'library_item_id') String? get libraryItemId; String get day;@JsonKey(name: 'meal_type') String get mealType; String get name; double get weight; double get calories;@JsonKey(defaultValue: 1) int get quantity; String? get note;
/// Create a copy of TripMealItemRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripMealItemRequestCopyWith<TripMealItemRequest> get copyWith => _$TripMealItemRequestCopyWithImpl<TripMealItemRequest>(this as TripMealItemRequest, _$identity);

  /// Serializes this TripMealItemRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripMealItemRequest&&(identical(other.libraryItemId, libraryItemId) || other.libraryItemId == libraryItemId)&&(identical(other.day, day) || other.day == day)&&(identical(other.mealType, mealType) || other.mealType == mealType)&&(identical(other.name, name) || other.name == name)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.calories, calories) || other.calories == calories)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,libraryItemId,day,mealType,name,weight,calories,quantity,note);

@override
String toString() {
  return 'TripMealItemRequest(libraryItemId: $libraryItemId, day: $day, mealType: $mealType, name: $name, weight: $weight, calories: $calories, quantity: $quantity, note: $note)';
}


}

/// @nodoc
abstract mixin class $TripMealItemRequestCopyWith<$Res>  {
  factory $TripMealItemRequestCopyWith(TripMealItemRequest value, $Res Function(TripMealItemRequest) _then) = _$TripMealItemRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'library_item_id') String? libraryItemId, String day,@JsonKey(name: 'meal_type') String mealType, String name, double weight, double calories,@JsonKey(defaultValue: 1) int quantity, String? note
});




}
/// @nodoc
class _$TripMealItemRequestCopyWithImpl<$Res>
    implements $TripMealItemRequestCopyWith<$Res> {
  _$TripMealItemRequestCopyWithImpl(this._self, this._then);

  final TripMealItemRequest _self;
  final $Res Function(TripMealItemRequest) _then;

/// Create a copy of TripMealItemRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? libraryItemId = freezed,Object? day = null,Object? mealType = null,Object? name = null,Object? weight = null,Object? calories = null,Object? quantity = null,Object? note = freezed,}) {
  return _then(_self.copyWith(
libraryItemId: freezed == libraryItemId ? _self.libraryItemId : libraryItemId // ignore: cast_nullable_to_non_nullable
as String?,day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as String,mealType: null == mealType ? _self.mealType : mealType // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as double,calories: null == calories ? _self.calories : calories // ignore: cast_nullable_to_non_nullable
as double,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TripMealItemRequest].
extension TripMealItemRequestPatterns on TripMealItemRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripMealItemRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripMealItemRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripMealItemRequest value)  $default,){
final _that = this;
switch (_that) {
case _TripMealItemRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripMealItemRequest value)?  $default,){
final _that = this;
switch (_that) {
case _TripMealItemRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'library_item_id')  String? libraryItemId,  String day, @JsonKey(name: 'meal_type')  String mealType,  String name,  double weight,  double calories, @JsonKey(defaultValue: 1)  int quantity,  String? note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripMealItemRequest() when $default != null:
return $default(_that.libraryItemId,_that.day,_that.mealType,_that.name,_that.weight,_that.calories,_that.quantity,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'library_item_id')  String? libraryItemId,  String day, @JsonKey(name: 'meal_type')  String mealType,  String name,  double weight,  double calories, @JsonKey(defaultValue: 1)  int quantity,  String? note)  $default,) {final _that = this;
switch (_that) {
case _TripMealItemRequest():
return $default(_that.libraryItemId,_that.day,_that.mealType,_that.name,_that.weight,_that.calories,_that.quantity,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'library_item_id')  String? libraryItemId,  String day, @JsonKey(name: 'meal_type')  String mealType,  String name,  double weight,  double calories, @JsonKey(defaultValue: 1)  int quantity,  String? note)?  $default,) {final _that = this;
switch (_that) {
case _TripMealItemRequest() when $default != null:
return $default(_that.libraryItemId,_that.day,_that.mealType,_that.name,_that.weight,_that.calories,_that.quantity,_that.note);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TripMealItemRequest implements TripMealItemRequest {
  const _TripMealItemRequest({@JsonKey(name: 'library_item_id') this.libraryItemId, required this.day, @JsonKey(name: 'meal_type') required this.mealType, required this.name, required this.weight, required this.calories, @JsonKey(defaultValue: 1) required this.quantity, this.note});
  factory _TripMealItemRequest.fromJson(Map<String, dynamic> json) => _$TripMealItemRequestFromJson(json);

@override@JsonKey(name: 'library_item_id') final  String? libraryItemId;
@override final  String day;
@override@JsonKey(name: 'meal_type') final  String mealType;
@override final  String name;
@override final  double weight;
@override final  double calories;
@override@JsonKey(defaultValue: 1) final  int quantity;
@override final  String? note;

/// Create a copy of TripMealItemRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripMealItemRequestCopyWith<_TripMealItemRequest> get copyWith => __$TripMealItemRequestCopyWithImpl<_TripMealItemRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripMealItemRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripMealItemRequest&&(identical(other.libraryItemId, libraryItemId) || other.libraryItemId == libraryItemId)&&(identical(other.day, day) || other.day == day)&&(identical(other.mealType, mealType) || other.mealType == mealType)&&(identical(other.name, name) || other.name == name)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.calories, calories) || other.calories == calories)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,libraryItemId,day,mealType,name,weight,calories,quantity,note);

@override
String toString() {
  return 'TripMealItemRequest(libraryItemId: $libraryItemId, day: $day, mealType: $mealType, name: $name, weight: $weight, calories: $calories, quantity: $quantity, note: $note)';
}


}

/// @nodoc
abstract mixin class _$TripMealItemRequestCopyWith<$Res> implements $TripMealItemRequestCopyWith<$Res> {
  factory _$TripMealItemRequestCopyWith(_TripMealItemRequest value, $Res Function(_TripMealItemRequest) _then) = __$TripMealItemRequestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'library_item_id') String? libraryItemId, String day,@JsonKey(name: 'meal_type') String mealType, String name, double weight, double calories,@JsonKey(defaultValue: 1) int quantity, String? note
});




}
/// @nodoc
class __$TripMealItemRequestCopyWithImpl<$Res>
    implements _$TripMealItemRequestCopyWith<$Res> {
  __$TripMealItemRequestCopyWithImpl(this._self, this._then);

  final _TripMealItemRequest _self;
  final $Res Function(_TripMealItemRequest) _then;

/// Create a copy of TripMealItemRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? libraryItemId = freezed,Object? day = null,Object? mealType = null,Object? name = null,Object? weight = null,Object? calories = null,Object? quantity = null,Object? note = freezed,}) {
  return _then(_TripMealItemRequest(
libraryItemId: freezed == libraryItemId ? _self.libraryItemId : libraryItemId // ignore: cast_nullable_to_non_nullable
as String?,day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as String,mealType: null == mealType ? _self.mealType : mealType // ignore: cast_nullable_to_non_nullable
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
