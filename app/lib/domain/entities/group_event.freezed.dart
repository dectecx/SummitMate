// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GroupEvent {

 String get id; String get creatorId; String get title; String get description; GroupEventCategory get category; String get location; DateTime get startDate; DateTime? get endDate; GroupEventStatus get status; int get maxMembers; int get applicationCount; int get totalApplicationCount; bool get approvalRequired; String get privateMessage; String? get linkedTripId; TripSnapshot? get tripSnapshot; DateTime? get snapshotUpdatedAt; int get likeCount; int get commentCount; bool get isLiked; GroupEventApplicationStatus? get myApplicationStatus; String get creatorName; String get creatorAvatar; List<GroupEventComment> get latestComments; DateTime get createdAt; String get createdBy; DateTime get updatedAt; String get updatedBy;
/// Create a copy of GroupEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupEventCopyWith<GroupEvent> get copyWith => _$GroupEventCopyWithImpl<GroupEvent>(this as GroupEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.creatorId, creatorId) || other.creatorId == creatorId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.location, location) || other.location == location)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.maxMembers, maxMembers) || other.maxMembers == maxMembers)&&(identical(other.applicationCount, applicationCount) || other.applicationCount == applicationCount)&&(identical(other.totalApplicationCount, totalApplicationCount) || other.totalApplicationCount == totalApplicationCount)&&(identical(other.approvalRequired, approvalRequired) || other.approvalRequired == approvalRequired)&&(identical(other.privateMessage, privateMessage) || other.privateMessage == privateMessage)&&(identical(other.linkedTripId, linkedTripId) || other.linkedTripId == linkedTripId)&&(identical(other.tripSnapshot, tripSnapshot) || other.tripSnapshot == tripSnapshot)&&(identical(other.snapshotUpdatedAt, snapshotUpdatedAt) || other.snapshotUpdatedAt == snapshotUpdatedAt)&&(identical(other.likeCount, likeCount) || other.likeCount == likeCount)&&(identical(other.commentCount, commentCount) || other.commentCount == commentCount)&&(identical(other.isLiked, isLiked) || other.isLiked == isLiked)&&(identical(other.myApplicationStatus, myApplicationStatus) || other.myApplicationStatus == myApplicationStatus)&&(identical(other.creatorName, creatorName) || other.creatorName == creatorName)&&(identical(other.creatorAvatar, creatorAvatar) || other.creatorAvatar == creatorAvatar)&&const DeepCollectionEquality().equals(other.latestComments, latestComments)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,creatorId,title,description,category,location,startDate,endDate,status,maxMembers,applicationCount,totalApplicationCount,approvalRequired,privateMessage,linkedTripId,tripSnapshot,snapshotUpdatedAt,likeCount,commentCount,isLiked,myApplicationStatus,creatorName,creatorAvatar,const DeepCollectionEquality().hash(latestComments),createdAt,createdBy,updatedAt,updatedBy]);

@override
String toString() {
  return 'GroupEvent(id: $id, creatorId: $creatorId, title: $title, description: $description, category: $category, location: $location, startDate: $startDate, endDate: $endDate, status: $status, maxMembers: $maxMembers, applicationCount: $applicationCount, totalApplicationCount: $totalApplicationCount, approvalRequired: $approvalRequired, privateMessage: $privateMessage, linkedTripId: $linkedTripId, tripSnapshot: $tripSnapshot, snapshotUpdatedAt: $snapshotUpdatedAt, likeCount: $likeCount, commentCount: $commentCount, isLiked: $isLiked, myApplicationStatus: $myApplicationStatus, creatorName: $creatorName, creatorAvatar: $creatorAvatar, latestComments: $latestComments, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy)';
}


}

/// @nodoc
abstract mixin class $GroupEventCopyWith<$Res>  {
  factory $GroupEventCopyWith(GroupEvent value, $Res Function(GroupEvent) _then) = _$GroupEventCopyWithImpl;
@useResult
$Res call({
 String id, String creatorId, String title, String description, GroupEventCategory category, String location, DateTime startDate, DateTime? endDate, GroupEventStatus status, int maxMembers, int applicationCount, int totalApplicationCount, bool approvalRequired, String privateMessage, String? linkedTripId, TripSnapshot? tripSnapshot, DateTime? snapshotUpdatedAt, int likeCount, int commentCount, bool isLiked, GroupEventApplicationStatus? myApplicationStatus, String creatorName, String creatorAvatar, List<GroupEventComment> latestComments, DateTime createdAt, String createdBy, DateTime updatedAt, String updatedBy
});




}
/// @nodoc
class _$GroupEventCopyWithImpl<$Res>
    implements $GroupEventCopyWith<$Res> {
  _$GroupEventCopyWithImpl(this._self, this._then);

  final GroupEvent _self;
  final $Res Function(GroupEvent) _then;

/// Create a copy of GroupEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? creatorId = null,Object? title = null,Object? description = null,Object? category = null,Object? location = null,Object? startDate = null,Object? endDate = freezed,Object? status = null,Object? maxMembers = null,Object? applicationCount = null,Object? totalApplicationCount = null,Object? approvalRequired = null,Object? privateMessage = null,Object? linkedTripId = freezed,Object? tripSnapshot = freezed,Object? snapshotUpdatedAt = freezed,Object? likeCount = null,Object? commentCount = null,Object? isLiked = null,Object? myApplicationStatus = freezed,Object? creatorName = null,Object? creatorAvatar = null,Object? latestComments = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,}) {
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
as GroupEventStatus,maxMembers: null == maxMembers ? _self.maxMembers : maxMembers // ignore: cast_nullable_to_non_nullable
as int,applicationCount: null == applicationCount ? _self.applicationCount : applicationCount // ignore: cast_nullable_to_non_nullable
as int,totalApplicationCount: null == totalApplicationCount ? _self.totalApplicationCount : totalApplicationCount // ignore: cast_nullable_to_non_nullable
as int,approvalRequired: null == approvalRequired ? _self.approvalRequired : approvalRequired // ignore: cast_nullable_to_non_nullable
as bool,privateMessage: null == privateMessage ? _self.privateMessage : privateMessage // ignore: cast_nullable_to_non_nullable
as String,linkedTripId: freezed == linkedTripId ? _self.linkedTripId : linkedTripId // ignore: cast_nullable_to_non_nullable
as String?,tripSnapshot: freezed == tripSnapshot ? _self.tripSnapshot : tripSnapshot // ignore: cast_nullable_to_non_nullable
as TripSnapshot?,snapshotUpdatedAt: freezed == snapshotUpdatedAt ? _self.snapshotUpdatedAt : snapshotUpdatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,likeCount: null == likeCount ? _self.likeCount : likeCount // ignore: cast_nullable_to_non_nullable
as int,commentCount: null == commentCount ? _self.commentCount : commentCount // ignore: cast_nullable_to_non_nullable
as int,isLiked: null == isLiked ? _self.isLiked : isLiked // ignore: cast_nullable_to_non_nullable
as bool,myApplicationStatus: freezed == myApplicationStatus ? _self.myApplicationStatus : myApplicationStatus // ignore: cast_nullable_to_non_nullable
as GroupEventApplicationStatus?,creatorName: null == creatorName ? _self.creatorName : creatorName // ignore: cast_nullable_to_non_nullable
as String,creatorAvatar: null == creatorAvatar ? _self.creatorAvatar : creatorAvatar // ignore: cast_nullable_to_non_nullable
as String,latestComments: null == latestComments ? _self.latestComments : latestComments // ignore: cast_nullable_to_non_nullable
as List<GroupEventComment>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupEvent].
extension GroupEventPatterns on GroupEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupEvent value)  $default,){
final _that = this;
switch (_that) {
case _GroupEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupEvent value)?  $default,){
final _that = this;
switch (_that) {
case _GroupEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String creatorId,  String title,  String description,  GroupEventCategory category,  String location,  DateTime startDate,  DateTime? endDate,  GroupEventStatus status,  int maxMembers,  int applicationCount,  int totalApplicationCount,  bool approvalRequired,  String privateMessage,  String? linkedTripId,  TripSnapshot? tripSnapshot,  DateTime? snapshotUpdatedAt,  int likeCount,  int commentCount,  bool isLiked,  GroupEventApplicationStatus? myApplicationStatus,  String creatorName,  String creatorAvatar,  List<GroupEventComment> latestComments,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupEvent() when $default != null:
return $default(_that.id,_that.creatorId,_that.title,_that.description,_that.category,_that.location,_that.startDate,_that.endDate,_that.status,_that.maxMembers,_that.applicationCount,_that.totalApplicationCount,_that.approvalRequired,_that.privateMessage,_that.linkedTripId,_that.tripSnapshot,_that.snapshotUpdatedAt,_that.likeCount,_that.commentCount,_that.isLiked,_that.myApplicationStatus,_that.creatorName,_that.creatorAvatar,_that.latestComments,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String creatorId,  String title,  String description,  GroupEventCategory category,  String location,  DateTime startDate,  DateTime? endDate,  GroupEventStatus status,  int maxMembers,  int applicationCount,  int totalApplicationCount,  bool approvalRequired,  String privateMessage,  String? linkedTripId,  TripSnapshot? tripSnapshot,  DateTime? snapshotUpdatedAt,  int likeCount,  int commentCount,  bool isLiked,  GroupEventApplicationStatus? myApplicationStatus,  String creatorName,  String creatorAvatar,  List<GroupEventComment> latestComments,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy)  $default,) {final _that = this;
switch (_that) {
case _GroupEvent():
return $default(_that.id,_that.creatorId,_that.title,_that.description,_that.category,_that.location,_that.startDate,_that.endDate,_that.status,_that.maxMembers,_that.applicationCount,_that.totalApplicationCount,_that.approvalRequired,_that.privateMessage,_that.linkedTripId,_that.tripSnapshot,_that.snapshotUpdatedAt,_that.likeCount,_that.commentCount,_that.isLiked,_that.myApplicationStatus,_that.creatorName,_that.creatorAvatar,_that.latestComments,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String creatorId,  String title,  String description,  GroupEventCategory category,  String location,  DateTime startDate,  DateTime? endDate,  GroupEventStatus status,  int maxMembers,  int applicationCount,  int totalApplicationCount,  bool approvalRequired,  String privateMessage,  String? linkedTripId,  TripSnapshot? tripSnapshot,  DateTime? snapshotUpdatedAt,  int likeCount,  int commentCount,  bool isLiked,  GroupEventApplicationStatus? myApplicationStatus,  String creatorName,  String creatorAvatar,  List<GroupEventComment> latestComments,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy)?  $default,) {final _that = this;
switch (_that) {
case _GroupEvent() when $default != null:
return $default(_that.id,_that.creatorId,_that.title,_that.description,_that.category,_that.location,_that.startDate,_that.endDate,_that.status,_that.maxMembers,_that.applicationCount,_that.totalApplicationCount,_that.approvalRequired,_that.privateMessage,_that.linkedTripId,_that.tripSnapshot,_that.snapshotUpdatedAt,_that.likeCount,_that.commentCount,_that.isLiked,_that.myApplicationStatus,_that.creatorName,_that.creatorAvatar,_that.latestComments,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
  return null;

}
}

}

/// @nodoc


class _GroupEvent extends GroupEvent {
  const _GroupEvent({required this.id, required this.creatorId, required this.title, this.description = '', this.category = GroupEventCategory.other, this.location = '', required this.startDate, this.endDate, this.status = GroupEventStatus.open, this.maxMembers = 10, this.applicationCount = 0, this.totalApplicationCount = 0, this.approvalRequired = false, this.privateMessage = '', this.linkedTripId, this.tripSnapshot, this.snapshotUpdatedAt, this.likeCount = 0, this.commentCount = 0, this.isLiked = false, this.myApplicationStatus, this.creatorName = '', this.creatorAvatar = '🐻', final  List<GroupEventComment> latestComments = const [], required this.createdAt, required this.createdBy, required this.updatedAt, required this.updatedBy}): _latestComments = latestComments,super._();
  

@override final  String id;
@override final  String creatorId;
@override final  String title;
@override@JsonKey() final  String description;
@override@JsonKey() final  GroupEventCategory category;
@override@JsonKey() final  String location;
@override final  DateTime startDate;
@override final  DateTime? endDate;
@override@JsonKey() final  GroupEventStatus status;
@override@JsonKey() final  int maxMembers;
@override@JsonKey() final  int applicationCount;
@override@JsonKey() final  int totalApplicationCount;
@override@JsonKey() final  bool approvalRequired;
@override@JsonKey() final  String privateMessage;
@override final  String? linkedTripId;
@override final  TripSnapshot? tripSnapshot;
@override final  DateTime? snapshotUpdatedAt;
@override@JsonKey() final  int likeCount;
@override@JsonKey() final  int commentCount;
@override@JsonKey() final  bool isLiked;
@override final  GroupEventApplicationStatus? myApplicationStatus;
@override@JsonKey() final  String creatorName;
@override@JsonKey() final  String creatorAvatar;
 final  List<GroupEventComment> _latestComments;
@override@JsonKey() List<GroupEventComment> get latestComments {
  if (_latestComments is EqualUnmodifiableListView) return _latestComments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_latestComments);
}

@override final  DateTime createdAt;
@override final  String createdBy;
@override final  DateTime updatedAt;
@override final  String updatedBy;

/// Create a copy of GroupEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupEventCopyWith<_GroupEvent> get copyWith => __$GroupEventCopyWithImpl<_GroupEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.creatorId, creatorId) || other.creatorId == creatorId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.location, location) || other.location == location)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.maxMembers, maxMembers) || other.maxMembers == maxMembers)&&(identical(other.applicationCount, applicationCount) || other.applicationCount == applicationCount)&&(identical(other.totalApplicationCount, totalApplicationCount) || other.totalApplicationCount == totalApplicationCount)&&(identical(other.approvalRequired, approvalRequired) || other.approvalRequired == approvalRequired)&&(identical(other.privateMessage, privateMessage) || other.privateMessage == privateMessage)&&(identical(other.linkedTripId, linkedTripId) || other.linkedTripId == linkedTripId)&&(identical(other.tripSnapshot, tripSnapshot) || other.tripSnapshot == tripSnapshot)&&(identical(other.snapshotUpdatedAt, snapshotUpdatedAt) || other.snapshotUpdatedAt == snapshotUpdatedAt)&&(identical(other.likeCount, likeCount) || other.likeCount == likeCount)&&(identical(other.commentCount, commentCount) || other.commentCount == commentCount)&&(identical(other.isLiked, isLiked) || other.isLiked == isLiked)&&(identical(other.myApplicationStatus, myApplicationStatus) || other.myApplicationStatus == myApplicationStatus)&&(identical(other.creatorName, creatorName) || other.creatorName == creatorName)&&(identical(other.creatorAvatar, creatorAvatar) || other.creatorAvatar == creatorAvatar)&&const DeepCollectionEquality().equals(other._latestComments, _latestComments)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,creatorId,title,description,category,location,startDate,endDate,status,maxMembers,applicationCount,totalApplicationCount,approvalRequired,privateMessage,linkedTripId,tripSnapshot,snapshotUpdatedAt,likeCount,commentCount,isLiked,myApplicationStatus,creatorName,creatorAvatar,const DeepCollectionEquality().hash(_latestComments),createdAt,createdBy,updatedAt,updatedBy]);

@override
String toString() {
  return 'GroupEvent(id: $id, creatorId: $creatorId, title: $title, description: $description, category: $category, location: $location, startDate: $startDate, endDate: $endDate, status: $status, maxMembers: $maxMembers, applicationCount: $applicationCount, totalApplicationCount: $totalApplicationCount, approvalRequired: $approvalRequired, privateMessage: $privateMessage, linkedTripId: $linkedTripId, tripSnapshot: $tripSnapshot, snapshotUpdatedAt: $snapshotUpdatedAt, likeCount: $likeCount, commentCount: $commentCount, isLiked: $isLiked, myApplicationStatus: $myApplicationStatus, creatorName: $creatorName, creatorAvatar: $creatorAvatar, latestComments: $latestComments, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy)';
}


}

/// @nodoc
abstract mixin class _$GroupEventCopyWith<$Res> implements $GroupEventCopyWith<$Res> {
  factory _$GroupEventCopyWith(_GroupEvent value, $Res Function(_GroupEvent) _then) = __$GroupEventCopyWithImpl;
@override @useResult
$Res call({
 String id, String creatorId, String title, String description, GroupEventCategory category, String location, DateTime startDate, DateTime? endDate, GroupEventStatus status, int maxMembers, int applicationCount, int totalApplicationCount, bool approvalRequired, String privateMessage, String? linkedTripId, TripSnapshot? tripSnapshot, DateTime? snapshotUpdatedAt, int likeCount, int commentCount, bool isLiked, GroupEventApplicationStatus? myApplicationStatus, String creatorName, String creatorAvatar, List<GroupEventComment> latestComments, DateTime createdAt, String createdBy, DateTime updatedAt, String updatedBy
});




}
/// @nodoc
class __$GroupEventCopyWithImpl<$Res>
    implements _$GroupEventCopyWith<$Res> {
  __$GroupEventCopyWithImpl(this._self, this._then);

  final _GroupEvent _self;
  final $Res Function(_GroupEvent) _then;

/// Create a copy of GroupEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? creatorId = null,Object? title = null,Object? description = null,Object? category = null,Object? location = null,Object? startDate = null,Object? endDate = freezed,Object? status = null,Object? maxMembers = null,Object? applicationCount = null,Object? totalApplicationCount = null,Object? approvalRequired = null,Object? privateMessage = null,Object? linkedTripId = freezed,Object? tripSnapshot = freezed,Object? snapshotUpdatedAt = freezed,Object? likeCount = null,Object? commentCount = null,Object? isLiked = null,Object? myApplicationStatus = freezed,Object? creatorName = null,Object? creatorAvatar = null,Object? latestComments = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,}) {
  return _then(_GroupEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,creatorId: null == creatorId ? _self.creatorId : creatorId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as GroupEventCategory,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GroupEventStatus,maxMembers: null == maxMembers ? _self.maxMembers : maxMembers // ignore: cast_nullable_to_non_nullable
as int,applicationCount: null == applicationCount ? _self.applicationCount : applicationCount // ignore: cast_nullable_to_non_nullable
as int,totalApplicationCount: null == totalApplicationCount ? _self.totalApplicationCount : totalApplicationCount // ignore: cast_nullable_to_non_nullable
as int,approvalRequired: null == approvalRequired ? _self.approvalRequired : approvalRequired // ignore: cast_nullable_to_non_nullable
as bool,privateMessage: null == privateMessage ? _self.privateMessage : privateMessage // ignore: cast_nullable_to_non_nullable
as String,linkedTripId: freezed == linkedTripId ? _self.linkedTripId : linkedTripId // ignore: cast_nullable_to_non_nullable
as String?,tripSnapshot: freezed == tripSnapshot ? _self.tripSnapshot : tripSnapshot // ignore: cast_nullable_to_non_nullable
as TripSnapshot?,snapshotUpdatedAt: freezed == snapshotUpdatedAt ? _self.snapshotUpdatedAt : snapshotUpdatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,likeCount: null == likeCount ? _self.likeCount : likeCount // ignore: cast_nullable_to_non_nullable
as int,commentCount: null == commentCount ? _self.commentCount : commentCount // ignore: cast_nullable_to_non_nullable
as int,isLiked: null == isLiked ? _self.isLiked : isLiked // ignore: cast_nullable_to_non_nullable
as bool,myApplicationStatus: freezed == myApplicationStatus ? _self.myApplicationStatus : myApplicationStatus // ignore: cast_nullable_to_non_nullable
as GroupEventApplicationStatus?,creatorName: null == creatorName ? _self.creatorName : creatorName // ignore: cast_nullable_to_non_nullable
as String,creatorAvatar: null == creatorAvatar ? _self.creatorAvatar : creatorAvatar // ignore: cast_nullable_to_non_nullable
as String,latestComments: null == latestComments ? _self._latestComments : latestComments // ignore: cast_nullable_to_non_nullable
as List<GroupEventComment>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$GroupEventApplication {

 String get id; String get eventId; String get userId; GroupEventApplicationStatus get status; String get message; DateTime get createdAt; DateTime get updatedAt; String get updatedBy; String get userName; String get userAvatar;
/// Create a copy of GroupEventApplication
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupEventApplicationCopyWith<GroupEventApplication> get copyWith => _$GroupEventApplicationCopyWithImpl<GroupEventApplication>(this as GroupEventApplication, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupEventApplication&&(identical(other.id, id) || other.id == id)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.status, status) || other.status == status)&&(identical(other.message, message) || other.message == message)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.userAvatar, userAvatar) || other.userAvatar == userAvatar));
}


@override
int get hashCode => Object.hash(runtimeType,id,eventId,userId,status,message,createdAt,updatedAt,updatedBy,userName,userAvatar);

@override
String toString() {
  return 'GroupEventApplication(id: $id, eventId: $eventId, userId: $userId, status: $status, message: $message, createdAt: $createdAt, updatedAt: $updatedAt, updatedBy: $updatedBy, userName: $userName, userAvatar: $userAvatar)';
}


}

/// @nodoc
abstract mixin class $GroupEventApplicationCopyWith<$Res>  {
  factory $GroupEventApplicationCopyWith(GroupEventApplication value, $Res Function(GroupEventApplication) _then) = _$GroupEventApplicationCopyWithImpl;
@useResult
$Res call({
 String id, String eventId, String userId, GroupEventApplicationStatus status, String message, DateTime createdAt, DateTime updatedAt, String updatedBy, String userName, String userAvatar
});




}
/// @nodoc
class _$GroupEventApplicationCopyWithImpl<$Res>
    implements $GroupEventApplicationCopyWith<$Res> {
  _$GroupEventApplicationCopyWithImpl(this._self, this._then);

  final GroupEventApplication _self;
  final $Res Function(GroupEventApplication) _then;

/// Create a copy of GroupEventApplication
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? eventId = null,Object? userId = null,Object? status = null,Object? message = null,Object? createdAt = null,Object? updatedAt = null,Object? updatedBy = null,Object? userName = null,Object? userAvatar = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GroupEventApplicationStatus,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,userAvatar: null == userAvatar ? _self.userAvatar : userAvatar // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupEventApplication].
extension GroupEventApplicationPatterns on GroupEventApplication {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupEventApplication value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupEventApplication() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupEventApplication value)  $default,){
final _that = this;
switch (_that) {
case _GroupEventApplication():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupEventApplication value)?  $default,){
final _that = this;
switch (_that) {
case _GroupEventApplication() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String eventId,  String userId,  GroupEventApplicationStatus status,  String message,  DateTime createdAt,  DateTime updatedAt,  String updatedBy,  String userName,  String userAvatar)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupEventApplication() when $default != null:
return $default(_that.id,_that.eventId,_that.userId,_that.status,_that.message,_that.createdAt,_that.updatedAt,_that.updatedBy,_that.userName,_that.userAvatar);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String eventId,  String userId,  GroupEventApplicationStatus status,  String message,  DateTime createdAt,  DateTime updatedAt,  String updatedBy,  String userName,  String userAvatar)  $default,) {final _that = this;
switch (_that) {
case _GroupEventApplication():
return $default(_that.id,_that.eventId,_that.userId,_that.status,_that.message,_that.createdAt,_that.updatedAt,_that.updatedBy,_that.userName,_that.userAvatar);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String eventId,  String userId,  GroupEventApplicationStatus status,  String message,  DateTime createdAt,  DateTime updatedAt,  String updatedBy,  String userName,  String userAvatar)?  $default,) {final _that = this;
switch (_that) {
case _GroupEventApplication() when $default != null:
return $default(_that.id,_that.eventId,_that.userId,_that.status,_that.message,_that.createdAt,_that.updatedAt,_that.updatedBy,_that.userName,_that.userAvatar);case _:
  return null;

}
}

}

/// @nodoc


class _GroupEventApplication extends GroupEventApplication {
  const _GroupEventApplication({required this.id, required this.eventId, required this.userId, this.status = GroupEventApplicationStatus.pending, this.message = '', required this.createdAt, required this.updatedAt, required this.updatedBy, this.userName = '', this.userAvatar = '🐻'}): super._();
  

@override final  String id;
@override final  String eventId;
@override final  String userId;
@override@JsonKey() final  GroupEventApplicationStatus status;
@override@JsonKey() final  String message;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  String updatedBy;
@override@JsonKey() final  String userName;
@override@JsonKey() final  String userAvatar;

/// Create a copy of GroupEventApplication
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupEventApplicationCopyWith<_GroupEventApplication> get copyWith => __$GroupEventApplicationCopyWithImpl<_GroupEventApplication>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupEventApplication&&(identical(other.id, id) || other.id == id)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.status, status) || other.status == status)&&(identical(other.message, message) || other.message == message)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.userAvatar, userAvatar) || other.userAvatar == userAvatar));
}


@override
int get hashCode => Object.hash(runtimeType,id,eventId,userId,status,message,createdAt,updatedAt,updatedBy,userName,userAvatar);

@override
String toString() {
  return 'GroupEventApplication(id: $id, eventId: $eventId, userId: $userId, status: $status, message: $message, createdAt: $createdAt, updatedAt: $updatedAt, updatedBy: $updatedBy, userName: $userName, userAvatar: $userAvatar)';
}


}

/// @nodoc
abstract mixin class _$GroupEventApplicationCopyWith<$Res> implements $GroupEventApplicationCopyWith<$Res> {
  factory _$GroupEventApplicationCopyWith(_GroupEventApplication value, $Res Function(_GroupEventApplication) _then) = __$GroupEventApplicationCopyWithImpl;
@override @useResult
$Res call({
 String id, String eventId, String userId, GroupEventApplicationStatus status, String message, DateTime createdAt, DateTime updatedAt, String updatedBy, String userName, String userAvatar
});




}
/// @nodoc
class __$GroupEventApplicationCopyWithImpl<$Res>
    implements _$GroupEventApplicationCopyWith<$Res> {
  __$GroupEventApplicationCopyWithImpl(this._self, this._then);

  final _GroupEventApplication _self;
  final $Res Function(_GroupEventApplication) _then;

/// Create a copy of GroupEventApplication
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? eventId = null,Object? userId = null,Object? status = null,Object? message = null,Object? createdAt = null,Object? updatedAt = null,Object? updatedBy = null,Object? userName = null,Object? userAvatar = null,}) {
  return _then(_GroupEventApplication(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GroupEventApplicationStatus,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,userAvatar: null == userAvatar ? _self.userAvatar : userAvatar // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
