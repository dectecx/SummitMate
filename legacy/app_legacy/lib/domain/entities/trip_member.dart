import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip_member.freezed.dart';
part 'trip_member.g.dart';

/// 行程成員實體 (Domain Entity)
@freezed
abstract class TripMember with _$TripMember {
  const factory TripMember({
    required String userId,
    required String name,
    String? avatar,
    required String role,
    required DateTime joinedAt,
  }) = _TripMember;

  factory TripMember.fromJson(Map<String, dynamic> json) => _$TripMemberFromJson(json);
}
