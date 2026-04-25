// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trip_gear_api_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TripGearItemResponse {

 String get id;@JsonKey(name: 'trip_id') String get tripId;@JsonKey(name: 'library_item_id') String? get libraryItemId;@JsonKey(defaultValue: '') String get name;@JsonKey(defaultValue: 0.0) double get weight;@JsonKey(defaultValue: 'Other') String get category;@JsonKey(defaultValue: 1) int get quantity;@JsonKey(name: 'is_checked', defaultValue: false) bool get isChecked;@JsonKey(name: 'order_index') int? get orderIndex;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime get updatedAt;
/// Create a copy of TripGearItemResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripGearItemResponseCopyWith<TripGearItemResponse> get copyWith => _$TripGearItemResponseCopyWithImpl<TripGearItemResponse>(this as TripGearItemResponse, _$identity);

  /// Serializes this TripGearItemResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripGearItemResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.libraryItemId, libraryItemId) || other.libraryItemId == libraryItemId)&&(identical(other.name, name) || other.name == name)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.category, category) || other.category == category)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.isChecked, isChecked) || other.isChecked == isChecked)&&(identical(other.orderIndex, orderIndex) || other.orderIndex == orderIndex)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,libraryItemId,name,weight,category,quantity,isChecked,orderIndex,createdAt,updatedAt);

@override
String toString() {
  return 'TripGearItemResponse(id: $id, tripId: $tripId, libraryItemId: $libraryItemId, name: $name, weight: $weight, category: $category, quantity: $quantity, isChecked: $isChecked, orderIndex: $orderIndex, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $TripGearItemResponseCopyWith<$Res>  {
  factory $TripGearItemResponseCopyWith(TripGearItemResponse value, $Res Function(TripGearItemResponse) _then) = _$TripGearItemResponseCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'trip_id') String tripId,@JsonKey(name: 'library_item_id') String? libraryItemId,@JsonKey(defaultValue: '') String name,@JsonKey(defaultValue: 0.0) double weight,@JsonKey(defaultValue: 'Other') String category,@JsonKey(defaultValue: 1) int quantity,@JsonKey(name: 'is_checked', defaultValue: false) bool isChecked,@JsonKey(name: 'order_index') int? orderIndex,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt
});




}
/// @nodoc
class _$TripGearItemResponseCopyWithImpl<$Res>
    implements $TripGearItemResponseCopyWith<$Res> {
  _$TripGearItemResponseCopyWithImpl(this._self, this._then);

  final TripGearItemResponse _self;
  final $Res Function(TripGearItemResponse) _then;

/// Create a copy of TripGearItemResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tripId = null,Object? libraryItemId = freezed,Object? name = null,Object? weight = null,Object? category = null,Object? quantity = null,Object? isChecked = null,Object? orderIndex = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,libraryItemId: freezed == libraryItemId ? _self.libraryItemId : libraryItemId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as double,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,isChecked: null == isChecked ? _self.isChecked : isChecked // ignore: cast_nullable_to_non_nullable
as bool,orderIndex: freezed == orderIndex ? _self.orderIndex : orderIndex // ignore: cast_nullable_to_non_nullable
as int?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [TripGearItemResponse].
extension TripGearItemResponsePatterns on TripGearItemResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripGearItemResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripGearItemResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripGearItemResponse value)  $default,){
final _that = this;
switch (_that) {
case _TripGearItemResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripGearItemResponse value)?  $default,){
final _that = this;
switch (_that) {
case _TripGearItemResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'trip_id')  String tripId, @JsonKey(name: 'library_item_id')  String? libraryItemId, @JsonKey(defaultValue: '')  String name, @JsonKey(defaultValue: 0.0)  double weight, @JsonKey(defaultValue: 'Other')  String category, @JsonKey(defaultValue: 1)  int quantity, @JsonKey(name: 'is_checked', defaultValue: false)  bool isChecked, @JsonKey(name: 'order_index')  int? orderIndex, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripGearItemResponse() when $default != null:
return $default(_that.id,_that.tripId,_that.libraryItemId,_that.name,_that.weight,_that.category,_that.quantity,_that.isChecked,_that.orderIndex,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'trip_id')  String tripId, @JsonKey(name: 'library_item_id')  String? libraryItemId, @JsonKey(defaultValue: '')  String name, @JsonKey(defaultValue: 0.0)  double weight, @JsonKey(defaultValue: 'Other')  String category, @JsonKey(defaultValue: 1)  int quantity, @JsonKey(name: 'is_checked', defaultValue: false)  bool isChecked, @JsonKey(name: 'order_index')  int? orderIndex, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _TripGearItemResponse():
return $default(_that.id,_that.tripId,_that.libraryItemId,_that.name,_that.weight,_that.category,_that.quantity,_that.isChecked,_that.orderIndex,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'trip_id')  String tripId, @JsonKey(name: 'library_item_id')  String? libraryItemId, @JsonKey(defaultValue: '')  String name, @JsonKey(defaultValue: 0.0)  double weight, @JsonKey(defaultValue: 'Other')  String category, @JsonKey(defaultValue: 1)  int quantity, @JsonKey(name: 'is_checked', defaultValue: false)  bool isChecked, @JsonKey(name: 'order_index')  int? orderIndex, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _TripGearItemResponse() when $default != null:
return $default(_that.id,_that.tripId,_that.libraryItemId,_that.name,_that.weight,_that.category,_that.quantity,_that.isChecked,_that.orderIndex,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TripGearItemResponse implements TripGearItemResponse {
  const _TripGearItemResponse({required this.id, @JsonKey(name: 'trip_id') required this.tripId, @JsonKey(name: 'library_item_id') this.libraryItemId, @JsonKey(defaultValue: '') required this.name, @JsonKey(defaultValue: 0.0) required this.weight, @JsonKey(defaultValue: 'Other') required this.category, @JsonKey(defaultValue: 1) required this.quantity, @JsonKey(name: 'is_checked', defaultValue: false) required this.isChecked, @JsonKey(name: 'order_index') this.orderIndex, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt});
  factory _TripGearItemResponse.fromJson(Map<String, dynamic> json) => _$TripGearItemResponseFromJson(json);

@override final  String id;
@override@JsonKey(name: 'trip_id') final  String tripId;
@override@JsonKey(name: 'library_item_id') final  String? libraryItemId;
@override@JsonKey(defaultValue: '') final  String name;
@override@JsonKey(defaultValue: 0.0) final  double weight;
@override@JsonKey(defaultValue: 'Other') final  String category;
@override@JsonKey(defaultValue: 1) final  int quantity;
@override@JsonKey(name: 'is_checked', defaultValue: false) final  bool isChecked;
@override@JsonKey(name: 'order_index') final  int? orderIndex;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;

/// Create a copy of TripGearItemResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripGearItemResponseCopyWith<_TripGearItemResponse> get copyWith => __$TripGearItemResponseCopyWithImpl<_TripGearItemResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripGearItemResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripGearItemResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.libraryItemId, libraryItemId) || other.libraryItemId == libraryItemId)&&(identical(other.name, name) || other.name == name)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.category, category) || other.category == category)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.isChecked, isChecked) || other.isChecked == isChecked)&&(identical(other.orderIndex, orderIndex) || other.orderIndex == orderIndex)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,libraryItemId,name,weight,category,quantity,isChecked,orderIndex,createdAt,updatedAt);

@override
String toString() {
  return 'TripGearItemResponse(id: $id, tripId: $tripId, libraryItemId: $libraryItemId, name: $name, weight: $weight, category: $category, quantity: $quantity, isChecked: $isChecked, orderIndex: $orderIndex, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$TripGearItemResponseCopyWith<$Res> implements $TripGearItemResponseCopyWith<$Res> {
  factory _$TripGearItemResponseCopyWith(_TripGearItemResponse value, $Res Function(_TripGearItemResponse) _then) = __$TripGearItemResponseCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'trip_id') String tripId,@JsonKey(name: 'library_item_id') String? libraryItemId,@JsonKey(defaultValue: '') String name,@JsonKey(defaultValue: 0.0) double weight,@JsonKey(defaultValue: 'Other') String category,@JsonKey(defaultValue: 1) int quantity,@JsonKey(name: 'is_checked', defaultValue: false) bool isChecked,@JsonKey(name: 'order_index') int? orderIndex,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt
});




}
/// @nodoc
class __$TripGearItemResponseCopyWithImpl<$Res>
    implements _$TripGearItemResponseCopyWith<$Res> {
  __$TripGearItemResponseCopyWithImpl(this._self, this._then);

  final _TripGearItemResponse _self;
  final $Res Function(_TripGearItemResponse) _then;

/// Create a copy of TripGearItemResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tripId = null,Object? libraryItemId = freezed,Object? name = null,Object? weight = null,Object? category = null,Object? quantity = null,Object? isChecked = null,Object? orderIndex = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_TripGearItemResponse(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,libraryItemId: freezed == libraryItemId ? _self.libraryItemId : libraryItemId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as double,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,isChecked: null == isChecked ? _self.isChecked : isChecked // ignore: cast_nullable_to_non_nullable
as bool,orderIndex: freezed == orderIndex ? _self.orderIndex : orderIndex // ignore: cast_nullable_to_non_nullable
as int?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$TripGearItemRequest {

@JsonKey(name: 'library_item_id') String? get libraryItemId; String get name; double get weight; String get category;@JsonKey(defaultValue: 1) int get quantity;@JsonKey(name: 'is_checked', defaultValue: false) bool get isChecked;@JsonKey(name: 'order_index') int? get orderIndex;
/// Create a copy of TripGearItemRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripGearItemRequestCopyWith<TripGearItemRequest> get copyWith => _$TripGearItemRequestCopyWithImpl<TripGearItemRequest>(this as TripGearItemRequest, _$identity);

  /// Serializes this TripGearItemRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripGearItemRequest&&(identical(other.libraryItemId, libraryItemId) || other.libraryItemId == libraryItemId)&&(identical(other.name, name) || other.name == name)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.category, category) || other.category == category)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.isChecked, isChecked) || other.isChecked == isChecked)&&(identical(other.orderIndex, orderIndex) || other.orderIndex == orderIndex));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,libraryItemId,name,weight,category,quantity,isChecked,orderIndex);

@override
String toString() {
  return 'TripGearItemRequest(libraryItemId: $libraryItemId, name: $name, weight: $weight, category: $category, quantity: $quantity, isChecked: $isChecked, orderIndex: $orderIndex)';
}


}

/// @nodoc
abstract mixin class $TripGearItemRequestCopyWith<$Res>  {
  factory $TripGearItemRequestCopyWith(TripGearItemRequest value, $Res Function(TripGearItemRequest) _then) = _$TripGearItemRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'library_item_id') String? libraryItemId, String name, double weight, String category,@JsonKey(defaultValue: 1) int quantity,@JsonKey(name: 'is_checked', defaultValue: false) bool isChecked,@JsonKey(name: 'order_index') int? orderIndex
});




}
/// @nodoc
class _$TripGearItemRequestCopyWithImpl<$Res>
    implements $TripGearItemRequestCopyWith<$Res> {
  _$TripGearItemRequestCopyWithImpl(this._self, this._then);

  final TripGearItemRequest _self;
  final $Res Function(TripGearItemRequest) _then;

/// Create a copy of TripGearItemRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? libraryItemId = freezed,Object? name = null,Object? weight = null,Object? category = null,Object? quantity = null,Object? isChecked = null,Object? orderIndex = freezed,}) {
  return _then(_self.copyWith(
libraryItemId: freezed == libraryItemId ? _self.libraryItemId : libraryItemId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as double,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,isChecked: null == isChecked ? _self.isChecked : isChecked // ignore: cast_nullable_to_non_nullable
as bool,orderIndex: freezed == orderIndex ? _self.orderIndex : orderIndex // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [TripGearItemRequest].
extension TripGearItemRequestPatterns on TripGearItemRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripGearItemRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripGearItemRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripGearItemRequest value)  $default,){
final _that = this;
switch (_that) {
case _TripGearItemRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripGearItemRequest value)?  $default,){
final _that = this;
switch (_that) {
case _TripGearItemRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'library_item_id')  String? libraryItemId,  String name,  double weight,  String category, @JsonKey(defaultValue: 1)  int quantity, @JsonKey(name: 'is_checked', defaultValue: false)  bool isChecked, @JsonKey(name: 'order_index')  int? orderIndex)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripGearItemRequest() when $default != null:
return $default(_that.libraryItemId,_that.name,_that.weight,_that.category,_that.quantity,_that.isChecked,_that.orderIndex);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'library_item_id')  String? libraryItemId,  String name,  double weight,  String category, @JsonKey(defaultValue: 1)  int quantity, @JsonKey(name: 'is_checked', defaultValue: false)  bool isChecked, @JsonKey(name: 'order_index')  int? orderIndex)  $default,) {final _that = this;
switch (_that) {
case _TripGearItemRequest():
return $default(_that.libraryItemId,_that.name,_that.weight,_that.category,_that.quantity,_that.isChecked,_that.orderIndex);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'library_item_id')  String? libraryItemId,  String name,  double weight,  String category, @JsonKey(defaultValue: 1)  int quantity, @JsonKey(name: 'is_checked', defaultValue: false)  bool isChecked, @JsonKey(name: 'order_index')  int? orderIndex)?  $default,) {final _that = this;
switch (_that) {
case _TripGearItemRequest() when $default != null:
return $default(_that.libraryItemId,_that.name,_that.weight,_that.category,_that.quantity,_that.isChecked,_that.orderIndex);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TripGearItemRequest implements TripGearItemRequest {
  const _TripGearItemRequest({@JsonKey(name: 'library_item_id') this.libraryItemId, required this.name, required this.weight, required this.category, @JsonKey(defaultValue: 1) required this.quantity, @JsonKey(name: 'is_checked', defaultValue: false) required this.isChecked, @JsonKey(name: 'order_index') this.orderIndex});
  factory _TripGearItemRequest.fromJson(Map<String, dynamic> json) => _$TripGearItemRequestFromJson(json);

@override@JsonKey(name: 'library_item_id') final  String? libraryItemId;
@override final  String name;
@override final  double weight;
@override final  String category;
@override@JsonKey(defaultValue: 1) final  int quantity;
@override@JsonKey(name: 'is_checked', defaultValue: false) final  bool isChecked;
@override@JsonKey(name: 'order_index') final  int? orderIndex;

/// Create a copy of TripGearItemRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripGearItemRequestCopyWith<_TripGearItemRequest> get copyWith => __$TripGearItemRequestCopyWithImpl<_TripGearItemRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripGearItemRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripGearItemRequest&&(identical(other.libraryItemId, libraryItemId) || other.libraryItemId == libraryItemId)&&(identical(other.name, name) || other.name == name)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.category, category) || other.category == category)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.isChecked, isChecked) || other.isChecked == isChecked)&&(identical(other.orderIndex, orderIndex) || other.orderIndex == orderIndex));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,libraryItemId,name,weight,category,quantity,isChecked,orderIndex);

@override
String toString() {
  return 'TripGearItemRequest(libraryItemId: $libraryItemId, name: $name, weight: $weight, category: $category, quantity: $quantity, isChecked: $isChecked, orderIndex: $orderIndex)';
}


}

/// @nodoc
abstract mixin class _$TripGearItemRequestCopyWith<$Res> implements $TripGearItemRequestCopyWith<$Res> {
  factory _$TripGearItemRequestCopyWith(_TripGearItemRequest value, $Res Function(_TripGearItemRequest) _then) = __$TripGearItemRequestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'library_item_id') String? libraryItemId, String name, double weight, String category,@JsonKey(defaultValue: 1) int quantity,@JsonKey(name: 'is_checked', defaultValue: false) bool isChecked,@JsonKey(name: 'order_index') int? orderIndex
});




}
/// @nodoc
class __$TripGearItemRequestCopyWithImpl<$Res>
    implements _$TripGearItemRequestCopyWith<$Res> {
  __$TripGearItemRequestCopyWithImpl(this._self, this._then);

  final _TripGearItemRequest _self;
  final $Res Function(_TripGearItemRequest) _then;

/// Create a copy of TripGearItemRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? libraryItemId = freezed,Object? name = null,Object? weight = null,Object? category = null,Object? quantity = null,Object? isChecked = null,Object? orderIndex = freezed,}) {
  return _then(_TripGearItemRequest(
libraryItemId: freezed == libraryItemId ? _self.libraryItemId : libraryItemId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as double,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,isChecked: null == isChecked ? _self.isChecked : isChecked // ignore: cast_nullable_to_non_nullable
as bool,orderIndex: freezed == orderIndex ? _self.orderIndex : orderIndex // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
