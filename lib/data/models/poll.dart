import 'package:hive/hive.dart';

part 'poll.g.dart';

@HiveType(typeId: 6) // Ensure typeId is unique. Check existing adapters.
class Poll {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String creatorId;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime? deadline;

  @HiveField(6)
  final bool isAllowAddOption;

  @HiveField(7)
  final int maxOptionLimit;

  @HiveField(8)
  final bool allowMultipleVotes;

  @HiveField(9)
  final String resultDisplayType; // 'realtime' or 'blind'

  @HiveField(10)
  final String status; // 'active', 'ended'

  @HiveField(11)
  final List<PollOption> options;

  @HiveField(12)
  final List<String> myVotes; // List of optionIds I voted for

  @HiveField(13)
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

  factory Poll.fromJson(Map<String, dynamic> json) {
    return Poll(
      id: json['poll_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      creatorId: json['creator_id']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now(),
      deadline: json['deadline'] != null && json['deadline'].toString().isNotEmpty
          ? DateTime.tryParse(json['deadline'].toString())
          : null,
      isAllowAddOption: json['is_allow_add_option'] == true,
      maxOptionLimit: int.tryParse(json['max_option_limit'].toString()) ?? 20,
      allowMultipleVotes: json['allow_multiple_votes'] == true,
      resultDisplayType: json['result_display_type']?.toString() ?? 'realtime',
      status: json['status']?.toString() ?? 'active',
      options: (json['options'] as List<dynamic>?)?.map((e) => PollOption.fromJson(e)).toList() ?? [],
      myVotes: (json['my_votes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      totalVotes: int.tryParse(json['total_votes'].toString()) ?? 0,
    );
  }

  // To JSON for API (if needed, mostly read-only from API)
  Map<String, dynamic> toJson() {
    return {
      'poll_id': id,
      'title': title,
      'description': description,
      'creator_id': creatorId,
      'created_at': createdAt.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'is_allow_add_option': isAllowAddOption,
      'max_option_limit': maxOptionLimit,
      'allow_multiple_votes': allowMultipleVotes,
      'result_display_type': resultDisplayType,
      'status': status,
      'options': options.map((e) => e.toJson()).toList(),
      'my_votes': myVotes,
      'total_votes': totalVotes,
    };
  }
}

@HiveType(typeId: 7)
class PollOption {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String pollId;

  @HiveField(2)
  final String text;

  @HiveField(3)
  final String creatorId;

  @HiveField(4)
  final int voteCount;

  @HiveField(5)
  final List<Map<String, dynamic>> voters;

  PollOption({
    required this.id,
    required this.pollId,
    required this.text,
    required this.creatorId,
    this.voteCount = 0,
    this.voters = const [],
  });

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      id: json['option_id']?.toString() ?? '',
      pollId: json['poll_id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      creatorId: json['creator_id']?.toString() ?? '',
      voteCount: int.tryParse(json['vote_count'].toString()) ?? 0,
      voters: (json['voters'] as List<dynamic>?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'option_id': id,
      'poll_id': pollId,
      'text': text,
      'creator_id': creatorId,
      'vote_count': voteCount,
      'voters': voters,
    };
  }
}
