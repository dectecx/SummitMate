import 'package:freezed_annotation/freezed_annotation.dart';

part 'pagination_api_models.freezed.dart';
part 'pagination_api_models.g.dart';

@freezed
abstract class PaginationMetadata with _$PaginationMetadata {
  const factory PaginationMetadata({
    @JsonKey(name: 'next_cursor') String? nextCursor,
    @JsonKey(name: 'has_more') required bool hasMore,
    @JsonKey(name: 'page') required int page,
    @JsonKey(name: 'limit') required int limit,
    @JsonKey(name: 'total') required int total,
  }) = _PaginationMetadata;

  factory PaginationMetadata.fromJson(Map<String, dynamic> json) => _$PaginationMetadataFromJson(json);
}
