// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'poll.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Poll {

 String get id; String get tripId; String get title; String get description; String get creatorId; DateTime? get deadline; bool get isAllowAddOption; int get maxOptionLimit; bool get allowMultipleVotes; String get resultDisplayType; String get status; List<PollOption> get options; List<String> get myVotes; int get totalVotes; DateTime get createdAt; String get createdBy; DateTime get updatedAt; String get updatedBy;
/// Create a copy of Poll
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PollCopyWith<Poll> get copyWith => _$PollCopyWithImpl<Poll>(this as Poll, _$identity);

  /// Serializes this Poll to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Poll&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.creatorId, creatorId) || other.creatorId == creatorId)&&(identical(other.deadline, deadline) || other.deadline == deadline)&&(identical(other.isAllowAddOption, isAllowAddOption) || other.isAllowAddOption == isAllowAddOption)&&(identical(other.maxOptionLimit, maxOptionLimit) || other.maxOptionLimit == maxOptionLimit)&&(identical(other.allowMultipleVotes, allowMultipleVotes) || other.allowMultipleVotes == allowMultipleVotes)&&(identical(other.resultDisplayType, resultDisplayType) || other.resultDisplayType == resultDisplayType)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.options, options)&&const DeepCollectionEquality().equals(other.myVotes, myVotes)&&(identical(other.totalVotes, totalVotes) || other.totalVotes == totalVotes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,title,description,creatorId,deadline,isAllowAddOption,maxOptionLimit,allowMultipleVotes,resultDisplayType,status,const DeepCollectionEquality().hash(options),const DeepCollectionEquality().hash(myVotes),totalVotes,createdAt,createdBy,updatedAt,updatedBy);

@override
String toString() {
  return 'Poll(id: $id, tripId: $tripId, title: $title, description: $description, creatorId: $creatorId, deadline: $deadline, isAllowAddOption: $isAllowAddOption, maxOptionLimit: $maxOptionLimit, allowMultipleVotes: $allowMultipleVotes, resultDisplayType: $resultDisplayType, status: $status, options: $options, myVotes: $myVotes, totalVotes: $totalVotes, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy)';
}


}

/// @nodoc
abstract mixin class $PollCopyWith<$Res>  {
  factory $PollCopyWith(Poll value, $Res Function(Poll) _then) = _$PollCopyWithImpl;
@useResult
$Res call({
 String id, String tripId, String title, String description, String creatorId, DateTime? deadline, bool isAllowAddOption, int maxOptionLimit, bool allowMultipleVotes, String resultDisplayType, String status, List<PollOption> options, List<String> myVotes, int totalVotes, DateTime createdAt, String createdBy, DateTime updatedAt, String updatedBy
});




}
/// @nodoc
class _$PollCopyWithImpl<$Res>
    implements $PollCopyWith<$Res> {
  _$PollCopyWithImpl(this._self, this._then);

  final Poll _self;
  final $Res Function(Poll) _then;

/// Create a copy of Poll
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tripId = null,Object? title = null,Object? description = null,Object? creatorId = null,Object? deadline = freezed,Object? isAllowAddOption = null,Object? maxOptionLimit = null,Object? allowMultipleVotes = null,Object? resultDisplayType = null,Object? status = null,Object? options = null,Object? myVotes = null,Object? totalVotes = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
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
as List<PollOption>,myVotes: null == myVotes ? _self.myVotes : myVotes // ignore: cast_nullable_to_non_nullable
as List<String>,totalVotes: null == totalVotes ? _self.totalVotes : totalVotes // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Poll].
extension PollPatterns on Poll {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Poll value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Poll() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Poll value)  $default,){
final _that = this;
switch (_that) {
case _Poll():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Poll value)?  $default,){
final _that = this;
switch (_that) {
case _Poll() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tripId,  String title,  String description,  String creatorId,  DateTime? deadline,  bool isAllowAddOption,  int maxOptionLimit,  bool allowMultipleVotes,  String resultDisplayType,  String status,  List<PollOption> options,  List<String> myVotes,  int totalVotes,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Poll() when $default != null:
return $default(_that.id,_that.tripId,_that.title,_that.description,_that.creatorId,_that.deadline,_that.isAllowAddOption,_that.maxOptionLimit,_that.allowMultipleVotes,_that.resultDisplayType,_that.status,_that.options,_that.myVotes,_that.totalVotes,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tripId,  String title,  String description,  String creatorId,  DateTime? deadline,  bool isAllowAddOption,  int maxOptionLimit,  bool allowMultipleVotes,  String resultDisplayType,  String status,  List<PollOption> options,  List<String> myVotes,  int totalVotes,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy)  $default,) {final _that = this;
switch (_that) {
case _Poll():
return $default(_that.id,_that.tripId,_that.title,_that.description,_that.creatorId,_that.deadline,_that.isAllowAddOption,_that.maxOptionLimit,_that.allowMultipleVotes,_that.resultDisplayType,_that.status,_that.options,_that.myVotes,_that.totalVotes,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tripId,  String title,  String description,  String creatorId,  DateTime? deadline,  bool isAllowAddOption,  int maxOptionLimit,  bool allowMultipleVotes,  String resultDisplayType,  String status,  List<PollOption> options,  List<String> myVotes,  int totalVotes,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy)?  $default,) {final _that = this;
switch (_that) {
case _Poll() when $default != null:
return $default(_that.id,_that.tripId,_that.title,_that.description,_that.creatorId,_that.deadline,_that.isAllowAddOption,_that.maxOptionLimit,_that.allowMultipleVotes,_that.resultDisplayType,_that.status,_that.options,_that.myVotes,_that.totalVotes,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Poll extends Poll {
  const _Poll({required this.id, this.tripId = '', required this.title, this.description = '', required this.creatorId, this.deadline, this.isAllowAddOption = false, this.maxOptionLimit = 20, this.allowMultipleVotes = false, this.resultDisplayType = 'realtime', this.status = 'active', final  List<PollOption> options = const [], final  List<String> myVotes = const [], this.totalVotes = 0, required this.createdAt, required this.createdBy, required this.updatedAt, required this.updatedBy}): _options = options,_myVotes = myVotes,super._();
  factory _Poll.fromJson(Map<String, dynamic> json) => _$PollFromJson(json);

@override final  String id;
@override@JsonKey() final  String tripId;
@override final  String title;
@override@JsonKey() final  String description;
@override final  String creatorId;
@override final  DateTime? deadline;
@override@JsonKey() final  bool isAllowAddOption;
@override@JsonKey() final  int maxOptionLimit;
@override@JsonKey() final  bool allowMultipleVotes;
@override@JsonKey() final  String resultDisplayType;
@override@JsonKey() final  String status;
 final  List<PollOption> _options;
@override@JsonKey() List<PollOption> get options {
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_options);
}

 final  List<String> _myVotes;
@override@JsonKey() List<String> get myVotes {
  if (_myVotes is EqualUnmodifiableListView) return _myVotes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_myVotes);
}

@override@JsonKey() final  int totalVotes;
@override final  DateTime createdAt;
@override final  String createdBy;
@override final  DateTime updatedAt;
@override final  String updatedBy;

/// Create a copy of Poll
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PollCopyWith<_Poll> get copyWith => __$PollCopyWithImpl<_Poll>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PollToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Poll&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.creatorId, creatorId) || other.creatorId == creatorId)&&(identical(other.deadline, deadline) || other.deadline == deadline)&&(identical(other.isAllowAddOption, isAllowAddOption) || other.isAllowAddOption == isAllowAddOption)&&(identical(other.maxOptionLimit, maxOptionLimit) || other.maxOptionLimit == maxOptionLimit)&&(identical(other.allowMultipleVotes, allowMultipleVotes) || other.allowMultipleVotes == allowMultipleVotes)&&(identical(other.resultDisplayType, resultDisplayType) || other.resultDisplayType == resultDisplayType)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._options, _options)&&const DeepCollectionEquality().equals(other._myVotes, _myVotes)&&(identical(other.totalVotes, totalVotes) || other.totalVotes == totalVotes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,title,description,creatorId,deadline,isAllowAddOption,maxOptionLimit,allowMultipleVotes,resultDisplayType,status,const DeepCollectionEquality().hash(_options),const DeepCollectionEquality().hash(_myVotes),totalVotes,createdAt,createdBy,updatedAt,updatedBy);

@override
String toString() {
  return 'Poll(id: $id, tripId: $tripId, title: $title, description: $description, creatorId: $creatorId, deadline: $deadline, isAllowAddOption: $isAllowAddOption, maxOptionLimit: $maxOptionLimit, allowMultipleVotes: $allowMultipleVotes, resultDisplayType: $resultDisplayType, status: $status, options: $options, myVotes: $myVotes, totalVotes: $totalVotes, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy)';
}


}

/// @nodoc
abstract mixin class _$PollCopyWith<$Res> implements $PollCopyWith<$Res> {
  factory _$PollCopyWith(_Poll value, $Res Function(_Poll) _then) = __$PollCopyWithImpl;
@override @useResult
$Res call({
 String id, String tripId, String title, String description, String creatorId, DateTime? deadline, bool isAllowAddOption, int maxOptionLimit, bool allowMultipleVotes, String resultDisplayType, String status, List<PollOption> options, List<String> myVotes, int totalVotes, DateTime createdAt, String createdBy, DateTime updatedAt, String updatedBy
});




}
/// @nodoc
class __$PollCopyWithImpl<$Res>
    implements _$PollCopyWith<$Res> {
  __$PollCopyWithImpl(this._self, this._then);

  final _Poll _self;
  final $Res Function(_Poll) _then;

/// Create a copy of Poll
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tripId = null,Object? title = null,Object? description = null,Object? creatorId = null,Object? deadline = freezed,Object? isAllowAddOption = null,Object? maxOptionLimit = null,Object? allowMultipleVotes = null,Object? resultDisplayType = null,Object? status = null,Object? options = null,Object? myVotes = null,Object? totalVotes = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,}) {
  return _then(_Poll(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
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
as List<PollOption>,myVotes: null == myVotes ? _self._myVotes : myVotes // ignore: cast_nullable_to_non_nullable
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
mixin _$PollOption {

 String get id; String get pollId; String get text; String get creatorId; int get voteCount; List<Map<String, dynamic>> get voters; DateTime get createdAt; String get createdBy; DateTime get updatedAt; String get updatedBy;
/// Create a copy of PollOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PollOptionCopyWith<PollOption> get copyWith => _$PollOptionCopyWithImpl<PollOption>(this as PollOption, _$identity);

  /// Serializes this PollOption to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PollOption&&(identical(other.id, id) || other.id == id)&&(identical(other.pollId, pollId) || other.pollId == pollId)&&(identical(other.text, text) || other.text == text)&&(identical(other.creatorId, creatorId) || other.creatorId == creatorId)&&(identical(other.voteCount, voteCount) || other.voteCount == voteCount)&&const DeepCollectionEquality().equals(other.voters, voters)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,pollId,text,creatorId,voteCount,const DeepCollectionEquality().hash(voters),createdAt,createdBy,updatedAt,updatedBy);

@override
String toString() {
  return 'PollOption(id: $id, pollId: $pollId, text: $text, creatorId: $creatorId, voteCount: $voteCount, voters: $voters, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy)';
}


}

/// @nodoc
abstract mixin class $PollOptionCopyWith<$Res>  {
  factory $PollOptionCopyWith(PollOption value, $Res Function(PollOption) _then) = _$PollOptionCopyWithImpl;
@useResult
$Res call({
 String id, String pollId, String text, String creatorId, int voteCount, List<Map<String, dynamic>> voters, DateTime createdAt, String createdBy, DateTime updatedAt, String updatedBy
});




}
/// @nodoc
class _$PollOptionCopyWithImpl<$Res>
    implements $PollOptionCopyWith<$Res> {
  _$PollOptionCopyWithImpl(this._self, this._then);

  final PollOption _self;
  final $Res Function(PollOption) _then;

/// Create a copy of PollOption
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


/// Adds pattern-matching-related methods to [PollOption].
extension PollOptionPatterns on PollOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PollOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PollOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PollOption value)  $default,){
final _that = this;
switch (_that) {
case _PollOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PollOption value)?  $default,){
final _that = this;
switch (_that) {
case _PollOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String pollId,  String text,  String creatorId,  int voteCount,  List<Map<String, dynamic>> voters,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PollOption() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String pollId,  String text,  String creatorId,  int voteCount,  List<Map<String, dynamic>> voters,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy)  $default,) {final _that = this;
switch (_that) {
case _PollOption():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String pollId,  String text,  String creatorId,  int voteCount,  List<Map<String, dynamic>> voters,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy)?  $default,) {final _that = this;
switch (_that) {
case _PollOption() when $default != null:
return $default(_that.id,_that.pollId,_that.text,_that.creatorId,_that.voteCount,_that.voters,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PollOption extends PollOption {
  const _PollOption({required this.id, required this.pollId, required this.text, required this.creatorId, this.voteCount = 0, final  List<Map<String, dynamic>> voters = const [], required this.createdAt, required this.createdBy, required this.updatedAt, required this.updatedBy}): _voters = voters,super._();
  factory _PollOption.fromJson(Map<String, dynamic> json) => _$PollOptionFromJson(json);

@override final  String id;
@override final  String pollId;
@override final  String text;
@override final  String creatorId;
@override@JsonKey() final  int voteCount;
 final  List<Map<String, dynamic>> _voters;
@override@JsonKey() List<Map<String, dynamic>> get voters {
  if (_voters is EqualUnmodifiableListView) return _voters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_voters);
}

@override final  DateTime createdAt;
@override final  String createdBy;
@override final  DateTime updatedAt;
@override final  String updatedBy;

/// Create a copy of PollOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PollOptionCopyWith<_PollOption> get copyWith => __$PollOptionCopyWithImpl<_PollOption>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PollOptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PollOption&&(identical(other.id, id) || other.id == id)&&(identical(other.pollId, pollId) || other.pollId == pollId)&&(identical(other.text, text) || other.text == text)&&(identical(other.creatorId, creatorId) || other.creatorId == creatorId)&&(identical(other.voteCount, voteCount) || other.voteCount == voteCount)&&const DeepCollectionEquality().equals(other._voters, _voters)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,pollId,text,creatorId,voteCount,const DeepCollectionEquality().hash(_voters),createdAt,createdBy,updatedAt,updatedBy);

@override
String toString() {
  return 'PollOption(id: $id, pollId: $pollId, text: $text, creatorId: $creatorId, voteCount: $voteCount, voters: $voters, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy)';
}


}

/// @nodoc
abstract mixin class _$PollOptionCopyWith<$Res> implements $PollOptionCopyWith<$Res> {
  factory _$PollOptionCopyWith(_PollOption value, $Res Function(_PollOption) _then) = __$PollOptionCopyWithImpl;
@override @useResult
$Res call({
 String id, String pollId, String text, String creatorId, int voteCount, List<Map<String, dynamic>> voters, DateTime createdAt, String createdBy, DateTime updatedAt, String updatedBy
});




}
/// @nodoc
class __$PollOptionCopyWithImpl<$Res>
    implements _$PollOptionCopyWith<$Res> {
  __$PollOptionCopyWithImpl(this._self, this._then);

  final _PollOption _self;
  final $Res Function(_PollOption) _then;

/// Create a copy of PollOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? pollId = null,Object? text = null,Object? creatorId = null,Object? voteCount = null,Object? voters = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,}) {
  return _then(_PollOption(
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

// dart format on
