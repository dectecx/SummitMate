import 'package:freezed_annotation/freezed_annotation.dart';

part 'itinerary_edit_result.freezed.dart';

/// 行程編輯對話框的回傳結果 (typed dialog result)
@freezed
abstract class ItineraryEditResult with _$ItineraryEditResult {
  const factory ItineraryEditResult({
    required String name,
    required String estTime,
    required int altitude,
    required double distance,
    required String note,
  }) = _ItineraryEditResult;
}
