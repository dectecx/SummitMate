// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group_event_comment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GroupEventComment {

 String get id; String get eventId; String get userId; String get content; String get userName; String get userAvatar; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of GroupEventComment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupEventCommentCopyWith<GroupEventComment> get copyWith => _$GroupEventCommentCopyWithImpl<GroupEventComment>(this as GroupEventComment, _$identity);

  /// Serializes this GroupEventComment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupEventComment&&(identical(other.id, id) || other.id == id)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.content, content) || other.content == content)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.userAvatar, userAvatar) || other.userAvatar == userAvatar)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,eventId,userId,content,userName,userAvatar,createdAt,updatedAt);

@override
String toString() {
  return 'GroupEventComment(id: $id, eventId: $eventId, userId: $userId, content: $content, userName: $userName, userAvatar: $userAvatar, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $GroupEventCommentCopyWith<$Res>  {
  factory $GroupEventCommentCopyWith(GroupEventComment value, $Res Function(GroupEventComment) _then) = _$GroupEventCommentCopyWithImpl;
@useResult
$Res call({
 String id, String eventId, String userId, String content, String userName, String userAvatar, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$GroupEventCommentCopyWithImpl<$Res>
    implements $GroupEventCommentCopyWith<$Res> {
  _$GroupEventCommentCopyWithImpl(this._self, this._then);

  final GroupEventComment _self;
  final $Res Function(GroupEventComment) _then;

/// Create a copy of GroupEventComment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? eventId = null,Object? userId = null,Object? content = null,Object? userName = null,Object? userAvatar = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,userAvatar: null == userAvatar ? _self.userAvatar : userAvatar // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupEventComment].
extension GroupEventCommentPatterns on GroupEventComment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupEventComment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupEventComment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupEventComment value)  $default,){
final _that = this;
switch (_that) {
case _GroupEventComment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupEventComment value)?  $default,){
final _that = this;
switch (_that) {
case _GroupEventComment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String eventId,  String userId,  String content,  String userName,  String userAvatar,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupEventComment() when $default != null:
return $default(_that.id,_that.eventId,_that.userId,_that.content,_that.userName,_that.userAvatar,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String eventId,  String userId,  String content,  String userName,  String userAvatar,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _GroupEventComment():
return $default(_that.id,_that.eventId,_that.userId,_that.content,_that.userName,_that.userAvatar,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String eventId,  String userId,  String content,  String userName,  String userAvatar,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _GroupEventComment() when $default != null:
return $default(_that.id,_that.eventId,_that.userId,_that.content,_that.userName,_that.userAvatar,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroupEventComment implements GroupEventComment {
  const _GroupEventComment({required this.id, required this.eventId, required this.userId, required this.content, required this.userName, required this.userAvatar, required this.createdAt, required this.updatedAt});
  factory _GroupEventComment.fromJson(Map<String, dynamic> json) => _$GroupEventCommentFromJson(json);

@override final  String id;
@override final  String eventId;
@override final  String userId;
@override final  String content;
@override final  String userName;
@override final  String userAvatar;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of GroupEventComment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupEventCommentCopyWith<_GroupEventComment> get copyWith => __$GroupEventCommentCopyWithImpl<_GroupEventComment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroupEventCommentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupEventComment&&(identical(other.id, id) || other.id == id)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.content, content) || other.content == content)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.userAvatar, userAvatar) || other.userAvatar == userAvatar)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,eventId,userId,content,userName,userAvatar,createdAt,updatedAt);

@override
String toString() {
  return 'GroupEventComment(id: $id, eventId: $eventId, userId: $userId, content: $content, userName: $userName, userAvatar: $userAvatar, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$GroupEventCommentCopyWith<$Res> implements $GroupEventCommentCopyWith<$Res> {
  factory _$GroupEventCommentCopyWith(_GroupEventComment value, $Res Function(_GroupEventComment) _then) = __$GroupEventCommentCopyWithImpl;
@override @useResult
$Res call({
 String id, String eventId, String userId, String content, String userName, String userAvatar, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$GroupEventCommentCopyWithImpl<$Res>
    implements _$GroupEventCommentCopyWith<$Res> {
  __$GroupEventCommentCopyWithImpl(this._self, this._then);

  final _GroupEventComment _self;
  final $Res Function(_GroupEventComment) _then;

/// Create a copy of GroupEventComment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? eventId = null,Object? userId = null,Object? content = null,Object? userName = null,Object? userAvatar = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_GroupEventComment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,userAvatar: null == userAvatar ? _self.userAvatar : userAvatar // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
