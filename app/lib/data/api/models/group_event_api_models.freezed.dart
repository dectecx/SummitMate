// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group_event_api_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GroupEventPaginationResponse {

 List<GroupEventResponse> get items; PaginationMetadata get pagination;
/// Create a copy of GroupEventPaginationResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupEventPaginationResponseCopyWith<GroupEventPaginationResponse> get copyWith => _$GroupEventPaginationResponseCopyWithImpl<GroupEventPaginationResponse>(this as GroupEventPaginationResponse, _$identity);

  /// Serializes this GroupEventPaginationResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupEventPaginationResponse&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.pagination, pagination) || other.pagination == pagination));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),pagination);

@override
String toString() {
  return 'GroupEventPaginationResponse(items: $items, pagination: $pagination)';
}


}

/// @nodoc
abstract mixin class $GroupEventPaginationResponseCopyWith<$Res>  {
  factory $GroupEventPaginationResponseCopyWith(GroupEventPaginationResponse value, $Res Function(GroupEventPaginationResponse) _then) = _$GroupEventPaginationResponseCopyWithImpl;
@useResult
$Res call({
 List<GroupEventResponse> items, PaginationMetadata pagination
});


$PaginationMetadataCopyWith<$Res> get pagination;

}
/// @nodoc
class _$GroupEventPaginationResponseCopyWithImpl<$Res>
    implements $GroupEventPaginationResponseCopyWith<$Res> {
  _$GroupEventPaginationResponseCopyWithImpl(this._self, this._then);

  final GroupEventPaginationResponse _self;
  final $Res Function(GroupEventPaginationResponse) _then;

/// Create a copy of GroupEventPaginationResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? pagination = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<GroupEventResponse>,pagination: null == pagination ? _self.pagination : pagination // ignore: cast_nullable_to_non_nullable
as PaginationMetadata,
  ));
}
/// Create a copy of GroupEventPaginationResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaginationMetadataCopyWith<$Res> get pagination {
  
  return $PaginationMetadataCopyWith<$Res>(_self.pagination, (value) {
    return _then(_self.copyWith(pagination: value));
  });
}
}


/// Adds pattern-matching-related methods to [GroupEventPaginationResponse].
extension GroupEventPaginationResponsePatterns on GroupEventPaginationResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupEventPaginationResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupEventPaginationResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupEventPaginationResponse value)  $default,){
final _that = this;
switch (_that) {
case _GroupEventPaginationResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupEventPaginationResponse value)?  $default,){
final _that = this;
switch (_that) {
case _GroupEventPaginationResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<GroupEventResponse> items,  PaginationMetadata pagination)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupEventPaginationResponse() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<GroupEventResponse> items,  PaginationMetadata pagination)  $default,) {final _that = this;
switch (_that) {
case _GroupEventPaginationResponse():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<GroupEventResponse> items,  PaginationMetadata pagination)?  $default,) {final _that = this;
switch (_that) {
case _GroupEventPaginationResponse() when $default != null:
return $default(_that.items,_that.pagination);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroupEventPaginationResponse implements GroupEventPaginationResponse {
  const _GroupEventPaginationResponse({required final  List<GroupEventResponse> items, required this.pagination}): _items = items;
  factory _GroupEventPaginationResponse.fromJson(Map<String, dynamic> json) => _$GroupEventPaginationResponseFromJson(json);

 final  List<GroupEventResponse> _items;
@override List<GroupEventResponse> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  PaginationMetadata pagination;

/// Create a copy of GroupEventPaginationResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupEventPaginationResponseCopyWith<_GroupEventPaginationResponse> get copyWith => __$GroupEventPaginationResponseCopyWithImpl<_GroupEventPaginationResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroupEventPaginationResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupEventPaginationResponse&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.pagination, pagination) || other.pagination == pagination));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),pagination);

@override
String toString() {
  return 'GroupEventPaginationResponse(items: $items, pagination: $pagination)';
}


}

/// @nodoc
abstract mixin class _$GroupEventPaginationResponseCopyWith<$Res> implements $GroupEventPaginationResponseCopyWith<$Res> {
  factory _$GroupEventPaginationResponseCopyWith(_GroupEventPaginationResponse value, $Res Function(_GroupEventPaginationResponse) _then) = __$GroupEventPaginationResponseCopyWithImpl;
@override @useResult
$Res call({
 List<GroupEventResponse> items, PaginationMetadata pagination
});


@override $PaginationMetadataCopyWith<$Res> get pagination;

}
/// @nodoc
class __$GroupEventPaginationResponseCopyWithImpl<$Res>
    implements _$GroupEventPaginationResponseCopyWith<$Res> {
  __$GroupEventPaginationResponseCopyWithImpl(this._self, this._then);

  final _GroupEventPaginationResponse _self;
  final $Res Function(_GroupEventPaginationResponse) _then;

/// Create a copy of GroupEventPaginationResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? pagination = null,}) {
  return _then(_GroupEventPaginationResponse(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<GroupEventResponse>,pagination: null == pagination ? _self.pagination : pagination // ignore: cast_nullable_to_non_nullable
as PaginationMetadata,
  ));
}

/// Create a copy of GroupEventPaginationResponse
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
mixin _$GroupEventResponse {

 String get id;@JsonKey(name: 'creator_id') String get creatorId; String get title;@JsonKey(defaultValue: '') String get description;@JsonKey(defaultValue: GroupEventCategory.other) GroupEventCategory get category;@JsonKey(defaultValue: '') String get location;@JsonKey(name: 'start_date') DateTime get startDate;@JsonKey(name: 'end_date') DateTime? get endDate;@JsonKey(defaultValue: 'open') String get status;@JsonKey(name: 'max_members', defaultValue: 10) int get maxMembers;@JsonKey(name: 'application_count', defaultValue: 0) int get applicationCount;@JsonKey(name: 'total_application_count', defaultValue: 0) int get totalApplicationCount;@JsonKey(name: 'approval_required', defaultValue: false) bool get approvalRequired;@JsonKey(name: 'private_message', defaultValue: '') String get privateMessage;@JsonKey(name: 'linked_trip_id') String? get linkedTripId;@JsonKey(name: 'like_count', defaultValue: 0) int get likeCount;@JsonKey(name: 'comment_count', defaultValue: 0) int get commentCount;@JsonKey(name: 'is_liked', defaultValue: false) bool get isLiked;@JsonKey(name: 'my_application_status') String? get myApplicationStatus;@JsonKey(name: 'creator_name', defaultValue: '') String get creatorName;@JsonKey(name: 'creator_avatar', defaultValue: '🐻') String get creatorAvatar;@JsonKey(name: 'latest_comments', defaultValue: []) List<GroupEventCommentResponse> get latestComments;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'created_by') String get createdBy;@JsonKey(name: 'updated_at') DateTime get updatedAt;@JsonKey(name: 'updated_by') String get updatedBy;
/// Create a copy of GroupEventResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupEventResponseCopyWith<GroupEventResponse> get copyWith => _$GroupEventResponseCopyWithImpl<GroupEventResponse>(this as GroupEventResponse, _$identity);

  /// Serializes this GroupEventResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupEventResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.creatorId, creatorId) || other.creatorId == creatorId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.location, location) || other.location == location)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.maxMembers, maxMembers) || other.maxMembers == maxMembers)&&(identical(other.applicationCount, applicationCount) || other.applicationCount == applicationCount)&&(identical(other.totalApplicationCount, totalApplicationCount) || other.totalApplicationCount == totalApplicationCount)&&(identical(other.approvalRequired, approvalRequired) || other.approvalRequired == approvalRequired)&&(identical(other.privateMessage, privateMessage) || other.privateMessage == privateMessage)&&(identical(other.linkedTripId, linkedTripId) || other.linkedTripId == linkedTripId)&&(identical(other.likeCount, likeCount) || other.likeCount == likeCount)&&(identical(other.commentCount, commentCount) || other.commentCount == commentCount)&&(identical(other.isLiked, isLiked) || other.isLiked == isLiked)&&(identical(other.myApplicationStatus, myApplicationStatus) || other.myApplicationStatus == myApplicationStatus)&&(identical(other.creatorName, creatorName) || other.creatorName == creatorName)&&(identical(other.creatorAvatar, creatorAvatar) || other.creatorAvatar == creatorAvatar)&&const DeepCollectionEquality().equals(other.latestComments, latestComments)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,creatorId,title,description,category,location,startDate,endDate,status,maxMembers,applicationCount,totalApplicationCount,approvalRequired,privateMessage,linkedTripId,likeCount,commentCount,isLiked,myApplicationStatus,creatorName,creatorAvatar,const DeepCollectionEquality().hash(latestComments),createdAt,createdBy,updatedAt,updatedBy]);

@override
String toString() {
  return 'GroupEventResponse(id: $id, creatorId: $creatorId, title: $title, description: $description, category: $category, location: $location, startDate: $startDate, endDate: $endDate, status: $status, maxMembers: $maxMembers, applicationCount: $applicationCount, totalApplicationCount: $totalApplicationCount, approvalRequired: $approvalRequired, privateMessage: $privateMessage, linkedTripId: $linkedTripId, likeCount: $likeCount, commentCount: $commentCount, isLiked: $isLiked, myApplicationStatus: $myApplicationStatus, creatorName: $creatorName, creatorAvatar: $creatorAvatar, latestComments: $latestComments, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy)';
}


}

/// @nodoc
abstract mixin class $GroupEventResponseCopyWith<$Res>  {
  factory $GroupEventResponseCopyWith(GroupEventResponse value, $Res Function(GroupEventResponse) _then) = _$GroupEventResponseCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'creator_id') String creatorId, String title,@JsonKey(defaultValue: '') String description,@JsonKey(defaultValue: GroupEventCategory.other) GroupEventCategory category,@JsonKey(defaultValue: '') String location,@JsonKey(name: 'start_date') DateTime startDate,@JsonKey(name: 'end_date') DateTime? endDate,@JsonKey(defaultValue: 'open') String status,@JsonKey(name: 'max_members', defaultValue: 10) int maxMembers,@JsonKey(name: 'application_count', defaultValue: 0) int applicationCount,@JsonKey(name: 'total_application_count', defaultValue: 0) int totalApplicationCount,@JsonKey(name: 'approval_required', defaultValue: false) bool approvalRequired,@JsonKey(name: 'private_message', defaultValue: '') String privateMessage,@JsonKey(name: 'linked_trip_id') String? linkedTripId,@JsonKey(name: 'like_count', defaultValue: 0) int likeCount,@JsonKey(name: 'comment_count', defaultValue: 0) int commentCount,@JsonKey(name: 'is_liked', defaultValue: false) bool isLiked,@JsonKey(name: 'my_application_status') String? myApplicationStatus,@JsonKey(name: 'creator_name', defaultValue: '') String creatorName,@JsonKey(name: 'creator_avatar', defaultValue: '🐻') String creatorAvatar,@JsonKey(name: 'latest_comments', defaultValue: []) List<GroupEventCommentResponse> latestComments,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'created_by') String createdBy,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'updated_by') String updatedBy
});




}
/// @nodoc
class _$GroupEventResponseCopyWithImpl<$Res>
    implements $GroupEventResponseCopyWith<$Res> {
  _$GroupEventResponseCopyWithImpl(this._self, this._then);

  final GroupEventResponse _self;
  final $Res Function(GroupEventResponse) _then;

/// Create a copy of GroupEventResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? creatorId = null,Object? title = null,Object? description = null,Object? category = null,Object? location = null,Object? startDate = null,Object? endDate = freezed,Object? status = null,Object? maxMembers = null,Object? applicationCount = null,Object? totalApplicationCount = null,Object? approvalRequired = null,Object? privateMessage = null,Object? linkedTripId = freezed,Object? likeCount = null,Object? commentCount = null,Object? isLiked = null,Object? myApplicationStatus = freezed,Object? creatorName = null,Object? creatorAvatar = null,Object? latestComments = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,creatorId: null == creatorId ? _self.creatorId : creatorId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as GroupEventCategory,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,maxMembers: null == maxMembers ? _self.maxMembers : maxMembers // ignore: cast_nullable_to_non_nullable
as int,applicationCount: null == applicationCount ? _self.applicationCount : applicationCount // ignore: cast_nullable_to_non_nullable
as int,totalApplicationCount: null == totalApplicationCount ? _self.totalApplicationCount : totalApplicationCount // ignore: cast_nullable_to_non_nullable
as int,approvalRequired: null == approvalRequired ? _self.approvalRequired : approvalRequired // ignore: cast_nullable_to_non_nullable
as bool,privateMessage: null == privateMessage ? _self.privateMessage : privateMessage // ignore: cast_nullable_to_non_nullable
as String,linkedTripId: freezed == linkedTripId ? _self.linkedTripId : linkedTripId // ignore: cast_nullable_to_non_nullable
as String?,likeCount: null == likeCount ? _self.likeCount : likeCount // ignore: cast_nullable_to_non_nullable
as int,commentCount: null == commentCount ? _self.commentCount : commentCount // ignore: cast_nullable_to_non_nullable
as int,isLiked: null == isLiked ? _self.isLiked : isLiked // ignore: cast_nullable_to_non_nullable
as bool,myApplicationStatus: freezed == myApplicationStatus ? _self.myApplicationStatus : myApplicationStatus // ignore: cast_nullable_to_non_nullable
as String?,creatorName: null == creatorName ? _self.creatorName : creatorName // ignore: cast_nullable_to_non_nullable
as String,creatorAvatar: null == creatorAvatar ? _self.creatorAvatar : creatorAvatar // ignore: cast_nullable_to_non_nullable
as String,latestComments: null == latestComments ? _self.latestComments : latestComments // ignore: cast_nullable_to_non_nullable
as List<GroupEventCommentResponse>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupEventResponse].
extension GroupEventResponsePatterns on GroupEventResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupEventResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupEventResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupEventResponse value)  $default,){
final _that = this;
switch (_that) {
case _GroupEventResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupEventResponse value)?  $default,){
final _that = this;
switch (_that) {
case _GroupEventResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'creator_id')  String creatorId,  String title, @JsonKey(defaultValue: '')  String description, @JsonKey(defaultValue: GroupEventCategory.other)  GroupEventCategory category, @JsonKey(defaultValue: '')  String location, @JsonKey(name: 'start_date')  DateTime startDate, @JsonKey(name: 'end_date')  DateTime? endDate, @JsonKey(defaultValue: 'open')  String status, @JsonKey(name: 'max_members', defaultValue: 10)  int maxMembers, @JsonKey(name: 'application_count', defaultValue: 0)  int applicationCount, @JsonKey(name: 'total_application_count', defaultValue: 0)  int totalApplicationCount, @JsonKey(name: 'approval_required', defaultValue: false)  bool approvalRequired, @JsonKey(name: 'private_message', defaultValue: '')  String privateMessage, @JsonKey(name: 'linked_trip_id')  String? linkedTripId, @JsonKey(name: 'like_count', defaultValue: 0)  int likeCount, @JsonKey(name: 'comment_count', defaultValue: 0)  int commentCount, @JsonKey(name: 'is_liked', defaultValue: false)  bool isLiked, @JsonKey(name: 'my_application_status')  String? myApplicationStatus, @JsonKey(name: 'creator_name', defaultValue: '')  String creatorName, @JsonKey(name: 'creator_avatar', defaultValue: '🐻')  String creatorAvatar, @JsonKey(name: 'latest_comments', defaultValue: [])  List<GroupEventCommentResponse> latestComments, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'created_by')  String createdBy, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'updated_by')  String updatedBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupEventResponse() when $default != null:
return $default(_that.id,_that.creatorId,_that.title,_that.description,_that.category,_that.location,_that.startDate,_that.endDate,_that.status,_that.maxMembers,_that.applicationCount,_that.totalApplicationCount,_that.approvalRequired,_that.privateMessage,_that.linkedTripId,_that.likeCount,_that.commentCount,_that.isLiked,_that.myApplicationStatus,_that.creatorName,_that.creatorAvatar,_that.latestComments,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'creator_id')  String creatorId,  String title, @JsonKey(defaultValue: '')  String description, @JsonKey(defaultValue: GroupEventCategory.other)  GroupEventCategory category, @JsonKey(defaultValue: '')  String location, @JsonKey(name: 'start_date')  DateTime startDate, @JsonKey(name: 'end_date')  DateTime? endDate, @JsonKey(defaultValue: 'open')  String status, @JsonKey(name: 'max_members', defaultValue: 10)  int maxMembers, @JsonKey(name: 'application_count', defaultValue: 0)  int applicationCount, @JsonKey(name: 'total_application_count', defaultValue: 0)  int totalApplicationCount, @JsonKey(name: 'approval_required', defaultValue: false)  bool approvalRequired, @JsonKey(name: 'private_message', defaultValue: '')  String privateMessage, @JsonKey(name: 'linked_trip_id')  String? linkedTripId, @JsonKey(name: 'like_count', defaultValue: 0)  int likeCount, @JsonKey(name: 'comment_count', defaultValue: 0)  int commentCount, @JsonKey(name: 'is_liked', defaultValue: false)  bool isLiked, @JsonKey(name: 'my_application_status')  String? myApplicationStatus, @JsonKey(name: 'creator_name', defaultValue: '')  String creatorName, @JsonKey(name: 'creator_avatar', defaultValue: '🐻')  String creatorAvatar, @JsonKey(name: 'latest_comments', defaultValue: [])  List<GroupEventCommentResponse> latestComments, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'created_by')  String createdBy, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'updated_by')  String updatedBy)  $default,) {final _that = this;
switch (_that) {
case _GroupEventResponse():
return $default(_that.id,_that.creatorId,_that.title,_that.description,_that.category,_that.location,_that.startDate,_that.endDate,_that.status,_that.maxMembers,_that.applicationCount,_that.totalApplicationCount,_that.approvalRequired,_that.privateMessage,_that.linkedTripId,_that.likeCount,_that.commentCount,_that.isLiked,_that.myApplicationStatus,_that.creatorName,_that.creatorAvatar,_that.latestComments,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'creator_id')  String creatorId,  String title, @JsonKey(defaultValue: '')  String description, @JsonKey(defaultValue: GroupEventCategory.other)  GroupEventCategory category, @JsonKey(defaultValue: '')  String location, @JsonKey(name: 'start_date')  DateTime startDate, @JsonKey(name: 'end_date')  DateTime? endDate, @JsonKey(defaultValue: 'open')  String status, @JsonKey(name: 'max_members', defaultValue: 10)  int maxMembers, @JsonKey(name: 'application_count', defaultValue: 0)  int applicationCount, @JsonKey(name: 'total_application_count', defaultValue: 0)  int totalApplicationCount, @JsonKey(name: 'approval_required', defaultValue: false)  bool approvalRequired, @JsonKey(name: 'private_message', defaultValue: '')  String privateMessage, @JsonKey(name: 'linked_trip_id')  String? linkedTripId, @JsonKey(name: 'like_count', defaultValue: 0)  int likeCount, @JsonKey(name: 'comment_count', defaultValue: 0)  int commentCount, @JsonKey(name: 'is_liked', defaultValue: false)  bool isLiked, @JsonKey(name: 'my_application_status')  String? myApplicationStatus, @JsonKey(name: 'creator_name', defaultValue: '')  String creatorName, @JsonKey(name: 'creator_avatar', defaultValue: '🐻')  String creatorAvatar, @JsonKey(name: 'latest_comments', defaultValue: [])  List<GroupEventCommentResponse> latestComments, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'created_by')  String createdBy, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'updated_by')  String updatedBy)?  $default,) {final _that = this;
switch (_that) {
case _GroupEventResponse() when $default != null:
return $default(_that.id,_that.creatorId,_that.title,_that.description,_that.category,_that.location,_that.startDate,_that.endDate,_that.status,_that.maxMembers,_that.applicationCount,_that.totalApplicationCount,_that.approvalRequired,_that.privateMessage,_that.linkedTripId,_that.likeCount,_that.commentCount,_that.isLiked,_that.myApplicationStatus,_that.creatorName,_that.creatorAvatar,_that.latestComments,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroupEventResponse implements GroupEventResponse {
  const _GroupEventResponse({required this.id, @JsonKey(name: 'creator_id') required this.creatorId, required this.title, @JsonKey(defaultValue: '') required this.description, @JsonKey(defaultValue: GroupEventCategory.other) required this.category, @JsonKey(defaultValue: '') required this.location, @JsonKey(name: 'start_date') required this.startDate, @JsonKey(name: 'end_date') this.endDate, @JsonKey(defaultValue: 'open') required this.status, @JsonKey(name: 'max_members', defaultValue: 10) required this.maxMembers, @JsonKey(name: 'application_count', defaultValue: 0) required this.applicationCount, @JsonKey(name: 'total_application_count', defaultValue: 0) required this.totalApplicationCount, @JsonKey(name: 'approval_required', defaultValue: false) required this.approvalRequired, @JsonKey(name: 'private_message', defaultValue: '') required this.privateMessage, @JsonKey(name: 'linked_trip_id') this.linkedTripId, @JsonKey(name: 'like_count', defaultValue: 0) required this.likeCount, @JsonKey(name: 'comment_count', defaultValue: 0) required this.commentCount, @JsonKey(name: 'is_liked', defaultValue: false) required this.isLiked, @JsonKey(name: 'my_application_status') this.myApplicationStatus, @JsonKey(name: 'creator_name', defaultValue: '') required this.creatorName, @JsonKey(name: 'creator_avatar', defaultValue: '🐻') required this.creatorAvatar, @JsonKey(name: 'latest_comments', defaultValue: []) required final  List<GroupEventCommentResponse> latestComments, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'created_by') required this.createdBy, @JsonKey(name: 'updated_at') required this.updatedAt, @JsonKey(name: 'updated_by') required this.updatedBy}): _latestComments = latestComments;
  factory _GroupEventResponse.fromJson(Map<String, dynamic> json) => _$GroupEventResponseFromJson(json);

@override final  String id;
@override@JsonKey(name: 'creator_id') final  String creatorId;
@override final  String title;
@override@JsonKey(defaultValue: '') final  String description;
@override@JsonKey(defaultValue: GroupEventCategory.other) final  GroupEventCategory category;
@override@JsonKey(defaultValue: '') final  String location;
@override@JsonKey(name: 'start_date') final  DateTime startDate;
@override@JsonKey(name: 'end_date') final  DateTime? endDate;
@override@JsonKey(defaultValue: 'open') final  String status;
@override@JsonKey(name: 'max_members', defaultValue: 10) final  int maxMembers;
@override@JsonKey(name: 'application_count', defaultValue: 0) final  int applicationCount;
@override@JsonKey(name: 'total_application_count', defaultValue: 0) final  int totalApplicationCount;
@override@JsonKey(name: 'approval_required', defaultValue: false) final  bool approvalRequired;
@override@JsonKey(name: 'private_message', defaultValue: '') final  String privateMessage;
@override@JsonKey(name: 'linked_trip_id') final  String? linkedTripId;
@override@JsonKey(name: 'like_count', defaultValue: 0) final  int likeCount;
@override@JsonKey(name: 'comment_count', defaultValue: 0) final  int commentCount;
@override@JsonKey(name: 'is_liked', defaultValue: false) final  bool isLiked;
@override@JsonKey(name: 'my_application_status') final  String? myApplicationStatus;
@override@JsonKey(name: 'creator_name', defaultValue: '') final  String creatorName;
@override@JsonKey(name: 'creator_avatar', defaultValue: '🐻') final  String creatorAvatar;
 final  List<GroupEventCommentResponse> _latestComments;
@override@JsonKey(name: 'latest_comments', defaultValue: []) List<GroupEventCommentResponse> get latestComments {
  if (_latestComments is EqualUnmodifiableListView) return _latestComments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_latestComments);
}

@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'created_by') final  String createdBy;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;
@override@JsonKey(name: 'updated_by') final  String updatedBy;

/// Create a copy of GroupEventResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupEventResponseCopyWith<_GroupEventResponse> get copyWith => __$GroupEventResponseCopyWithImpl<_GroupEventResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroupEventResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupEventResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.creatorId, creatorId) || other.creatorId == creatorId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.location, location) || other.location == location)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.maxMembers, maxMembers) || other.maxMembers == maxMembers)&&(identical(other.applicationCount, applicationCount) || other.applicationCount == applicationCount)&&(identical(other.totalApplicationCount, totalApplicationCount) || other.totalApplicationCount == totalApplicationCount)&&(identical(other.approvalRequired, approvalRequired) || other.approvalRequired == approvalRequired)&&(identical(other.privateMessage, privateMessage) || other.privateMessage == privateMessage)&&(identical(other.linkedTripId, linkedTripId) || other.linkedTripId == linkedTripId)&&(identical(other.likeCount, likeCount) || other.likeCount == likeCount)&&(identical(other.commentCount, commentCount) || other.commentCount == commentCount)&&(identical(other.isLiked, isLiked) || other.isLiked == isLiked)&&(identical(other.myApplicationStatus, myApplicationStatus) || other.myApplicationStatus == myApplicationStatus)&&(identical(other.creatorName, creatorName) || other.creatorName == creatorName)&&(identical(other.creatorAvatar, creatorAvatar) || other.creatorAvatar == creatorAvatar)&&const DeepCollectionEquality().equals(other._latestComments, _latestComments)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,creatorId,title,description,category,location,startDate,endDate,status,maxMembers,applicationCount,totalApplicationCount,approvalRequired,privateMessage,linkedTripId,likeCount,commentCount,isLiked,myApplicationStatus,creatorName,creatorAvatar,const DeepCollectionEquality().hash(_latestComments),createdAt,createdBy,updatedAt,updatedBy]);

@override
String toString() {
  return 'GroupEventResponse(id: $id, creatorId: $creatorId, title: $title, description: $description, category: $category, location: $location, startDate: $startDate, endDate: $endDate, status: $status, maxMembers: $maxMembers, applicationCount: $applicationCount, totalApplicationCount: $totalApplicationCount, approvalRequired: $approvalRequired, privateMessage: $privateMessage, linkedTripId: $linkedTripId, likeCount: $likeCount, commentCount: $commentCount, isLiked: $isLiked, myApplicationStatus: $myApplicationStatus, creatorName: $creatorName, creatorAvatar: $creatorAvatar, latestComments: $latestComments, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy)';
}


}

/// @nodoc
abstract mixin class _$GroupEventResponseCopyWith<$Res> implements $GroupEventResponseCopyWith<$Res> {
  factory _$GroupEventResponseCopyWith(_GroupEventResponse value, $Res Function(_GroupEventResponse) _then) = __$GroupEventResponseCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'creator_id') String creatorId, String title,@JsonKey(defaultValue: '') String description,@JsonKey(defaultValue: GroupEventCategory.other) GroupEventCategory category,@JsonKey(defaultValue: '') String location,@JsonKey(name: 'start_date') DateTime startDate,@JsonKey(name: 'end_date') DateTime? endDate,@JsonKey(defaultValue: 'open') String status,@JsonKey(name: 'max_members', defaultValue: 10) int maxMembers,@JsonKey(name: 'application_count', defaultValue: 0) int applicationCount,@JsonKey(name: 'total_application_count', defaultValue: 0) int totalApplicationCount,@JsonKey(name: 'approval_required', defaultValue: false) bool approvalRequired,@JsonKey(name: 'private_message', defaultValue: '') String privateMessage,@JsonKey(name: 'linked_trip_id') String? linkedTripId,@JsonKey(name: 'like_count', defaultValue: 0) int likeCount,@JsonKey(name: 'comment_count', defaultValue: 0) int commentCount,@JsonKey(name: 'is_liked', defaultValue: false) bool isLiked,@JsonKey(name: 'my_application_status') String? myApplicationStatus,@JsonKey(name: 'creator_name', defaultValue: '') String creatorName,@JsonKey(name: 'creator_avatar', defaultValue: '🐻') String creatorAvatar,@JsonKey(name: 'latest_comments', defaultValue: []) List<GroupEventCommentResponse> latestComments,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'created_by') String createdBy,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'updated_by') String updatedBy
});




}
/// @nodoc
class __$GroupEventResponseCopyWithImpl<$Res>
    implements _$GroupEventResponseCopyWith<$Res> {
  __$GroupEventResponseCopyWithImpl(this._self, this._then);

  final _GroupEventResponse _self;
  final $Res Function(_GroupEventResponse) _then;

/// Create a copy of GroupEventResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? creatorId = null,Object? title = null,Object? description = null,Object? category = null,Object? location = null,Object? startDate = null,Object? endDate = freezed,Object? status = null,Object? maxMembers = null,Object? applicationCount = null,Object? totalApplicationCount = null,Object? approvalRequired = null,Object? privateMessage = null,Object? linkedTripId = freezed,Object? likeCount = null,Object? commentCount = null,Object? isLiked = null,Object? myApplicationStatus = freezed,Object? creatorName = null,Object? creatorAvatar = null,Object? latestComments = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,}) {
  return _then(_GroupEventResponse(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,creatorId: null == creatorId ? _self.creatorId : creatorId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as GroupEventCategory,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,maxMembers: null == maxMembers ? _self.maxMembers : maxMembers // ignore: cast_nullable_to_non_nullable
as int,applicationCount: null == applicationCount ? _self.applicationCount : applicationCount // ignore: cast_nullable_to_non_nullable
as int,totalApplicationCount: null == totalApplicationCount ? _self.totalApplicationCount : totalApplicationCount // ignore: cast_nullable_to_non_nullable
as int,approvalRequired: null == approvalRequired ? _self.approvalRequired : approvalRequired // ignore: cast_nullable_to_non_nullable
as bool,privateMessage: null == privateMessage ? _self.privateMessage : privateMessage // ignore: cast_nullable_to_non_nullable
as String,linkedTripId: freezed == linkedTripId ? _self.linkedTripId : linkedTripId // ignore: cast_nullable_to_non_nullable
as String?,likeCount: null == likeCount ? _self.likeCount : likeCount // ignore: cast_nullable_to_non_nullable
as int,commentCount: null == commentCount ? _self.commentCount : commentCount // ignore: cast_nullable_to_non_nullable
as int,isLiked: null == isLiked ? _self.isLiked : isLiked // ignore: cast_nullable_to_non_nullable
as bool,myApplicationStatus: freezed == myApplicationStatus ? _self.myApplicationStatus : myApplicationStatus // ignore: cast_nullable_to_non_nullable
as String?,creatorName: null == creatorName ? _self.creatorName : creatorName // ignore: cast_nullable_to_non_nullable
as String,creatorAvatar: null == creatorAvatar ? _self.creatorAvatar : creatorAvatar // ignore: cast_nullable_to_non_nullable
as String,latestComments: null == latestComments ? _self._latestComments : latestComments // ignore: cast_nullable_to_non_nullable
as List<GroupEventCommentResponse>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$GroupEventApplicationResponse {

 String get id;@JsonKey(name: 'event_id') String get eventId;@JsonKey(name: 'user_id') String get userId;@JsonKey(defaultValue: 'pending') String get status;@JsonKey(defaultValue: '') String get message;@JsonKey(name: 'user_name', defaultValue: '') String get userName;@JsonKey(name: 'user_avatar', defaultValue: '🐻') String get userAvatar;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime get updatedAt;@JsonKey(name: 'updated_by') String get updatedBy;
/// Create a copy of GroupEventApplicationResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupEventApplicationResponseCopyWith<GroupEventApplicationResponse> get copyWith => _$GroupEventApplicationResponseCopyWithImpl<GroupEventApplicationResponse>(this as GroupEventApplicationResponse, _$identity);

  /// Serializes this GroupEventApplicationResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupEventApplicationResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.status, status) || other.status == status)&&(identical(other.message, message) || other.message == message)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.userAvatar, userAvatar) || other.userAvatar == userAvatar)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,eventId,userId,status,message,userName,userAvatar,createdAt,updatedAt,updatedBy);

@override
String toString() {
  return 'GroupEventApplicationResponse(id: $id, eventId: $eventId, userId: $userId, status: $status, message: $message, userName: $userName, userAvatar: $userAvatar, createdAt: $createdAt, updatedAt: $updatedAt, updatedBy: $updatedBy)';
}


}

/// @nodoc
abstract mixin class $GroupEventApplicationResponseCopyWith<$Res>  {
  factory $GroupEventApplicationResponseCopyWith(GroupEventApplicationResponse value, $Res Function(GroupEventApplicationResponse) _then) = _$GroupEventApplicationResponseCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'event_id') String eventId,@JsonKey(name: 'user_id') String userId,@JsonKey(defaultValue: 'pending') String status,@JsonKey(defaultValue: '') String message,@JsonKey(name: 'user_name', defaultValue: '') String userName,@JsonKey(name: 'user_avatar', defaultValue: '🐻') String userAvatar,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'updated_by') String updatedBy
});




}
/// @nodoc
class _$GroupEventApplicationResponseCopyWithImpl<$Res>
    implements $GroupEventApplicationResponseCopyWith<$Res> {
  _$GroupEventApplicationResponseCopyWithImpl(this._self, this._then);

  final GroupEventApplicationResponse _self;
  final $Res Function(GroupEventApplicationResponse) _then;

/// Create a copy of GroupEventApplicationResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? eventId = null,Object? userId = null,Object? status = null,Object? message = null,Object? userName = null,Object? userAvatar = null,Object? createdAt = null,Object? updatedAt = null,Object? updatedBy = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,userAvatar: null == userAvatar ? _self.userAvatar : userAvatar // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupEventApplicationResponse].
extension GroupEventApplicationResponsePatterns on GroupEventApplicationResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupEventApplicationResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupEventApplicationResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupEventApplicationResponse value)  $default,){
final _that = this;
switch (_that) {
case _GroupEventApplicationResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupEventApplicationResponse value)?  $default,){
final _that = this;
switch (_that) {
case _GroupEventApplicationResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'event_id')  String eventId, @JsonKey(name: 'user_id')  String userId, @JsonKey(defaultValue: 'pending')  String status, @JsonKey(defaultValue: '')  String message, @JsonKey(name: 'user_name', defaultValue: '')  String userName, @JsonKey(name: 'user_avatar', defaultValue: '🐻')  String userAvatar, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'updated_by')  String updatedBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupEventApplicationResponse() when $default != null:
return $default(_that.id,_that.eventId,_that.userId,_that.status,_that.message,_that.userName,_that.userAvatar,_that.createdAt,_that.updatedAt,_that.updatedBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'event_id')  String eventId, @JsonKey(name: 'user_id')  String userId, @JsonKey(defaultValue: 'pending')  String status, @JsonKey(defaultValue: '')  String message, @JsonKey(name: 'user_name', defaultValue: '')  String userName, @JsonKey(name: 'user_avatar', defaultValue: '🐻')  String userAvatar, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'updated_by')  String updatedBy)  $default,) {final _that = this;
switch (_that) {
case _GroupEventApplicationResponse():
return $default(_that.id,_that.eventId,_that.userId,_that.status,_that.message,_that.userName,_that.userAvatar,_that.createdAt,_that.updatedAt,_that.updatedBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'event_id')  String eventId, @JsonKey(name: 'user_id')  String userId, @JsonKey(defaultValue: 'pending')  String status, @JsonKey(defaultValue: '')  String message, @JsonKey(name: 'user_name', defaultValue: '')  String userName, @JsonKey(name: 'user_avatar', defaultValue: '🐻')  String userAvatar, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'updated_by')  String updatedBy)?  $default,) {final _that = this;
switch (_that) {
case _GroupEventApplicationResponse() when $default != null:
return $default(_that.id,_that.eventId,_that.userId,_that.status,_that.message,_that.userName,_that.userAvatar,_that.createdAt,_that.updatedAt,_that.updatedBy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroupEventApplicationResponse implements GroupEventApplicationResponse {
  const _GroupEventApplicationResponse({required this.id, @JsonKey(name: 'event_id') required this.eventId, @JsonKey(name: 'user_id') required this.userId, @JsonKey(defaultValue: 'pending') required this.status, @JsonKey(defaultValue: '') required this.message, @JsonKey(name: 'user_name', defaultValue: '') required this.userName, @JsonKey(name: 'user_avatar', defaultValue: '🐻') required this.userAvatar, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt, @JsonKey(name: 'updated_by') required this.updatedBy});
  factory _GroupEventApplicationResponse.fromJson(Map<String, dynamic> json) => _$GroupEventApplicationResponseFromJson(json);

@override final  String id;
@override@JsonKey(name: 'event_id') final  String eventId;
@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey(defaultValue: 'pending') final  String status;
@override@JsonKey(defaultValue: '') final  String message;
@override@JsonKey(name: 'user_name', defaultValue: '') final  String userName;
@override@JsonKey(name: 'user_avatar', defaultValue: '🐻') final  String userAvatar;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;
@override@JsonKey(name: 'updated_by') final  String updatedBy;

/// Create a copy of GroupEventApplicationResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupEventApplicationResponseCopyWith<_GroupEventApplicationResponse> get copyWith => __$GroupEventApplicationResponseCopyWithImpl<_GroupEventApplicationResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroupEventApplicationResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupEventApplicationResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.status, status) || other.status == status)&&(identical(other.message, message) || other.message == message)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.userAvatar, userAvatar) || other.userAvatar == userAvatar)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,eventId,userId,status,message,userName,userAvatar,createdAt,updatedAt,updatedBy);

@override
String toString() {
  return 'GroupEventApplicationResponse(id: $id, eventId: $eventId, userId: $userId, status: $status, message: $message, userName: $userName, userAvatar: $userAvatar, createdAt: $createdAt, updatedAt: $updatedAt, updatedBy: $updatedBy)';
}


}

/// @nodoc
abstract mixin class _$GroupEventApplicationResponseCopyWith<$Res> implements $GroupEventApplicationResponseCopyWith<$Res> {
  factory _$GroupEventApplicationResponseCopyWith(_GroupEventApplicationResponse value, $Res Function(_GroupEventApplicationResponse) _then) = __$GroupEventApplicationResponseCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'event_id') String eventId,@JsonKey(name: 'user_id') String userId,@JsonKey(defaultValue: 'pending') String status,@JsonKey(defaultValue: '') String message,@JsonKey(name: 'user_name', defaultValue: '') String userName,@JsonKey(name: 'user_avatar', defaultValue: '🐻') String userAvatar,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'updated_by') String updatedBy
});




}
/// @nodoc
class __$GroupEventApplicationResponseCopyWithImpl<$Res>
    implements _$GroupEventApplicationResponseCopyWith<$Res> {
  __$GroupEventApplicationResponseCopyWithImpl(this._self, this._then);

  final _GroupEventApplicationResponse _self;
  final $Res Function(_GroupEventApplicationResponse) _then;

/// Create a copy of GroupEventApplicationResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? eventId = null,Object? userId = null,Object? status = null,Object? message = null,Object? userName = null,Object? userAvatar = null,Object? createdAt = null,Object? updatedAt = null,Object? updatedBy = null,}) {
  return _then(_GroupEventApplicationResponse(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,userAvatar: null == userAvatar ? _self.userAvatar : userAvatar // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$GroupEventCommentResponse {

 String get id;@JsonKey(name: 'event_id') String get eventId;@JsonKey(name: 'user_id') String get userId; String get content;@JsonKey(name: 'user_name', defaultValue: '') String get userName;@JsonKey(name: 'user_avatar', defaultValue: '🐻') String get userAvatar;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime get updatedAt;
/// Create a copy of GroupEventCommentResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupEventCommentResponseCopyWith<GroupEventCommentResponse> get copyWith => _$GroupEventCommentResponseCopyWithImpl<GroupEventCommentResponse>(this as GroupEventCommentResponse, _$identity);

  /// Serializes this GroupEventCommentResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupEventCommentResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.content, content) || other.content == content)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.userAvatar, userAvatar) || other.userAvatar == userAvatar)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,eventId,userId,content,userName,userAvatar,createdAt,updatedAt);

@override
String toString() {
  return 'GroupEventCommentResponse(id: $id, eventId: $eventId, userId: $userId, content: $content, userName: $userName, userAvatar: $userAvatar, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $GroupEventCommentResponseCopyWith<$Res>  {
  factory $GroupEventCommentResponseCopyWith(GroupEventCommentResponse value, $Res Function(GroupEventCommentResponse) _then) = _$GroupEventCommentResponseCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'event_id') String eventId,@JsonKey(name: 'user_id') String userId, String content,@JsonKey(name: 'user_name', defaultValue: '') String userName,@JsonKey(name: 'user_avatar', defaultValue: '🐻') String userAvatar,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt
});




}
/// @nodoc
class _$GroupEventCommentResponseCopyWithImpl<$Res>
    implements $GroupEventCommentResponseCopyWith<$Res> {
  _$GroupEventCommentResponseCopyWithImpl(this._self, this._then);

  final GroupEventCommentResponse _self;
  final $Res Function(GroupEventCommentResponse) _then;

/// Create a copy of GroupEventCommentResponse
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


/// Adds pattern-matching-related methods to [GroupEventCommentResponse].
extension GroupEventCommentResponsePatterns on GroupEventCommentResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupEventCommentResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupEventCommentResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupEventCommentResponse value)  $default,){
final _that = this;
switch (_that) {
case _GroupEventCommentResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupEventCommentResponse value)?  $default,){
final _that = this;
switch (_that) {
case _GroupEventCommentResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'event_id')  String eventId, @JsonKey(name: 'user_id')  String userId,  String content, @JsonKey(name: 'user_name', defaultValue: '')  String userName, @JsonKey(name: 'user_avatar', defaultValue: '🐻')  String userAvatar, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupEventCommentResponse() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'event_id')  String eventId, @JsonKey(name: 'user_id')  String userId,  String content, @JsonKey(name: 'user_name', defaultValue: '')  String userName, @JsonKey(name: 'user_avatar', defaultValue: '🐻')  String userAvatar, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _GroupEventCommentResponse():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'event_id')  String eventId, @JsonKey(name: 'user_id')  String userId,  String content, @JsonKey(name: 'user_name', defaultValue: '')  String userName, @JsonKey(name: 'user_avatar', defaultValue: '🐻')  String userAvatar, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _GroupEventCommentResponse() when $default != null:
return $default(_that.id,_that.eventId,_that.userId,_that.content,_that.userName,_that.userAvatar,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroupEventCommentResponse implements GroupEventCommentResponse {
  const _GroupEventCommentResponse({required this.id, @JsonKey(name: 'event_id') required this.eventId, @JsonKey(name: 'user_id') required this.userId, required this.content, @JsonKey(name: 'user_name', defaultValue: '') required this.userName, @JsonKey(name: 'user_avatar', defaultValue: '🐻') required this.userAvatar, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt});
  factory _GroupEventCommentResponse.fromJson(Map<String, dynamic> json) => _$GroupEventCommentResponseFromJson(json);

@override final  String id;
@override@JsonKey(name: 'event_id') final  String eventId;
@override@JsonKey(name: 'user_id') final  String userId;
@override final  String content;
@override@JsonKey(name: 'user_name', defaultValue: '') final  String userName;
@override@JsonKey(name: 'user_avatar', defaultValue: '🐻') final  String userAvatar;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;

/// Create a copy of GroupEventCommentResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupEventCommentResponseCopyWith<_GroupEventCommentResponse> get copyWith => __$GroupEventCommentResponseCopyWithImpl<_GroupEventCommentResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroupEventCommentResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupEventCommentResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.content, content) || other.content == content)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.userAvatar, userAvatar) || other.userAvatar == userAvatar)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,eventId,userId,content,userName,userAvatar,createdAt,updatedAt);

@override
String toString() {
  return 'GroupEventCommentResponse(id: $id, eventId: $eventId, userId: $userId, content: $content, userName: $userName, userAvatar: $userAvatar, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$GroupEventCommentResponseCopyWith<$Res> implements $GroupEventCommentResponseCopyWith<$Res> {
  factory _$GroupEventCommentResponseCopyWith(_GroupEventCommentResponse value, $Res Function(_GroupEventCommentResponse) _then) = __$GroupEventCommentResponseCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'event_id') String eventId,@JsonKey(name: 'user_id') String userId, String content,@JsonKey(name: 'user_name', defaultValue: '') String userName,@JsonKey(name: 'user_avatar', defaultValue: '🐻') String userAvatar,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt
});




}
/// @nodoc
class __$GroupEventCommentResponseCopyWithImpl<$Res>
    implements _$GroupEventCommentResponseCopyWith<$Res> {
  __$GroupEventCommentResponseCopyWithImpl(this._self, this._then);

  final _GroupEventCommentResponse _self;
  final $Res Function(_GroupEventCommentResponse) _then;

/// Create a copy of GroupEventCommentResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? eventId = null,Object? userId = null,Object? content = null,Object? userName = null,Object? userAvatar = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_GroupEventCommentResponse(
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


/// @nodoc
mixin _$GroupEventCreateRequest {

 String get title; String get description;@JsonKey(defaultValue: GroupEventCategory.other) GroupEventCategory get category; String get location;@JsonKey(name: 'start_date') DateTime get startDate;@JsonKey(name: 'end_date') DateTime? get endDate;@JsonKey(name: 'max_members', defaultValue: 10) int get maxMembers;@JsonKey(name: 'approval_required', defaultValue: false) bool get approvalRequired;@JsonKey(name: 'private_message') String? get privateMessage;@JsonKey(name: 'linked_trip_id') String? get linkedTripId;
/// Create a copy of GroupEventCreateRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupEventCreateRequestCopyWith<GroupEventCreateRequest> get copyWith => _$GroupEventCreateRequestCopyWithImpl<GroupEventCreateRequest>(this as GroupEventCreateRequest, _$identity);

  /// Serializes this GroupEventCreateRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupEventCreateRequest&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.location, location) || other.location == location)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.maxMembers, maxMembers) || other.maxMembers == maxMembers)&&(identical(other.approvalRequired, approvalRequired) || other.approvalRequired == approvalRequired)&&(identical(other.privateMessage, privateMessage) || other.privateMessage == privateMessage)&&(identical(other.linkedTripId, linkedTripId) || other.linkedTripId == linkedTripId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,description,category,location,startDate,endDate,maxMembers,approvalRequired,privateMessage,linkedTripId);

@override
String toString() {
  return 'GroupEventCreateRequest(title: $title, description: $description, category: $category, location: $location, startDate: $startDate, endDate: $endDate, maxMembers: $maxMembers, approvalRequired: $approvalRequired, privateMessage: $privateMessage, linkedTripId: $linkedTripId)';
}


}

/// @nodoc
abstract mixin class $GroupEventCreateRequestCopyWith<$Res>  {
  factory $GroupEventCreateRequestCopyWith(GroupEventCreateRequest value, $Res Function(GroupEventCreateRequest) _then) = _$GroupEventCreateRequestCopyWithImpl;
@useResult
$Res call({
 String title, String description,@JsonKey(defaultValue: GroupEventCategory.other) GroupEventCategory category, String location,@JsonKey(name: 'start_date') DateTime startDate,@JsonKey(name: 'end_date') DateTime? endDate,@JsonKey(name: 'max_members', defaultValue: 10) int maxMembers,@JsonKey(name: 'approval_required', defaultValue: false) bool approvalRequired,@JsonKey(name: 'private_message') String? privateMessage,@JsonKey(name: 'linked_trip_id') String? linkedTripId
});




}
/// @nodoc
class _$GroupEventCreateRequestCopyWithImpl<$Res>
    implements $GroupEventCreateRequestCopyWith<$Res> {
  _$GroupEventCreateRequestCopyWithImpl(this._self, this._then);

  final GroupEventCreateRequest _self;
  final $Res Function(GroupEventCreateRequest) _then;

/// Create a copy of GroupEventCreateRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? description = null,Object? category = null,Object? location = null,Object? startDate = null,Object? endDate = freezed,Object? maxMembers = null,Object? approvalRequired = null,Object? privateMessage = freezed,Object? linkedTripId = freezed,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as GroupEventCategory,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,maxMembers: null == maxMembers ? _self.maxMembers : maxMembers // ignore: cast_nullable_to_non_nullable
as int,approvalRequired: null == approvalRequired ? _self.approvalRequired : approvalRequired // ignore: cast_nullable_to_non_nullable
as bool,privateMessage: freezed == privateMessage ? _self.privateMessage : privateMessage // ignore: cast_nullable_to_non_nullable
as String?,linkedTripId: freezed == linkedTripId ? _self.linkedTripId : linkedTripId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupEventCreateRequest].
extension GroupEventCreateRequestPatterns on GroupEventCreateRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupEventCreateRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupEventCreateRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupEventCreateRequest value)  $default,){
final _that = this;
switch (_that) {
case _GroupEventCreateRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupEventCreateRequest value)?  $default,){
final _that = this;
switch (_that) {
case _GroupEventCreateRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String description, @JsonKey(defaultValue: GroupEventCategory.other)  GroupEventCategory category,  String location, @JsonKey(name: 'start_date')  DateTime startDate, @JsonKey(name: 'end_date')  DateTime? endDate, @JsonKey(name: 'max_members', defaultValue: 10)  int maxMembers, @JsonKey(name: 'approval_required', defaultValue: false)  bool approvalRequired, @JsonKey(name: 'private_message')  String? privateMessage, @JsonKey(name: 'linked_trip_id')  String? linkedTripId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupEventCreateRequest() when $default != null:
return $default(_that.title,_that.description,_that.category,_that.location,_that.startDate,_that.endDate,_that.maxMembers,_that.approvalRequired,_that.privateMessage,_that.linkedTripId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String description, @JsonKey(defaultValue: GroupEventCategory.other)  GroupEventCategory category,  String location, @JsonKey(name: 'start_date')  DateTime startDate, @JsonKey(name: 'end_date')  DateTime? endDate, @JsonKey(name: 'max_members', defaultValue: 10)  int maxMembers, @JsonKey(name: 'approval_required', defaultValue: false)  bool approvalRequired, @JsonKey(name: 'private_message')  String? privateMessage, @JsonKey(name: 'linked_trip_id')  String? linkedTripId)  $default,) {final _that = this;
switch (_that) {
case _GroupEventCreateRequest():
return $default(_that.title,_that.description,_that.category,_that.location,_that.startDate,_that.endDate,_that.maxMembers,_that.approvalRequired,_that.privateMessage,_that.linkedTripId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String description, @JsonKey(defaultValue: GroupEventCategory.other)  GroupEventCategory category,  String location, @JsonKey(name: 'start_date')  DateTime startDate, @JsonKey(name: 'end_date')  DateTime? endDate, @JsonKey(name: 'max_members', defaultValue: 10)  int maxMembers, @JsonKey(name: 'approval_required', defaultValue: false)  bool approvalRequired, @JsonKey(name: 'private_message')  String? privateMessage, @JsonKey(name: 'linked_trip_id')  String? linkedTripId)?  $default,) {final _that = this;
switch (_that) {
case _GroupEventCreateRequest() when $default != null:
return $default(_that.title,_that.description,_that.category,_that.location,_that.startDate,_that.endDate,_that.maxMembers,_that.approvalRequired,_that.privateMessage,_that.linkedTripId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroupEventCreateRequest implements GroupEventCreateRequest {
  const _GroupEventCreateRequest({required this.title, required this.description, @JsonKey(defaultValue: GroupEventCategory.other) required this.category, required this.location, @JsonKey(name: 'start_date') required this.startDate, @JsonKey(name: 'end_date') this.endDate, @JsonKey(name: 'max_members', defaultValue: 10) required this.maxMembers, @JsonKey(name: 'approval_required', defaultValue: false) required this.approvalRequired, @JsonKey(name: 'private_message') this.privateMessage, @JsonKey(name: 'linked_trip_id') this.linkedTripId});
  factory _GroupEventCreateRequest.fromJson(Map<String, dynamic> json) => _$GroupEventCreateRequestFromJson(json);

@override final  String title;
@override final  String description;
@override@JsonKey(defaultValue: GroupEventCategory.other) final  GroupEventCategory category;
@override final  String location;
@override@JsonKey(name: 'start_date') final  DateTime startDate;
@override@JsonKey(name: 'end_date') final  DateTime? endDate;
@override@JsonKey(name: 'max_members', defaultValue: 10) final  int maxMembers;
@override@JsonKey(name: 'approval_required', defaultValue: false) final  bool approvalRequired;
@override@JsonKey(name: 'private_message') final  String? privateMessage;
@override@JsonKey(name: 'linked_trip_id') final  String? linkedTripId;

/// Create a copy of GroupEventCreateRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupEventCreateRequestCopyWith<_GroupEventCreateRequest> get copyWith => __$GroupEventCreateRequestCopyWithImpl<_GroupEventCreateRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroupEventCreateRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupEventCreateRequest&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.location, location) || other.location == location)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.maxMembers, maxMembers) || other.maxMembers == maxMembers)&&(identical(other.approvalRequired, approvalRequired) || other.approvalRequired == approvalRequired)&&(identical(other.privateMessage, privateMessage) || other.privateMessage == privateMessage)&&(identical(other.linkedTripId, linkedTripId) || other.linkedTripId == linkedTripId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,description,category,location,startDate,endDate,maxMembers,approvalRequired,privateMessage,linkedTripId);

@override
String toString() {
  return 'GroupEventCreateRequest(title: $title, description: $description, category: $category, location: $location, startDate: $startDate, endDate: $endDate, maxMembers: $maxMembers, approvalRequired: $approvalRequired, privateMessage: $privateMessage, linkedTripId: $linkedTripId)';
}


}

/// @nodoc
abstract mixin class _$GroupEventCreateRequestCopyWith<$Res> implements $GroupEventCreateRequestCopyWith<$Res> {
  factory _$GroupEventCreateRequestCopyWith(_GroupEventCreateRequest value, $Res Function(_GroupEventCreateRequest) _then) = __$GroupEventCreateRequestCopyWithImpl;
@override @useResult
$Res call({
 String title, String description,@JsonKey(defaultValue: GroupEventCategory.other) GroupEventCategory category, String location,@JsonKey(name: 'start_date') DateTime startDate,@JsonKey(name: 'end_date') DateTime? endDate,@JsonKey(name: 'max_members', defaultValue: 10) int maxMembers,@JsonKey(name: 'approval_required', defaultValue: false) bool approvalRequired,@JsonKey(name: 'private_message') String? privateMessage,@JsonKey(name: 'linked_trip_id') String? linkedTripId
});




}
/// @nodoc
class __$GroupEventCreateRequestCopyWithImpl<$Res>
    implements _$GroupEventCreateRequestCopyWith<$Res> {
  __$GroupEventCreateRequestCopyWithImpl(this._self, this._then);

  final _GroupEventCreateRequest _self;
  final $Res Function(_GroupEventCreateRequest) _then;

/// Create a copy of GroupEventCreateRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? description = null,Object? category = null,Object? location = null,Object? startDate = null,Object? endDate = freezed,Object? maxMembers = null,Object? approvalRequired = null,Object? privateMessage = freezed,Object? linkedTripId = freezed,}) {
  return _then(_GroupEventCreateRequest(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as GroupEventCategory,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,maxMembers: null == maxMembers ? _self.maxMembers : maxMembers // ignore: cast_nullable_to_non_nullable
as int,approvalRequired: null == approvalRequired ? _self.approvalRequired : approvalRequired // ignore: cast_nullable_to_non_nullable
as bool,privateMessage: freezed == privateMessage ? _self.privateMessage : privateMessage // ignore: cast_nullable_to_non_nullable
as String?,linkedTripId: freezed == linkedTripId ? _self.linkedTripId : linkedTripId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$GroupEventUpdateRequest {

 String? get title; String? get description; GroupEventCategory? get category; String? get location;@JsonKey(name: 'start_date') DateTime? get startDate;@JsonKey(name: 'end_date') DateTime? get endDate;@JsonKey(name: 'max_members') int? get maxMembers;@JsonKey(name: 'approval_required') bool? get approvalRequired;@JsonKey(name: 'private_message') String? get privateMessage;
/// Create a copy of GroupEventUpdateRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupEventUpdateRequestCopyWith<GroupEventUpdateRequest> get copyWith => _$GroupEventUpdateRequestCopyWithImpl<GroupEventUpdateRequest>(this as GroupEventUpdateRequest, _$identity);

  /// Serializes this GroupEventUpdateRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupEventUpdateRequest&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.location, location) || other.location == location)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.maxMembers, maxMembers) || other.maxMembers == maxMembers)&&(identical(other.approvalRequired, approvalRequired) || other.approvalRequired == approvalRequired)&&(identical(other.privateMessage, privateMessage) || other.privateMessage == privateMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,description,category,location,startDate,endDate,maxMembers,approvalRequired,privateMessage);

@override
String toString() {
  return 'GroupEventUpdateRequest(title: $title, description: $description, category: $category, location: $location, startDate: $startDate, endDate: $endDate, maxMembers: $maxMembers, approvalRequired: $approvalRequired, privateMessage: $privateMessage)';
}


}

/// @nodoc
abstract mixin class $GroupEventUpdateRequestCopyWith<$Res>  {
  factory $GroupEventUpdateRequestCopyWith(GroupEventUpdateRequest value, $Res Function(GroupEventUpdateRequest) _then) = _$GroupEventUpdateRequestCopyWithImpl;
@useResult
$Res call({
 String? title, String? description, GroupEventCategory? category, String? location,@JsonKey(name: 'start_date') DateTime? startDate,@JsonKey(name: 'end_date') DateTime? endDate,@JsonKey(name: 'max_members') int? maxMembers,@JsonKey(name: 'approval_required') bool? approvalRequired,@JsonKey(name: 'private_message') String? privateMessage
});




}
/// @nodoc
class _$GroupEventUpdateRequestCopyWithImpl<$Res>
    implements $GroupEventUpdateRequestCopyWith<$Res> {
  _$GroupEventUpdateRequestCopyWithImpl(this._self, this._then);

  final GroupEventUpdateRequest _self;
  final $Res Function(GroupEventUpdateRequest) _then;

/// Create a copy of GroupEventUpdateRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = freezed,Object? description = freezed,Object? category = freezed,Object? location = freezed,Object? startDate = freezed,Object? endDate = freezed,Object? maxMembers = freezed,Object? approvalRequired = freezed,Object? privateMessage = freezed,}) {
  return _then(_self.copyWith(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as GroupEventCategory?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,maxMembers: freezed == maxMembers ? _self.maxMembers : maxMembers // ignore: cast_nullable_to_non_nullable
as int?,approvalRequired: freezed == approvalRequired ? _self.approvalRequired : approvalRequired // ignore: cast_nullable_to_non_nullable
as bool?,privateMessage: freezed == privateMessage ? _self.privateMessage : privateMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupEventUpdateRequest].
extension GroupEventUpdateRequestPatterns on GroupEventUpdateRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupEventUpdateRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupEventUpdateRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupEventUpdateRequest value)  $default,){
final _that = this;
switch (_that) {
case _GroupEventUpdateRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupEventUpdateRequest value)?  $default,){
final _that = this;
switch (_that) {
case _GroupEventUpdateRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? title,  String? description,  GroupEventCategory? category,  String? location, @JsonKey(name: 'start_date')  DateTime? startDate, @JsonKey(name: 'end_date')  DateTime? endDate, @JsonKey(name: 'max_members')  int? maxMembers, @JsonKey(name: 'approval_required')  bool? approvalRequired, @JsonKey(name: 'private_message')  String? privateMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupEventUpdateRequest() when $default != null:
return $default(_that.title,_that.description,_that.category,_that.location,_that.startDate,_that.endDate,_that.maxMembers,_that.approvalRequired,_that.privateMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? title,  String? description,  GroupEventCategory? category,  String? location, @JsonKey(name: 'start_date')  DateTime? startDate, @JsonKey(name: 'end_date')  DateTime? endDate, @JsonKey(name: 'max_members')  int? maxMembers, @JsonKey(name: 'approval_required')  bool? approvalRequired, @JsonKey(name: 'private_message')  String? privateMessage)  $default,) {final _that = this;
switch (_that) {
case _GroupEventUpdateRequest():
return $default(_that.title,_that.description,_that.category,_that.location,_that.startDate,_that.endDate,_that.maxMembers,_that.approvalRequired,_that.privateMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? title,  String? description,  GroupEventCategory? category,  String? location, @JsonKey(name: 'start_date')  DateTime? startDate, @JsonKey(name: 'end_date')  DateTime? endDate, @JsonKey(name: 'max_members')  int? maxMembers, @JsonKey(name: 'approval_required')  bool? approvalRequired, @JsonKey(name: 'private_message')  String? privateMessage)?  $default,) {final _that = this;
switch (_that) {
case _GroupEventUpdateRequest() when $default != null:
return $default(_that.title,_that.description,_that.category,_that.location,_that.startDate,_that.endDate,_that.maxMembers,_that.approvalRequired,_that.privateMessage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroupEventUpdateRequest implements GroupEventUpdateRequest {
  const _GroupEventUpdateRequest({this.title, this.description, this.category, this.location, @JsonKey(name: 'start_date') this.startDate, @JsonKey(name: 'end_date') this.endDate, @JsonKey(name: 'max_members') this.maxMembers, @JsonKey(name: 'approval_required') this.approvalRequired, @JsonKey(name: 'private_message') this.privateMessage});
  factory _GroupEventUpdateRequest.fromJson(Map<String, dynamic> json) => _$GroupEventUpdateRequestFromJson(json);

@override final  String? title;
@override final  String? description;
@override final  GroupEventCategory? category;
@override final  String? location;
@override@JsonKey(name: 'start_date') final  DateTime? startDate;
@override@JsonKey(name: 'end_date') final  DateTime? endDate;
@override@JsonKey(name: 'max_members') final  int? maxMembers;
@override@JsonKey(name: 'approval_required') final  bool? approvalRequired;
@override@JsonKey(name: 'private_message') final  String? privateMessage;

/// Create a copy of GroupEventUpdateRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupEventUpdateRequestCopyWith<_GroupEventUpdateRequest> get copyWith => __$GroupEventUpdateRequestCopyWithImpl<_GroupEventUpdateRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroupEventUpdateRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupEventUpdateRequest&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.location, location) || other.location == location)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.maxMembers, maxMembers) || other.maxMembers == maxMembers)&&(identical(other.approvalRequired, approvalRequired) || other.approvalRequired == approvalRequired)&&(identical(other.privateMessage, privateMessage) || other.privateMessage == privateMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,description,category,location,startDate,endDate,maxMembers,approvalRequired,privateMessage);

@override
String toString() {
  return 'GroupEventUpdateRequest(title: $title, description: $description, category: $category, location: $location, startDate: $startDate, endDate: $endDate, maxMembers: $maxMembers, approvalRequired: $approvalRequired, privateMessage: $privateMessage)';
}


}

/// @nodoc
abstract mixin class _$GroupEventUpdateRequestCopyWith<$Res> implements $GroupEventUpdateRequestCopyWith<$Res> {
  factory _$GroupEventUpdateRequestCopyWith(_GroupEventUpdateRequest value, $Res Function(_GroupEventUpdateRequest) _then) = __$GroupEventUpdateRequestCopyWithImpl;
@override @useResult
$Res call({
 String? title, String? description, GroupEventCategory? category, String? location,@JsonKey(name: 'start_date') DateTime? startDate,@JsonKey(name: 'end_date') DateTime? endDate,@JsonKey(name: 'max_members') int? maxMembers,@JsonKey(name: 'approval_required') bool? approvalRequired,@JsonKey(name: 'private_message') String? privateMessage
});




}
/// @nodoc
class __$GroupEventUpdateRequestCopyWithImpl<$Res>
    implements _$GroupEventUpdateRequestCopyWith<$Res> {
  __$GroupEventUpdateRequestCopyWithImpl(this._self, this._then);

  final _GroupEventUpdateRequest _self;
  final $Res Function(_GroupEventUpdateRequest) _then;

/// Create a copy of GroupEventUpdateRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = freezed,Object? description = freezed,Object? category = freezed,Object? location = freezed,Object? startDate = freezed,Object? endDate = freezed,Object? maxMembers = freezed,Object? approvalRequired = freezed,Object? privateMessage = freezed,}) {
  return _then(_GroupEventUpdateRequest(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as GroupEventCategory?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,maxMembers: freezed == maxMembers ? _self.maxMembers : maxMembers // ignore: cast_nullable_to_non_nullable
as int?,approvalRequired: freezed == approvalRequired ? _self.approvalRequired : approvalRequired // ignore: cast_nullable_to_non_nullable
as bool?,privateMessage: freezed == privateMessage ? _self.privateMessage : privateMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$GroupEventStatusRequest {

 String get status; String? get action;
/// Create a copy of GroupEventStatusRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupEventStatusRequestCopyWith<GroupEventStatusRequest> get copyWith => _$GroupEventStatusRequestCopyWithImpl<GroupEventStatusRequest>(this as GroupEventStatusRequest, _$identity);

  /// Serializes this GroupEventStatusRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupEventStatusRequest&&(identical(other.status, status) || other.status == status)&&(identical(other.action, action) || other.action == action));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,action);

@override
String toString() {
  return 'GroupEventStatusRequest(status: $status, action: $action)';
}


}

/// @nodoc
abstract mixin class $GroupEventStatusRequestCopyWith<$Res>  {
  factory $GroupEventStatusRequestCopyWith(GroupEventStatusRequest value, $Res Function(GroupEventStatusRequest) _then) = _$GroupEventStatusRequestCopyWithImpl;
@useResult
$Res call({
 String status, String? action
});




}
/// @nodoc
class _$GroupEventStatusRequestCopyWithImpl<$Res>
    implements $GroupEventStatusRequestCopyWith<$Res> {
  _$GroupEventStatusRequestCopyWithImpl(this._self, this._then);

  final GroupEventStatusRequest _self;
  final $Res Function(GroupEventStatusRequest) _then;

/// Create a copy of GroupEventStatusRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? action = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,action: freezed == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupEventStatusRequest].
extension GroupEventStatusRequestPatterns on GroupEventStatusRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupEventStatusRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupEventStatusRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupEventStatusRequest value)  $default,){
final _that = this;
switch (_that) {
case _GroupEventStatusRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupEventStatusRequest value)?  $default,){
final _that = this;
switch (_that) {
case _GroupEventStatusRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String status,  String? action)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupEventStatusRequest() when $default != null:
return $default(_that.status,_that.action);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String status,  String? action)  $default,) {final _that = this;
switch (_that) {
case _GroupEventStatusRequest():
return $default(_that.status,_that.action);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String status,  String? action)?  $default,) {final _that = this;
switch (_that) {
case _GroupEventStatusRequest() when $default != null:
return $default(_that.status,_that.action);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroupEventStatusRequest implements GroupEventStatusRequest {
  const _GroupEventStatusRequest({required this.status, this.action});
  factory _GroupEventStatusRequest.fromJson(Map<String, dynamic> json) => _$GroupEventStatusRequestFromJson(json);

@override final  String status;
@override final  String? action;

/// Create a copy of GroupEventStatusRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupEventStatusRequestCopyWith<_GroupEventStatusRequest> get copyWith => __$GroupEventStatusRequestCopyWithImpl<_GroupEventStatusRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroupEventStatusRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupEventStatusRequest&&(identical(other.status, status) || other.status == status)&&(identical(other.action, action) || other.action == action));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,action);

@override
String toString() {
  return 'GroupEventStatusRequest(status: $status, action: $action)';
}


}

/// @nodoc
abstract mixin class _$GroupEventStatusRequestCopyWith<$Res> implements $GroupEventStatusRequestCopyWith<$Res> {
  factory _$GroupEventStatusRequestCopyWith(_GroupEventStatusRequest value, $Res Function(_GroupEventStatusRequest) _then) = __$GroupEventStatusRequestCopyWithImpl;
@override @useResult
$Res call({
 String status, String? action
});




}
/// @nodoc
class __$GroupEventStatusRequestCopyWithImpl<$Res>
    implements _$GroupEventStatusRequestCopyWith<$Res> {
  __$GroupEventStatusRequestCopyWithImpl(this._self, this._then);

  final _GroupEventStatusRequest _self;
  final $Res Function(_GroupEventStatusRequest) _then;

/// Create a copy of GroupEventStatusRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? action = freezed,}) {
  return _then(_GroupEventStatusRequest(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,action: freezed == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$GroupEventApplyRequest {

 String? get message;
/// Create a copy of GroupEventApplyRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupEventApplyRequestCopyWith<GroupEventApplyRequest> get copyWith => _$GroupEventApplyRequestCopyWithImpl<GroupEventApplyRequest>(this as GroupEventApplyRequest, _$identity);

  /// Serializes this GroupEventApplyRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupEventApplyRequest&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'GroupEventApplyRequest(message: $message)';
}


}

/// @nodoc
abstract mixin class $GroupEventApplyRequestCopyWith<$Res>  {
  factory $GroupEventApplyRequestCopyWith(GroupEventApplyRequest value, $Res Function(GroupEventApplyRequest) _then) = _$GroupEventApplyRequestCopyWithImpl;
@useResult
$Res call({
 String? message
});




}
/// @nodoc
class _$GroupEventApplyRequestCopyWithImpl<$Res>
    implements $GroupEventApplyRequestCopyWith<$Res> {
  _$GroupEventApplyRequestCopyWithImpl(this._self, this._then);

  final GroupEventApplyRequest _self;
  final $Res Function(GroupEventApplyRequest) _then;

/// Create a copy of GroupEventApplyRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? message = freezed,}) {
  return _then(_self.copyWith(
message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupEventApplyRequest].
extension GroupEventApplyRequestPatterns on GroupEventApplyRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupEventApplyRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupEventApplyRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupEventApplyRequest value)  $default,){
final _that = this;
switch (_that) {
case _GroupEventApplyRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupEventApplyRequest value)?  $default,){
final _that = this;
switch (_that) {
case _GroupEventApplyRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupEventApplyRequest() when $default != null:
return $default(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? message)  $default,) {final _that = this;
switch (_that) {
case _GroupEventApplyRequest():
return $default(_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? message)?  $default,) {final _that = this;
switch (_that) {
case _GroupEventApplyRequest() when $default != null:
return $default(_that.message);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroupEventApplyRequest implements GroupEventApplyRequest {
  const _GroupEventApplyRequest({this.message});
  factory _GroupEventApplyRequest.fromJson(Map<String, dynamic> json) => _$GroupEventApplyRequestFromJson(json);

@override final  String? message;

/// Create a copy of GroupEventApplyRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupEventApplyRequestCopyWith<_GroupEventApplyRequest> get copyWith => __$GroupEventApplyRequestCopyWithImpl<_GroupEventApplyRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroupEventApplyRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupEventApplyRequest&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'GroupEventApplyRequest(message: $message)';
}


}

/// @nodoc
abstract mixin class _$GroupEventApplyRequestCopyWith<$Res> implements $GroupEventApplyRequestCopyWith<$Res> {
  factory _$GroupEventApplyRequestCopyWith(_GroupEventApplyRequest value, $Res Function(_GroupEventApplyRequest) _then) = __$GroupEventApplyRequestCopyWithImpl;
@override @useResult
$Res call({
 String? message
});




}
/// @nodoc
class __$GroupEventApplyRequestCopyWithImpl<$Res>
    implements _$GroupEventApplyRequestCopyWith<$Res> {
  __$GroupEventApplyRequestCopyWithImpl(this._self, this._then);

  final _GroupEventApplyRequest _self;
  final $Res Function(_GroupEventApplyRequest) _then;

/// Create a copy of GroupEventApplyRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = freezed,}) {
  return _then(_GroupEventApplyRequest(
message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$GroupEventReviewRequest {

 String get action;
/// Create a copy of GroupEventReviewRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupEventReviewRequestCopyWith<GroupEventReviewRequest> get copyWith => _$GroupEventReviewRequestCopyWithImpl<GroupEventReviewRequest>(this as GroupEventReviewRequest, _$identity);

  /// Serializes this GroupEventReviewRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupEventReviewRequest&&(identical(other.action, action) || other.action == action));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,action);

@override
String toString() {
  return 'GroupEventReviewRequest(action: $action)';
}


}

/// @nodoc
abstract mixin class $GroupEventReviewRequestCopyWith<$Res>  {
  factory $GroupEventReviewRequestCopyWith(GroupEventReviewRequest value, $Res Function(GroupEventReviewRequest) _then) = _$GroupEventReviewRequestCopyWithImpl;
@useResult
$Res call({
 String action
});




}
/// @nodoc
class _$GroupEventReviewRequestCopyWithImpl<$Res>
    implements $GroupEventReviewRequestCopyWith<$Res> {
  _$GroupEventReviewRequestCopyWithImpl(this._self, this._then);

  final GroupEventReviewRequest _self;
  final $Res Function(GroupEventReviewRequest) _then;

/// Create a copy of GroupEventReviewRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? action = null,}) {
  return _then(_self.copyWith(
action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupEventReviewRequest].
extension GroupEventReviewRequestPatterns on GroupEventReviewRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupEventReviewRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupEventReviewRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupEventReviewRequest value)  $default,){
final _that = this;
switch (_that) {
case _GroupEventReviewRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupEventReviewRequest value)?  $default,){
final _that = this;
switch (_that) {
case _GroupEventReviewRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String action)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupEventReviewRequest() when $default != null:
return $default(_that.action);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String action)  $default,) {final _that = this;
switch (_that) {
case _GroupEventReviewRequest():
return $default(_that.action);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String action)?  $default,) {final _that = this;
switch (_that) {
case _GroupEventReviewRequest() when $default != null:
return $default(_that.action);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroupEventReviewRequest implements GroupEventReviewRequest {
  const _GroupEventReviewRequest({required this.action});
  factory _GroupEventReviewRequest.fromJson(Map<String, dynamic> json) => _$GroupEventReviewRequestFromJson(json);

@override final  String action;

/// Create a copy of GroupEventReviewRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupEventReviewRequestCopyWith<_GroupEventReviewRequest> get copyWith => __$GroupEventReviewRequestCopyWithImpl<_GroupEventReviewRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroupEventReviewRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupEventReviewRequest&&(identical(other.action, action) || other.action == action));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,action);

@override
String toString() {
  return 'GroupEventReviewRequest(action: $action)';
}


}

/// @nodoc
abstract mixin class _$GroupEventReviewRequestCopyWith<$Res> implements $GroupEventReviewRequestCopyWith<$Res> {
  factory _$GroupEventReviewRequestCopyWith(_GroupEventReviewRequest value, $Res Function(_GroupEventReviewRequest) _then) = __$GroupEventReviewRequestCopyWithImpl;
@override @useResult
$Res call({
 String action
});




}
/// @nodoc
class __$GroupEventReviewRequestCopyWithImpl<$Res>
    implements _$GroupEventReviewRequestCopyWith<$Res> {
  __$GroupEventReviewRequestCopyWithImpl(this._self, this._then);

  final _GroupEventReviewRequest _self;
  final $Res Function(_GroupEventReviewRequest) _then;

/// Create a copy of GroupEventReviewRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? action = null,}) {
  return _then(_GroupEventReviewRequest(
action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$GroupEventCommentRequest {

 String get content;
/// Create a copy of GroupEventCommentRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupEventCommentRequestCopyWith<GroupEventCommentRequest> get copyWith => _$GroupEventCommentRequestCopyWithImpl<GroupEventCommentRequest>(this as GroupEventCommentRequest, _$identity);

  /// Serializes this GroupEventCommentRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupEventCommentRequest&&(identical(other.content, content) || other.content == content));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,content);

@override
String toString() {
  return 'GroupEventCommentRequest(content: $content)';
}


}

/// @nodoc
abstract mixin class $GroupEventCommentRequestCopyWith<$Res>  {
  factory $GroupEventCommentRequestCopyWith(GroupEventCommentRequest value, $Res Function(GroupEventCommentRequest) _then) = _$GroupEventCommentRequestCopyWithImpl;
@useResult
$Res call({
 String content
});




}
/// @nodoc
class _$GroupEventCommentRequestCopyWithImpl<$Res>
    implements $GroupEventCommentRequestCopyWith<$Res> {
  _$GroupEventCommentRequestCopyWithImpl(this._self, this._then);

  final GroupEventCommentRequest _self;
  final $Res Function(GroupEventCommentRequest) _then;

/// Create a copy of GroupEventCommentRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? content = null,}) {
  return _then(_self.copyWith(
content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupEventCommentRequest].
extension GroupEventCommentRequestPatterns on GroupEventCommentRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupEventCommentRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupEventCommentRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupEventCommentRequest value)  $default,){
final _that = this;
switch (_that) {
case _GroupEventCommentRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupEventCommentRequest value)?  $default,){
final _that = this;
switch (_that) {
case _GroupEventCommentRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String content)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupEventCommentRequest() when $default != null:
return $default(_that.content);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String content)  $default,) {final _that = this;
switch (_that) {
case _GroupEventCommentRequest():
return $default(_that.content);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String content)?  $default,) {final _that = this;
switch (_that) {
case _GroupEventCommentRequest() when $default != null:
return $default(_that.content);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroupEventCommentRequest implements GroupEventCommentRequest {
  const _GroupEventCommentRequest({required this.content});
  factory _GroupEventCommentRequest.fromJson(Map<String, dynamic> json) => _$GroupEventCommentRequestFromJson(json);

@override final  String content;

/// Create a copy of GroupEventCommentRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupEventCommentRequestCopyWith<_GroupEventCommentRequest> get copyWith => __$GroupEventCommentRequestCopyWithImpl<_GroupEventCommentRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroupEventCommentRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupEventCommentRequest&&(identical(other.content, content) || other.content == content));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,content);

@override
String toString() {
  return 'GroupEventCommentRequest(content: $content)';
}


}

/// @nodoc
abstract mixin class _$GroupEventCommentRequestCopyWith<$Res> implements $GroupEventCommentRequestCopyWith<$Res> {
  factory _$GroupEventCommentRequestCopyWith(_GroupEventCommentRequest value, $Res Function(_GroupEventCommentRequest) _then) = __$GroupEventCommentRequestCopyWithImpl;
@override @useResult
$Res call({
 String content
});




}
/// @nodoc
class __$GroupEventCommentRequestCopyWithImpl<$Res>
    implements _$GroupEventCommentRequestCopyWith<$Res> {
  __$GroupEventCommentRequestCopyWithImpl(this._self, this._then);

  final _GroupEventCommentRequest _self;
  final $Res Function(_GroupEventCommentRequest) _then;

/// Create a copy of GroupEventCommentRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? content = null,}) {
  return _then(_GroupEventCommentRequest(
content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
