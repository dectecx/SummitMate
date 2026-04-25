// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gear_library_api_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GearLibraryPaginationResponse {

 List<GearLibraryItemResponse> get items; PaginationMetadata get pagination;
/// Create a copy of GearLibraryPaginationResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GearLibraryPaginationResponseCopyWith<GearLibraryPaginationResponse> get copyWith => _$GearLibraryPaginationResponseCopyWithImpl<GearLibraryPaginationResponse>(this as GearLibraryPaginationResponse, _$identity);

  /// Serializes this GearLibraryPaginationResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GearLibraryPaginationResponse&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.pagination, pagination) || other.pagination == pagination));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),pagination);

@override
String toString() {
  return 'GearLibraryPaginationResponse(items: $items, pagination: $pagination)';
}


}

/// @nodoc
abstract mixin class $GearLibraryPaginationResponseCopyWith<$Res>  {
  factory $GearLibraryPaginationResponseCopyWith(GearLibraryPaginationResponse value, $Res Function(GearLibraryPaginationResponse) _then) = _$GearLibraryPaginationResponseCopyWithImpl;
@useResult
$Res call({
 List<GearLibraryItemResponse> items, PaginationMetadata pagination
});


$PaginationMetadataCopyWith<$Res> get pagination;

}
/// @nodoc
class _$GearLibraryPaginationResponseCopyWithImpl<$Res>
    implements $GearLibraryPaginationResponseCopyWith<$Res> {
  _$GearLibraryPaginationResponseCopyWithImpl(this._self, this._then);

  final GearLibraryPaginationResponse _self;
  final $Res Function(GearLibraryPaginationResponse) _then;

/// Create a copy of GearLibraryPaginationResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? pagination = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<GearLibraryItemResponse>,pagination: null == pagination ? _self.pagination : pagination // ignore: cast_nullable_to_non_nullable
as PaginationMetadata,
  ));
}
/// Create a copy of GearLibraryPaginationResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaginationMetadataCopyWith<$Res> get pagination {
  
  return $PaginationMetadataCopyWith<$Res>(_self.pagination, (value) {
    return _then(_self.copyWith(pagination: value));
  });
}
}


/// Adds pattern-matching-related methods to [GearLibraryPaginationResponse].
extension GearLibraryPaginationResponsePatterns on GearLibraryPaginationResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GearLibraryPaginationResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GearLibraryPaginationResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GearLibraryPaginationResponse value)  $default,){
final _that = this;
switch (_that) {
case _GearLibraryPaginationResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GearLibraryPaginationResponse value)?  $default,){
final _that = this;
switch (_that) {
case _GearLibraryPaginationResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<GearLibraryItemResponse> items,  PaginationMetadata pagination)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GearLibraryPaginationResponse() when $default != null:
return $default(_that.items,_that.pagination);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<GearLibraryItemResponse> items,  PaginationMetadata pagination)  $default,) {final _that = this;
switch (_that) {
case _GearLibraryPaginationResponse():
return $default(_that.items,_that.pagination);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<GearLibraryItemResponse> items,  PaginationMetadata pagination)?  $default,) {final _that = this;
switch (_that) {
case _GearLibraryPaginationResponse() when $default != null:
return $default(_that.items,_that.pagination);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GearLibraryPaginationResponse implements GearLibraryPaginationResponse {
  const _GearLibraryPaginationResponse({required final  List<GearLibraryItemResponse> items, required this.pagination}): _items = items;
  factory _GearLibraryPaginationResponse.fromJson(Map<String, dynamic> json) => _$GearLibraryPaginationResponseFromJson(json);

 final  List<GearLibraryItemResponse> _items;
@override List<GearLibraryItemResponse> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  PaginationMetadata pagination;

/// Create a copy of GearLibraryPaginationResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GearLibraryPaginationResponseCopyWith<_GearLibraryPaginationResponse> get copyWith => __$GearLibraryPaginationResponseCopyWithImpl<_GearLibraryPaginationResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GearLibraryPaginationResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GearLibraryPaginationResponse&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.pagination, pagination) || other.pagination == pagination));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),pagination);

@override
String toString() {
  return 'GearLibraryPaginationResponse(items: $items, pagination: $pagination)';
}


}

/// @nodoc
abstract mixin class _$GearLibraryPaginationResponseCopyWith<$Res> implements $GearLibraryPaginationResponseCopyWith<$Res> {
  factory _$GearLibraryPaginationResponseCopyWith(_GearLibraryPaginationResponse value, $Res Function(_GearLibraryPaginationResponse) _then) = __$GearLibraryPaginationResponseCopyWithImpl;
@override @useResult
$Res call({
 List<GearLibraryItemResponse> items, PaginationMetadata pagination
});


@override $PaginationMetadataCopyWith<$Res> get pagination;

}
/// @nodoc
class __$GearLibraryPaginationResponseCopyWithImpl<$Res>
    implements _$GearLibraryPaginationResponseCopyWith<$Res> {
  __$GearLibraryPaginationResponseCopyWithImpl(this._self, this._then);

  final _GearLibraryPaginationResponse _self;
  final $Res Function(_GearLibraryPaginationResponse) _then;

/// Create a copy of GearLibraryPaginationResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? pagination = null,}) {
  return _then(_GearLibraryPaginationResponse(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<GearLibraryItemResponse>,pagination: null == pagination ? _self.pagination : pagination // ignore: cast_nullable_to_non_nullable
as PaginationMetadata,
  ));
}

/// Create a copy of GearLibraryPaginationResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaginationMetadataCopyWith<$Res> get pagination {
  
  return $PaginationMetadataCopyWith<$Res>(_self.pagination, (value) {
    return _then(_self.copyWith(pagination: value));
  });
}
}


/// @nodoc
mixin _$GearLibraryItemResponse {

 String get id;@JsonKey(name: 'user_id') String get userId;@JsonKey(defaultValue: '') String get name;@JsonKey(defaultValue: 0.0) double get weight;@JsonKey(defaultValue: 'Other') String get category; String? get notes;@JsonKey(name: 'is_archived', defaultValue: false) bool get isArchived;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'created_by') String get createdBy;@JsonKey(name: 'updated_at') DateTime get updatedAt;@JsonKey(name: 'updated_by') String get updatedBy;
/// Create a copy of GearLibraryItemResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GearLibraryItemResponseCopyWith<GearLibraryItemResponse> get copyWith => _$GearLibraryItemResponseCopyWithImpl<GearLibraryItemResponse>(this as GearLibraryItemResponse, _$identity);

  /// Serializes this GearLibraryItemResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GearLibraryItemResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.category, category) || other.category == category)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,name,weight,category,notes,isArchived,createdAt,createdBy,updatedAt,updatedBy);

@override
String toString() {
  return 'GearLibraryItemResponse(id: $id, userId: $userId, name: $name, weight: $weight, category: $category, notes: $notes, isArchived: $isArchived, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy)';
}


}

/// @nodoc
abstract mixin class $GearLibraryItemResponseCopyWith<$Res>  {
  factory $GearLibraryItemResponseCopyWith(GearLibraryItemResponse value, $Res Function(GearLibraryItemResponse) _then) = _$GearLibraryItemResponseCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId,@JsonKey(defaultValue: '') String name,@JsonKey(defaultValue: 0.0) double weight,@JsonKey(defaultValue: 'Other') String category, String? notes,@JsonKey(name: 'is_archived', defaultValue: false) bool isArchived,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'created_by') String createdBy,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'updated_by') String updatedBy
});




}
/// @nodoc
class _$GearLibraryItemResponseCopyWithImpl<$Res>
    implements $GearLibraryItemResponseCopyWith<$Res> {
  _$GearLibraryItemResponseCopyWithImpl(this._self, this._then);

  final GearLibraryItemResponse _self;
  final $Res Function(GearLibraryItemResponse) _then;

/// Create a copy of GearLibraryItemResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? name = null,Object? weight = null,Object? category = null,Object? notes = freezed,Object? isArchived = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as double,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [GearLibraryItemResponse].
extension GearLibraryItemResponsePatterns on GearLibraryItemResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GearLibraryItemResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GearLibraryItemResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GearLibraryItemResponse value)  $default,){
final _that = this;
switch (_that) {
case _GearLibraryItemResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GearLibraryItemResponse value)?  $default,){
final _that = this;
switch (_that) {
case _GearLibraryItemResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId, @JsonKey(defaultValue: '')  String name, @JsonKey(defaultValue: 0.0)  double weight, @JsonKey(defaultValue: 'Other')  String category,  String? notes, @JsonKey(name: 'is_archived', defaultValue: false)  bool isArchived, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'created_by')  String createdBy, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'updated_by')  String updatedBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GearLibraryItemResponse() when $default != null:
return $default(_that.id,_that.userId,_that.name,_that.weight,_that.category,_that.notes,_that.isArchived,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId, @JsonKey(defaultValue: '')  String name, @JsonKey(defaultValue: 0.0)  double weight, @JsonKey(defaultValue: 'Other')  String category,  String? notes, @JsonKey(name: 'is_archived', defaultValue: false)  bool isArchived, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'created_by')  String createdBy, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'updated_by')  String updatedBy)  $default,) {final _that = this;
switch (_that) {
case _GearLibraryItemResponse():
return $default(_that.id,_that.userId,_that.name,_that.weight,_that.category,_that.notes,_that.isArchived,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'user_id')  String userId, @JsonKey(defaultValue: '')  String name, @JsonKey(defaultValue: 0.0)  double weight, @JsonKey(defaultValue: 'Other')  String category,  String? notes, @JsonKey(name: 'is_archived', defaultValue: false)  bool isArchived, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'created_by')  String createdBy, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'updated_by')  String updatedBy)?  $default,) {final _that = this;
switch (_that) {
case _GearLibraryItemResponse() when $default != null:
return $default(_that.id,_that.userId,_that.name,_that.weight,_that.category,_that.notes,_that.isArchived,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GearLibraryItemResponse implements GearLibraryItemResponse {
  const _GearLibraryItemResponse({required this.id, @JsonKey(name: 'user_id') required this.userId, @JsonKey(defaultValue: '') required this.name, @JsonKey(defaultValue: 0.0) required this.weight, @JsonKey(defaultValue: 'Other') required this.category, this.notes, @JsonKey(name: 'is_archived', defaultValue: false) required this.isArchived, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'created_by') required this.createdBy, @JsonKey(name: 'updated_at') required this.updatedAt, @JsonKey(name: 'updated_by') required this.updatedBy});
  factory _GearLibraryItemResponse.fromJson(Map<String, dynamic> json) => _$GearLibraryItemResponseFromJson(json);

@override final  String id;
@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey(defaultValue: '') final  String name;
@override@JsonKey(defaultValue: 0.0) final  double weight;
@override@JsonKey(defaultValue: 'Other') final  String category;
@override final  String? notes;
@override@JsonKey(name: 'is_archived', defaultValue: false) final  bool isArchived;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'created_by') final  String createdBy;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;
@override@JsonKey(name: 'updated_by') final  String updatedBy;

/// Create a copy of GearLibraryItemResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GearLibraryItemResponseCopyWith<_GearLibraryItemResponse> get copyWith => __$GearLibraryItemResponseCopyWithImpl<_GearLibraryItemResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GearLibraryItemResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GearLibraryItemResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.category, category) || other.category == category)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,name,weight,category,notes,isArchived,createdAt,createdBy,updatedAt,updatedBy);

@override
String toString() {
  return 'GearLibraryItemResponse(id: $id, userId: $userId, name: $name, weight: $weight, category: $category, notes: $notes, isArchived: $isArchived, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy)';
}


}

/// @nodoc
abstract mixin class _$GearLibraryItemResponseCopyWith<$Res> implements $GearLibraryItemResponseCopyWith<$Res> {
  factory _$GearLibraryItemResponseCopyWith(_GearLibraryItemResponse value, $Res Function(_GearLibraryItemResponse) _then) = __$GearLibraryItemResponseCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId,@JsonKey(defaultValue: '') String name,@JsonKey(defaultValue: 0.0) double weight,@JsonKey(defaultValue: 'Other') String category, String? notes,@JsonKey(name: 'is_archived', defaultValue: false) bool isArchived,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'created_by') String createdBy,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'updated_by') String updatedBy
});




}
/// @nodoc
class __$GearLibraryItemResponseCopyWithImpl<$Res>
    implements _$GearLibraryItemResponseCopyWith<$Res> {
  __$GearLibraryItemResponseCopyWithImpl(this._self, this._then);

  final _GearLibraryItemResponse _self;
  final $Res Function(_GearLibraryItemResponse) _then;

/// Create a copy of GearLibraryItemResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? name = null,Object? weight = null,Object? category = null,Object? notes = freezed,Object? isArchived = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,}) {
  return _then(_GearLibraryItemResponse(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as double,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$GearLibraryItemRequest {

 String get name; double get weight; String get category; String? get notes;@JsonKey(name: 'is_archived', defaultValue: false) bool get isArchived;
/// Create a copy of GearLibraryItemRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GearLibraryItemRequestCopyWith<GearLibraryItemRequest> get copyWith => _$GearLibraryItemRequestCopyWithImpl<GearLibraryItemRequest>(this as GearLibraryItemRequest, _$identity);

  /// Serializes this GearLibraryItemRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GearLibraryItemRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.category, category) || other.category == category)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,weight,category,notes,isArchived);

@override
String toString() {
  return 'GearLibraryItemRequest(name: $name, weight: $weight, category: $category, notes: $notes, isArchived: $isArchived)';
}


}

/// @nodoc
abstract mixin class $GearLibraryItemRequestCopyWith<$Res>  {
  factory $GearLibraryItemRequestCopyWith(GearLibraryItemRequest value, $Res Function(GearLibraryItemRequest) _then) = _$GearLibraryItemRequestCopyWithImpl;
@useResult
$Res call({
 String name, double weight, String category, String? notes,@JsonKey(name: 'is_archived', defaultValue: false) bool isArchived
});




}
/// @nodoc
class _$GearLibraryItemRequestCopyWithImpl<$Res>
    implements $GearLibraryItemRequestCopyWith<$Res> {
  _$GearLibraryItemRequestCopyWithImpl(this._self, this._then);

  final GearLibraryItemRequest _self;
  final $Res Function(GearLibraryItemRequest) _then;

/// Create a copy of GearLibraryItemRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? weight = null,Object? category = null,Object? notes = freezed,Object? isArchived = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as double,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [GearLibraryItemRequest].
extension GearLibraryItemRequestPatterns on GearLibraryItemRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GearLibraryItemRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GearLibraryItemRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GearLibraryItemRequest value)  $default,){
final _that = this;
switch (_that) {
case _GearLibraryItemRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GearLibraryItemRequest value)?  $default,){
final _that = this;
switch (_that) {
case _GearLibraryItemRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  double weight,  String category,  String? notes, @JsonKey(name: 'is_archived', defaultValue: false)  bool isArchived)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GearLibraryItemRequest() when $default != null:
return $default(_that.name,_that.weight,_that.category,_that.notes,_that.isArchived);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  double weight,  String category,  String? notes, @JsonKey(name: 'is_archived', defaultValue: false)  bool isArchived)  $default,) {final _that = this;
switch (_that) {
case _GearLibraryItemRequest():
return $default(_that.name,_that.weight,_that.category,_that.notes,_that.isArchived);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  double weight,  String category,  String? notes, @JsonKey(name: 'is_archived', defaultValue: false)  bool isArchived)?  $default,) {final _that = this;
switch (_that) {
case _GearLibraryItemRequest() when $default != null:
return $default(_that.name,_that.weight,_that.category,_that.notes,_that.isArchived);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GearLibraryItemRequest implements GearLibraryItemRequest {
  const _GearLibraryItemRequest({required this.name, required this.weight, required this.category, this.notes, @JsonKey(name: 'is_archived', defaultValue: false) required this.isArchived});
  factory _GearLibraryItemRequest.fromJson(Map<String, dynamic> json) => _$GearLibraryItemRequestFromJson(json);

@override final  String name;
@override final  double weight;
@override final  String category;
@override final  String? notes;
@override@JsonKey(name: 'is_archived', defaultValue: false) final  bool isArchived;

/// Create a copy of GearLibraryItemRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GearLibraryItemRequestCopyWith<_GearLibraryItemRequest> get copyWith => __$GearLibraryItemRequestCopyWithImpl<_GearLibraryItemRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GearLibraryItemRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GearLibraryItemRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.category, category) || other.category == category)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,weight,category,notes,isArchived);

@override
String toString() {
  return 'GearLibraryItemRequest(name: $name, weight: $weight, category: $category, notes: $notes, isArchived: $isArchived)';
}


}

/// @nodoc
abstract mixin class _$GearLibraryItemRequestCopyWith<$Res> implements $GearLibraryItemRequestCopyWith<$Res> {
  factory _$GearLibraryItemRequestCopyWith(_GearLibraryItemRequest value, $Res Function(_GearLibraryItemRequest) _then) = __$GearLibraryItemRequestCopyWithImpl;
@override @useResult
$Res call({
 String name, double weight, String category, String? notes,@JsonKey(name: 'is_archived', defaultValue: false) bool isArchived
});




}
/// @nodoc
class __$GearLibraryItemRequestCopyWithImpl<$Res>
    implements _$GearLibraryItemRequestCopyWith<$Res> {
  __$GearLibraryItemRequestCopyWithImpl(this._self, this._then);

  final _GearLibraryItemRequest _self;
  final $Res Function(_GearLibraryItemRequest) _then;

/// Create a copy of GearLibraryItemRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? weight = null,Object? category = null,Object? notes = freezed,Object? isArchived = null,}) {
  return _then(_GearLibraryItemRequest(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as double,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
