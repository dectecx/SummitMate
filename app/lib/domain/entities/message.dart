import 'package:freezed_annotation/freezed_annotation.dart';

part 'message.freezed.dart';
part 'message.g.dart';

/// 留言領域實體 (Domain Entity)
///
/// 不可變物件，承載留言的業務邏輯。
@freezed
abstract class Message with _$Message {
  const Message._();

  const factory Message({
    required String id,
    String? tripId,
    String? parentId,
    @Default('') String userId,
    @Default('') String user,
    @Default('🐻') String avatar,
    @Default('') String category,
    @Default('') String content,
    required DateTime timestamp,
    required DateTime createdAt,
    required String createdBy,
    required DateTime updatedAt,
    required String updatedBy,
  }) = _Message;

  /// 是否為回覆留言
  bool get isReply => parentId != null;

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);
}
