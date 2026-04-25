// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'meal_library_api_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MealLibraryPaginationResponse {

 List<MealLibraryItem> get items; PaginationMetadata get pagination;
/// Create a copy of MealLibraryPaginationResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MealLibraryPaginationResponseCopyWith<MealLibraryPaginationResponse> get copyWith => _$MealLibraryPaginationResponseCopyWithImpl<MealLibraryPaginationResponse>(this as MealLibraryPaginationResponse, _$identity);

  /// Serializes this MealLibraryPaginationResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MealLibraryPaginationResponse&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.pagination, pagination) || other.pagination == pagination));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),pagination);

@override
String toString() {
  return 'MealLibraryPaginationResponse(items: $items, pagination: $pagination)';
}


}

/// @nodoc
abstract mixin class $MealLibraryPaginationResponseCopyWith<$Res>  {
  factory $MealLibraryPaginationResponseCopyWith(MealLibraryPaginationResponse value, $Res Function(MealLibraryPaginationResponse) _then) = _$MealLibraryPaginationResponseCopyWithImpl;
@useResult
$Res call({
 List<MealLibraryItem> items, PaginationMetadata pagination
});


$PaginationMetadataCopyWith<$Res> get pagination;

}
/// @nodoc
class _$MealLibraryPaginationResponseCopyWithImpl<$Res>
    implements $MealLibraryPaginationResponseCopyWith<$Res> {
  _$MealLibraryPaginationResponseCopyWithImpl(this._self, this._then);

  final MealLibraryPaginationResponse _self;
  final $Res Function(MealLibraryPaginationResponse) _then;

/// Create a copy of MealLibraryPaginationResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? pagination = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<MealLibraryItem>,pagination: null == pagination ? _self.pagination : pagination // ignore: cast_nullable_to_non_nullable
as PaginationMetadata,
  ));
}
/// Create a copy of MealLibraryPaginationResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaginationMetadataCopyWith<$Res> get pagination {
  
  return $PaginationMetadataCopyWith<$Res>(_self.pagination, (value) {
    return _then(_self.copyWith(pagination: value));
  });
}
}


/// Adds pattern-matching-related methods to [MealLibraryPaginationResponse].
extension MealLibraryPaginationResponsePatterns on MealLibraryPaginationResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MealLibraryPaginationResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MealLibraryPaginationResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MealLibraryPaginationResponse value)  $default,){
final _that = this;
switch (_that) {
case _MealLibraryPaginationResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MealLibraryPaginationResponse value)?  $default,){
final _that = this;
switch (_that) {
case _MealLibraryPaginationResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<MealLibraryItem> items,  PaginationMetadata pagination)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MealLibraryPaginationResponse() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<MealLibraryItem> items,  PaginationMetadata pagination)  $default,) {final _that = this;
switch (_that) {
case _MealLibraryPaginationResponse():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<MealLibraryItem> items,  PaginationMetadata pagination)?  $default,) {final _that = this;
switch (_that) {
case _MealLibraryPaginationResponse() when $default != null:
return $default(_that.items,_that.pagination);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MealLibraryPaginationResponse implements MealLibraryPaginationResponse {
  const _MealLibraryPaginationResponse({required final  List<MealLibraryItem> items, required this.pagination}): _items = items;
  factory _MealLibraryPaginationResponse.fromJson(Map<String, dynamic> json) => _$MealLibraryPaginationResponseFromJson(json);

 final  List<MealLibraryItem> _items;
@override List<MealLibraryItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  PaginationMetadata pagination;

/// Create a copy of MealLibraryPaginationResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MealLibraryPaginationResponseCopyWith<_MealLibraryPaginationResponse> get copyWith => __$MealLibraryPaginationResponseCopyWithImpl<_MealLibraryPaginationResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MealLibraryPaginationResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MealLibraryPaginationResponse&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.pagination, pagination) || other.pagination == pagination));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),pagination);

@override
String toString() {
  return 'MealLibraryPaginationResponse(items: $items, pagination: $pagination)';
}


}

/// @nodoc
abstract mixin class _$MealLibraryPaginationResponseCopyWith<$Res> implements $MealLibraryPaginationResponseCopyWith<$Res> {
  factory _$MealLibraryPaginationResponseCopyWith(_MealLibraryPaginationResponse value, $Res Function(_MealLibraryPaginationResponse) _then) = __$MealLibraryPaginationResponseCopyWithImpl;
@override @useResult
$Res call({
 List<MealLibraryItem> items, PaginationMetadata pagination
});


@override $PaginationMetadataCopyWith<$Res> get pagination;

}
/// @nodoc
class __$MealLibraryPaginationResponseCopyWithImpl<$Res>
    implements _$MealLibraryPaginationResponseCopyWith<$Res> {
  __$MealLibraryPaginationResponseCopyWithImpl(this._self, this._then);

  final _MealLibraryPaginationResponse _self;
  final $Res Function(_MealLibraryPaginationResponse) _then;

/// Create a copy of MealLibraryPaginationResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? pagination = null,}) {
  return _then(_MealLibraryPaginationResponse(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<MealLibraryItem>,pagination: null == pagination ? _self.pagination : pagination // ignore: cast_nullable_to_non_nullable
as PaginationMetadata,
  ));
}

/// Create a copy of MealLibraryPaginationResponse
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
mixin _$MealLibraryItem {

 String get id;@JsonKey(name: 'user_id') String get userId; String get name; double get weight; double get calories; String? get notes;@JsonKey(name: 'is_archived') bool get isArchived;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime get updatedAt;
/// Create a copy of MealLibraryItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MealLibraryItemCopyWith<MealLibraryItem> get copyWith => _$MealLibraryItemCopyWithImpl<MealLibraryItem>(this as MealLibraryItem, _$identity);

  /// Serializes this MealLibraryItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MealLibraryItem&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.calories, calories) || other.calories == calories)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,name,weight,calories,notes,isArchived,createdAt,updatedAt);

@override
String toString() {
  return 'MealLibraryItem(id: $id, userId: $userId, name: $name, weight: $weight, calories: $calories, notes: $notes, isArchived: $isArchived, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $MealLibraryItemCopyWith<$Res>  {
  factory $MealLibraryItemCopyWith(MealLibraryItem value, $Res Function(MealLibraryItem) _then) = _$MealLibraryItemCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId, String name, double weight, double calories, String? notes,@JsonKey(name: 'is_archived') bool isArchived,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt
});




}
/// @nodoc
class _$MealLibraryItemCopyWithImpl<$Res>
    implements $MealLibraryItemCopyWith<$Res> {
  _$MealLibraryItemCopyWithImpl(this._self, this._then);

  final MealLibraryItem _self;
  final $Res Function(MealLibraryItem) _then;

/// Create a copy of MealLibraryItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? name = null,Object? weight = null,Object? calories = null,Object? notes = freezed,Object? isArchived = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as double,calories: null == calories ? _self.calories : calories // ignore: cast_nullable_to_non_nullable
as double,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [MealLibraryItem].
extension MealLibraryItemPatterns on MealLibraryItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MealLibraryItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MealLibraryItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MealLibraryItem value)  $default,){
final _that = this;
switch (_that) {
case _MealLibraryItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MealLibraryItem value)?  $default,){
final _that = this;
switch (_that) {
case _MealLibraryItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId,  String name,  double weight,  double calories,  String? notes, @JsonKey(name: 'is_archived')  bool isArchived, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MealLibraryItem() when $default != null:
return $default(_that.id,_that.userId,_that.name,_that.weight,_that.calories,_that.notes,_that.isArchived,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId,  String name,  double weight,  double calories,  String? notes, @JsonKey(name: 'is_archived')  bool isArchived, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _MealLibraryItem():
return $default(_that.id,_that.userId,_that.name,_that.weight,_that.calories,_that.notes,_that.isArchived,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'user_id')  String userId,  String name,  double weight,  double calories,  String? notes, @JsonKey(name: 'is_archived')  bool isArchived, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _MealLibraryItem() when $default != null:
return $default(_that.id,_that.userId,_that.name,_that.weight,_that.calories,_that.notes,_that.isArchived,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MealLibraryItem implements MealLibraryItem {
  const _MealLibraryItem({required this.id, @JsonKey(name: 'user_id') required this.userId, required this.name, required this.weight, required this.calories, this.notes, @JsonKey(name: 'is_archived') required this.isArchived, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt});
  factory _MealLibraryItem.fromJson(Map<String, dynamic> json) => _$MealLibraryItemFromJson(json);

@override final  String id;
@override@JsonKey(name: 'user_id') final  String userId;
@override final  String name;
@override final  double weight;
@override final  double calories;
@override final  String? notes;
@override@JsonKey(name: 'is_archived') final  bool isArchived;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;

/// Create a copy of MealLibraryItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MealLibraryItemCopyWith<_MealLibraryItem> get copyWith => __$MealLibraryItemCopyWithImpl<_MealLibraryItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MealLibraryItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MealLibraryItem&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.calories, calories) || other.calories == calories)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,name,weight,calories,notes,isArchived,createdAt,updatedAt);

@override
String toString() {
  return 'MealLibraryItem(id: $id, userId: $userId, name: $name, weight: $weight, calories: $calories, notes: $notes, isArchived: $isArchived, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$MealLibraryItemCopyWith<$Res> implements $MealLibraryItemCopyWith<$Res> {
  factory _$MealLibraryItemCopyWith(_MealLibraryItem value, $Res Function(_MealLibraryItem) _then) = __$MealLibraryItemCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId, String name, double weight, double calories, String? notes,@JsonKey(name: 'is_archived') bool isArchived,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt
});




}
/// @nodoc
class __$MealLibraryItemCopyWithImpl<$Res>
    implements _$MealLibraryItemCopyWith<$Res> {
  __$MealLibraryItemCopyWithImpl(this._self, this._then);

  final _MealLibraryItem _self;
  final $Res Function(_MealLibraryItem) _then;

/// Create a copy of MealLibraryItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? name = null,Object? weight = null,Object? calories = null,Object? notes = freezed,Object? isArchived = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_MealLibraryItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as double,calories: null == calories ? _self.calories : calories // ignore: cast_nullable_to_non_nullable
as double,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$MealLibraryItemRequest {

 String get name; double get weight; double get calories; String? get notes;@JsonKey(name: 'is_archived') bool? get isArchived;
/// Create a copy of MealLibraryItemRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MealLibraryItemRequestCopyWith<MealLibraryItemRequest> get copyWith => _$MealLibraryItemRequestCopyWithImpl<MealLibraryItemRequest>(this as MealLibraryItemRequest, _$identity);

  /// Serializes this MealLibraryItemRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MealLibraryItemRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.calories, calories) || other.calories == calories)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,weight,calories,notes,isArchived);

@override
String toString() {
  return 'MealLibraryItemRequest(name: $name, weight: $weight, calories: $calories, notes: $notes, isArchived: $isArchived)';
}


}

/// @nodoc
abstract mixin class $MealLibraryItemRequestCopyWith<$Res>  {
  factory $MealLibraryItemRequestCopyWith(MealLibraryItemRequest value, $Res Function(MealLibraryItemRequest) _then) = _$MealLibraryItemRequestCopyWithImpl;
@useResult
$Res call({
 String name, double weight, double calories, String? notes,@JsonKey(name: 'is_archived') bool? isArchived
});




}
/// @nodoc
class _$MealLibraryItemRequestCopyWithImpl<$Res>
    implements $MealLibraryItemRequestCopyWith<$Res> {
  _$MealLibraryItemRequestCopyWithImpl(this._self, this._then);

  final MealLibraryItemRequest _self;
  final $Res Function(MealLibraryItemRequest) _then;

/// Create a copy of MealLibraryItemRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? weight = null,Object? calories = null,Object? notes = freezed,Object? isArchived = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as double,calories: null == calories ? _self.calories : calories // ignore: cast_nullable_to_non_nullable
as double,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,isArchived: freezed == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [MealLibraryItemRequest].
extension MealLibraryItemRequestPatterns on MealLibraryItemRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MealLibraryItemRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MealLibraryItemRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MealLibraryItemRequest value)  $default,){
final _that = this;
switch (_that) {
case _MealLibraryItemRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MealLibraryItemRequest value)?  $default,){
final _that = this;
switch (_that) {
case _MealLibraryItemRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  double weight,  double calories,  String? notes, @JsonKey(name: 'is_archived')  bool? isArchived)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MealLibraryItemRequest() when $default != null:
return $default(_that.name,_that.weight,_that.calories,_that.notes,_that.isArchived);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  double weight,  double calories,  String? notes, @JsonKey(name: 'is_archived')  bool? isArchived)  $default,) {final _that = this;
switch (_that) {
case _MealLibraryItemRequest():
return $default(_that.name,_that.weight,_that.calories,_that.notes,_that.isArchived);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  double weight,  double calories,  String? notes, @JsonKey(name: 'is_archived')  bool? isArchived)?  $default,) {final _that = this;
switch (_that) {
case _MealLibraryItemRequest() when $default != null:
return $default(_that.name,_that.weight,_that.calories,_that.notes,_that.isArchived);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MealLibraryItemRequest implements MealLibraryItemRequest {
  const _MealLibraryItemRequest({required this.name, required this.weight, required this.calories, this.notes, @JsonKey(name: 'is_archived') this.isArchived});
  factory _MealLibraryItemRequest.fromJson(Map<String, dynamic> json) => _$MealLibraryItemRequestFromJson(json);

@override final  String name;
@override final  double weight;
@override final  double calories;
@override final  String? notes;
@override@JsonKey(name: 'is_archived') final  bool? isArchived;

/// Create a copy of MealLibraryItemRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MealLibraryItemRequestCopyWith<_MealLibraryItemRequest> get copyWith => __$MealLibraryItemRequestCopyWithImpl<_MealLibraryItemRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MealLibraryItemRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MealLibraryItemRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.calories, calories) || other.calories == calories)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,weight,calories,notes,isArchived);

@override
String toString() {
  return 'MealLibraryItemRequest(name: $name, weight: $weight, calories: $calories, notes: $notes, isArchived: $isArchived)';
}


}

/// @nodoc
abstract mixin class _$MealLibraryItemRequestCopyWith<$Res> implements $MealLibraryItemRequestCopyWith<$Res> {
  factory _$MealLibraryItemRequestCopyWith(_MealLibraryItemRequest value, $Res Function(_MealLibraryItemRequest) _then) = __$MealLibraryItemRequestCopyWithImpl;
@override @useResult
$Res call({
 String name, double weight, double calories, String? notes,@JsonKey(name: 'is_archived') bool? isArchived
});




}
/// @nodoc
class __$MealLibraryItemRequestCopyWithImpl<$Res>
    implements _$MealLibraryItemRequestCopyWith<$Res> {
  __$MealLibraryItemRequestCopyWithImpl(this._self, this._then);

  final _MealLibraryItemRequest _self;
  final $Res Function(_MealLibraryItemRequest) _then;

/// Create a copy of MealLibraryItemRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? weight = null,Object? calories = null,Object? notes = freezed,Object? isArchived = freezed,}) {
  return _then(_MealLibraryItemRequest(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as double,calories: null == calories ? _self.calories : calories // ignore: cast_nullable_to_non_nullable
as double,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,isArchived: freezed == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

// dart format on
