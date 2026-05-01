import 'package:freezed_annotation/freezed_annotation.dart';

part 'gear_item.freezed.dart';
part 'gear_item.g.dart';

/// 裝備實體 (Domain Entity)
@freezed
abstract class GearItem with _$GearItem {
  const GearItem._();

  const factory GearItem({
    required String id,
    required String tripId,
    required String name,
    required double weight,
    required String category,
    @Default(false) bool isChecked,
    @Default(0) int orderIndex,
    @Default(1) int quantity,
    String? libraryItemId,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
  }) = _GearItem;

  /// 總重量 (重量 × 數量)
  double get totalWeight => weight * quantity;

  /// 重量轉換為公斤
  double get weightInKg => weight / 1000;

  /// 是否連結到裝備庫
  bool get isLinkedToLibrary => libraryItemId != null && libraryItemId!.isNotEmpty;

  factory GearItem.fromJson(Map<String, dynamic> json) => _$GearItemFromJson(json);
}
