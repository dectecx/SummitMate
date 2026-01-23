import 'package:json_annotation/json_annotation.dart';

part 'gear_key_record.g.dart';

/// 裝備清單上傳記錄
///
/// 用於本地儲存已上傳至雲端的清單 Key，方便使用者管理與存取。
@JsonSerializable(fieldRename: FieldRename.snake)
class GearKeyRecord {
  /// 雲端唯一識別碼 (Key)
  final String key;

  /// 清單標題
  final String title;

  /// 可見度 (public / private / unlisted)
  @JsonKey(defaultValue: 'private')
  final String visibility;

  /// 上傳時間
  @JsonKey(fromJson: _parseDateTime, toJson: _dateTimeToJson)
  final DateTime uploadedAt;

  GearKeyRecord({required this.key, required this.title, required this.visibility, required this.uploadedAt});

  factory GearKeyRecord.fromJson(Map<String, dynamic> json) => _$GearKeyRecordFromJson(json);
  Map<String, dynamic> toJson() => _$GearKeyRecordToJson(this);

  /// 序列化為儲存字串 (for SharedPreferences / simple storage)
  String toStorageString() {
    return '$key|$title|$visibility|${uploadedAt.toIso8601String()}';
  }

  factory GearKeyRecord.fromStorageString(String str) {
    final parts = str.split('|');
    return GearKeyRecord(
      key: parts.isNotEmpty ? parts[0] : '',
      title: parts.length > 1 ? parts[1] : '',
      visibility: parts.length > 2 ? parts[2] : 'private',
      uploadedAt: parts.length > 3 ? DateTime.tryParse(parts[3]) ?? DateTime.now() : DateTime.now(),
    );
  }

  // DateTime parsing helpers
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  static String _dateTimeToJson(DateTime dt) => dt.toIso8601String();
}
