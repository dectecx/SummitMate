import 'package:freezed_annotation/freezed_annotation.dart';

part 'linked_trip_info.freezed.dart';

/// 裝備庫項目所連結的行程摘要 (Domain DTO)
///
/// 用於顯示裝備庫項目被哪些行程使用，取代原本的 `Map<String, dynamic>`。
@freezed
abstract class LinkedTripInfo with _$LinkedTripInfo {
  const factory LinkedTripInfo({
    required String tripId,
    required String tripName,
    required DateTime startDate,
  }) = _LinkedTripInfo;
}
