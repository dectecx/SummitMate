// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'poll_api_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PollOptionResponse {

 String get id;@JsonKey(name: 'poll_id') String get pollId; String get text;@JsonKey(name: 'creator_id') String get creatorId;@JsonKey(name: 'vote_count', defaultValue: 0) int get voteCount;@JsonKey(defaultValue: []) List<Map<String, dynamic>> get voters;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'created_by') String get createdBy;@JsonKey(name: 'updated_at') DateTime get updatedAt;@JsonKey(name: 'updated_by') String get updatedBy;
/// Create a copy of PollOptionResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PollOptionResponseCopyWith<PollOptionResponse> get copyWith => _$PollOptionResponseCopyWithImpl<PollOptionResponse>(this as PollOptionResponse, _$identity);

  /// Serializes this PollOptionResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PollOptionResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.pollId, pollId) || other.pollId == pollId)&&(identical(other.text, text) || other.text == text)&&(identical(other.creatorId, creatorId) || other.creatorId == creatorId)&&(identical(other.voteCount, voteCount) || other.voteCount == voteCount)&&const DeepCollectionEquality().equals(other.voters, voters)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,pollId,text,creatorId,voteCount,const DeepCollectionEquality().hash(voters),createdAt,createdBy,updatedAt,updatedBy);

@override
String toString() {
  return 'PollOptionResponse(id: $id, pollId: $pollId, text: $text, creatorId: $creatorId, voteCount: $voteCount, voters: $voters, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy)';
}


}

/// @nodoc
abstract mixin class $PollOptionResponseCopyWith<$Res>  {
  factory $PollOptionResponseCopyWith(PollOptionResponse value, $Res Function(PollOptionResponse) _then) = _$PollOptionResponseCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'poll_id') String pollId, String text,@JsonKey(name: 'creator_id') String creatorId,@JsonKey(name: 'vote_count', defaultValue: 0) int voteCount,@JsonKey(defaultValue: []) List<Map<String, dynamic>> voters,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'created_by') String createdBy,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'updated_by') String updatedBy
});




}
/// @nodoc
class _$PollOptionResponseCopyWithImpl<$Res>
    implements $PollOptionResponseCopyWith<$Res> {
  _$PollOptionResponseCopyWithImpl(this._self, this._then);

  final PollOptionResponse _self;
  final $Res Function(PollOptionResponse) _then;

/// Create a copy of PollOptionResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? pollId = null,Object? text = null,Object? creatorId = null,Object? voteCount = null,Object? voters = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,pollId: null == pollId ? _self.pollId : pollId // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,creatorId: null == creatorId ? _self.creatorId : creatorId // ignore: cast_nullable_to_non_nullable
as String,voteCount: null == voteCount ? _self.voteCount : voteCount // ignore: cast_nullable_to_non_nullable
as int,voters: null == voters ? _self.voters : voters // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PollOptionResponse].
extension PollOptionResponsePatterns on PollOptionResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PollOptionResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PollOptionResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PollOptionResponse value)  $default,){
final _that = this;
switch (_that) {
case _PollOptionResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PollOptionResponse value)?  $default,){
final _that = this;
switch (_that) {
case _PollOptionResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'poll_id')  String pollId,  String text, @JsonKey(name: 'creator_id')  String creatorId, @JsonKey(name: 'vote_count', defaultValue: 0)  int voteCount, @JsonKey(defaultValue: [])  List<Map<String, dynamic>> voters, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'created_by')  String createdBy, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'updated_by')  String updatedBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PollOptionResponse() when $default != null:
return $default(_that.id,_that.pollId,_that.text,_that.creatorId,_that.voteCount,_that.voters,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'poll_id')  String pollId,  String text, @JsonKey(name: 'creator_id')  String creatorId, @JsonKey(name: 'vote_count', defaultValue: 0)  int voteCount, @JsonKey(defaultValue: [])  List<Map<String, dynamic>> voters, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'created_by')  String createdBy, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'updated_by')  String updatedBy)  $default,) {final _that = this;
switch (_that) {
case _PollOptionResponse():
return $default(_that.id,_that.pollId,_that.text,_that.creatorId,_that.voteCount,_that.voters,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'poll_id')  String pollId,  String text, @JsonKey(name: 'creator_id')  String creatorId, @JsonKey(name: 'vote_count', defaultValue: 0)  int voteCount, @JsonKey(defaultValue: [])  List<Map<String, dynamic>> voters, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'created_by')  String createdBy, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'updated_by')  String updatedBy)?  $default,) {final _that = this;
switch (_that) {
case _PollOptionResponse() when $default != null:
return $default(_that.id,_that.pollId,_that.text,_that.creatorId,_that.voteCount,_that.voters,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PollOptionResponse implements PollOptionResponse {
  const _PollOptionResponse({required this.id, @JsonKey(name: 'poll_id') required this.pollId, required this.text, @JsonKey(name: 'creator_id') required this.creatorId, @JsonKey(name: 'vote_count', defaultValue: 0) required this.voteCount, @JsonKey(defaultValue: []) required final  List<Map<String, dynamic>> voters, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'created_by') required this.createdBy, @JsonKey(name: 'updated_at') required this.updatedAt, @JsonKey(name: 'updated_by') required this.updatedBy}): _voters = voters;
  factory _PollOptionResponse.fromJson(Map<String, dynamic> json) => _$PollOptionResponseFromJson(json);

@override final  String id;
@override@JsonKey(name: 'poll_id') final  String pollId;
@override final  String text;
@override@JsonKey(name: 'creator_id') final  String creatorId;
@override@JsonKey(name: 'vote_count', defaultValue: 0) final  int voteCount;
 final  List<Map<String, dynamic>> _voters;
@override@JsonKey(defaultValue: []) List<Map<String, dynamic>> get voters {
  if (_voters is EqualUnmodifiableListView) return _voters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_voters);
}

@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'created_by') final  String createdBy;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;
@override@JsonKey(name: 'updated_by') final  String updatedBy;

/// Create a copy of PollOptionResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PollOptionResponseCopyWith<_PollOptionResponse> get copyWith => __$PollOptionResponseCopyWithImpl<_PollOptionResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PollOptionResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PollOptionResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.pollId, pollId) || other.pollId == pollId)&&(identical(other.text, text) || other.text == text)&&(identical(other.creatorId, creatorId) || other.creatorId == creatorId)&&(identical(other.voteCount, voteCount) || other.voteCount == voteCount)&&const DeepCollectionEquality().equals(other._voters, _voters)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,pollId,text,creatorId,voteCount,const DeepCollectionEquality().hash(_voters),createdAt,createdBy,updatedAt,updatedBy);

@override
String toString() {
  return 'PollOptionResponse(id: $id, pollId: $pollId, text: $text, creatorId: $creatorId, voteCount: $voteCount, voters: $voters, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy)';
}


}

/// @nodoc
abstract mixin class _$PollOptionResponseCopyWith<$Res> implements $PollOptionResponseCopyWith<$Res> {
  factory _$PollOptionResponseCopyWith(_PollOptionResponse value, $Res Function(_PollOptionResponse) _then) = __$PollOptionResponseCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'poll_id') String pollId, String text,@JsonKey(name: 'creator_id') String creatorId,@JsonKey(name: 'vote_count', defaultValue: 0) int voteCount,@JsonKey(defaultValue: []) List<Map<String, dynamic>> voters,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'created_by') String createdBy,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'updated_by') String updatedBy
});




}
/// @nodoc
class __$PollOptionResponseCopyWithImpl<$Res>
    implements _$PollOptionResponseCopyWith<$Res> {
  __$PollOptionResponseCopyWithImpl(this._self, this._then);

  final _PollOptionResponse _self;
  final $Res Function(_PollOptionResponse) _then;

/// Create a copy of PollOptionResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? pollId = null,Object? text = null,Object? creatorId = null,Object? voteCount = null,Object? voters = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,}) {
  return _then(_PollOptionResponse(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,pollId: null == pollId ? _self.pollId : pollId // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,creatorId: null == creatorId ? _self.creatorId : creatorId // ignore: cast_nullable_to_non_nullable
as String,voteCount: null == voteCount ? _self.voteCount : voteCount // ignore: cast_nullable_to_non_nullable
as int,voters: null == voters ? _self._voters : voters // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PollResponse {

 String get id; String get title;@JsonKey(defaultValue: '') String get description;@JsonKey(name: 'creator_id') String get creatorId; DateTime? get deadline;@JsonKey(name: 'is_allow_add_option', defaultValue: false) bool get isAllowAddOption;@JsonKey(name: 'max_option_limit', defaultValue: 20) int get maxOptionLimit;@JsonKey(name: 'allow_multiple_votes', defaultValue: false) bool get allowMultipleVotes;@JsonKey(name: 'result_display_type', defaultValue: 'realtime') String get resultDisplayType;@JsonKey(defaultValue: 'active') String get status;@JsonKey(defaultValue: []) List<PollOptionResponse> get options;@JsonKey(name: 'my_votes', defaultValue: []) List<String> get myVotes;@JsonKey(name: 'total_votes', defaultValue: 0) int get totalVotes;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'created_by') String get createdBy;@JsonKey(name: 'updated_at') DateTime get updatedAt;@JsonKey(name: 'updated_by') String get updatedBy;
/// Create a copy of PollResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PollResponseCopyWith<PollResponse> get copyWith => _$PollResponseCopyWithImpl<PollResponse>(this as PollResponse, _$identity);

  /// Serializes this PollResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PollResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.creatorId, creatorId) || other.creatorId == creatorId)&&(identical(other.deadline, deadline) || other.deadline == deadline)&&(identical(other.isAllowAddOption, isAllowAddOption) || other.isAllowAddOption == isAllowAddOption)&&(identical(other.maxOptionLimit, maxOptionLimit) || other.maxOptionLimit == maxOptionLimit)&&(identical(other.allowMultipleVotes, allowMultipleVotes) || other.allowMultipleVotes == allowMultipleVotes)&&(identical(other.resultDisplayType, resultDisplayType) || other.resultDisplayType == resultDisplayType)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.options, options)&&const DeepCollectionEquality().equals(other.myVotes, myVotes)&&(identical(other.totalVotes, totalVotes) || other.totalVotes == totalVotes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,creatorId,deadline,isAllowAddOption,maxOptionLimit,allowMultipleVotes,resultDisplayType,status,const DeepCollectionEquality().hash(options),const DeepCollectionEquality().hash(myVotes),totalVotes,createdAt,createdBy,updatedAt,updatedBy);

@override
String toString() {
  return 'PollResponse(id: $id, title: $title, description: $description, creatorId: $creatorId, deadline: $deadline, isAllowAddOption: $isAllowAddOption, maxOptionLimit: $maxOptionLimit, allowMultipleVotes: $allowMultipleVotes, resultDisplayType: $resultDisplayType, status: $status, options: $options, myVotes: $myVotes, totalVotes: $totalVotes, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy)';
}


}

/// @nodoc
abstract mixin class $PollResponseCopyWith<$Res>  {
  factory $PollResponseCopyWith(PollResponse value, $Res Function(PollResponse) _then) = _$PollResponseCopyWithImpl;
@useResult
$Res call({
 String id, String title,@JsonKey(defaultValue: '') String description,@JsonKey(name: 'creator_id') String creatorId, DateTime? deadline,@JsonKey(name: 'is_allow_add_option', defaultValue: false) bool isAllowAddOption,@JsonKey(name: 'max_option_limit', defaultValue: 20) int maxOptionLimit,@JsonKey(name: 'allow_multiple_votes', defaultValue: false) bool allowMultipleVotes,@JsonKey(name: 'result_display_type', defaultValue: 'realtime') String resultDisplayType,@JsonKey(defaultValue: 'active') String status,@JsonKey(defaultValue: []) List<PollOptionResponse> options,@JsonKey(name: 'my_votes', defaultValue: []) List<String> myVotes,@JsonKey(name: 'total_votes', defaultValue: 0) int totalVotes,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'created_by') String createdBy,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'updated_by') String updatedBy
});




}
/// @nodoc
class _$PollResponseCopyWithImpl<$Res>
    implements $PollResponseCopyWith<$Res> {
  _$PollResponseCopyWithImpl(this._self, this._then);

  final PollResponse _self;
  final $Res Function(PollResponse) _then;

/// Create a copy of PollResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = null,Object? creatorId = null,Object? deadline = freezed,Object? isAllowAddOption = null,Object? maxOptionLimit = null,Object? allowMultipleVotes = null,Object? resultDisplayType = null,Object? status = null,Object? options = null,Object? myVotes = null,Object? totalVotes = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,creatorId: null == creatorId ? _self.creatorId : creatorId // ignore: cast_nullable_to_non_nullable
as String,deadline: freezed == deadline ? _self.deadline : deadline // ignore: cast_nullable_to_non_nullable
as DateTime?,isAllowAddOption: null == isAllowAddOption ? _self.isAllowAddOption : isAllowAddOption // ignore: cast_nullable_to_non_nullable
as bool,maxOptionLimit: null == maxOptionLimit ? _self.maxOptionLimit : maxOptionLimit // ignore: cast_nullable_to_non_nullable
as int,allowMultipleVotes: null == allowMultipleVotes ? _self.allowMultipleVotes : allowMultipleVotes // ignore: cast_nullable_to_non_nullable
as bool,resultDisplayType: null == resultDisplayType ? _self.resultDisplayType : resultDisplayType // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as List<PollOptionResponse>,myVotes: null == myVotes ? _self.myVotes : myVotes // ignore: cast_nullable_to_non_nullable
as List<String>,totalVotes: null == totalVotes ? _self.totalVotes : totalVotes // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PollResponse].
extension PollResponsePatterns on PollResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PollResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PollResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PollResponse value)  $default,){
final _that = this;
switch (_that) {
case _PollResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PollResponse value)?  $default,){
final _that = this;
switch (_that) {
case _PollResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title, @JsonKey(defaultValue: '')  String description, @JsonKey(name: 'creator_id')  String creatorId,  DateTime? deadline, @JsonKey(name: 'is_allow_add_option', defaultValue: false)  bool isAllowAddOption, @JsonKey(name: 'max_option_limit', defaultValue: 20)  int maxOptionLimit, @JsonKey(name: 'allow_multiple_votes', defaultValue: false)  bool allowMultipleVotes, @JsonKey(name: 'result_display_type', defaultValue: 'realtime')  String resultDisplayType, @JsonKey(defaultValue: 'active')  String status, @JsonKey(defaultValue: [])  List<PollOptionResponse> options, @JsonKey(name: 'my_votes', defaultValue: [])  List<String> myVotes, @JsonKey(name: 'total_votes', defaultValue: 0)  int totalVotes, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'created_by')  String createdBy, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'updated_by')  String updatedBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PollResponse() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.creatorId,_that.deadline,_that.isAllowAddOption,_that.maxOptionLimit,_that.allowMultipleVotes,_that.resultDisplayType,_that.status,_that.options,_that.myVotes,_that.totalVotes,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title, @JsonKey(defaultValue: '')  String description, @JsonKey(name: 'creator_id')  String creatorId,  DateTime? deadline, @JsonKey(name: 'is_allow_add_option', defaultValue: false)  bool isAllowAddOption, @JsonKey(name: 'max_option_limit', defaultValue: 20)  int maxOptionLimit, @JsonKey(name: 'allow_multiple_votes', defaultValue: false)  bool allowMultipleVotes, @JsonKey(name: 'result_display_type', defaultValue: 'realtime')  String resultDisplayType, @JsonKey(defaultValue: 'active')  String status, @JsonKey(defaultValue: [])  List<PollOptionResponse> options, @JsonKey(name: 'my_votes', defaultValue: [])  List<String> myVotes, @JsonKey(name: 'total_votes', defaultValue: 0)  int totalVotes, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'created_by')  String createdBy, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'updated_by')  String updatedBy)  $default,) {final _that = this;
switch (_that) {
case _PollResponse():
return $default(_that.id,_that.title,_that.description,_that.creatorId,_that.deadline,_that.isAllowAddOption,_that.maxOptionLimit,_that.allowMultipleVotes,_that.resultDisplayType,_that.status,_that.options,_that.myVotes,_that.totalVotes,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title, @JsonKey(defaultValue: '')  String description, @JsonKey(name: 'creator_id')  String creatorId,  DateTime? deadline, @JsonKey(name: 'is_allow_add_option', defaultValue: false)  bool isAllowAddOption, @JsonKey(name: 'max_option_limit', defaultValue: 20)  int maxOptionLimit, @JsonKey(name: 'allow_multiple_votes', defaultValue: false)  bool allowMultipleVotes, @JsonKey(name: 'result_display_type', defaultValue: 'realtime')  String resultDisplayType, @JsonKey(defaultValue: 'active')  String status, @JsonKey(defaultValue: [])  List<PollOptionResponse> options, @JsonKey(name: 'my_votes', defaultValue: [])  List<String> myVotes, @JsonKey(name: 'total_votes', defaultValue: 0)  int totalVotes, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'created_by')  String createdBy, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'updated_by')  String updatedBy)?  $default,) {final _that = this;
switch (_that) {
case _PollResponse() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.creatorId,_that.deadline,_that.isAllowAddOption,_that.maxOptionLimit,_that.allowMultipleVotes,_that.resultDisplayType,_that.status,_that.options,_that.myVotes,_that.totalVotes,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PollResponse implements PollResponse {
  const _PollResponse({required this.id, required this.title, @JsonKey(defaultValue: '') required this.description, @JsonKey(name: 'creator_id') required this.creatorId, this.deadline, @JsonKey(name: 'is_allow_add_option', defaultValue: false) required this.isAllowAddOption, @JsonKey(name: 'max_option_limit', defaultValue: 20) required this.maxOptionLimit, @JsonKey(name: 'allow_multiple_votes', defaultValue: false) required this.allowMultipleVotes, @JsonKey(name: 'result_display_type', defaultValue: 'realtime') required this.resultDisplayType, @JsonKey(defaultValue: 'active') required this.status, @JsonKey(defaultValue: []) required final  List<PollOptionResponse> options, @JsonKey(name: 'my_votes', defaultValue: []) required final  List<String> myVotes, @JsonKey(name: 'total_votes', defaultValue: 0) required this.totalVotes, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'created_by') required this.createdBy, @JsonKey(name: 'updated_at') required this.updatedAt, @JsonKey(name: 'updated_by') required this.updatedBy}): _options = options,_myVotes = myVotes;
  factory _PollResponse.fromJson(Map<String, dynamic> json) => _$PollResponseFromJson(json);

@override final  String id;
@override final  String title;
@override@JsonKey(defaultValue: '') final  String description;
@override@JsonKey(name: 'creator_id') final  String creatorId;
@override final  DateTime? deadline;
@override@JsonKey(name: 'is_allow_add_option', defaultValue: false) final  bool isAllowAddOption;
@override@JsonKey(name: 'max_option_limit', defaultValue: 20) final  int maxOptionLimit;
@override@JsonKey(name: 'allow_multiple_votes', defaultValue: false) final  bool allowMultipleVotes;
@override@JsonKey(name: 'result_display_type', defaultValue: 'realtime') final  String resultDisplayType;
@override@JsonKey(defaultValue: 'active') final  String status;
 final  List<PollOptionResponse> _options;
@override@JsonKey(defaultValue: []) List<PollOptionResponse> get options {
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_options);
}

 final  List<String> _myVotes;
@override@JsonKey(name: 'my_votes', defaultValue: []) List<String> get myVotes {
  if (_myVotes is EqualUnmodifiableListView) return _myVotes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_myVotes);
}

@override@JsonKey(name: 'total_votes', defaultValue: 0) final  int totalVotes;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'created_by') final  String createdBy;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;
@override@JsonKey(name: 'updated_by') final  String updatedBy;

/// Create a copy of PollResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PollResponseCopyWith<_PollResponse> get copyWith => __$PollResponseCopyWithImpl<_PollResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PollResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PollResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.creatorId, creatorId) || other.creatorId == creatorId)&&(identical(other.deadline, deadline) || other.deadline == deadline)&&(identical(other.isAllowAddOption, isAllowAddOption) || other.isAllowAddOption == isAllowAddOption)&&(identical(other.maxOptionLimit, maxOptionLimit) || other.maxOptionLimit == maxOptionLimit)&&(identical(other.allowMultipleVotes, allowMultipleVotes) || other.allowMultipleVotes == allowMultipleVotes)&&(identical(other.resultDisplayType, resultDisplayType) || other.resultDisplayType == resultDisplayType)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._options, _options)&&const DeepCollectionEquality().equals(other._myVotes, _myVotes)&&(identical(other.totalVotes, totalVotes) || other.totalVotes == totalVotes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,creatorId,deadline,isAllowAddOption,maxOptionLimit,allowMultipleVotes,resultDisplayType,status,const DeepCollectionEquality().hash(_options),const DeepCollectionEquality().hash(_myVotes),totalVotes,createdAt,createdBy,updatedAt,updatedBy);

@override
String toString() {
  return 'PollResponse(id: $id, title: $title, description: $description, creatorId: $creatorId, deadline: $deadline, isAllowAddOption: $isAllowAddOption, maxOptionLimit: $maxOptionLimit, allowMultipleVotes: $allowMultipleVotes, resultDisplayType: $resultDisplayType, status: $status, options: $options, myVotes: $myVotes, totalVotes: $totalVotes, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy)';
}


}

/// @nodoc
abstract mixin class _$PollResponseCopyWith<$Res> implements $PollResponseCopyWith<$Res> {
  factory _$PollResponseCopyWith(_PollResponse value, $Res Function(_PollResponse) _then) = __$PollResponseCopyWithImpl;
@override @useResult
$Res call({
 String id, String title,@JsonKey(defaultValue: '') String description,@JsonKey(name: 'creator_id') String creatorId, DateTime? deadline,@JsonKey(name: 'is_allow_add_option', defaultValue: false) bool isAllowAddOption,@JsonKey(name: 'max_option_limit', defaultValue: 20) int maxOptionLimit,@JsonKey(name: 'allow_multiple_votes', defaultValue: false) bool allowMultipleVotes,@JsonKey(name: 'result_display_type', defaultValue: 'realtime') String resultDisplayType,@JsonKey(defaultValue: 'active') String status,@JsonKey(defaultValue: []) List<PollOptionResponse> options,@JsonKey(name: 'my_votes', defaultValue: []) List<String> myVotes,@JsonKey(name: 'total_votes', defaultValue: 0) int totalVotes,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'created_by') String createdBy,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'updated_by') String updatedBy
});




}
/// @nodoc
class __$PollResponseCopyWithImpl<$Res>
    implements _$PollResponseCopyWith<$Res> {
  __$PollResponseCopyWithImpl(this._self, this._then);

  final _PollResponse _self;
  final $Res Function(_PollResponse) _then;

/// Create a copy of PollResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = null,Object? creatorId = null,Object? deadline = freezed,Object? isAllowAddOption = null,Object? maxOptionLimit = null,Object? allowMultipleVotes = null,Object? resultDisplayType = null,Object? status = null,Object? options = null,Object? myVotes = null,Object? totalVotes = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,}) {
  return _then(_PollResponse(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,creatorId: null == creatorId ? _self.creatorId : creatorId // ignore: cast_nullable_to_non_nullable
as String,deadline: freezed == deadline ? _self.deadline : deadline // ignore: cast_nullable_to_non_nullable
as DateTime?,isAllowAddOption: null == isAllowAddOption ? _self.isAllowAddOption : isAllowAddOption // ignore: cast_nullable_to_non_nullable
as bool,maxOptionLimit: null == maxOptionLimit ? _self.maxOptionLimit : maxOptionLimit // ignore: cast_nullable_to_non_nullable
as int,allowMultipleVotes: null == allowMultipleVotes ? _self.allowMultipleVotes : allowMultipleVotes // ignore: cast_nullable_to_non_nullable
as bool,resultDisplayType: null == resultDisplayType ? _self.resultDisplayType : resultDisplayType // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,options: null == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<PollOptionResponse>,myVotes: null == myVotes ? _self._myVotes : myVotes // ignore: cast_nullable_to_non_nullable
as List<String>,totalVotes: null == totalVotes ? _self.totalVotes : totalVotes // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PollCreateRequest {

 String get title;@JsonKey(defaultValue: '') String? get description; DateTime? get deadline;@JsonKey(name: 'initial_options', defaultValue: []) List<String> get initialOptions;@JsonKey(name: 'is_allow_add_option', defaultValue: false) bool get isAllowAddOption;@JsonKey(name: 'max_option_limit', defaultValue: 20) int get maxOptionLimit;@JsonKey(name: 'allow_multiple_votes', defaultValue: false) bool get allowMultipleVotes;@JsonKey(name: 'result_display_type', defaultValue: 'realtime') String get resultDisplayType;
/// Create a copy of PollCreateRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PollCreateRequestCopyWith<PollCreateRequest> get copyWith => _$PollCreateRequestCopyWithImpl<PollCreateRequest>(this as PollCreateRequest, _$identity);

  /// Serializes this PollCreateRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PollCreateRequest&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.deadline, deadline) || other.deadline == deadline)&&const DeepCollectionEquality().equals(other.initialOptions, initialOptions)&&(identical(other.isAllowAddOption, isAllowAddOption) || other.isAllowAddOption == isAllowAddOption)&&(identical(other.maxOptionLimit, maxOptionLimit) || other.maxOptionLimit == maxOptionLimit)&&(identical(other.allowMultipleVotes, allowMultipleVotes) || other.allowMultipleVotes == allowMultipleVotes)&&(identical(other.resultDisplayType, resultDisplayType) || other.resultDisplayType == resultDisplayType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,description,deadline,const DeepCollectionEquality().hash(initialOptions),isAllowAddOption,maxOptionLimit,allowMultipleVotes,resultDisplayType);

@override
String toString() {
  return 'PollCreateRequest(title: $title, description: $description, deadline: $deadline, initialOptions: $initialOptions, isAllowAddOption: $isAllowAddOption, maxOptionLimit: $maxOptionLimit, allowMultipleVotes: $allowMultipleVotes, resultDisplayType: $resultDisplayType)';
}


}

/// @nodoc
abstract mixin class $PollCreateRequestCopyWith<$Res>  {
  factory $PollCreateRequestCopyWith(PollCreateRequest value, $Res Function(PollCreateRequest) _then) = _$PollCreateRequestCopyWithImpl;
@useResult
$Res call({
 String title,@JsonKey(defaultValue: '') String? description, DateTime? deadline,@JsonKey(name: 'initial_options', defaultValue: []) List<String> initialOptions,@JsonKey(name: 'is_allow_add_option', defaultValue: false) bool isAllowAddOption,@JsonKey(name: 'max_option_limit', defaultValue: 20) int maxOptionLimit,@JsonKey(name: 'allow_multiple_votes', defaultValue: false) bool allowMultipleVotes,@JsonKey(name: 'result_display_type', defaultValue: 'realtime') String resultDisplayType
});




}
/// @nodoc
class _$PollCreateRequestCopyWithImpl<$Res>
    implements $PollCreateRequestCopyWith<$Res> {
  _$PollCreateRequestCopyWithImpl(this._self, this._then);

  final PollCreateRequest _self;
  final $Res Function(PollCreateRequest) _then;

/// Create a copy of PollCreateRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? description = freezed,Object? deadline = freezed,Object? initialOptions = null,Object? isAllowAddOption = null,Object? maxOptionLimit = null,Object? allowMultipleVotes = null,Object? resultDisplayType = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,deadline: freezed == deadline ? _self.deadline : deadline // ignore: cast_nullable_to_non_nullable
as DateTime?,initialOptions: null == initialOptions ? _self.initialOptions : initialOptions // ignore: cast_nullable_to_non_nullable
as List<String>,isAllowAddOption: null == isAllowAddOption ? _self.isAllowAddOption : isAllowAddOption // ignore: cast_nullable_to_non_nullable
as bool,maxOptionLimit: null == maxOptionLimit ? _self.maxOptionLimit : maxOptionLimit // ignore: cast_nullable_to_non_nullable
as int,allowMultipleVotes: null == allowMultipleVotes ? _self.allowMultipleVotes : allowMultipleVotes // ignore: cast_nullable_to_non_nullable
as bool,resultDisplayType: null == resultDisplayType ? _self.resultDisplayType : resultDisplayType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PollCreateRequest].
extension PollCreateRequestPatterns on PollCreateRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PollCreateRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PollCreateRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PollCreateRequest value)  $default,){
final _that = this;
switch (_that) {
case _PollCreateRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PollCreateRequest value)?  $default,){
final _that = this;
switch (_that) {
case _PollCreateRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title, @JsonKey(defaultValue: '')  String? description,  DateTime? deadline, @JsonKey(name: 'initial_options', defaultValue: [])  List<String> initialOptions, @JsonKey(name: 'is_allow_add_option', defaultValue: false)  bool isAllowAddOption, @JsonKey(name: 'max_option_limit', defaultValue: 20)  int maxOptionLimit, @JsonKey(name: 'allow_multiple_votes', defaultValue: false)  bool allowMultipleVotes, @JsonKey(name: 'result_display_type', defaultValue: 'realtime')  String resultDisplayType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PollCreateRequest() when $default != null:
return $default(_that.title,_that.description,_that.deadline,_that.initialOptions,_that.isAllowAddOption,_that.maxOptionLimit,_that.allowMultipleVotes,_that.resultDisplayType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title, @JsonKey(defaultValue: '')  String? description,  DateTime? deadline, @JsonKey(name: 'initial_options', defaultValue: [])  List<String> initialOptions, @JsonKey(name: 'is_allow_add_option', defaultValue: false)  bool isAllowAddOption, @JsonKey(name: 'max_option_limit', defaultValue: 20)  int maxOptionLimit, @JsonKey(name: 'allow_multiple_votes', defaultValue: false)  bool allowMultipleVotes, @JsonKey(name: 'result_display_type', defaultValue: 'realtime')  String resultDisplayType)  $default,) {final _that = this;
switch (_that) {
case _PollCreateRequest():
return $default(_that.title,_that.description,_that.deadline,_that.initialOptions,_that.isAllowAddOption,_that.maxOptionLimit,_that.allowMultipleVotes,_that.resultDisplayType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title, @JsonKey(defaultValue: '')  String? description,  DateTime? deadline, @JsonKey(name: 'initial_options', defaultValue: [])  List<String> initialOptions, @JsonKey(name: 'is_allow_add_option', defaultValue: false)  bool isAllowAddOption, @JsonKey(name: 'max_option_limit', defaultValue: 20)  int maxOptionLimit, @JsonKey(name: 'allow_multiple_votes', defaultValue: false)  bool allowMultipleVotes, @JsonKey(name: 'result_display_type', defaultValue: 'realtime')  String resultDisplayType)?  $default,) {final _that = this;
switch (_that) {
case _PollCreateRequest() when $default != null:
return $default(_that.title,_that.description,_that.deadline,_that.initialOptions,_that.isAllowAddOption,_that.maxOptionLimit,_that.allowMultipleVotes,_that.resultDisplayType);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PollCreateRequest implements PollCreateRequest {
  const _PollCreateRequest({required this.title, @JsonKey(defaultValue: '') this.description, this.deadline, @JsonKey(name: 'initial_options', defaultValue: []) required final  List<String> initialOptions, @JsonKey(name: 'is_allow_add_option', defaultValue: false) required this.isAllowAddOption, @JsonKey(name: 'max_option_limit', defaultValue: 20) required this.maxOptionLimit, @JsonKey(name: 'allow_multiple_votes', defaultValue: false) required this.allowMultipleVotes, @JsonKey(name: 'result_display_type', defaultValue: 'realtime') required this.resultDisplayType}): _initialOptions = initialOptions;
  factory _PollCreateRequest.fromJson(Map<String, dynamic> json) => _$PollCreateRequestFromJson(json);

@override final  String title;
@override@JsonKey(defaultValue: '') final  String? description;
@override final  DateTime? deadline;
 final  List<String> _initialOptions;
@override@JsonKey(name: 'initial_options', defaultValue: []) List<String> get initialOptions {
  if (_initialOptions is EqualUnmodifiableListView) return _initialOptions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_initialOptions);
}

@override@JsonKey(name: 'is_allow_add_option', defaultValue: false) final  bool isAllowAddOption;
@override@JsonKey(name: 'max_option_limit', defaultValue: 20) final  int maxOptionLimit;
@override@JsonKey(name: 'allow_multiple_votes', defaultValue: false) final  bool allowMultipleVotes;
@override@JsonKey(name: 'result_display_type', defaultValue: 'realtime') final  String resultDisplayType;

/// Create a copy of PollCreateRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PollCreateRequestCopyWith<_PollCreateRequest> get copyWith => __$PollCreateRequestCopyWithImpl<_PollCreateRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PollCreateRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PollCreateRequest&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.deadline, deadline) || other.deadline == deadline)&&const DeepCollectionEquality().equals(other._initialOptions, _initialOptions)&&(identical(other.isAllowAddOption, isAllowAddOption) || other.isAllowAddOption == isAllowAddOption)&&(identical(other.maxOptionLimit, maxOptionLimit) || other.maxOptionLimit == maxOptionLimit)&&(identical(other.allowMultipleVotes, allowMultipleVotes) || other.allowMultipleVotes == allowMultipleVotes)&&(identical(other.resultDisplayType, resultDisplayType) || other.resultDisplayType == resultDisplayType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,description,deadline,const DeepCollectionEquality().hash(_initialOptions),isAllowAddOption,maxOptionLimit,allowMultipleVotes,resultDisplayType);

@override
String toString() {
  return 'PollCreateRequest(title: $title, description: $description, deadline: $deadline, initialOptions: $initialOptions, isAllowAddOption: $isAllowAddOption, maxOptionLimit: $maxOptionLimit, allowMultipleVotes: $allowMultipleVotes, resultDisplayType: $resultDisplayType)';
}


}

/// @nodoc
abstract mixin class _$PollCreateRequestCopyWith<$Res> implements $PollCreateRequestCopyWith<$Res> {
  factory _$PollCreateRequestCopyWith(_PollCreateRequest value, $Res Function(_PollCreateRequest) _then) = __$PollCreateRequestCopyWithImpl;
@override @useResult
$Res call({
 String title,@JsonKey(defaultValue: '') String? description, DateTime? deadline,@JsonKey(name: 'initial_options', defaultValue: []) List<String> initialOptions,@JsonKey(name: 'is_allow_add_option', defaultValue: false) bool isAllowAddOption,@JsonKey(name: 'max_option_limit', defaultValue: 20) int maxOptionLimit,@JsonKey(name: 'allow_multiple_votes', defaultValue: false) bool allowMultipleVotes,@JsonKey(name: 'result_display_type', defaultValue: 'realtime') String resultDisplayType
});




}
/// @nodoc
class __$PollCreateRequestCopyWithImpl<$Res>
    implements _$PollCreateRequestCopyWith<$Res> {
  __$PollCreateRequestCopyWithImpl(this._self, this._then);

  final _PollCreateRequest _self;
  final $Res Function(_PollCreateRequest) _then;

/// Create a copy of PollCreateRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? description = freezed,Object? deadline = freezed,Object? initialOptions = null,Object? isAllowAddOption = null,Object? maxOptionLimit = null,Object? allowMultipleVotes = null,Object? resultDisplayType = null,}) {
  return _then(_PollCreateRequest(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,deadline: freezed == deadline ? _self.deadline : deadline // ignore: cast_nullable_to_non_nullable
as DateTime?,initialOptions: null == initialOptions ? _self._initialOptions : initialOptions // ignore: cast_nullable_to_non_nullable
as List<String>,isAllowAddOption: null == isAllowAddOption ? _self.isAllowAddOption : isAllowAddOption // ignore: cast_nullable_to_non_nullable
as bool,maxOptionLimit: null == maxOptionLimit ? _self.maxOptionLimit : maxOptionLimit // ignore: cast_nullable_to_non_nullable
as int,allowMultipleVotes: null == allowMultipleVotes ? _self.allowMultipleVotes : allowMultipleVotes // ignore: cast_nullable_to_non_nullable
as bool,resultDisplayType: null == resultDisplayType ? _self.resultDisplayType : resultDisplayType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PollOptionRequest {

 String get text;
/// Create a copy of PollOptionRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PollOptionRequestCopyWith<PollOptionRequest> get copyWith => _$PollOptionRequestCopyWithImpl<PollOptionRequest>(this as PollOptionRequest, _$identity);

  /// Serializes this PollOptionRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PollOptionRequest&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text);

@override
String toString() {
  return 'PollOptionRequest(text: $text)';
}


}

/// @nodoc
abstract mixin class $PollOptionRequestCopyWith<$Res>  {
  factory $PollOptionRequestCopyWith(PollOptionRequest value, $Res Function(PollOptionRequest) _then) = _$PollOptionRequestCopyWithImpl;
@useResult
$Res call({
 String text
});




}
/// @nodoc
class _$PollOptionRequestCopyWithImpl<$Res>
    implements $PollOptionRequestCopyWith<$Res> {
  _$PollOptionRequestCopyWithImpl(this._self, this._then);

  final PollOptionRequest _self;
  final $Res Function(PollOptionRequest) _then;

/// Create a copy of PollOptionRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,}) {
  return _then(_self.copyWith(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PollOptionRequest].
extension PollOptionRequestPatterns on PollOptionRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PollOptionRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PollOptionRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PollOptionRequest value)  $default,){
final _that = this;
switch (_that) {
case _PollOptionRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PollOptionRequest value)?  $default,){
final _that = this;
switch (_that) {
case _PollOptionRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String text)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PollOptionRequest() when $default != null:
return $default(_that.text);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String text)  $default,) {final _that = this;
switch (_that) {
case _PollOptionRequest():
return $default(_that.text);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String text)?  $default,) {final _that = this;
switch (_that) {
case _PollOptionRequest() when $default != null:
return $default(_that.text);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PollOptionRequest implements PollOptionRequest {
  const _PollOptionRequest({required this.text});
  factory _PollOptionRequest.fromJson(Map<String, dynamic> json) => _$PollOptionRequestFromJson(json);

@override final  String text;

/// Create a copy of PollOptionRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PollOptionRequestCopyWith<_PollOptionRequest> get copyWith => __$PollOptionRequestCopyWithImpl<_PollOptionRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PollOptionRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PollOptionRequest&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text);

@override
String toString() {
  return 'PollOptionRequest(text: $text)';
}


}

/// @nodoc
abstract mixin class _$PollOptionRequestCopyWith<$Res> implements $PollOptionRequestCopyWith<$Res> {
  factory _$PollOptionRequestCopyWith(_PollOptionRequest value, $Res Function(_PollOptionRequest) _then) = __$PollOptionRequestCopyWithImpl;
@override @useResult
$Res call({
 String text
});




}
/// @nodoc
class __$PollOptionRequestCopyWithImpl<$Res>
    implements _$PollOptionRequestCopyWith<$Res> {
  __$PollOptionRequestCopyWithImpl(this._self, this._then);

  final _PollOptionRequest _self;
  final $Res Function(_PollOptionRequest) _then;

/// Create a copy of PollOptionRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(_PollOptionRequest(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
