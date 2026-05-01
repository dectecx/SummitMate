import 'package:hive_ce/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/poll.dart';

part 'poll_model.g.dart';

@HiveType(typeId: 6)
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class PollModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  @JsonKey(defaultValue: '')
  final String tripId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  @JsonKey(defaultValue: '', fromJson: _parseString)
  final String description;

  @HiveField(4)
  final String creatorId;

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
  final String resultDisplayType;

  @HiveField(10)
  @JsonKey(defaultValue: 'active')
  final String status;

  @HiveField(11)
  @JsonKey(defaultValue: [])
  final List<PollOptionModel> options;

  @HiveField(12)
  @JsonKey(defaultValue: [], fromJson: _parseStringList)
  final List<String> myVotes;

  @HiveField(13)
  @JsonKey(defaultValue: 0, fromJson: _parseInt)
  final int totalVotes;

  @HiveField(14)
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @HiveField(15)
  @JsonKey(name: 'created_by')
  final String createdBy;

  @HiveField(16)
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  @HiveField(17)
  @JsonKey(name: 'updated_by')
  final String updatedBy;

  PollModel({
    required this.id,
    this.tripId = '',
    required this.title,
    this.description = '',
    required this.creatorId,
    this.deadline,
    this.isAllowAddOption = false,
    this.maxOptionLimit = 20,
    this.allowMultipleVotes = false,
    this.resultDisplayType = 'realtime',
    this.status = 'active',
    this.options = const [],
    this.myVotes = const [],
    this.totalVotes = 0,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
  });

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _parseString(dynamic value) {
    return value?.toString() ?? '';
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// 轉換為 Domain Entity
  Poll toDomain() {
    return Poll(
      id: id,
      tripId: tripId,
      title: title,
      description: description,
      creatorId: creatorId,
      deadline: deadline,
      isAllowAddOption: isAllowAddOption,
      maxOptionLimit: maxOptionLimit,
      allowMultipleVotes: allowMultipleVotes,
      resultDisplayType: resultDisplayType,
      status: status,
      options: options.map((o) => o.toDomain()).toList(),
      myVotes: myVotes,
      totalVotes: totalVotes,
      createdAt: createdAt,
      createdBy: createdBy,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
    );
  }

  /// 從 Domain Entity 建立 Persistence Model
  factory PollModel.fromDomain(Poll entity) {
    return PollModel(
      id: entity.id,
      tripId: entity.tripId,
      title: entity.title,
      description: entity.description,
      creatorId: entity.creatorId,
      deadline: entity.deadline,
      isAllowAddOption: entity.isAllowAddOption,
      maxOptionLimit: entity.maxOptionLimit,
      allowMultipleVotes: entity.allowMultipleVotes,
      resultDisplayType: entity.resultDisplayType,
      status: entity.status,
      options: entity.options.map((o) => PollOptionModel.fromDomain(o)).toList(),
      myVotes: entity.myVotes,
      totalVotes: entity.totalVotes,
      createdAt: entity.createdAt,
      createdBy: entity.createdBy,
      updatedAt: entity.updatedAt,
      updatedBy: entity.updatedBy,
    );
  }

  factory PollModel.fromJson(Map<String, dynamic> json) => _$PollModelFromJson(json);
  Map<String, dynamic> toJson() => _$PollModelToJson(this);
}

@HiveType(typeId: 7)
@JsonSerializable(fieldRename: FieldRename.snake)
class PollOptionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String pollId;

  @HiveField(2)
  final String text;

  @HiveField(3)
  final String creatorId;

  @HiveField(4)
  @JsonKey(defaultValue: 0, fromJson: PollModel._parseInt)
  final int voteCount;

  @HiveField(5)
  @JsonKey(defaultValue: [], fromJson: _parseVoters)
  final List<Map<String, dynamic>> voters;

  @HiveField(6)
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @HiveField(7)
  @JsonKey(name: 'created_by')
  final String createdBy;

  @HiveField(8)
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  @HiveField(9)
  @JsonKey(name: 'updated_by')
  final String updatedBy;

  PollOptionModel({
    required this.id,
    required this.pollId,
    required this.text,
    required this.creatorId,
    this.voteCount = 0,
    this.voters = const [],
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
  });

  static List<Map<String, dynamic>> _parseVoters(dynamic value) {
    if (value is List) {
      return value.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  /// 轉換為 Domain Entity
  PollOption toDomain() {
    return PollOption(
      id: id,
      pollId: pollId,
      text: text,
      creatorId: creatorId,
      voteCount: voteCount,
      voters: voters,
      createdAt: createdAt,
      createdBy: createdBy,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
    );
  }

  /// 從 Domain Entity 建立 Persistence Model
  factory PollOptionModel.fromDomain(PollOption entity) {
    return PollOptionModel(
      id: entity.id,
      pollId: entity.pollId,
      text: entity.text,
      creatorId: entity.creatorId,
      voteCount: entity.voteCount,
      voters: entity.voters,
      createdAt: entity.createdAt,
      createdBy: entity.createdBy,
      updatedAt: entity.updatedAt,
      updatedBy: entity.updatedBy,
    );
  }

  factory PollOptionModel.fromJson(Map<String, dynamic> json) => _$PollOptionModelFromJson(json);
  Map<String, dynamic> toJson() => _$PollOptionModelToJson(this);
}
