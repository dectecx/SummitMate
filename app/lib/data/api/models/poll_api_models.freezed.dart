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
mixin _$PollCreateRequest {

 String get title;@JsonKey(defaultValue: '') String? get description; DateTime? get deadline;@JsonKey(name: 'initial_options', defaultValue: <String>[]) List<String>? get initialOptions;@JsonKey(name: 'is_allow_add_option', defaultValue: false) bool? get isAllowAddOption;@JsonKey(name: 'max_option_limit', defaultValue: 20) int? get maxOptionLimit;@JsonKey(name: 'allow_multiple_votes', defaultValue: false) bool? get allowMultipleVotes;@JsonKey(name: 'result_display_type', defaultValue: 'realtime') String? get resultDisplayType;
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
 String title,@JsonKey(defaultValue: '') String? description, DateTime? deadline,@JsonKey(name: 'initial_options', defaultValue: <String>[]) List<String>? initialOptions,@JsonKey(name: 'is_allow_add_option', defaultValue: false) bool? isAllowAddOption,@JsonKey(name: 'max_option_limit', defaultValue: 20) int? maxOptionLimit,@JsonKey(name: 'allow_multiple_votes', defaultValue: false) bool? allowMultipleVotes,@JsonKey(name: 'result_display_type', defaultValue: 'realtime') String? resultDisplayType
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
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? description = freezed,Object? deadline = freezed,Object? initialOptions = freezed,Object? isAllowAddOption = freezed,Object? maxOptionLimit = freezed,Object? allowMultipleVotes = freezed,Object? resultDisplayType = freezed,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,deadline: freezed == deadline ? _self.deadline : deadline // ignore: cast_nullable_to_non_nullable
as DateTime?,initialOptions: freezed == initialOptions ? _self.initialOptions : initialOptions // ignore: cast_nullable_to_non_nullable
as List<String>?,isAllowAddOption: freezed == isAllowAddOption ? _self.isAllowAddOption : isAllowAddOption // ignore: cast_nullable_to_non_nullable
as bool?,maxOptionLimit: freezed == maxOptionLimit ? _self.maxOptionLimit : maxOptionLimit // ignore: cast_nullable_to_non_nullable
as int?,allowMultipleVotes: freezed == allowMultipleVotes ? _self.allowMultipleVotes : allowMultipleVotes // ignore: cast_nullable_to_non_nullable
as bool?,resultDisplayType: freezed == resultDisplayType ? _self.resultDisplayType : resultDisplayType // ignore: cast_nullable_to_non_nullable
as String?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title, @JsonKey(defaultValue: '')  String? description,  DateTime? deadline, @JsonKey(name: 'initial_options', defaultValue: <String>[])  List<String>? initialOptions, @JsonKey(name: 'is_allow_add_option', defaultValue: false)  bool? isAllowAddOption, @JsonKey(name: 'max_option_limit', defaultValue: 20)  int? maxOptionLimit, @JsonKey(name: 'allow_multiple_votes', defaultValue: false)  bool? allowMultipleVotes, @JsonKey(name: 'result_display_type', defaultValue: 'realtime')  String? resultDisplayType)?  $default,{required TResult orElse(),}) {final _that = this;
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title, @JsonKey(defaultValue: '')  String? description,  DateTime? deadline, @JsonKey(name: 'initial_options', defaultValue: <String>[])  List<String>? initialOptions, @JsonKey(name: 'is_allow_add_option', defaultValue: false)  bool? isAllowAddOption, @JsonKey(name: 'max_option_limit', defaultValue: 20)  int? maxOptionLimit, @JsonKey(name: 'allow_multiple_votes', defaultValue: false)  bool? allowMultipleVotes, @JsonKey(name: 'result_display_type', defaultValue: 'realtime')  String? resultDisplayType)  $default,) {final _that = this;
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title, @JsonKey(defaultValue: '')  String? description,  DateTime? deadline, @JsonKey(name: 'initial_options', defaultValue: <String>[])  List<String>? initialOptions, @JsonKey(name: 'is_allow_add_option', defaultValue: false)  bool? isAllowAddOption, @JsonKey(name: 'max_option_limit', defaultValue: 20)  int? maxOptionLimit, @JsonKey(name: 'allow_multiple_votes', defaultValue: false)  bool? allowMultipleVotes, @JsonKey(name: 'result_display_type', defaultValue: 'realtime')  String? resultDisplayType)?  $default,) {final _that = this;
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
  const _PollCreateRequest({required this.title, @JsonKey(defaultValue: '') this.description, this.deadline, @JsonKey(name: 'initial_options', defaultValue: <String>[]) final  List<String>? initialOptions, @JsonKey(name: 'is_allow_add_option', defaultValue: false) this.isAllowAddOption, @JsonKey(name: 'max_option_limit', defaultValue: 20) this.maxOptionLimit, @JsonKey(name: 'allow_multiple_votes', defaultValue: false) this.allowMultipleVotes, @JsonKey(name: 'result_display_type', defaultValue: 'realtime') this.resultDisplayType}): _initialOptions = initialOptions;
  factory _PollCreateRequest.fromJson(Map<String, dynamic> json) => _$PollCreateRequestFromJson(json);

@override final  String title;
@override@JsonKey(defaultValue: '') final  String? description;
@override final  DateTime? deadline;
 final  List<String>? _initialOptions;
@override@JsonKey(name: 'initial_options', defaultValue: <String>[]) List<String>? get initialOptions {
  final value = _initialOptions;
  if (value == null) return null;
  if (_initialOptions is EqualUnmodifiableListView) return _initialOptions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey(name: 'is_allow_add_option', defaultValue: false) final  bool? isAllowAddOption;
@override@JsonKey(name: 'max_option_limit', defaultValue: 20) final  int? maxOptionLimit;
@override@JsonKey(name: 'allow_multiple_votes', defaultValue: false) final  bool? allowMultipleVotes;
@override@JsonKey(name: 'result_display_type', defaultValue: 'realtime') final  String? resultDisplayType;

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
 String title,@JsonKey(defaultValue: '') String? description, DateTime? deadline,@JsonKey(name: 'initial_options', defaultValue: <String>[]) List<String>? initialOptions,@JsonKey(name: 'is_allow_add_option', defaultValue: false) bool? isAllowAddOption,@JsonKey(name: 'max_option_limit', defaultValue: 20) int? maxOptionLimit,@JsonKey(name: 'allow_multiple_votes', defaultValue: false) bool? allowMultipleVotes,@JsonKey(name: 'result_display_type', defaultValue: 'realtime') String? resultDisplayType
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
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? description = freezed,Object? deadline = freezed,Object? initialOptions = freezed,Object? isAllowAddOption = freezed,Object? maxOptionLimit = freezed,Object? allowMultipleVotes = freezed,Object? resultDisplayType = freezed,}) {
  return _then(_PollCreateRequest(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,deadline: freezed == deadline ? _self.deadline : deadline // ignore: cast_nullable_to_non_nullable
as DateTime?,initialOptions: freezed == initialOptions ? _self._initialOptions : initialOptions // ignore: cast_nullable_to_non_nullable
as List<String>?,isAllowAddOption: freezed == isAllowAddOption ? _self.isAllowAddOption : isAllowAddOption // ignore: cast_nullable_to_non_nullable
as bool?,maxOptionLimit: freezed == maxOptionLimit ? _self.maxOptionLimit : maxOptionLimit // ignore: cast_nullable_to_non_nullable
as int?,allowMultipleVotes: freezed == allowMultipleVotes ? _self.allowMultipleVotes : allowMultipleVotes // ignore: cast_nullable_to_non_nullable
as bool?,resultDisplayType: freezed == resultDisplayType ? _self.resultDisplayType : resultDisplayType // ignore: cast_nullable_to_non_nullable
as String?,
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
