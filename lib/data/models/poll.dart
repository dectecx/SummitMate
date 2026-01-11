import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'poll.g.dart';

@HiveType(typeId: 6)
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class Poll {
  /// 投票 ID (PK)
  @HiveField(0)
  @HiveField(0)
  final String id;

  /// 標題
  @HiveField(1)
  final String title;

  /// 描述
  @HiveField(2)
  @JsonKey(defaultValue: '', fromJson: _parseString)
  final String description;

  /// 建立者 ID
  @HiveField(3)
  final String creatorId;

  /// 建立時間
  @HiveField(4)
  final DateTime createdAt;

  /// 截止時間
  @HiveField(5)
  final DateTime? deadline;

  /// 是否允許新增選項
  @HiveField(6)
  @JsonKey(defaultValue: false)
  final bool isAllowAddOption;

  /// 選項上限
  @HiveField(7)
  @JsonKey(defaultValue: 20, fromJson: _parseInt)
  final int maxOptionLimit;

  /// 是否允許複選
  @HiveField(8)
  @JsonKey(defaultValue: false)
  final bool allowMultipleVotes;

  /// 結果顯示方式 ('realtime' 或 'blind')
  @HiveField(9)
  @JsonKey(defaultValue: 'realtime')
  final String resultDisplayType;

  /// 狀態 ('active' 或 'ended')
  @HiveField(10)
  @JsonKey(defaultValue: 'active')
  final String status;

  /// 投票選項列表
  @HiveField(11)
  @JsonKey(defaultValue: [])
  final List<PollOption> options;

  /// 我的投票紀錄 (選項 ID 列表)
  @HiveField(12)
  @JsonKey(defaultValue: [], fromJson: _parseStringList)
  final List<String> myVotes;

  /// 總票數
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

  /// 是否已過期
  bool get isExpired {
    if (deadline == null) return false;
    return DateTime.now().isAfter(deadline!);
  }

  /// 是否活動中 (未結束且未過期)
  bool get isActive => status == 'active' && !isExpired;

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

  factory Poll.fromJson(Map<String, dynamic> json) => _$PollFromJson(json);
  Map<String, dynamic> toJson() => _$PollToJson(this);
}

@HiveType(typeId: 7)
@JsonSerializable(fieldRename: FieldRename.snake)
class PollOption {
  /// 選項 ID (PK)
  @HiveField(0)
  @HiveField(0)
  final String id;

  /// 關聯的投票 ID (FK)
  @HiveField(1)
  final String pollId;

  /// 選項文字
  @HiveField(2)
  final String text;

  /// 選項建立者
  @HiveField(3)
  final String creatorId;

  /// 得票數
  @HiveField(4)
  @JsonKey(defaultValue: 0, fromJson: Poll._parseInt)
  final int voteCount;

  /// 投票者列表 (List of Maps, containing voter info)
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
