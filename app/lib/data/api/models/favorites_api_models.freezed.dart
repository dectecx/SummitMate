// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'favorites_api_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FavoritePaginationResponse {

 List<FavoriteResponse> get items; PaginationMetadata get pagination;
/// Create a copy of FavoritePaginationResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FavoritePaginationResponseCopyWith<FavoritePaginationResponse> get copyWith => _$FavoritePaginationResponseCopyWithImpl<FavoritePaginationResponse>(this as FavoritePaginationResponse, _$identity);

  /// Serializes this FavoritePaginationResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FavoritePaginationResponse&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.pagination, pagination) || other.pagination == pagination));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),pagination);

@override
String toString() {
  return 'FavoritePaginationResponse(items: $items, pagination: $pagination)';
}


}

/// @nodoc
abstract mixin class $FavoritePaginationResponseCopyWith<$Res>  {
  factory $FavoritePaginationResponseCopyWith(FavoritePaginationResponse value, $Res Function(FavoritePaginationResponse) _then) = _$FavoritePaginationResponseCopyWithImpl;
@useResult
$Res call({
 List<FavoriteResponse> items, PaginationMetadata pagination
});


$PaginationMetadataCopyWith<$Res> get pagination;

}
/// @nodoc
class _$FavoritePaginationResponseCopyWithImpl<$Res>
    implements $FavoritePaginationResponseCopyWith<$Res> {
  _$FavoritePaginationResponseCopyWithImpl(this._self, this._then);

  final FavoritePaginationResponse _self;
  final $Res Function(FavoritePaginationResponse) _then;

/// Create a copy of FavoritePaginationResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? pagination = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<FavoriteResponse>,pagination: null == pagination ? _self.pagination : pagination // ignore: cast_nullable_to_non_nullable
as PaginationMetadata,
  ));
}
/// Create a copy of FavoritePaginationResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaginationMetadataCopyWith<$Res> get pagination {
  
  return $PaginationMetadataCopyWith<$Res>(_self.pagination, (value) {
    return _then(_self.copyWith(pagination: value));
  });
}
}


/// Adds pattern-matching-related methods to [FavoritePaginationResponse].
extension FavoritePaginationResponsePatterns on FavoritePaginationResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FavoritePaginationResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FavoritePaginationResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FavoritePaginationResponse value)  $default,){
final _that = this;
switch (_that) {
case _FavoritePaginationResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FavoritePaginationResponse value)?  $default,){
final _that = this;
switch (_that) {
case _FavoritePaginationResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<FavoriteResponse> items,  PaginationMetadata pagination)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FavoritePaginationResponse() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<FavoriteResponse> items,  PaginationMetadata pagination)  $default,) {final _that = this;
switch (_that) {
case _FavoritePaginationResponse():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<FavoriteResponse> items,  PaginationMetadata pagination)?  $default,) {final _that = this;
switch (_that) {
case _FavoritePaginationResponse() when $default != null:
return $default(_that.items,_that.pagination);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FavoritePaginationResponse implements FavoritePaginationResponse {
  const _FavoritePaginationResponse({required final  List<FavoriteResponse> items, required this.pagination}): _items = items;
  factory _FavoritePaginationResponse.fromJson(Map<String, dynamic> json) => _$FavoritePaginationResponseFromJson(json);

 final  List<FavoriteResponse> _items;
@override List<FavoriteResponse> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  PaginationMetadata pagination;

/// Create a copy of FavoritePaginationResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FavoritePaginationResponseCopyWith<_FavoritePaginationResponse> get copyWith => __$FavoritePaginationResponseCopyWithImpl<_FavoritePaginationResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FavoritePaginationResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FavoritePaginationResponse&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.pagination, pagination) || other.pagination == pagination));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),pagination);

@override
String toString() {
  return 'FavoritePaginationResponse(items: $items, pagination: $pagination)';
}


}

/// @nodoc
abstract mixin class _$FavoritePaginationResponseCopyWith<$Res> implements $FavoritePaginationResponseCopyWith<$Res> {
  factory _$FavoritePaginationResponseCopyWith(_FavoritePaginationResponse value, $Res Function(_FavoritePaginationResponse) _then) = __$FavoritePaginationResponseCopyWithImpl;
@override @useResult
$Res call({
 List<FavoriteResponse> items, PaginationMetadata pagination
});


@override $PaginationMetadataCopyWith<$Res> get pagination;

}
/// @nodoc
class __$FavoritePaginationResponseCopyWithImpl<$Res>
    implements _$FavoritePaginationResponseCopyWith<$Res> {
  __$FavoritePaginationResponseCopyWithImpl(this._self, this._then);

  final _FavoritePaginationResponse _self;
  final $Res Function(_FavoritePaginationResponse) _then;

/// Create a copy of FavoritePaginationResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? pagination = null,}) {
  return _then(_FavoritePaginationResponse(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<FavoriteResponse>,pagination: null == pagination ? _self.pagination : pagination // ignore: cast_nullable_to_non_nullable
as PaginationMetadata,
  ));
}

/// Create a copy of FavoritePaginationResponse
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
mixin _$FavoriteResponse {

 String get id;@JsonKey(name: 'target_id') String get targetId; String get type;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'created_by') String get createdBy;@JsonKey(name: 'updated_at') DateTime get updatedAt;@JsonKey(name: 'updated_by') String get updatedBy;
/// Create a copy of FavoriteResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FavoriteResponseCopyWith<FavoriteResponse> get copyWith => _$FavoriteResponseCopyWithImpl<FavoriteResponse>(this as FavoriteResponse, _$identity);

  /// Serializes this FavoriteResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FavoriteResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.targetId, targetId) || other.targetId == targetId)&&(identical(other.type, type) || other.type == type)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,targetId,type,createdAt,createdBy,updatedAt,updatedBy);

@override
String toString() {
  return 'FavoriteResponse(id: $id, targetId: $targetId, type: $type, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy)';
}


}

/// @nodoc
abstract mixin class $FavoriteResponseCopyWith<$Res>  {
  factory $FavoriteResponseCopyWith(FavoriteResponse value, $Res Function(FavoriteResponse) _then) = _$FavoriteResponseCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'target_id') String targetId, String type,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'created_by') String createdBy,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'updated_by') String updatedBy
});




}
/// @nodoc
class _$FavoriteResponseCopyWithImpl<$Res>
    implements $FavoriteResponseCopyWith<$Res> {
  _$FavoriteResponseCopyWithImpl(this._self, this._then);

  final FavoriteResponse _self;
  final $Res Function(FavoriteResponse) _then;

/// Create a copy of FavoriteResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? targetId = null,Object? type = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [FavoriteResponse].
extension FavoriteResponsePatterns on FavoriteResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FavoriteResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FavoriteResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FavoriteResponse value)  $default,){
final _that = this;
switch (_that) {
case _FavoriteResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FavoriteResponse value)?  $default,){
final _that = this;
switch (_that) {
case _FavoriteResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'target_id')  String targetId,  String type, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'created_by')  String createdBy, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'updated_by')  String updatedBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FavoriteResponse() when $default != null:
return $default(_that.id,_that.targetId,_that.type,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'target_id')  String targetId,  String type, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'created_by')  String createdBy, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'updated_by')  String updatedBy)  $default,) {final _that = this;
switch (_that) {
case _FavoriteResponse():
return $default(_that.id,_that.targetId,_that.type,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'target_id')  String targetId,  String type, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'created_by')  String createdBy, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'updated_by')  String updatedBy)?  $default,) {final _that = this;
switch (_that) {
case _FavoriteResponse() when $default != null:
return $default(_that.id,_that.targetId,_that.type,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FavoriteResponse implements FavoriteResponse {
  const _FavoriteResponse({required this.id, @JsonKey(name: 'target_id') required this.targetId, required this.type, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'created_by') required this.createdBy, @JsonKey(name: 'updated_at') required this.updatedAt, @JsonKey(name: 'updated_by') required this.updatedBy});
  factory _FavoriteResponse.fromJson(Map<String, dynamic> json) => _$FavoriteResponseFromJson(json);

@override final  String id;
@override@JsonKey(name: 'target_id') final  String targetId;
@override final  String type;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'created_by') final  String createdBy;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;
@override@JsonKey(name: 'updated_by') final  String updatedBy;

/// Create a copy of FavoriteResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FavoriteResponseCopyWith<_FavoriteResponse> get copyWith => __$FavoriteResponseCopyWithImpl<_FavoriteResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FavoriteResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FavoriteResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.targetId, targetId) || other.targetId == targetId)&&(identical(other.type, type) || other.type == type)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,targetId,type,createdAt,createdBy,updatedAt,updatedBy);

@override
String toString() {
  return 'FavoriteResponse(id: $id, targetId: $targetId, type: $type, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy)';
}


}

/// @nodoc
abstract mixin class _$FavoriteResponseCopyWith<$Res> implements $FavoriteResponseCopyWith<$Res> {
  factory _$FavoriteResponseCopyWith(_FavoriteResponse value, $Res Function(_FavoriteResponse) _then) = __$FavoriteResponseCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'target_id') String targetId, String type,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'created_by') String createdBy,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'updated_by') String updatedBy
});




}
/// @nodoc
class __$FavoriteResponseCopyWithImpl<$Res>
    implements _$FavoriteResponseCopyWith<$Res> {
  __$FavoriteResponseCopyWithImpl(this._self, this._then);

  final _FavoriteResponse _self;
  final $Res Function(_FavoriteResponse) _then;

/// Create a copy of FavoriteResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? targetId = null,Object? type = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,}) {
  return _then(_FavoriteResponse(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$FavoriteAddRequest {

@JsonKey(name: 'target_id') String get targetId; String get type;
/// Create a copy of FavoriteAddRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FavoriteAddRequestCopyWith<FavoriteAddRequest> get copyWith => _$FavoriteAddRequestCopyWithImpl<FavoriteAddRequest>(this as FavoriteAddRequest, _$identity);

  /// Serializes this FavoriteAddRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FavoriteAddRequest&&(identical(other.targetId, targetId) || other.targetId == targetId)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,targetId,type);

@override
String toString() {
  return 'FavoriteAddRequest(targetId: $targetId, type: $type)';
}


}

/// @nodoc
abstract mixin class $FavoriteAddRequestCopyWith<$Res>  {
  factory $FavoriteAddRequestCopyWith(FavoriteAddRequest value, $Res Function(FavoriteAddRequest) _then) = _$FavoriteAddRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'target_id') String targetId, String type
});




}
/// @nodoc
class _$FavoriteAddRequestCopyWithImpl<$Res>
    implements $FavoriteAddRequestCopyWith<$Res> {
  _$FavoriteAddRequestCopyWithImpl(this._self, this._then);

  final FavoriteAddRequest _self;
  final $Res Function(FavoriteAddRequest) _then;

/// Create a copy of FavoriteAddRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? targetId = null,Object? type = null,}) {
  return _then(_self.copyWith(
targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [FavoriteAddRequest].
extension FavoriteAddRequestPatterns on FavoriteAddRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FavoriteAddRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FavoriteAddRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FavoriteAddRequest value)  $default,){
final _that = this;
switch (_that) {
case _FavoriteAddRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FavoriteAddRequest value)?  $default,){
final _that = this;
switch (_that) {
case _FavoriteAddRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'target_id')  String targetId,  String type)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FavoriteAddRequest() when $default != null:
return $default(_that.targetId,_that.type);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'target_id')  String targetId,  String type)  $default,) {final _that = this;
switch (_that) {
case _FavoriteAddRequest():
return $default(_that.targetId,_that.type);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'target_id')  String targetId,  String type)?  $default,) {final _that = this;
switch (_that) {
case _FavoriteAddRequest() when $default != null:
return $default(_that.targetId,_that.type);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FavoriteAddRequest implements FavoriteAddRequest {
  const _FavoriteAddRequest({@JsonKey(name: 'target_id') required this.targetId, required this.type});
  factory _FavoriteAddRequest.fromJson(Map<String, dynamic> json) => _$FavoriteAddRequestFromJson(json);

@override@JsonKey(name: 'target_id') final  String targetId;
@override final  String type;

/// Create a copy of FavoriteAddRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FavoriteAddRequestCopyWith<_FavoriteAddRequest> get copyWith => __$FavoriteAddRequestCopyWithImpl<_FavoriteAddRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FavoriteAddRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FavoriteAddRequest&&(identical(other.targetId, targetId) || other.targetId == targetId)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,targetId,type);

@override
String toString() {
  return 'FavoriteAddRequest(targetId: $targetId, type: $type)';
}


}

/// @nodoc
abstract mixin class _$FavoriteAddRequestCopyWith<$Res> implements $FavoriteAddRequestCopyWith<$Res> {
  factory _$FavoriteAddRequestCopyWith(_FavoriteAddRequest value, $Res Function(_FavoriteAddRequest) _then) = __$FavoriteAddRequestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'target_id') String targetId, String type
});




}
/// @nodoc
class __$FavoriteAddRequestCopyWithImpl<$Res>
    implements _$FavoriteAddRequestCopyWith<$Res> {
  __$FavoriteAddRequestCopyWithImpl(this._self, this._then);

  final _FavoriteAddRequest _self;
  final $Res Function(_FavoriteAddRequest) _then;

/// Create a copy of FavoriteAddRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? targetId = null,Object? type = null,}) {
  return _then(_FavoriteAddRequest(
targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$BatchFavoriteItem {

@JsonKey(name: 'target_id') String get targetId; String get type;@JsonKey(name: 'is_favorite') bool get isFavorite;
/// Create a copy of BatchFavoriteItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BatchFavoriteItemCopyWith<BatchFavoriteItem> get copyWith => _$BatchFavoriteItemCopyWithImpl<BatchFavoriteItem>(this as BatchFavoriteItem, _$identity);

  /// Serializes this BatchFavoriteItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BatchFavoriteItem&&(identical(other.targetId, targetId) || other.targetId == targetId)&&(identical(other.type, type) || other.type == type)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,targetId,type,isFavorite);

@override
String toString() {
  return 'BatchFavoriteItem(targetId: $targetId, type: $type, isFavorite: $isFavorite)';
}


}

/// @nodoc
abstract mixin class $BatchFavoriteItemCopyWith<$Res>  {
  factory $BatchFavoriteItemCopyWith(BatchFavoriteItem value, $Res Function(BatchFavoriteItem) _then) = _$BatchFavoriteItemCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'target_id') String targetId, String type,@JsonKey(name: 'is_favorite') bool isFavorite
});




}
/// @nodoc
class _$BatchFavoriteItemCopyWithImpl<$Res>
    implements $BatchFavoriteItemCopyWith<$Res> {
  _$BatchFavoriteItemCopyWithImpl(this._self, this._then);

  final BatchFavoriteItem _self;
  final $Res Function(BatchFavoriteItem) _then;

/// Create a copy of BatchFavoriteItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? targetId = null,Object? type = null,Object? isFavorite = null,}) {
  return _then(_self.copyWith(
targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [BatchFavoriteItem].
extension BatchFavoriteItemPatterns on BatchFavoriteItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BatchFavoriteItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BatchFavoriteItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BatchFavoriteItem value)  $default,){
final _that = this;
switch (_that) {
case _BatchFavoriteItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BatchFavoriteItem value)?  $default,){
final _that = this;
switch (_that) {
case _BatchFavoriteItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'target_id')  String targetId,  String type, @JsonKey(name: 'is_favorite')  bool isFavorite)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BatchFavoriteItem() when $default != null:
return $default(_that.targetId,_that.type,_that.isFavorite);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'target_id')  String targetId,  String type, @JsonKey(name: 'is_favorite')  bool isFavorite)  $default,) {final _that = this;
switch (_that) {
case _BatchFavoriteItem():
return $default(_that.targetId,_that.type,_that.isFavorite);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'target_id')  String targetId,  String type, @JsonKey(name: 'is_favorite')  bool isFavorite)?  $default,) {final _that = this;
switch (_that) {
case _BatchFavoriteItem() when $default != null:
return $default(_that.targetId,_that.type,_that.isFavorite);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BatchFavoriteItem implements BatchFavoriteItem {
  const _BatchFavoriteItem({@JsonKey(name: 'target_id') required this.targetId, required this.type, @JsonKey(name: 'is_favorite') required this.isFavorite});
  factory _BatchFavoriteItem.fromJson(Map<String, dynamic> json) => _$BatchFavoriteItemFromJson(json);

@override@JsonKey(name: 'target_id') final  String targetId;
@override final  String type;
@override@JsonKey(name: 'is_favorite') final  bool isFavorite;

/// Create a copy of BatchFavoriteItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BatchFavoriteItemCopyWith<_BatchFavoriteItem> get copyWith => __$BatchFavoriteItemCopyWithImpl<_BatchFavoriteItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BatchFavoriteItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BatchFavoriteItem&&(identical(other.targetId, targetId) || other.targetId == targetId)&&(identical(other.type, type) || other.type == type)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,targetId,type,isFavorite);

@override
String toString() {
  return 'BatchFavoriteItem(targetId: $targetId, type: $type, isFavorite: $isFavorite)';
}


}

/// @nodoc
abstract mixin class _$BatchFavoriteItemCopyWith<$Res> implements $BatchFavoriteItemCopyWith<$Res> {
  factory _$BatchFavoriteItemCopyWith(_BatchFavoriteItem value, $Res Function(_BatchFavoriteItem) _then) = __$BatchFavoriteItemCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'target_id') String targetId, String type,@JsonKey(name: 'is_favorite') bool isFavorite
});




}
/// @nodoc
class __$BatchFavoriteItemCopyWithImpl<$Res>
    implements _$BatchFavoriteItemCopyWith<$Res> {
  __$BatchFavoriteItemCopyWithImpl(this._self, this._then);

  final _BatchFavoriteItem _self;
  final $Res Function(_BatchFavoriteItem) _then;

/// Create a copy of BatchFavoriteItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? targetId = null,Object? type = null,Object? isFavorite = null,}) {
  return _then(_BatchFavoriteItem(
targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
