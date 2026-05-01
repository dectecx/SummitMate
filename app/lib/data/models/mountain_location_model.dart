import '../../domain/enums/mountain_enums.dart';
import '../../domain/entities/mountain_location.dart';

class MountainLocationModel {
  final String id;
  final String name;
  final int altitude;
  final MountainRegion region;
  final String introduction;
  final String features;
  final List<String> trailheads;
  final String mapRef;
  final String jurisdiction;
  final bool isBeginnerFriendly;
  final List<String> photoUrls;
  final String cwaPid;
  final String windyParams;
  final MountainCategory category;
  final List<MountainLinkModel> links;

  const MountainLocationModel({
    required this.id,
    required this.name,
    required this.altitude,
    required this.region,
    required this.introduction,
    required this.features,
    required this.trailheads,
    required this.mapRef,
    required this.jurisdiction,
    this.isBeginnerFriendly = false,
    this.photoUrls = const [],
    required this.cwaPid,
    required this.windyParams,
    required this.category,
    this.links = const [],
  });

  MountainLocation toDomain() => MountainLocation(
        id: id,
        name: name,
        altitude: altitude,
        region: region,
        introduction: introduction,
        features: features,
        trailheads: trailheads,
        mapRef: mapRef,
        jurisdiction: jurisdiction,
        isBeginnerFriendly: isBeginnerFriendly,
        photoUrls: photoUrls,
        cwaPid: cwaPid,
        windyParams: windyParams,
        category: category,
        links: links.map((l) => l.toDomain()).toList(),
      );

  factory MountainLocationModel.fromDomain(MountainLocation entity) => MountainLocationModel(
        id: entity.id,
        name: entity.name,
        altitude: entity.altitude,
        region: entity.region,
        introduction: entity.introduction,
        features: entity.features,
        trailheads: entity.trailheads,
        mapRef: entity.mapRef,
        jurisdiction: entity.jurisdiction,
        isBeginnerFriendly: entity.isBeginnerFriendly,
        photoUrls: entity.photoUrls,
        cwaPid: entity.cwaPid,
        windyParams: entity.windyParams,
        category: entity.category,
        links: entity.links.map((l) => MountainLinkModel.fromDomain(l)).toList(),
      );
}

class MountainLinkModel {
  final LinkType type;
  final String title;
  final String url;

  const MountainLinkModel({required this.type, required this.title, required this.url});

  MountainLink toDomain() => MountainLink(type: type, title: title, url: url);

  factory MountainLinkModel.fromDomain(MountainLink entity) =>
      MountainLinkModel(type: entity.type, title: entity.title, url: entity.url);
}
