// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gear_library_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GearLibraryItem {

 String get id; String get userId; String get name; double get weight; String get category; String? get notes; bool get isArchived; SyncStatus get syncStatus; DateTime get createdAt; String get createdBy; DateTime get updatedAt; String get updatedBy;
/// Create a copy of GearLibraryItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GearLibraryItemCopyWith<GearLibraryItem> get copyWith => _$GearLibraryItemCopyWithImpl<GearLibraryItem>(this as GearLibraryItem, _$identity);

  /// Serializes this GearLibraryItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GearLibraryItem&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.category, category) || other.category == category)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,name,weight,category,notes,isArchived,syncStatus,createdAt,createdBy,updatedAt,updatedBy);

@override
String toString() {
  return 'GearLibraryItem(id: $id, userId: $userId, name: $name, weight: $weight, category: $category, notes: $notes, isArchived: $isArchived, syncStatus: $syncStatus, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy)';
}


}

/// @nodoc
abstract mixin class $GearLibraryItemCopyWith<$Res>  {
  factory $GearLibraryItemCopyWith(GearLibraryItem value, $Res Function(GearLibraryItem) _then) = _$GearLibraryItemCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String name, double weight, String category, String? notes, bool isArchived, SyncStatus syncStatus, DateTime createdAt, String createdBy, DateTime updatedAt, String updatedBy
});




}
/// @nodoc
class _$GearLibraryItemCopyWithImpl<$Res>
    implements $GearLibraryItemCopyWith<$Res> {
  _$GearLibraryItemCopyWithImpl(this._self, this._then);

  final GearLibraryItem _self;
  final $Res Function(GearLibraryItem) _then;

/// Create a copy of GearLibraryItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? name = null,Object? weight = null,Object? category = null,Object? notes = freezed,Object? isArchived = null,Object? syncStatus = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as double,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as SyncStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [GearLibraryItem].
extension GearLibraryItemPatterns on GearLibraryItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GearLibraryItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GearLibraryItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GearLibraryItem value)  $default,){
final _that = this;
switch (_that) {
case _GearLibraryItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GearLibraryItem value)?  $default,){
final _that = this;
switch (_that) {
case _GearLibraryItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String name,  double weight,  String category,  String? notes,  bool isArchived,  SyncStatus syncStatus,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GearLibraryItem() when $default != null:
return $default(_that.id,_that.userId,_that.name,_that.weight,_that.category,_that.notes,_that.isArchived,_that.syncStatus,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String name,  double weight,  String category,  String? notes,  bool isArchived,  SyncStatus syncStatus,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy)  $default,) {final _that = this;
switch (_that) {
case _GearLibraryItem():
return $default(_that.id,_that.userId,_that.name,_that.weight,_that.category,_that.notes,_that.isArchived,_that.syncStatus,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String name,  double weight,  String category,  String? notes,  bool isArchived,  SyncStatus syncStatus,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy)?  $default,) {final _that = this;
switch (_that) {
case _GearLibraryItem() when $default != null:
return $default(_that.id,_that.userId,_that.name,_that.weight,_that.category,_that.notes,_that.isArchived,_that.syncStatus,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GearLibraryItem extends GearLibraryItem {
  const _GearLibraryItem({required this.id, required this.userId, required this.name, required this.weight, required this.category, this.notes, this.isArchived = false, this.syncStatus = SyncStatus.pendingCreate, required this.createdAt, required this.createdBy, required this.updatedAt, required this.updatedBy}): super._();
  factory _GearLibraryItem.fromJson(Map<String, dynamic> json) => _$GearLibraryItemFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String name;
@override final  double weight;
@override final  String category;
@override final  String? notes;
@override@JsonKey() final  bool isArchived;
@override@JsonKey() final  SyncStatus syncStatus;
@override final  DateTime createdAt;
@override final  String createdBy;
@override final  DateTime updatedAt;
@override final  String updatedBy;

/// Create a copy of GearLibraryItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GearLibraryItemCopyWith<_GearLibraryItem> get copyWith => __$GearLibraryItemCopyWithImpl<_GearLibraryItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GearLibraryItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GearLibraryItem&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.category, category) || other.category == category)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,name,weight,category,notes,isArchived,syncStatus,createdAt,createdBy,updatedAt,updatedBy);

@override
String toString() {
  return 'GearLibraryItem(id: $id, userId: $userId, name: $name, weight: $weight, category: $category, notes: $notes, isArchived: $isArchived, syncStatus: $syncStatus, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy)';
}


}

/// @nodoc
abstract mixin class _$GearLibraryItemCopyWith<$Res> implements $GearLibraryItemCopyWith<$Res> {
  factory _$GearLibraryItemCopyWith(_GearLibraryItem value, $Res Function(_GearLibraryItem) _then) = __$GearLibraryItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String name, double weight, String category, String? notes, bool isArchived, SyncStatus syncStatus, DateTime createdAt, String createdBy, DateTime updatedAt, String updatedBy
});




}
/// @nodoc
class __$GearLibraryItemCopyWithImpl<$Res>
    implements _$GearLibraryItemCopyWith<$Res> {
  __$GearLibraryItemCopyWithImpl(this._self, this._then);

  final _GearLibraryItem _self;
  final $Res Function(_GearLibraryItem) _then;

/// Create a copy of GearLibraryItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? name = null,Object? weight = null,Object? category = null,Object? notes = freezed,Object? isArchived = null,Object? syncStatus = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,}) {
  return _then(_GearLibraryItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as double,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as SyncStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
