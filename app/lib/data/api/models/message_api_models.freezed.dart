// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message_api_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MessageResponse {

 String get id;@JsonKey(name: 'trip_id') String get tripId;@JsonKey(name: 'parent_id') String? get parentId;@JsonKey(name: 'user_id') String get userId;@JsonKey(name: 'display_name', defaultValue: '') String get displayName;@JsonKey(defaultValue: '🐻') String? get avatar;@JsonKey(defaultValue: '') String get category;@JsonKey(defaultValue: '') String get content; DateTime get timestamp; List<MessageResponse>? get replies;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;
/// Create a copy of MessageResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageResponseCopyWith<MessageResponse> get copyWith => _$MessageResponseCopyWithImpl<MessageResponse>(this as MessageResponse, _$identity);

  /// Serializes this MessageResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.category, category) || other.category == category)&&(identical(other.content, content) || other.content == content)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&const DeepCollectionEquality().equals(other.replies, replies)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,parentId,userId,displayName,avatar,category,content,timestamp,const DeepCollectionEquality().hash(replies),createdAt,updatedAt);

@override
String toString() {
  return 'MessageResponse(id: $id, tripId: $tripId, parentId: $parentId, userId: $userId, displayName: $displayName, avatar: $avatar, category: $category, content: $content, timestamp: $timestamp, replies: $replies, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $MessageResponseCopyWith<$Res>  {
  factory $MessageResponseCopyWith(MessageResponse value, $Res Function(MessageResponse) _then) = _$MessageResponseCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'trip_id') String tripId,@JsonKey(name: 'parent_id') String? parentId,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'display_name', defaultValue: '') String displayName,@JsonKey(defaultValue: '🐻') String? avatar,@JsonKey(defaultValue: '') String category,@JsonKey(defaultValue: '') String content, DateTime timestamp, List<MessageResponse>? replies,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class _$MessageResponseCopyWithImpl<$Res>
    implements $MessageResponseCopyWith<$Res> {
  _$MessageResponseCopyWithImpl(this._self, this._then);

  final MessageResponse _self;
  final $Res Function(MessageResponse) _then;

/// Create a copy of MessageResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tripId = null,Object? parentId = freezed,Object? userId = null,Object? displayName = null,Object? avatar = freezed,Object? category = null,Object? content = null,Object? timestamp = null,Object? replies = freezed,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatar: freezed == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as String?,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,replies: freezed == replies ? _self.replies : replies // ignore: cast_nullable_to_non_nullable
as List<MessageResponse>?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [MessageResponse].
extension MessageResponsePatterns on MessageResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageResponse value)  $default,){
final _that = this;
switch (_that) {
case _MessageResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageResponse value)?  $default,){
final _that = this;
switch (_that) {
case _MessageResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'trip_id')  String tripId, @JsonKey(name: 'parent_id')  String? parentId, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'display_name', defaultValue: '')  String displayName, @JsonKey(defaultValue: '🐻')  String? avatar, @JsonKey(defaultValue: '')  String category, @JsonKey(defaultValue: '')  String content,  DateTime timestamp,  List<MessageResponse>? replies, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageResponse() when $default != null:
return $default(_that.id,_that.tripId,_that.parentId,_that.userId,_that.displayName,_that.avatar,_that.category,_that.content,_that.timestamp,_that.replies,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'trip_id')  String tripId, @JsonKey(name: 'parent_id')  String? parentId, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'display_name', defaultValue: '')  String displayName, @JsonKey(defaultValue: '🐻')  String? avatar, @JsonKey(defaultValue: '')  String category, @JsonKey(defaultValue: '')  String content,  DateTime timestamp,  List<MessageResponse>? replies, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _MessageResponse():
return $default(_that.id,_that.tripId,_that.parentId,_that.userId,_that.displayName,_that.avatar,_that.category,_that.content,_that.timestamp,_that.replies,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'trip_id')  String tripId, @JsonKey(name: 'parent_id')  String? parentId, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'display_name', defaultValue: '')  String displayName, @JsonKey(defaultValue: '🐻')  String? avatar, @JsonKey(defaultValue: '')  String category, @JsonKey(defaultValue: '')  String content,  DateTime timestamp,  List<MessageResponse>? replies, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _MessageResponse() when $default != null:
return $default(_that.id,_that.tripId,_that.parentId,_that.userId,_that.displayName,_that.avatar,_that.category,_that.content,_that.timestamp,_that.replies,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MessageResponse implements MessageResponse {
  const _MessageResponse({required this.id, @JsonKey(name: 'trip_id') required this.tripId, @JsonKey(name: 'parent_id') this.parentId, @JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'display_name', defaultValue: '') required this.displayName, @JsonKey(defaultValue: '🐻') this.avatar, @JsonKey(defaultValue: '') required this.category, @JsonKey(defaultValue: '') required this.content, required this.timestamp, final  List<MessageResponse>? replies, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt}): _replies = replies;
  factory _MessageResponse.fromJson(Map<String, dynamic> json) => _$MessageResponseFromJson(json);

@override final  String id;
@override@JsonKey(name: 'trip_id') final  String tripId;
@override@JsonKey(name: 'parent_id') final  String? parentId;
@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey(name: 'display_name', defaultValue: '') final  String displayName;
@override@JsonKey(defaultValue: '🐻') final  String? avatar;
@override@JsonKey(defaultValue: '') final  String category;
@override@JsonKey(defaultValue: '') final  String content;
@override final  DateTime timestamp;
 final  List<MessageResponse>? _replies;
@override List<MessageResponse>? get replies {
  final value = _replies;
  if (value == null) return null;
  if (_replies is EqualUnmodifiableListView) return _replies;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;

/// Create a copy of MessageResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageResponseCopyWith<_MessageResponse> get copyWith => __$MessageResponseCopyWithImpl<_MessageResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.category, category) || other.category == category)&&(identical(other.content, content) || other.content == content)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&const DeepCollectionEquality().equals(other._replies, _replies)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,parentId,userId,displayName,avatar,category,content,timestamp,const DeepCollectionEquality().hash(_replies),createdAt,updatedAt);

@override
String toString() {
  return 'MessageResponse(id: $id, tripId: $tripId, parentId: $parentId, userId: $userId, displayName: $displayName, avatar: $avatar, category: $category, content: $content, timestamp: $timestamp, replies: $replies, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$MessageResponseCopyWith<$Res> implements $MessageResponseCopyWith<$Res> {
  factory _$MessageResponseCopyWith(_MessageResponse value, $Res Function(_MessageResponse) _then) = __$MessageResponseCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'trip_id') String tripId,@JsonKey(name: 'parent_id') String? parentId,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'display_name', defaultValue: '') String displayName,@JsonKey(defaultValue: '🐻') String? avatar,@JsonKey(defaultValue: '') String category,@JsonKey(defaultValue: '') String content, DateTime timestamp, List<MessageResponse>? replies,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class __$MessageResponseCopyWithImpl<$Res>
    implements _$MessageResponseCopyWith<$Res> {
  __$MessageResponseCopyWithImpl(this._self, this._then);

  final _MessageResponse _self;
  final $Res Function(_MessageResponse) _then;

/// Create a copy of MessageResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tripId = null,Object? parentId = freezed,Object? userId = null,Object? displayName = null,Object? avatar = freezed,Object? category = null,Object? content = null,Object? timestamp = null,Object? replies = freezed,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(_MessageResponse(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatar: freezed == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as String?,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,replies: freezed == replies ? _self._replies : replies // ignore: cast_nullable_to_non_nullable
as List<MessageResponse>?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$MessageCreateRequest {

 String get content; String? get category;@JsonKey(name: 'parent_id') String? get parentId;
/// Create a copy of MessageCreateRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageCreateRequestCopyWith<MessageCreateRequest> get copyWith => _$MessageCreateRequestCopyWithImpl<MessageCreateRequest>(this as MessageCreateRequest, _$identity);

  /// Serializes this MessageCreateRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageCreateRequest&&(identical(other.content, content) || other.content == content)&&(identical(other.category, category) || other.category == category)&&(identical(other.parentId, parentId) || other.parentId == parentId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,content,category,parentId);

@override
String toString() {
  return 'MessageCreateRequest(content: $content, category: $category, parentId: $parentId)';
}


}

/// @nodoc
abstract mixin class $MessageCreateRequestCopyWith<$Res>  {
  factory $MessageCreateRequestCopyWith(MessageCreateRequest value, $Res Function(MessageCreateRequest) _then) = _$MessageCreateRequestCopyWithImpl;
@useResult
$Res call({
 String content, String? category,@JsonKey(name: 'parent_id') String? parentId
});




}
/// @nodoc
class _$MessageCreateRequestCopyWithImpl<$Res>
    implements $MessageCreateRequestCopyWith<$Res> {
  _$MessageCreateRequestCopyWithImpl(this._self, this._then);

  final MessageCreateRequest _self;
  final $Res Function(MessageCreateRequest) _then;

/// Create a copy of MessageCreateRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? content = null,Object? category = freezed,Object? parentId = freezed,}) {
  return _then(_self.copyWith(
content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MessageCreateRequest].
extension MessageCreateRequestPatterns on MessageCreateRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageCreateRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageCreateRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageCreateRequest value)  $default,){
final _that = this;
switch (_that) {
case _MessageCreateRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageCreateRequest value)?  $default,){
final _that = this;
switch (_that) {
case _MessageCreateRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String content,  String? category, @JsonKey(name: 'parent_id')  String? parentId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageCreateRequest() when $default != null:
return $default(_that.content,_that.category,_that.parentId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String content,  String? category, @JsonKey(name: 'parent_id')  String? parentId)  $default,) {final _that = this;
switch (_that) {
case _MessageCreateRequest():
return $default(_that.content,_that.category,_that.parentId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String content,  String? category, @JsonKey(name: 'parent_id')  String? parentId)?  $default,) {final _that = this;
switch (_that) {
case _MessageCreateRequest() when $default != null:
return $default(_that.content,_that.category,_that.parentId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MessageCreateRequest implements MessageCreateRequest {
  const _MessageCreateRequest({required this.content, this.category, @JsonKey(name: 'parent_id') this.parentId});
  factory _MessageCreateRequest.fromJson(Map<String, dynamic> json) => _$MessageCreateRequestFromJson(json);

@override final  String content;
@override final  String? category;
@override@JsonKey(name: 'parent_id') final  String? parentId;

/// Create a copy of MessageCreateRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageCreateRequestCopyWith<_MessageCreateRequest> get copyWith => __$MessageCreateRequestCopyWithImpl<_MessageCreateRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageCreateRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageCreateRequest&&(identical(other.content, content) || other.content == content)&&(identical(other.category, category) || other.category == category)&&(identical(other.parentId, parentId) || other.parentId == parentId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,content,category,parentId);

@override
String toString() {
  return 'MessageCreateRequest(content: $content, category: $category, parentId: $parentId)';
}


}

/// @nodoc
abstract mixin class _$MessageCreateRequestCopyWith<$Res> implements $MessageCreateRequestCopyWith<$Res> {
  factory _$MessageCreateRequestCopyWith(_MessageCreateRequest value, $Res Function(_MessageCreateRequest) _then) = __$MessageCreateRequestCopyWithImpl;
@override @useResult
$Res call({
 String content, String? category,@JsonKey(name: 'parent_id') String? parentId
});




}
/// @nodoc
class __$MessageCreateRequestCopyWithImpl<$Res>
    implements _$MessageCreateRequestCopyWith<$Res> {
  __$MessageCreateRequestCopyWithImpl(this._self, this._then);

  final _MessageCreateRequest _self;
  final $Res Function(_MessageCreateRequest) _then;

/// Create a copy of MessageCreateRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? content = null,Object? category = freezed,Object? parentId = freezed,}) {
  return _then(_MessageCreateRequest(
content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
