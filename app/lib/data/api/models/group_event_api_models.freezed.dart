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
mixin _$GroupEventCreateRequest {

 String get title; String get description; String get location;@JsonKey(name: 'start_date') DateTime get startDate;@JsonKey(name: 'end_date') DateTime? get endDate;@JsonKey(name: 'max_members') int get maxMembers;@JsonKey(name: 'approval_required') bool get approvalRequired;@JsonKey(name: 'private_message') String? get privateMessage;@JsonKey(name: 'linked_trip_id') String? get linkedTripId;
/// Create a copy of GroupEventCreateRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupEventCreateRequestCopyWith<GroupEventCreateRequest> get copyWith => _$GroupEventCreateRequestCopyWithImpl<GroupEventCreateRequest>(this as GroupEventCreateRequest, _$identity);

  /// Serializes this GroupEventCreateRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupEventCreateRequest&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.location, location) || other.location == location)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.maxMembers, maxMembers) || other.maxMembers == maxMembers)&&(identical(other.approvalRequired, approvalRequired) || other.approvalRequired == approvalRequired)&&(identical(other.privateMessage, privateMessage) || other.privateMessage == privateMessage)&&(identical(other.linkedTripId, linkedTripId) || other.linkedTripId == linkedTripId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,description,location,startDate,endDate,maxMembers,approvalRequired,privateMessage,linkedTripId);

@override
String toString() {
  return 'GroupEventCreateRequest(title: $title, description: $description, location: $location, startDate: $startDate, endDate: $endDate, maxMembers: $maxMembers, approvalRequired: $approvalRequired, privateMessage: $privateMessage, linkedTripId: $linkedTripId)';
}


}

/// @nodoc
abstract mixin class $GroupEventCreateRequestCopyWith<$Res>  {
  factory $GroupEventCreateRequestCopyWith(GroupEventCreateRequest value, $Res Function(GroupEventCreateRequest) _then) = _$GroupEventCreateRequestCopyWithImpl;
@useResult
$Res call({
 String title, String description, String location,@JsonKey(name: 'start_date') DateTime startDate,@JsonKey(name: 'end_date') DateTime? endDate,@JsonKey(name: 'max_members') int maxMembers,@JsonKey(name: 'approval_required') bool approvalRequired,@JsonKey(name: 'private_message') String? privateMessage,@JsonKey(name: 'linked_trip_id') String? linkedTripId
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
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? description = null,Object? location = null,Object? startDate = null,Object? endDate = freezed,Object? maxMembers = null,Object? approvalRequired = null,Object? privateMessage = freezed,Object? linkedTripId = freezed,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String description,  String location, @JsonKey(name: 'start_date')  DateTime startDate, @JsonKey(name: 'end_date')  DateTime? endDate, @JsonKey(name: 'max_members')  int maxMembers, @JsonKey(name: 'approval_required')  bool approvalRequired, @JsonKey(name: 'private_message')  String? privateMessage, @JsonKey(name: 'linked_trip_id')  String? linkedTripId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupEventCreateRequest() when $default != null:
return $default(_that.title,_that.description,_that.location,_that.startDate,_that.endDate,_that.maxMembers,_that.approvalRequired,_that.privateMessage,_that.linkedTripId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String description,  String location, @JsonKey(name: 'start_date')  DateTime startDate, @JsonKey(name: 'end_date')  DateTime? endDate, @JsonKey(name: 'max_members')  int maxMembers, @JsonKey(name: 'approval_required')  bool approvalRequired, @JsonKey(name: 'private_message')  String? privateMessage, @JsonKey(name: 'linked_trip_id')  String? linkedTripId)  $default,) {final _that = this;
switch (_that) {
case _GroupEventCreateRequest():
return $default(_that.title,_that.description,_that.location,_that.startDate,_that.endDate,_that.maxMembers,_that.approvalRequired,_that.privateMessage,_that.linkedTripId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String description,  String location, @JsonKey(name: 'start_date')  DateTime startDate, @JsonKey(name: 'end_date')  DateTime? endDate, @JsonKey(name: 'max_members')  int maxMembers, @JsonKey(name: 'approval_required')  bool approvalRequired, @JsonKey(name: 'private_message')  String? privateMessage, @JsonKey(name: 'linked_trip_id')  String? linkedTripId)?  $default,) {final _that = this;
switch (_that) {
case _GroupEventCreateRequest() when $default != null:
return $default(_that.title,_that.description,_that.location,_that.startDate,_that.endDate,_that.maxMembers,_that.approvalRequired,_that.privateMessage,_that.linkedTripId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroupEventCreateRequest implements GroupEventCreateRequest {
  const _GroupEventCreateRequest({required this.title, required this.description, required this.location, @JsonKey(name: 'start_date') required this.startDate, @JsonKey(name: 'end_date') this.endDate, @JsonKey(name: 'max_members') required this.maxMembers, @JsonKey(name: 'approval_required') required this.approvalRequired, @JsonKey(name: 'private_message') this.privateMessage, @JsonKey(name: 'linked_trip_id') this.linkedTripId});
  factory _GroupEventCreateRequest.fromJson(Map<String, dynamic> json) => _$GroupEventCreateRequestFromJson(json);

@override final  String title;
@override final  String description;
@override final  String location;
@override@JsonKey(name: 'start_date') final  DateTime startDate;
@override@JsonKey(name: 'end_date') final  DateTime? endDate;
@override@JsonKey(name: 'max_members') final  int maxMembers;
@override@JsonKey(name: 'approval_required') final  bool approvalRequired;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupEventCreateRequest&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.location, location) || other.location == location)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.maxMembers, maxMembers) || other.maxMembers == maxMembers)&&(identical(other.approvalRequired, approvalRequired) || other.approvalRequired == approvalRequired)&&(identical(other.privateMessage, privateMessage) || other.privateMessage == privateMessage)&&(identical(other.linkedTripId, linkedTripId) || other.linkedTripId == linkedTripId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,description,location,startDate,endDate,maxMembers,approvalRequired,privateMessage,linkedTripId);

@override
String toString() {
  return 'GroupEventCreateRequest(title: $title, description: $description, location: $location, startDate: $startDate, endDate: $endDate, maxMembers: $maxMembers, approvalRequired: $approvalRequired, privateMessage: $privateMessage, linkedTripId: $linkedTripId)';
}


}

/// @nodoc
abstract mixin class _$GroupEventCreateRequestCopyWith<$Res> implements $GroupEventCreateRequestCopyWith<$Res> {
  factory _$GroupEventCreateRequestCopyWith(_GroupEventCreateRequest value, $Res Function(_GroupEventCreateRequest) _then) = __$GroupEventCreateRequestCopyWithImpl;
@override @useResult
$Res call({
 String title, String description, String location,@JsonKey(name: 'start_date') DateTime startDate,@JsonKey(name: 'end_date') DateTime? endDate,@JsonKey(name: 'max_members') int maxMembers,@JsonKey(name: 'approval_required') bool approvalRequired,@JsonKey(name: 'private_message') String? privateMessage,@JsonKey(name: 'linked_trip_id') String? linkedTripId
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
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? description = null,Object? location = null,Object? startDate = null,Object? endDate = freezed,Object? maxMembers = null,Object? approvalRequired = null,Object? privateMessage = freezed,Object? linkedTripId = freezed,}) {
  return _then(_GroupEventCreateRequest(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
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

 String? get title; String? get description; String? get location;@JsonKey(name: 'start_date') DateTime? get startDate;@JsonKey(name: 'end_date') DateTime? get endDate;@JsonKey(name: 'max_members') int? get maxMembers;@JsonKey(name: 'approval_required') bool? get approvalRequired;@JsonKey(name: 'private_message') String? get privateMessage;
/// Create a copy of GroupEventUpdateRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupEventUpdateRequestCopyWith<GroupEventUpdateRequest> get copyWith => _$GroupEventUpdateRequestCopyWithImpl<GroupEventUpdateRequest>(this as GroupEventUpdateRequest, _$identity);

  /// Serializes this GroupEventUpdateRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupEventUpdateRequest&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.location, location) || other.location == location)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.maxMembers, maxMembers) || other.maxMembers == maxMembers)&&(identical(other.approvalRequired, approvalRequired) || other.approvalRequired == approvalRequired)&&(identical(other.privateMessage, privateMessage) || other.privateMessage == privateMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,description,location,startDate,endDate,maxMembers,approvalRequired,privateMessage);

@override
String toString() {
  return 'GroupEventUpdateRequest(title: $title, description: $description, location: $location, startDate: $startDate, endDate: $endDate, maxMembers: $maxMembers, approvalRequired: $approvalRequired, privateMessage: $privateMessage)';
}


}

/// @nodoc
abstract mixin class $GroupEventUpdateRequestCopyWith<$Res>  {
  factory $GroupEventUpdateRequestCopyWith(GroupEventUpdateRequest value, $Res Function(GroupEventUpdateRequest) _then) = _$GroupEventUpdateRequestCopyWithImpl;
@useResult
$Res call({
 String? title, String? description, String? location,@JsonKey(name: 'start_date') DateTime? startDate,@JsonKey(name: 'end_date') DateTime? endDate,@JsonKey(name: 'max_members') int? maxMembers,@JsonKey(name: 'approval_required') bool? approvalRequired,@JsonKey(name: 'private_message') String? privateMessage
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
@pragma('vm:prefer-inline') @override $Res call({Object? title = freezed,Object? description = freezed,Object? location = freezed,Object? startDate = freezed,Object? endDate = freezed,Object? maxMembers = freezed,Object? approvalRequired = freezed,Object? privateMessage = freezed,}) {
  return _then(_self.copyWith(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? title,  String? description,  String? location, @JsonKey(name: 'start_date')  DateTime? startDate, @JsonKey(name: 'end_date')  DateTime? endDate, @JsonKey(name: 'max_members')  int? maxMembers, @JsonKey(name: 'approval_required')  bool? approvalRequired, @JsonKey(name: 'private_message')  String? privateMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupEventUpdateRequest() when $default != null:
return $default(_that.title,_that.description,_that.location,_that.startDate,_that.endDate,_that.maxMembers,_that.approvalRequired,_that.privateMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? title,  String? description,  String? location, @JsonKey(name: 'start_date')  DateTime? startDate, @JsonKey(name: 'end_date')  DateTime? endDate, @JsonKey(name: 'max_members')  int? maxMembers, @JsonKey(name: 'approval_required')  bool? approvalRequired, @JsonKey(name: 'private_message')  String? privateMessage)  $default,) {final _that = this;
switch (_that) {
case _GroupEventUpdateRequest():
return $default(_that.title,_that.description,_that.location,_that.startDate,_that.endDate,_that.maxMembers,_that.approvalRequired,_that.privateMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? title,  String? description,  String? location, @JsonKey(name: 'start_date')  DateTime? startDate, @JsonKey(name: 'end_date')  DateTime? endDate, @JsonKey(name: 'max_members')  int? maxMembers, @JsonKey(name: 'approval_required')  bool? approvalRequired, @JsonKey(name: 'private_message')  String? privateMessage)?  $default,) {final _that = this;
switch (_that) {
case _GroupEventUpdateRequest() when $default != null:
return $default(_that.title,_that.description,_that.location,_that.startDate,_that.endDate,_that.maxMembers,_that.approvalRequired,_that.privateMessage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroupEventUpdateRequest implements GroupEventUpdateRequest {
  const _GroupEventUpdateRequest({this.title, this.description, this.location, @JsonKey(name: 'start_date') this.startDate, @JsonKey(name: 'end_date') this.endDate, @JsonKey(name: 'max_members') this.maxMembers, @JsonKey(name: 'approval_required') this.approvalRequired, @JsonKey(name: 'private_message') this.privateMessage});
  factory _GroupEventUpdateRequest.fromJson(Map<String, dynamic> json) => _$GroupEventUpdateRequestFromJson(json);

@override final  String? title;
@override final  String? description;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupEventUpdateRequest&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.location, location) || other.location == location)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.maxMembers, maxMembers) || other.maxMembers == maxMembers)&&(identical(other.approvalRequired, approvalRequired) || other.approvalRequired == approvalRequired)&&(identical(other.privateMessage, privateMessage) || other.privateMessage == privateMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,description,location,startDate,endDate,maxMembers,approvalRequired,privateMessage);

@override
String toString() {
  return 'GroupEventUpdateRequest(title: $title, description: $description, location: $location, startDate: $startDate, endDate: $endDate, maxMembers: $maxMembers, approvalRequired: $approvalRequired, privateMessage: $privateMessage)';
}


}

/// @nodoc
abstract mixin class _$GroupEventUpdateRequestCopyWith<$Res> implements $GroupEventUpdateRequestCopyWith<$Res> {
  factory _$GroupEventUpdateRequestCopyWith(_GroupEventUpdateRequest value, $Res Function(_GroupEventUpdateRequest) _then) = __$GroupEventUpdateRequestCopyWithImpl;
@override @useResult
$Res call({
 String? title, String? description, String? location,@JsonKey(name: 'start_date') DateTime? startDate,@JsonKey(name: 'end_date') DateTime? endDate,@JsonKey(name: 'max_members') int? maxMembers,@JsonKey(name: 'approval_required') bool? approvalRequired,@JsonKey(name: 'private_message') String? privateMessage
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
@override @pragma('vm:prefer-inline') $Res call({Object? title = freezed,Object? description = freezed,Object? location = freezed,Object? startDate = freezed,Object? endDate = freezed,Object? maxMembers = freezed,Object? approvalRequired = freezed,Object? privateMessage = freezed,}) {
  return _then(_GroupEventUpdateRequest(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
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
