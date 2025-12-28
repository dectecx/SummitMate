import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'poll.g.dart';

@HiveType(typeId: 6)
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class Poll {
  @HiveField(0)
  @JsonKey(name: 'poll_id')
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  @JsonKey(defaultValue: '')
  final String description;

  @HiveField(3)
  final String creatorId;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime? deadline;

  @HiveField(6)
  @JsonKey(defaultValue: false)
  final bool isAllowAddOption;

  @HiveField(7)
  @JsonKey(defaultValue: 20, fromJson: _parseInt)
  final int maxOptionLimit;

  @HiveField(8)
  @JsonKey(defaultValue: false)
  final bool allowMultipleVotes;

  @HiveField(9)
  @JsonKey(defaultValue: 'realtime')
  final String resultDisplayType; // 'realtime' or 'blind'

  @HiveField(10)
  @JsonKey(defaultValue: 'active')
  final String status; // 'active', 'ended'

  @HiveField(11)
  @JsonKey(defaultValue: [])
  final List<PollOption> options;

  @HiveField(12)
  @JsonKey(defaultValue: [], fromJson: _parseStringList)
  final List<String> myVotes; // List of optionIds I voted for

  @HiveField(13)
  @JsonKey(defaultValue: 0, fromJson: _parseInt)
  final int totalVotes;

  Poll({
    required this.id,
    required this.title,
    this.description = '',
    required this.creatorId,
    required this.createdAt,
    this.deadline,
    this.isAllowAddOption = false,
    this.maxOptionLimit = 20,
    this.allowMultipleVotes = false,
    this.resultDisplayType = 'realtime',
    this.status = 'active',
    this.options = const [],
    this.myVotes = const [],
    this.totalVotes = 0,
  });

  bool get isExpired {
    if (deadline == null) return false;
    return DateTime.now().isAfter(deadline!);
  }

  bool get isActive => status == 'active' && !isExpired;

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  factory Poll.fromJson(Map<String, dynamic> json) => _$PollFromJson(json);
  Map<String, dynamic> toJson() => _$PollToJson(this);
}

@HiveType(typeId: 7)
@JsonSerializable(fieldRename: FieldRename.snake)
class PollOption {
  @HiveField(0)
  @JsonKey(name: 'option_id')
  final String id;

  @HiveField(1)
  final String pollId;

  @HiveField(2)
  final String text;

  @HiveField(3)
  final String creatorId;

  @HiveField(4)
  @JsonKey(defaultValue: 0, fromJson: Poll._parseInt)
  final int voteCount;

  @HiveField(5)
  @JsonKey(defaultValue: [], fromJson: _parseVoters)
  final List<Map<String, dynamic>> voters;

  PollOption({
    required this.id,
    required this.pollId,
    required this.text,
    required this.creatorId,
    this.voteCount = 0,
    this.voters = const [],
  });

  static List<Map<String, dynamic>> _parseVoters(dynamic value) {
    if (value is List) {
      return value.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  factory PollOption.fromJson(Map<String, dynamic> json) => _$PollOptionFromJson(json);
  Map<String, dynamic> toJson() => _$PollOptionToJson(this);
}
