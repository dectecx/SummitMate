// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gear_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GearItem {

 String get id; String get tripId; String get name; double get weight; String get category; bool get isChecked; int get orderIndex; int get quantity; String? get libraryItemId; DateTime? get createdAt; String? get createdBy; DateTime? get updatedAt; String? get updatedBy;
/// Create a copy of GearItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GearItemCopyWith<GearItem> get copyWith => _$GearItemCopyWithImpl<GearItem>(this as GearItem, _$identity);

  /// Serializes this GearItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GearItem&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.name, name) || other.name == name)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.category, category) || other.category == category)&&(identical(other.isChecked, isChecked) || other.isChecked == isChecked)&&(identical(other.orderIndex, orderIndex) || other.orderIndex == orderIndex)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.libraryItemId, libraryItemId) || other.libraryItemId == libraryItemId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,name,weight,category,isChecked,orderIndex,quantity,libraryItemId,createdAt,createdBy,updatedAt,updatedBy);

@override
String toString() {
  return 'GearItem(id: $id, tripId: $tripId, name: $name, weight: $weight, category: $category, isChecked: $isChecked, orderIndex: $orderIndex, quantity: $quantity, libraryItemId: $libraryItemId, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy)';
}


}

/// @nodoc
abstract mixin class $GearItemCopyWith<$Res>  {
  factory $GearItemCopyWith(GearItem value, $Res Function(GearItem) _then) = _$GearItemCopyWithImpl;
@useResult
$Res call({
 String id, String tripId, String name, double weight, String category, bool isChecked, int orderIndex, int quantity, String? libraryItemId, DateTime? createdAt, String? createdBy, DateTime? updatedAt, String? updatedBy
});




}
/// @nodoc
class _$GearItemCopyWithImpl<$Res>
    implements $GearItemCopyWith<$Res> {
  _$GearItemCopyWithImpl(this._self, this._then);

  final GearItem _self;
  final $Res Function(GearItem) _then;

/// Create a copy of GearItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tripId = null,Object? name = null,Object? weight = null,Object? category = null,Object? isChecked = null,Object? orderIndex = null,Object? quantity = null,Object? libraryItemId = freezed,Object? createdAt = freezed,Object? createdBy = freezed,Object? updatedAt = freezed,Object? updatedBy = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as double,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,isChecked: null == isChecked ? _self.isChecked : isChecked // ignore: cast_nullable_to_non_nullable
as bool,orderIndex: null == orderIndex ? _self.orderIndex : orderIndex // ignore: cast_nullable_to_non_nullable
as int,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,libraryItemId: freezed == libraryItemId ? _self.libraryItemId : libraryItemId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedBy: freezed == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [GearItem].
extension GearItemPatterns on GearItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GearItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GearItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GearItem value)  $default,){
final _that = this;
switch (_that) {
case _GearItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GearItem value)?  $default,){
final _that = this;
switch (_that) {
case _GearItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tripId,  String name,  double weight,  String category,  bool isChecked,  int orderIndex,  int quantity,  String? libraryItemId,  DateTime? createdAt,  String? createdBy,  DateTime? updatedAt,  String? updatedBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GearItem() when $default != null:
return $default(_that.id,_that.tripId,_that.name,_that.weight,_that.category,_that.isChecked,_that.orderIndex,_that.quantity,_that.libraryItemId,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tripId,  String name,  double weight,  String category,  bool isChecked,  int orderIndex,  int quantity,  String? libraryItemId,  DateTime? createdAt,  String? createdBy,  DateTime? updatedAt,  String? updatedBy)  $default,) {final _that = this;
switch (_that) {
case _GearItem():
return $default(_that.id,_that.tripId,_that.name,_that.weight,_that.category,_that.isChecked,_that.orderIndex,_that.quantity,_that.libraryItemId,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tripId,  String name,  double weight,  String category,  bool isChecked,  int orderIndex,  int quantity,  String? libraryItemId,  DateTime? createdAt,  String? createdBy,  DateTime? updatedAt,  String? updatedBy)?  $default,) {final _that = this;
switch (_that) {
case _GearItem() when $default != null:
return $default(_that.id,_that.tripId,_that.name,_that.weight,_that.category,_that.isChecked,_that.orderIndex,_that.quantity,_that.libraryItemId,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GearItem extends GearItem {
  const _GearItem({required this.id, required this.tripId, required this.name, required this.weight, required this.category, this.isChecked = false, this.orderIndex = 0, this.quantity = 1, this.libraryItemId, this.createdAt, this.createdBy, this.updatedAt, this.updatedBy}): super._();
  factory _GearItem.fromJson(Map<String, dynamic> json) => _$GearItemFromJson(json);

@override final  String id;
@override final  String tripId;
@override final  String name;
@override final  double weight;
@override final  String category;
@override@JsonKey() final  bool isChecked;
@override@JsonKey() final  int orderIndex;
@override@JsonKey() final  int quantity;
@override final  String? libraryItemId;
@override final  DateTime? createdAt;
@override final  String? createdBy;
@override final  DateTime? updatedAt;
@override final  String? updatedBy;

/// Create a copy of GearItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GearItemCopyWith<_GearItem> get copyWith => __$GearItemCopyWithImpl<_GearItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GearItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GearItem&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.name, name) || other.name == name)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.category, category) || other.category == category)&&(identical(other.isChecked, isChecked) || other.isChecked == isChecked)&&(identical(other.orderIndex, orderIndex) || other.orderIndex == orderIndex)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.libraryItemId, libraryItemId) || other.libraryItemId == libraryItemId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,name,weight,category,isChecked,orderIndex,quantity,libraryItemId,createdAt,createdBy,updatedAt,updatedBy);

@override
String toString() {
  return 'GearItem(id: $id, tripId: $tripId, name: $name, weight: $weight, category: $category, isChecked: $isChecked, orderIndex: $orderIndex, quantity: $quantity, libraryItemId: $libraryItemId, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy)';
}


}

/// @nodoc
abstract mixin class _$GearItemCopyWith<$Res> implements $GearItemCopyWith<$Res> {
  factory _$GearItemCopyWith(_GearItem value, $Res Function(_GearItem) _then) = __$GearItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String tripId, String name, double weight, String category, bool isChecked, int orderIndex, int quantity, String? libraryItemId, DateTime? createdAt, String? createdBy, DateTime? updatedAt, String? updatedBy
});




}
/// @nodoc
class __$GearItemCopyWithImpl<$Res>
    implements _$GearItemCopyWith<$Res> {
  __$GearItemCopyWithImpl(this._self, this._then);

  final _GearItem _self;
  final $Res Function(_GearItem) _then;

/// Create a copy of GearItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tripId = null,Object? name = null,Object? weight = null,Object? category = null,Object? isChecked = null,Object? orderIndex = null,Object? quantity = null,Object? libraryItemId = freezed,Object? createdAt = freezed,Object? createdBy = freezed,Object? updatedAt = freezed,Object? updatedBy = freezed,}) {
  return _then(_GearItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as double,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,isChecked: null == isChecked ? _self.isChecked : isChecked // ignore: cast_nullable_to_non_nullable
as bool,orderIndex: null == orderIndex ? _self.orderIndex : orderIndex // ignore: cast_nullable_to_non_nullable
as int,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,libraryItemId: freezed == libraryItemId ? _self.libraryItemId : libraryItemId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedBy: freezed == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
