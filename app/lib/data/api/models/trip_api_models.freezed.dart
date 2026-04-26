// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trip_api_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TripListPaginationResponse {

 List<TripListItemResponse> get items; PaginationMetadata get pagination;
/// Create a copy of TripListPaginationResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripListPaginationResponseCopyWith<TripListPaginationResponse> get copyWith => _$TripListPaginationResponseCopyWithImpl<TripListPaginationResponse>(this as TripListPaginationResponse, _$identity);

  /// Serializes this TripListPaginationResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripListPaginationResponse&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.pagination, pagination) || other.pagination == pagination));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),pagination);

@override
String toString() {
  return 'TripListPaginationResponse(items: $items, pagination: $pagination)';
}


}

/// @nodoc
abstract mixin class $TripListPaginationResponseCopyWith<$Res>  {
  factory $TripListPaginationResponseCopyWith(TripListPaginationResponse value, $Res Function(TripListPaginationResponse) _then) = _$TripListPaginationResponseCopyWithImpl;
@useResult
$Res call({
 List<TripListItemResponse> items, PaginationMetadata pagination
});


$PaginationMetadataCopyWith<$Res> get pagination;

}
/// @nodoc
class _$TripListPaginationResponseCopyWithImpl<$Res>
    implements $TripListPaginationResponseCopyWith<$Res> {
  _$TripListPaginationResponseCopyWithImpl(this._self, this._then);

  final TripListPaginationResponse _self;
  final $Res Function(TripListPaginationResponse) _then;

/// Create a copy of TripListPaginationResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? pagination = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<TripListItemResponse>,pagination: null == pagination ? _self.pagination : pagination // ignore: cast_nullable_to_non_nullable
as PaginationMetadata,
  ));
}
/// Create a copy of TripListPaginationResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaginationMetadataCopyWith<$Res> get pagination {
  
  return $PaginationMetadataCopyWith<$Res>(_self.pagination, (value) {
    return _then(_self.copyWith(pagination: value));
  });
}
}


/// Adds pattern-matching-related methods to [TripListPaginationResponse].
extension TripListPaginationResponsePatterns on TripListPaginationResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripListPaginationResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripListPaginationResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripListPaginationResponse value)  $default,){
final _that = this;
switch (_that) {
case _TripListPaginationResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripListPaginationResponse value)?  $default,){
final _that = this;
switch (_that) {
case _TripListPaginationResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<TripListItemResponse> items,  PaginationMetadata pagination)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripListPaginationResponse() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<TripListItemResponse> items,  PaginationMetadata pagination)  $default,) {final _that = this;
switch (_that) {
case _TripListPaginationResponse():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<TripListItemResponse> items,  PaginationMetadata pagination)?  $default,) {final _that = this;
switch (_that) {
case _TripListPaginationResponse() when $default != null:
return $default(_that.items,_that.pagination);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TripListPaginationResponse implements TripListPaginationResponse {
  const _TripListPaginationResponse({required final  List<TripListItemResponse> items, required this.pagination}): _items = items;
  factory _TripListPaginationResponse.fromJson(Map<String, dynamic> json) => _$TripListPaginationResponseFromJson(json);

 final  List<TripListItemResponse> _items;
@override List<TripListItemResponse> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  PaginationMetadata pagination;

/// Create a copy of TripListPaginationResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripListPaginationResponseCopyWith<_TripListPaginationResponse> get copyWith => __$TripListPaginationResponseCopyWithImpl<_TripListPaginationResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripListPaginationResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripListPaginationResponse&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.pagination, pagination) || other.pagination == pagination));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),pagination);

@override
String toString() {
  return 'TripListPaginationResponse(items: $items, pagination: $pagination)';
}


}

/// @nodoc
abstract mixin class _$TripListPaginationResponseCopyWith<$Res> implements $TripListPaginationResponseCopyWith<$Res> {
  factory _$TripListPaginationResponseCopyWith(_TripListPaginationResponse value, $Res Function(_TripListPaginationResponse) _then) = __$TripListPaginationResponseCopyWithImpl;
@override @useResult
$Res call({
 List<TripListItemResponse> items, PaginationMetadata pagination
});


@override $PaginationMetadataCopyWith<$Res> get pagination;

}
/// @nodoc
class __$TripListPaginationResponseCopyWithImpl<$Res>
    implements _$TripListPaginationResponseCopyWith<$Res> {
  __$TripListPaginationResponseCopyWithImpl(this._self, this._then);

  final _TripListPaginationResponse _self;
  final $Res Function(_TripListPaginationResponse) _then;

/// Create a copy of TripListPaginationResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? pagination = null,}) {
  return _then(_TripListPaginationResponse(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<TripListItemResponse>,pagination: null == pagination ? _self.pagination : pagination // ignore: cast_nullable_to_non_nullable
as PaginationMetadata,
  ));
}

/// Create a copy of TripListPaginationResponse
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
mixin _$TripResponse {

 String get id;@JsonKey(name: 'user_id') String get userId; String get name; String? get description;@JsonKey(name: 'start_date') DateTime get startDate;@JsonKey(name: 'end_date') DateTime? get endDate;@JsonKey(name: 'cover_image') String? get coverImage;@JsonKey(name: 'is_active') bool get isActive;@JsonKey(name: 'linked_event_id') String? get linkedEventId;@JsonKey(name: 'day_names', defaultValue: <String>[]) List<String> get dayNames;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'created_by') String get createdBy;@JsonKey(name: 'updated_at') DateTime get updatedAt;@JsonKey(name: 'updated_by') String get updatedBy;
/// Create a copy of TripResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripResponseCopyWith<TripResponse> get copyWith => _$TripResponseCopyWithImpl<TripResponse>(this as TripResponse, _$identity);

  /// Serializes this TripResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.coverImage, coverImage) || other.coverImage == coverImage)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.linkedEventId, linkedEventId) || other.linkedEventId == linkedEventId)&&const DeepCollectionEquality().equals(other.dayNames, dayNames)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,name,description,startDate,endDate,coverImage,isActive,linkedEventId,const DeepCollectionEquality().hash(dayNames),createdAt,createdBy,updatedAt,updatedBy);

@override
String toString() {
  return 'TripResponse(id: $id, userId: $userId, name: $name, description: $description, startDate: $startDate, endDate: $endDate, coverImage: $coverImage, isActive: $isActive, linkedEventId: $linkedEventId, dayNames: $dayNames, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy)';
}


}

/// @nodoc
abstract mixin class $TripResponseCopyWith<$Res>  {
  factory $TripResponseCopyWith(TripResponse value, $Res Function(TripResponse) _then) = _$TripResponseCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId, String name, String? description,@JsonKey(name: 'start_date') DateTime startDate,@JsonKey(name: 'end_date') DateTime? endDate,@JsonKey(name: 'cover_image') String? coverImage,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'linked_event_id') String? linkedEventId,@JsonKey(name: 'day_names', defaultValue: <String>[]) List<String> dayNames,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'created_by') String createdBy,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'updated_by') String updatedBy
});




}
/// @nodoc
class _$TripResponseCopyWithImpl<$Res>
    implements $TripResponseCopyWith<$Res> {
  _$TripResponseCopyWithImpl(this._self, this._then);

  final TripResponse _self;
  final $Res Function(TripResponse) _then;

/// Create a copy of TripResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? name = null,Object? description = freezed,Object? startDate = null,Object? endDate = freezed,Object? coverImage = freezed,Object? isActive = null,Object? linkedEventId = freezed,Object? dayNames = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,coverImage: freezed == coverImage ? _self.coverImage : coverImage // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,linkedEventId: freezed == linkedEventId ? _self.linkedEventId : linkedEventId // ignore: cast_nullable_to_non_nullable
as String?,dayNames: null == dayNames ? _self.dayNames : dayNames // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TripResponse].
extension TripResponsePatterns on TripResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripResponse value)  $default,){
final _that = this;
switch (_that) {
case _TripResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripResponse value)?  $default,){
final _that = this;
switch (_that) {
case _TripResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId,  String name,  String? description, @JsonKey(name: 'start_date')  DateTime startDate, @JsonKey(name: 'end_date')  DateTime? endDate, @JsonKey(name: 'cover_image')  String? coverImage, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'linked_event_id')  String? linkedEventId, @JsonKey(name: 'day_names', defaultValue: <String>[])  List<String> dayNames, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'created_by')  String createdBy, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'updated_by')  String updatedBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripResponse() when $default != null:
return $default(_that.id,_that.userId,_that.name,_that.description,_that.startDate,_that.endDate,_that.coverImage,_that.isActive,_that.linkedEventId,_that.dayNames,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId,  String name,  String? description, @JsonKey(name: 'start_date')  DateTime startDate, @JsonKey(name: 'end_date')  DateTime? endDate, @JsonKey(name: 'cover_image')  String? coverImage, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'linked_event_id')  String? linkedEventId, @JsonKey(name: 'day_names', defaultValue: <String>[])  List<String> dayNames, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'created_by')  String createdBy, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'updated_by')  String updatedBy)  $default,) {final _that = this;
switch (_that) {
case _TripResponse():
return $default(_that.id,_that.userId,_that.name,_that.description,_that.startDate,_that.endDate,_that.coverImage,_that.isActive,_that.linkedEventId,_that.dayNames,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'user_id')  String userId,  String name,  String? description, @JsonKey(name: 'start_date')  DateTime startDate, @JsonKey(name: 'end_date')  DateTime? endDate, @JsonKey(name: 'cover_image')  String? coverImage, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'linked_event_id')  String? linkedEventId, @JsonKey(name: 'day_names', defaultValue: <String>[])  List<String> dayNames, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'created_by')  String createdBy, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'updated_by')  String updatedBy)?  $default,) {final _that = this;
switch (_that) {
case _TripResponse() when $default != null:
return $default(_that.id,_that.userId,_that.name,_that.description,_that.startDate,_that.endDate,_that.coverImage,_that.isActive,_that.linkedEventId,_that.dayNames,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TripResponse implements TripResponse {
  const _TripResponse({required this.id, @JsonKey(name: 'user_id') required this.userId, required this.name, this.description, @JsonKey(name: 'start_date') required this.startDate, @JsonKey(name: 'end_date') this.endDate, @JsonKey(name: 'cover_image') this.coverImage, @JsonKey(name: 'is_active') required this.isActive, @JsonKey(name: 'linked_event_id') this.linkedEventId, @JsonKey(name: 'day_names', defaultValue: <String>[]) required final  List<String> dayNames, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'created_by') required this.createdBy, @JsonKey(name: 'updated_at') required this.updatedAt, @JsonKey(name: 'updated_by') required this.updatedBy}): _dayNames = dayNames;
  factory _TripResponse.fromJson(Map<String, dynamic> json) => _$TripResponseFromJson(json);

@override final  String id;
@override@JsonKey(name: 'user_id') final  String userId;
@override final  String name;
@override final  String? description;
@override@JsonKey(name: 'start_date') final  DateTime startDate;
@override@JsonKey(name: 'end_date') final  DateTime? endDate;
@override@JsonKey(name: 'cover_image') final  String? coverImage;
@override@JsonKey(name: 'is_active') final  bool isActive;
@override@JsonKey(name: 'linked_event_id') final  String? linkedEventId;
 final  List<String> _dayNames;
@override@JsonKey(name: 'day_names', defaultValue: <String>[]) List<String> get dayNames {
  if (_dayNames is EqualUnmodifiableListView) return _dayNames;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dayNames);
}

@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'created_by') final  String createdBy;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;
@override@JsonKey(name: 'updated_by') final  String updatedBy;

/// Create a copy of TripResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripResponseCopyWith<_TripResponse> get copyWith => __$TripResponseCopyWithImpl<_TripResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.coverImage, coverImage) || other.coverImage == coverImage)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.linkedEventId, linkedEventId) || other.linkedEventId == linkedEventId)&&const DeepCollectionEquality().equals(other._dayNames, _dayNames)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,name,description,startDate,endDate,coverImage,isActive,linkedEventId,const DeepCollectionEquality().hash(_dayNames),createdAt,createdBy,updatedAt,updatedBy);

@override
String toString() {
  return 'TripResponse(id: $id, userId: $userId, name: $name, description: $description, startDate: $startDate, endDate: $endDate, coverImage: $coverImage, isActive: $isActive, linkedEventId: $linkedEventId, dayNames: $dayNames, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy)';
}


}

/// @nodoc
abstract mixin class _$TripResponseCopyWith<$Res> implements $TripResponseCopyWith<$Res> {
  factory _$TripResponseCopyWith(_TripResponse value, $Res Function(_TripResponse) _then) = __$TripResponseCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId, String name, String? description,@JsonKey(name: 'start_date') DateTime startDate,@JsonKey(name: 'end_date') DateTime? endDate,@JsonKey(name: 'cover_image') String? coverImage,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'linked_event_id') String? linkedEventId,@JsonKey(name: 'day_names', defaultValue: <String>[]) List<String> dayNames,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'created_by') String createdBy,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'updated_by') String updatedBy
});




}
/// @nodoc
class __$TripResponseCopyWithImpl<$Res>
    implements _$TripResponseCopyWith<$Res> {
  __$TripResponseCopyWithImpl(this._self, this._then);

  final _TripResponse _self;
  final $Res Function(_TripResponse) _then;

/// Create a copy of TripResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? name = null,Object? description = freezed,Object? startDate = null,Object? endDate = freezed,Object? coverImage = freezed,Object? isActive = null,Object? linkedEventId = freezed,Object? dayNames = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,}) {
  return _then(_TripResponse(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,coverImage: freezed == coverImage ? _self.coverImage : coverImage // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,linkedEventId: freezed == linkedEventId ? _self.linkedEventId : linkedEventId // ignore: cast_nullable_to_non_nullable
as String?,dayNames: null == dayNames ? _self._dayNames : dayNames // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$TripListItemResponse {

 String get id;@JsonKey(name: 'user_id') String get userId; String get name;@JsonKey(name: 'cover_image') String? get coverImage;@JsonKey(name: 'start_date') DateTime get startDate;@JsonKey(name: 'end_date') DateTime? get endDate;@JsonKey(name: 'is_active') bool get isActive;@JsonKey(name: 'linked_event_id') String? get linkedEventId;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'created_by') String get createdBy;@JsonKey(name: 'updated_at') DateTime get updatedAt;@JsonKey(name: 'updated_by') String get updatedBy;
/// Create a copy of TripListItemResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripListItemResponseCopyWith<TripListItemResponse> get copyWith => _$TripListItemResponseCopyWithImpl<TripListItemResponse>(this as TripListItemResponse, _$identity);

  /// Serializes this TripListItemResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripListItemResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.coverImage, coverImage) || other.coverImage == coverImage)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.linkedEventId, linkedEventId) || other.linkedEventId == linkedEventId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,name,coverImage,startDate,endDate,isActive,linkedEventId,createdAt,createdBy,updatedAt,updatedBy);

@override
String toString() {
  return 'TripListItemResponse(id: $id, userId: $userId, name: $name, coverImage: $coverImage, startDate: $startDate, endDate: $endDate, isActive: $isActive, linkedEventId: $linkedEventId, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy)';
}


}

/// @nodoc
abstract mixin class $TripListItemResponseCopyWith<$Res>  {
  factory $TripListItemResponseCopyWith(TripListItemResponse value, $Res Function(TripListItemResponse) _then) = _$TripListItemResponseCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId, String name,@JsonKey(name: 'cover_image') String? coverImage,@JsonKey(name: 'start_date') DateTime startDate,@JsonKey(name: 'end_date') DateTime? endDate,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'linked_event_id') String? linkedEventId,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'created_by') String createdBy,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'updated_by') String updatedBy
});




}
/// @nodoc
class _$TripListItemResponseCopyWithImpl<$Res>
    implements $TripListItemResponseCopyWith<$Res> {
  _$TripListItemResponseCopyWithImpl(this._self, this._then);

  final TripListItemResponse _self;
  final $Res Function(TripListItemResponse) _then;

/// Create a copy of TripListItemResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? name = null,Object? coverImage = freezed,Object? startDate = null,Object? endDate = freezed,Object? isActive = null,Object? linkedEventId = freezed,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,coverImage: freezed == coverImage ? _self.coverImage : coverImage // ignore: cast_nullable_to_non_nullable
as String?,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,linkedEventId: freezed == linkedEventId ? _self.linkedEventId : linkedEventId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TripListItemResponse].
extension TripListItemResponsePatterns on TripListItemResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripListItemResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripListItemResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripListItemResponse value)  $default,){
final _that = this;
switch (_that) {
case _TripListItemResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripListItemResponse value)?  $default,){
final _that = this;
switch (_that) {
case _TripListItemResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId,  String name, @JsonKey(name: 'cover_image')  String? coverImage, @JsonKey(name: 'start_date')  DateTime startDate, @JsonKey(name: 'end_date')  DateTime? endDate, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'linked_event_id')  String? linkedEventId, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'created_by')  String createdBy, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'updated_by')  String updatedBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripListItemResponse() when $default != null:
return $default(_that.id,_that.userId,_that.name,_that.coverImage,_that.startDate,_that.endDate,_that.isActive,_that.linkedEventId,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId,  String name, @JsonKey(name: 'cover_image')  String? coverImage, @JsonKey(name: 'start_date')  DateTime startDate, @JsonKey(name: 'end_date')  DateTime? endDate, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'linked_event_id')  String? linkedEventId, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'created_by')  String createdBy, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'updated_by')  String updatedBy)  $default,) {final _that = this;
switch (_that) {
case _TripListItemResponse():
return $default(_that.id,_that.userId,_that.name,_that.coverImage,_that.startDate,_that.endDate,_that.isActive,_that.linkedEventId,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'user_id')  String userId,  String name, @JsonKey(name: 'cover_image')  String? coverImage, @JsonKey(name: 'start_date')  DateTime startDate, @JsonKey(name: 'end_date')  DateTime? endDate, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'linked_event_id')  String? linkedEventId, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'created_by')  String createdBy, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'updated_by')  String updatedBy)?  $default,) {final _that = this;
switch (_that) {
case _TripListItemResponse() when $default != null:
return $default(_that.id,_that.userId,_that.name,_that.coverImage,_that.startDate,_that.endDate,_that.isActive,_that.linkedEventId,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TripListItemResponse implements TripListItemResponse {
  const _TripListItemResponse({required this.id, @JsonKey(name: 'user_id') required this.userId, required this.name, @JsonKey(name: 'cover_image') this.coverImage, @JsonKey(name: 'start_date') required this.startDate, @JsonKey(name: 'end_date') this.endDate, @JsonKey(name: 'is_active') required this.isActive, @JsonKey(name: 'linked_event_id') this.linkedEventId, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'created_by') required this.createdBy, @JsonKey(name: 'updated_at') required this.updatedAt, @JsonKey(name: 'updated_by') required this.updatedBy});
  factory _TripListItemResponse.fromJson(Map<String, dynamic> json) => _$TripListItemResponseFromJson(json);

@override final  String id;
@override@JsonKey(name: 'user_id') final  String userId;
@override final  String name;
@override@JsonKey(name: 'cover_image') final  String? coverImage;
@override@JsonKey(name: 'start_date') final  DateTime startDate;
@override@JsonKey(name: 'end_date') final  DateTime? endDate;
@override@JsonKey(name: 'is_active') final  bool isActive;
@override@JsonKey(name: 'linked_event_id') final  String? linkedEventId;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'created_by') final  String createdBy;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;
@override@JsonKey(name: 'updated_by') final  String updatedBy;

/// Create a copy of TripListItemResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripListItemResponseCopyWith<_TripListItemResponse> get copyWith => __$TripListItemResponseCopyWithImpl<_TripListItemResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripListItemResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripListItemResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.coverImage, coverImage) || other.coverImage == coverImage)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.linkedEventId, linkedEventId) || other.linkedEventId == linkedEventId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,name,coverImage,startDate,endDate,isActive,linkedEventId,createdAt,createdBy,updatedAt,updatedBy);

@override
String toString() {
  return 'TripListItemResponse(id: $id, userId: $userId, name: $name, coverImage: $coverImage, startDate: $startDate, endDate: $endDate, isActive: $isActive, linkedEventId: $linkedEventId, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy)';
}


}

/// @nodoc
abstract mixin class _$TripListItemResponseCopyWith<$Res> implements $TripListItemResponseCopyWith<$Res> {
  factory _$TripListItemResponseCopyWith(_TripListItemResponse value, $Res Function(_TripListItemResponse) _then) = __$TripListItemResponseCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId, String name,@JsonKey(name: 'cover_image') String? coverImage,@JsonKey(name: 'start_date') DateTime startDate,@JsonKey(name: 'end_date') DateTime? endDate,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'linked_event_id') String? linkedEventId,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'created_by') String createdBy,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'updated_by') String updatedBy
});




}
/// @nodoc
class __$TripListItemResponseCopyWithImpl<$Res>
    implements _$TripListItemResponseCopyWith<$Res> {
  __$TripListItemResponseCopyWithImpl(this._self, this._then);

  final _TripListItemResponse _self;
  final $Res Function(_TripListItemResponse) _then;

/// Create a copy of TripListItemResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? name = null,Object? coverImage = freezed,Object? startDate = null,Object? endDate = freezed,Object? isActive = null,Object? linkedEventId = freezed,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,}) {
  return _then(_TripListItemResponse(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,coverImage: freezed == coverImage ? _self.coverImage : coverImage // ignore: cast_nullable_to_non_nullable
as String?,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,linkedEventId: freezed == linkedEventId ? _self.linkedEventId : linkedEventId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$TripMemberResponse {

@JsonKey(name: 'trip_id') String get tripId;@JsonKey(name: 'user_id') String get userId;@JsonKey(name: 'joined_at') DateTime get joinedAt;@JsonKey(name: 'user_metadata') TripMemberUserMetadata get userMetadata;
/// Create a copy of TripMemberResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripMemberResponseCopyWith<TripMemberResponse> get copyWith => _$TripMemberResponseCopyWithImpl<TripMemberResponse>(this as TripMemberResponse, _$identity);

  /// Serializes this TripMemberResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripMemberResponse&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.userMetadata, userMetadata) || other.userMetadata == userMetadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tripId,userId,joinedAt,userMetadata);

@override
String toString() {
  return 'TripMemberResponse(tripId: $tripId, userId: $userId, joinedAt: $joinedAt, userMetadata: $userMetadata)';
}


}

/// @nodoc
abstract mixin class $TripMemberResponseCopyWith<$Res>  {
  factory $TripMemberResponseCopyWith(TripMemberResponse value, $Res Function(TripMemberResponse) _then) = _$TripMemberResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'trip_id') String tripId,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'joined_at') DateTime joinedAt,@JsonKey(name: 'user_metadata') TripMemberUserMetadata userMetadata
});


$TripMemberUserMetadataCopyWith<$Res> get userMetadata;

}
/// @nodoc
class _$TripMemberResponseCopyWithImpl<$Res>
    implements $TripMemberResponseCopyWith<$Res> {
  _$TripMemberResponseCopyWithImpl(this._self, this._then);

  final TripMemberResponse _self;
  final $Res Function(TripMemberResponse) _then;

/// Create a copy of TripMemberResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tripId = null,Object? userId = null,Object? joinedAt = null,Object? userMetadata = null,}) {
  return _then(_self.copyWith(
tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,userMetadata: null == userMetadata ? _self.userMetadata : userMetadata // ignore: cast_nullable_to_non_nullable
as TripMemberUserMetadata,
  ));
}
/// Create a copy of TripMemberResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TripMemberUserMetadataCopyWith<$Res> get userMetadata {
  
  return $TripMemberUserMetadataCopyWith<$Res>(_self.userMetadata, (value) {
    return _then(_self.copyWith(userMetadata: value));
  });
}
}


/// Adds pattern-matching-related methods to [TripMemberResponse].
extension TripMemberResponsePatterns on TripMemberResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripMemberResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripMemberResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripMemberResponse value)  $default,){
final _that = this;
switch (_that) {
case _TripMemberResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripMemberResponse value)?  $default,){
final _that = this;
switch (_that) {
case _TripMemberResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'trip_id')  String tripId, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'joined_at')  DateTime joinedAt, @JsonKey(name: 'user_metadata')  TripMemberUserMetadata userMetadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripMemberResponse() when $default != null:
return $default(_that.tripId,_that.userId,_that.joinedAt,_that.userMetadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'trip_id')  String tripId, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'joined_at')  DateTime joinedAt, @JsonKey(name: 'user_metadata')  TripMemberUserMetadata userMetadata)  $default,) {final _that = this;
switch (_that) {
case _TripMemberResponse():
return $default(_that.tripId,_that.userId,_that.joinedAt,_that.userMetadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'trip_id')  String tripId, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'joined_at')  DateTime joinedAt, @JsonKey(name: 'user_metadata')  TripMemberUserMetadata userMetadata)?  $default,) {final _that = this;
switch (_that) {
case _TripMemberResponse() when $default != null:
return $default(_that.tripId,_that.userId,_that.joinedAt,_that.userMetadata);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TripMemberResponse implements TripMemberResponse {
  const _TripMemberResponse({@JsonKey(name: 'trip_id') required this.tripId, @JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'joined_at') required this.joinedAt, @JsonKey(name: 'user_metadata') required this.userMetadata});
  factory _TripMemberResponse.fromJson(Map<String, dynamic> json) => _$TripMemberResponseFromJson(json);

@override@JsonKey(name: 'trip_id') final  String tripId;
@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey(name: 'joined_at') final  DateTime joinedAt;
@override@JsonKey(name: 'user_metadata') final  TripMemberUserMetadata userMetadata;

/// Create a copy of TripMemberResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripMemberResponseCopyWith<_TripMemberResponse> get copyWith => __$TripMemberResponseCopyWithImpl<_TripMemberResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripMemberResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripMemberResponse&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.userMetadata, userMetadata) || other.userMetadata == userMetadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tripId,userId,joinedAt,userMetadata);

@override
String toString() {
  return 'TripMemberResponse(tripId: $tripId, userId: $userId, joinedAt: $joinedAt, userMetadata: $userMetadata)';
}


}

/// @nodoc
abstract mixin class _$TripMemberResponseCopyWith<$Res> implements $TripMemberResponseCopyWith<$Res> {
  factory _$TripMemberResponseCopyWith(_TripMemberResponse value, $Res Function(_TripMemberResponse) _then) = __$TripMemberResponseCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'trip_id') String tripId,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'joined_at') DateTime joinedAt,@JsonKey(name: 'user_metadata') TripMemberUserMetadata userMetadata
});


@override $TripMemberUserMetadataCopyWith<$Res> get userMetadata;

}
/// @nodoc
class __$TripMemberResponseCopyWithImpl<$Res>
    implements _$TripMemberResponseCopyWith<$Res> {
  __$TripMemberResponseCopyWithImpl(this._self, this._then);

  final _TripMemberResponse _self;
  final $Res Function(_TripMemberResponse) _then;

/// Create a copy of TripMemberResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tripId = null,Object? userId = null,Object? joinedAt = null,Object? userMetadata = null,}) {
  return _then(_TripMemberResponse(
tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,userMetadata: null == userMetadata ? _self.userMetadata : userMetadata // ignore: cast_nullable_to_non_nullable
as TripMemberUserMetadata,
  ));
}

/// Create a copy of TripMemberResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TripMemberUserMetadataCopyWith<$Res> get userMetadata {
  
  return $TripMemberUserMetadataCopyWith<$Res>(_self.userMetadata, (value) {
    return _then(_self.copyWith(userMetadata: value));
  });
}
}


/// @nodoc
mixin _$TripMemberUserMetadata {

 String get id; String get nickname; String get email; String? get avatar; String get role;
/// Create a copy of TripMemberUserMetadata
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripMemberUserMetadataCopyWith<TripMemberUserMetadata> get copyWith => _$TripMemberUserMetadataCopyWithImpl<TripMemberUserMetadata>(this as TripMemberUserMetadata, _$identity);

  /// Serializes this TripMemberUserMetadata to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripMemberUserMetadata&&(identical(other.id, id) || other.id == id)&&(identical(other.nickname, nickname) || other.nickname == nickname)&&(identical(other.email, email) || other.email == email)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.role, role) || other.role == role));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nickname,email,avatar,role);

@override
String toString() {
  return 'TripMemberUserMetadata(id: $id, nickname: $nickname, email: $email, avatar: $avatar, role: $role)';
}


}

/// @nodoc
abstract mixin class $TripMemberUserMetadataCopyWith<$Res>  {
  factory $TripMemberUserMetadataCopyWith(TripMemberUserMetadata value, $Res Function(TripMemberUserMetadata) _then) = _$TripMemberUserMetadataCopyWithImpl;
@useResult
$Res call({
 String id, String nickname, String email, String? avatar, String role
});




}
/// @nodoc
class _$TripMemberUserMetadataCopyWithImpl<$Res>
    implements $TripMemberUserMetadataCopyWith<$Res> {
  _$TripMemberUserMetadataCopyWithImpl(this._self, this._then);

  final TripMemberUserMetadata _self;
  final $Res Function(TripMemberUserMetadata) _then;

/// Create a copy of TripMemberUserMetadata
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nickname = null,Object? email = null,Object? avatar = freezed,Object? role = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nickname: null == nickname ? _self.nickname : nickname // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,avatar: freezed == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as String?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TripMemberUserMetadata].
extension TripMemberUserMetadataPatterns on TripMemberUserMetadata {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripMemberUserMetadata value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripMemberUserMetadata() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripMemberUserMetadata value)  $default,){
final _that = this;
switch (_that) {
case _TripMemberUserMetadata():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripMemberUserMetadata value)?  $default,){
final _that = this;
switch (_that) {
case _TripMemberUserMetadata() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String nickname,  String email,  String? avatar,  String role)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripMemberUserMetadata() when $default != null:
return $default(_that.id,_that.nickname,_that.email,_that.avatar,_that.role);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String nickname,  String email,  String? avatar,  String role)  $default,) {final _that = this;
switch (_that) {
case _TripMemberUserMetadata():
return $default(_that.id,_that.nickname,_that.email,_that.avatar,_that.role);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String nickname,  String email,  String? avatar,  String role)?  $default,) {final _that = this;
switch (_that) {
case _TripMemberUserMetadata() when $default != null:
return $default(_that.id,_that.nickname,_that.email,_that.avatar,_that.role);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TripMemberUserMetadata implements TripMemberUserMetadata {
  const _TripMemberUserMetadata({required this.id, required this.nickname, required this.email, this.avatar, required this.role});
  factory _TripMemberUserMetadata.fromJson(Map<String, dynamic> json) => _$TripMemberUserMetadataFromJson(json);

@override final  String id;
@override final  String nickname;
@override final  String email;
@override final  String? avatar;
@override final  String role;

/// Create a copy of TripMemberUserMetadata
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripMemberUserMetadataCopyWith<_TripMemberUserMetadata> get copyWith => __$TripMemberUserMetadataCopyWithImpl<_TripMemberUserMetadata>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripMemberUserMetadataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripMemberUserMetadata&&(identical(other.id, id) || other.id == id)&&(identical(other.nickname, nickname) || other.nickname == nickname)&&(identical(other.email, email) || other.email == email)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.role, role) || other.role == role));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nickname,email,avatar,role);

@override
String toString() {
  return 'TripMemberUserMetadata(id: $id, nickname: $nickname, email: $email, avatar: $avatar, role: $role)';
}


}

/// @nodoc
abstract mixin class _$TripMemberUserMetadataCopyWith<$Res> implements $TripMemberUserMetadataCopyWith<$Res> {
  factory _$TripMemberUserMetadataCopyWith(_TripMemberUserMetadata value, $Res Function(_TripMemberUserMetadata) _then) = __$TripMemberUserMetadataCopyWithImpl;
@override @useResult
$Res call({
 String id, String nickname, String email, String? avatar, String role
});




}
/// @nodoc
class __$TripMemberUserMetadataCopyWithImpl<$Res>
    implements _$TripMemberUserMetadataCopyWith<$Res> {
  __$TripMemberUserMetadataCopyWithImpl(this._self, this._then);

  final _TripMemberUserMetadata _self;
  final $Res Function(_TripMemberUserMetadata) _then;

/// Create a copy of TripMemberUserMetadata
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nickname = null,Object? email = null,Object? avatar = freezed,Object? role = null,}) {
  return _then(_TripMemberUserMetadata(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nickname: null == nickname ? _self.nickname : nickname // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,avatar: freezed == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as String?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$TripCreateRequest {

 String get name;@JsonKey(name: 'start_date') DateTime get startDate; String? get description;@JsonKey(name: 'end_date') DateTime? get endDate;@JsonKey(name: 'cover_image') String? get coverImage;@JsonKey(name: 'day_names') List<String>? get dayNames;
/// Create a copy of TripCreateRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripCreateRequestCopyWith<TripCreateRequest> get copyWith => _$TripCreateRequestCopyWithImpl<TripCreateRequest>(this as TripCreateRequest, _$identity);

  /// Serializes this TripCreateRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripCreateRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.description, description) || other.description == description)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.coverImage, coverImage) || other.coverImage == coverImage)&&const DeepCollectionEquality().equals(other.dayNames, dayNames));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,startDate,description,endDate,coverImage,const DeepCollectionEquality().hash(dayNames));

@override
String toString() {
  return 'TripCreateRequest(name: $name, startDate: $startDate, description: $description, endDate: $endDate, coverImage: $coverImage, dayNames: $dayNames)';
}


}

/// @nodoc
abstract mixin class $TripCreateRequestCopyWith<$Res>  {
  factory $TripCreateRequestCopyWith(TripCreateRequest value, $Res Function(TripCreateRequest) _then) = _$TripCreateRequestCopyWithImpl;
@useResult
$Res call({
 String name,@JsonKey(name: 'start_date') DateTime startDate, String? description,@JsonKey(name: 'end_date') DateTime? endDate,@JsonKey(name: 'cover_image') String? coverImage,@JsonKey(name: 'day_names') List<String>? dayNames
});




}
/// @nodoc
class _$TripCreateRequestCopyWithImpl<$Res>
    implements $TripCreateRequestCopyWith<$Res> {
  _$TripCreateRequestCopyWithImpl(this._self, this._then);

  final TripCreateRequest _self;
  final $Res Function(TripCreateRequest) _then;

/// Create a copy of TripCreateRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? startDate = null,Object? description = freezed,Object? endDate = freezed,Object? coverImage = freezed,Object? dayNames = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,coverImage: freezed == coverImage ? _self.coverImage : coverImage // ignore: cast_nullable_to_non_nullable
as String?,dayNames: freezed == dayNames ? _self.dayNames : dayNames // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

}


/// Adds pattern-matching-related methods to [TripCreateRequest].
extension TripCreateRequestPatterns on TripCreateRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripCreateRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripCreateRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripCreateRequest value)  $default,){
final _that = this;
switch (_that) {
case _TripCreateRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripCreateRequest value)?  $default,){
final _that = this;
switch (_that) {
case _TripCreateRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name, @JsonKey(name: 'start_date')  DateTime startDate,  String? description, @JsonKey(name: 'end_date')  DateTime? endDate, @JsonKey(name: 'cover_image')  String? coverImage, @JsonKey(name: 'day_names')  List<String>? dayNames)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripCreateRequest() when $default != null:
return $default(_that.name,_that.startDate,_that.description,_that.endDate,_that.coverImage,_that.dayNames);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name, @JsonKey(name: 'start_date')  DateTime startDate,  String? description, @JsonKey(name: 'end_date')  DateTime? endDate, @JsonKey(name: 'cover_image')  String? coverImage, @JsonKey(name: 'day_names')  List<String>? dayNames)  $default,) {final _that = this;
switch (_that) {
case _TripCreateRequest():
return $default(_that.name,_that.startDate,_that.description,_that.endDate,_that.coverImage,_that.dayNames);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name, @JsonKey(name: 'start_date')  DateTime startDate,  String? description, @JsonKey(name: 'end_date')  DateTime? endDate, @JsonKey(name: 'cover_image')  String? coverImage, @JsonKey(name: 'day_names')  List<String>? dayNames)?  $default,) {final _that = this;
switch (_that) {
case _TripCreateRequest() when $default != null:
return $default(_that.name,_that.startDate,_that.description,_that.endDate,_that.coverImage,_that.dayNames);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TripCreateRequest implements TripCreateRequest {
  const _TripCreateRequest({required this.name, @JsonKey(name: 'start_date') required this.startDate, this.description, @JsonKey(name: 'end_date') this.endDate, @JsonKey(name: 'cover_image') this.coverImage, @JsonKey(name: 'day_names') final  List<String>? dayNames}): _dayNames = dayNames;
  factory _TripCreateRequest.fromJson(Map<String, dynamic> json) => _$TripCreateRequestFromJson(json);

@override final  String name;
@override@JsonKey(name: 'start_date') final  DateTime startDate;
@override final  String? description;
@override@JsonKey(name: 'end_date') final  DateTime? endDate;
@override@JsonKey(name: 'cover_image') final  String? coverImage;
 final  List<String>? _dayNames;
@override@JsonKey(name: 'day_names') List<String>? get dayNames {
  final value = _dayNames;
  if (value == null) return null;
  if (_dayNames is EqualUnmodifiableListView) return _dayNames;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of TripCreateRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripCreateRequestCopyWith<_TripCreateRequest> get copyWith => __$TripCreateRequestCopyWithImpl<_TripCreateRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripCreateRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripCreateRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.description, description) || other.description == description)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.coverImage, coverImage) || other.coverImage == coverImage)&&const DeepCollectionEquality().equals(other._dayNames, _dayNames));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,startDate,description,endDate,coverImage,const DeepCollectionEquality().hash(_dayNames));

@override
String toString() {
  return 'TripCreateRequest(name: $name, startDate: $startDate, description: $description, endDate: $endDate, coverImage: $coverImage, dayNames: $dayNames)';
}


}

/// @nodoc
abstract mixin class _$TripCreateRequestCopyWith<$Res> implements $TripCreateRequestCopyWith<$Res> {
  factory _$TripCreateRequestCopyWith(_TripCreateRequest value, $Res Function(_TripCreateRequest) _then) = __$TripCreateRequestCopyWithImpl;
@override @useResult
$Res call({
 String name,@JsonKey(name: 'start_date') DateTime startDate, String? description,@JsonKey(name: 'end_date') DateTime? endDate,@JsonKey(name: 'cover_image') String? coverImage,@JsonKey(name: 'day_names') List<String>? dayNames
});




}
/// @nodoc
class __$TripCreateRequestCopyWithImpl<$Res>
    implements _$TripCreateRequestCopyWith<$Res> {
  __$TripCreateRequestCopyWithImpl(this._self, this._then);

  final _TripCreateRequest _self;
  final $Res Function(_TripCreateRequest) _then;

/// Create a copy of TripCreateRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? startDate = null,Object? description = freezed,Object? endDate = freezed,Object? coverImage = freezed,Object? dayNames = freezed,}) {
  return _then(_TripCreateRequest(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,coverImage: freezed == coverImage ? _self.coverImage : coverImage // ignore: cast_nullable_to_non_nullable
as String?,dayNames: freezed == dayNames ? _self._dayNames : dayNames // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}


}


/// @nodoc
mixin _$TripUpdateRequest {

 String? get name; String? get description;@JsonKey(name: 'start_date') DateTime? get startDate;@JsonKey(name: 'end_date') DateTime? get endDate;@JsonKey(name: 'cover_image') String? get coverImage;@JsonKey(name: 'is_active') bool? get isActive;@JsonKey(name: 'day_names') List<String>? get dayNames;@JsonKey(name: 'last_updated_at') DateTime? get lastUpdatedAt;
/// Create a copy of TripUpdateRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripUpdateRequestCopyWith<TripUpdateRequest> get copyWith => _$TripUpdateRequestCopyWithImpl<TripUpdateRequest>(this as TripUpdateRequest, _$identity);

  /// Serializes this TripUpdateRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripUpdateRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.coverImage, coverImage) || other.coverImage == coverImage)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&const DeepCollectionEquality().equals(other.dayNames, dayNames)&&(identical(other.lastUpdatedAt, lastUpdatedAt) || other.lastUpdatedAt == lastUpdatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,description,startDate,endDate,coverImage,isActive,const DeepCollectionEquality().hash(dayNames),lastUpdatedAt);

@override
String toString() {
  return 'TripUpdateRequest(name: $name, description: $description, startDate: $startDate, endDate: $endDate, coverImage: $coverImage, isActive: $isActive, dayNames: $dayNames, lastUpdatedAt: $lastUpdatedAt)';
}


}

/// @nodoc
abstract mixin class $TripUpdateRequestCopyWith<$Res>  {
  factory $TripUpdateRequestCopyWith(TripUpdateRequest value, $Res Function(TripUpdateRequest) _then) = _$TripUpdateRequestCopyWithImpl;
@useResult
$Res call({
 String? name, String? description,@JsonKey(name: 'start_date') DateTime? startDate,@JsonKey(name: 'end_date') DateTime? endDate,@JsonKey(name: 'cover_image') String? coverImage,@JsonKey(name: 'is_active') bool? isActive,@JsonKey(name: 'day_names') List<String>? dayNames,@JsonKey(name: 'last_updated_at') DateTime? lastUpdatedAt
});




}
/// @nodoc
class _$TripUpdateRequestCopyWithImpl<$Res>
    implements $TripUpdateRequestCopyWith<$Res> {
  _$TripUpdateRequestCopyWithImpl(this._self, this._then);

  final TripUpdateRequest _self;
  final $Res Function(TripUpdateRequest) _then;

/// Create a copy of TripUpdateRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = freezed,Object? description = freezed,Object? startDate = freezed,Object? endDate = freezed,Object? coverImage = freezed,Object? isActive = freezed,Object? dayNames = freezed,Object? lastUpdatedAt = freezed,}) {
  return _then(_self.copyWith(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,coverImage: freezed == coverImage ? _self.coverImage : coverImage // ignore: cast_nullable_to_non_nullable
as String?,isActive: freezed == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool?,dayNames: freezed == dayNames ? _self.dayNames : dayNames // ignore: cast_nullable_to_non_nullable
as List<String>?,lastUpdatedAt: freezed == lastUpdatedAt ? _self.lastUpdatedAt : lastUpdatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [TripUpdateRequest].
extension TripUpdateRequestPatterns on TripUpdateRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripUpdateRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripUpdateRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripUpdateRequest value)  $default,){
final _that = this;
switch (_that) {
case _TripUpdateRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripUpdateRequest value)?  $default,){
final _that = this;
switch (_that) {
case _TripUpdateRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? name,  String? description, @JsonKey(name: 'start_date')  DateTime? startDate, @JsonKey(name: 'end_date')  DateTime? endDate, @JsonKey(name: 'cover_image')  String? coverImage, @JsonKey(name: 'is_active')  bool? isActive, @JsonKey(name: 'day_names')  List<String>? dayNames, @JsonKey(name: 'last_updated_at')  DateTime? lastUpdatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripUpdateRequest() when $default != null:
return $default(_that.name,_that.description,_that.startDate,_that.endDate,_that.coverImage,_that.isActive,_that.dayNames,_that.lastUpdatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? name,  String? description, @JsonKey(name: 'start_date')  DateTime? startDate, @JsonKey(name: 'end_date')  DateTime? endDate, @JsonKey(name: 'cover_image')  String? coverImage, @JsonKey(name: 'is_active')  bool? isActive, @JsonKey(name: 'day_names')  List<String>? dayNames, @JsonKey(name: 'last_updated_at')  DateTime? lastUpdatedAt)  $default,) {final _that = this;
switch (_that) {
case _TripUpdateRequest():
return $default(_that.name,_that.description,_that.startDate,_that.endDate,_that.coverImage,_that.isActive,_that.dayNames,_that.lastUpdatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? name,  String? description, @JsonKey(name: 'start_date')  DateTime? startDate, @JsonKey(name: 'end_date')  DateTime? endDate, @JsonKey(name: 'cover_image')  String? coverImage, @JsonKey(name: 'is_active')  bool? isActive, @JsonKey(name: 'day_names')  List<String>? dayNames, @JsonKey(name: 'last_updated_at')  DateTime? lastUpdatedAt)?  $default,) {final _that = this;
switch (_that) {
case _TripUpdateRequest() when $default != null:
return $default(_that.name,_that.description,_that.startDate,_that.endDate,_that.coverImage,_that.isActive,_that.dayNames,_that.lastUpdatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TripUpdateRequest implements TripUpdateRequest {
  const _TripUpdateRequest({this.name, this.description, @JsonKey(name: 'start_date') this.startDate, @JsonKey(name: 'end_date') this.endDate, @JsonKey(name: 'cover_image') this.coverImage, @JsonKey(name: 'is_active') this.isActive, @JsonKey(name: 'day_names') final  List<String>? dayNames, @JsonKey(name: 'last_updated_at') this.lastUpdatedAt}): _dayNames = dayNames;
  factory _TripUpdateRequest.fromJson(Map<String, dynamic> json) => _$TripUpdateRequestFromJson(json);

@override final  String? name;
@override final  String? description;
@override@JsonKey(name: 'start_date') final  DateTime? startDate;
@override@JsonKey(name: 'end_date') final  DateTime? endDate;
@override@JsonKey(name: 'cover_image') final  String? coverImage;
@override@JsonKey(name: 'is_active') final  bool? isActive;
 final  List<String>? _dayNames;
@override@JsonKey(name: 'day_names') List<String>? get dayNames {
  final value = _dayNames;
  if (value == null) return null;
  if (_dayNames is EqualUnmodifiableListView) return _dayNames;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey(name: 'last_updated_at') final  DateTime? lastUpdatedAt;

/// Create a copy of TripUpdateRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripUpdateRequestCopyWith<_TripUpdateRequest> get copyWith => __$TripUpdateRequestCopyWithImpl<_TripUpdateRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripUpdateRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripUpdateRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.coverImage, coverImage) || other.coverImage == coverImage)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&const DeepCollectionEquality().equals(other._dayNames, _dayNames)&&(identical(other.lastUpdatedAt, lastUpdatedAt) || other.lastUpdatedAt == lastUpdatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,description,startDate,endDate,coverImage,isActive,const DeepCollectionEquality().hash(_dayNames),lastUpdatedAt);

@override
String toString() {
  return 'TripUpdateRequest(name: $name, description: $description, startDate: $startDate, endDate: $endDate, coverImage: $coverImage, isActive: $isActive, dayNames: $dayNames, lastUpdatedAt: $lastUpdatedAt)';
}


}

/// @nodoc
abstract mixin class _$TripUpdateRequestCopyWith<$Res> implements $TripUpdateRequestCopyWith<$Res> {
  factory _$TripUpdateRequestCopyWith(_TripUpdateRequest value, $Res Function(_TripUpdateRequest) _then) = __$TripUpdateRequestCopyWithImpl;
@override @useResult
$Res call({
 String? name, String? description,@JsonKey(name: 'start_date') DateTime? startDate,@JsonKey(name: 'end_date') DateTime? endDate,@JsonKey(name: 'cover_image') String? coverImage,@JsonKey(name: 'is_active') bool? isActive,@JsonKey(name: 'day_names') List<String>? dayNames,@JsonKey(name: 'last_updated_at') DateTime? lastUpdatedAt
});




}
/// @nodoc
class __$TripUpdateRequestCopyWithImpl<$Res>
    implements _$TripUpdateRequestCopyWith<$Res> {
  __$TripUpdateRequestCopyWithImpl(this._self, this._then);

  final _TripUpdateRequest _self;
  final $Res Function(_TripUpdateRequest) _then;

/// Create a copy of TripUpdateRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = freezed,Object? description = freezed,Object? startDate = freezed,Object? endDate = freezed,Object? coverImage = freezed,Object? isActive = freezed,Object? dayNames = freezed,Object? lastUpdatedAt = freezed,}) {
  return _then(_TripUpdateRequest(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,coverImage: freezed == coverImage ? _self.coverImage : coverImage // ignore: cast_nullable_to_non_nullable
as String?,isActive: freezed == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool?,dayNames: freezed == dayNames ? _self._dayNames : dayNames // ignore: cast_nullable_to_non_nullable
as List<String>?,lastUpdatedAt: freezed == lastUpdatedAt ? _self.lastUpdatedAt : lastUpdatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$AddMemberRequest {

 String get email;
/// Create a copy of AddMemberRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AddMemberRequestCopyWith<AddMemberRequest> get copyWith => _$AddMemberRequestCopyWithImpl<AddMemberRequest>(this as AddMemberRequest, _$identity);

  /// Serializes this AddMemberRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AddMemberRequest&&(identical(other.email, email) || other.email == email));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,email);

@override
String toString() {
  return 'AddMemberRequest(email: $email)';
}


}

/// @nodoc
abstract mixin class $AddMemberRequestCopyWith<$Res>  {
  factory $AddMemberRequestCopyWith(AddMemberRequest value, $Res Function(AddMemberRequest) _then) = _$AddMemberRequestCopyWithImpl;
@useResult
$Res call({
 String email
});




}
/// @nodoc
class _$AddMemberRequestCopyWithImpl<$Res>
    implements $AddMemberRequestCopyWith<$Res> {
  _$AddMemberRequestCopyWithImpl(this._self, this._then);

  final AddMemberRequest _self;
  final $Res Function(AddMemberRequest) _then;

/// Create a copy of AddMemberRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? email = null,}) {
  return _then(_self.copyWith(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AddMemberRequest].
extension AddMemberRequestPatterns on AddMemberRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AddMemberRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AddMemberRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AddMemberRequest value)  $default,){
final _that = this;
switch (_that) {
case _AddMemberRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AddMemberRequest value)?  $default,){
final _that = this;
switch (_that) {
case _AddMemberRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String email)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AddMemberRequest() when $default != null:
return $default(_that.email);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String email)  $default,) {final _that = this;
switch (_that) {
case _AddMemberRequest():
return $default(_that.email);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String email)?  $default,) {final _that = this;
switch (_that) {
case _AddMemberRequest() when $default != null:
return $default(_that.email);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AddMemberRequest implements AddMemberRequest {
  const _AddMemberRequest({required this.email});
  factory _AddMemberRequest.fromJson(Map<String, dynamic> json) => _$AddMemberRequestFromJson(json);

@override final  String email;

/// Create a copy of AddMemberRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AddMemberRequestCopyWith<_AddMemberRequest> get copyWith => __$AddMemberRequestCopyWithImpl<_AddMemberRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AddMemberRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AddMemberRequest&&(identical(other.email, email) || other.email == email));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,email);

@override
String toString() {
  return 'AddMemberRequest(email: $email)';
}


}

/// @nodoc
abstract mixin class _$AddMemberRequestCopyWith<$Res> implements $AddMemberRequestCopyWith<$Res> {
  factory _$AddMemberRequestCopyWith(_AddMemberRequest value, $Res Function(_AddMemberRequest) _then) = __$AddMemberRequestCopyWithImpl;
@override @useResult
$Res call({
 String email
});




}
/// @nodoc
class __$AddMemberRequestCopyWithImpl<$Res>
    implements _$AddMemberRequestCopyWith<$Res> {
  __$AddMemberRequestCopyWithImpl(this._self, this._then);

  final _AddMemberRequest _self;
  final $Res Function(_AddMemberRequest) _then;

/// Create a copy of AddMemberRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? email = null,}) {
  return _then(_AddMemberRequest(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$UpdateMemberRoleRequest {

 String get role;
/// Create a copy of UpdateMemberRoleRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateMemberRoleRequestCopyWith<UpdateMemberRoleRequest> get copyWith => _$UpdateMemberRoleRequestCopyWithImpl<UpdateMemberRoleRequest>(this as UpdateMemberRoleRequest, _$identity);

  /// Serializes this UpdateMemberRoleRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateMemberRoleRequest&&(identical(other.role, role) || other.role == role));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,role);

@override
String toString() {
  return 'UpdateMemberRoleRequest(role: $role)';
}


}

/// @nodoc
abstract mixin class $UpdateMemberRoleRequestCopyWith<$Res>  {
  factory $UpdateMemberRoleRequestCopyWith(UpdateMemberRoleRequest value, $Res Function(UpdateMemberRoleRequest) _then) = _$UpdateMemberRoleRequestCopyWithImpl;
@useResult
$Res call({
 String role
});




}
/// @nodoc
class _$UpdateMemberRoleRequestCopyWithImpl<$Res>
    implements $UpdateMemberRoleRequestCopyWith<$Res> {
  _$UpdateMemberRoleRequestCopyWithImpl(this._self, this._then);

  final UpdateMemberRoleRequest _self;
  final $Res Function(UpdateMemberRoleRequest) _then;

/// Create a copy of UpdateMemberRoleRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? role = null,}) {
  return _then(_self.copyWith(
role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [UpdateMemberRoleRequest].
extension UpdateMemberRoleRequestPatterns on UpdateMemberRoleRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpdateMemberRoleRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpdateMemberRoleRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpdateMemberRoleRequest value)  $default,){
final _that = this;
switch (_that) {
case _UpdateMemberRoleRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpdateMemberRoleRequest value)?  $default,){
final _that = this;
switch (_that) {
case _UpdateMemberRoleRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String role)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpdateMemberRoleRequest() when $default != null:
return $default(_that.role);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String role)  $default,) {final _that = this;
switch (_that) {
case _UpdateMemberRoleRequest():
return $default(_that.role);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String role)?  $default,) {final _that = this;
switch (_that) {
case _UpdateMemberRoleRequest() when $default != null:
return $default(_that.role);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UpdateMemberRoleRequest implements UpdateMemberRoleRequest {
  const _UpdateMemberRoleRequest({required this.role});
  factory _UpdateMemberRoleRequest.fromJson(Map<String, dynamic> json) => _$UpdateMemberRoleRequestFromJson(json);

@override final  String role;

/// Create a copy of UpdateMemberRoleRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateMemberRoleRequestCopyWith<_UpdateMemberRoleRequest> get copyWith => __$UpdateMemberRoleRequestCopyWithImpl<_UpdateMemberRoleRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UpdateMemberRoleRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateMemberRoleRequest&&(identical(other.role, role) || other.role == role));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,role);

@override
String toString() {
  return 'UpdateMemberRoleRequest(role: $role)';
}


}

/// @nodoc
abstract mixin class _$UpdateMemberRoleRequestCopyWith<$Res> implements $UpdateMemberRoleRequestCopyWith<$Res> {
  factory _$UpdateMemberRoleRequestCopyWith(_UpdateMemberRoleRequest value, $Res Function(_UpdateMemberRoleRequest) _then) = __$UpdateMemberRoleRequestCopyWithImpl;
@override @useResult
$Res call({
 String role
});




}
/// @nodoc
class __$UpdateMemberRoleRequestCopyWithImpl<$Res>
    implements _$UpdateMemberRoleRequestCopyWith<$Res> {
  __$UpdateMemberRoleRequestCopyWithImpl(this._self, this._then);

  final _UpdateMemberRoleRequest _self;
  final $Res Function(_UpdateMemberRoleRequest) _then;

/// Create a copy of UpdateMemberRoleRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? role = null,}) {
  return _then(_UpdateMemberRoleRequest(
role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
