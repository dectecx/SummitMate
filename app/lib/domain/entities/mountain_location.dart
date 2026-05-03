import 'package:freezed_annotation/freezed_annotation.dart';
import '../enums/mountain_enums.dart';

part 'mountain_location.freezed.dart';
part 'mountain_location.g.dart';

/// 山岳地點實體 (Domain Entity)
@freezed
abstract class MountainLocation with _$MountainLocation {
  const MountainLocation._();

  const factory MountainLocation({
    required String id,
    required String name,
    required int altitude,
    required MountainRegion region,
    required String introduction,
    required String features,
    required List<String> trailheads,
    required String mapRef,
    required String jurisdiction,
    @Default(false) bool isBeginnerFriendly,
    @Default([]) List<String> photoUrls,
    required String cwaPid,
    required String windyParams,
    required MountainCategory category,
    @Default([]) List<MountainLink> links,
  }) = _MountainLocation;

  String? getLinkUrl(LinkType type) {
    try {
      return links.firstWhere((link) => link.type == type).url;
    } catch (_) {
      return null;
    }
  }

  factory MountainLocation.fromJson(Map<String, dynamic> json) => _$MountainLocationFromJson(json);
}

/// 山岳相關連結實體 (Domain Entity)
@freezed
abstract class MountainLink with _$MountainLink {
  const factory MountainLink({required LinkType type, required String title, required String url}) = _MountainLink;

  factory MountainLink.fromJson(Map<String, dynamic> json) => _$MountainLinkFromJson(json);
}
