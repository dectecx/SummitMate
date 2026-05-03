import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/gear_key_record.dart';

part 'gear_key_record_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class GearKeyRecordModel {
  final String key;
  final String title;
  @JsonKey(defaultValue: 'private')
  final String visibility;
  @JsonKey(fromJson: _parseDateTime, toJson: _dateTimeToJson)
  final DateTime uploadedAt;

  GearKeyRecordModel({required this.key, required this.title, required this.visibility, required this.uploadedAt});

  GearKeyRecord toDomain() => GearKeyRecord(key: key, title: title, visibility: visibility, uploadedAt: uploadedAt);

  factory GearKeyRecordModel.fromDomain(GearKeyRecord entity) => GearKeyRecordModel(
    key: entity.key,
    title: entity.title,
    visibility: entity.visibility,
    uploadedAt: entity.uploadedAt,
  );

  factory GearKeyRecordModel.fromJson(Map<String, dynamic> json) => _$GearKeyRecordModelFromJson(json);
  Map<String, dynamic> toJson() => _$GearKeyRecordModelToJson(this);

  String toStorageString() {
    return '$key|$title|$visibility|${uploadedAt.toIso8601String()}';
  }

  factory GearKeyRecordModel.fromStorageString(String str) {
    final parts = str.split('|');
    return GearKeyRecordModel(
      key: parts.isNotEmpty ? parts[0] : '',
      title: parts.length > 1 ? parts[1] : '',
      visibility: parts.length > 2 ? parts[2] : 'private',
      uploadedAt: parts.length > 3 ? DateTime.tryParse(parts[3]) ?? DateTime.now() : DateTime.now(),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  static String _dateTimeToJson(DateTime dt) => dt.toIso8601String();
}
