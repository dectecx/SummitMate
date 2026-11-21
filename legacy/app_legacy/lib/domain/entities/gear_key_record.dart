import 'package:freezed_annotation/freezed_annotation.dart';

part 'gear_key_record.freezed.dart';
part 'gear_key_record.g.dart';

/// 裝備清單上傳記錄實體 (Domain Entity)
@freezed
abstract class GearKeyRecord with _$GearKeyRecord {
  const factory GearKeyRecord({
    required String key,
    required String title,
    @Default('private') String visibility,
    required DateTime uploadedAt,
  }) = _GearKeyRecord;

  factory GearKeyRecord.fromJson(Map<String, dynamic> json) => _$GearKeyRecordFromJson(json);
}
