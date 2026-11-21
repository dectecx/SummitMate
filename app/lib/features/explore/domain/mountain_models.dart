import 'dart:convert';

enum MountainCategory { baiyue, other }

class Mountain {
  const Mountain({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.elevation,
    required this.region,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.trailGrade,
    required this.beginnerFriendly,
    required this.summary,
    required this.permit,
    required this.verified,
    required this.sources,
  });

  final String id;
  final String name;
  final String? nameEn;

  /// Metres above sea level.
  final int elevation;
  final String region;
  final double latitude;
  final double longitude;
  final MountainCategory category;
  /// The national park service's trail grade (步道分級) 0-6 from the cited source, as published.
  /// Higher means harder; we deliberately do not translate it into our own labels.
  final int? trailGrade;
  final bool beginnerFriendly;
  final String summary;
  final String? permit;

  /// False while the entry has not been checked by a person (shown to the user).
  final bool verified;
  final List<String> sources;

  factory Mountain.fromJson(Map<String, dynamic> j) => Mountain(
    id: j['id'] as String,
    name: j['name'] as String,
    nameEn: j['name_en'] as String?,
    elevation: (j['elevation'] as num).toInt(),
    region: j['region'] as String,
    latitude: (j['latitude'] as num).toDouble(),
    longitude: (j['longitude'] as num).toDouble(),
    category: j['category'] == 'baiyue' ? MountainCategory.baiyue : MountainCategory.other,
    trailGrade: (j['trail_grade'] as num?)?.toInt(),
    beginnerFriendly: j['beginner_friendly'] as bool? ?? false,
    summary: j['summary'] as String? ?? '',
    permit: j['permit'] as String?,
    verified: j['verified'] as bool? ?? false,
    sources: [for (final s in (j['sources'] as List? ?? const [])) s as String],
  );
}

class MountainList {
  const MountainList({required this.version, required this.updatedAt, required this.mountains});
  final String version;
  final DateTime updatedAt;
  final List<Mountain> mountains;

  factory MountainList.parse(String payload) {
    final j = jsonDecode(payload) as Map<String, dynamic>;
    return MountainList(
      version: j['version'] as String,
      updatedAt: DateTime.parse(j['updated_at'] as String),
      mountains: [for (final m in j['mountains'] as List) Mountain.fromJson((m as Map).cast<String, dynamic>())],
    );
  }

  Mountain? byId(String id) {
    for (final m in mountains) {
      if (m.id == id) return m;
    }
    return null;
  }
}

enum MountainFilter { all, beginner, baiyue }

/// Mountains matching [query] (name, English name or region) and [filter], highest first.
List<Mountain> searchMountains(List<Mountain> all, {String query = '', MountainFilter filter = MountainFilter.all}) {
  final q = query.trim().toLowerCase();
  final list = all.where((m) {
    if (filter == MountainFilter.beginner && !m.beginnerFriendly) return false;
    if (filter == MountainFilter.baiyue && m.category != MountainCategory.baiyue) return false;
    if (q.isEmpty) return true;
    return m.name.toLowerCase().contains(q) || (m.nameEn?.toLowerCase().contains(q) ?? false) || m.region.toLowerCase().contains(q);
  }).toList()
    ..sort((a, b) {
      final e = b.elevation.compareTo(a.elevation);
      return e != 0 ? e : a.id.compareTo(b.id);
    });
  return list;
}

/// What the explore screens can show.
sealed class MountainsState {
  const MountainsState();
}

class MountainsLoading extends MountainsState {
  const MountainsLoading();
}

/// Nothing cached and the server could not be reached (first launch without a connection).
class MountainsUnavailable extends MountainsState {
  const MountainsUnavailable();
}

class MountainsReady extends MountainsState {
  const MountainsReady(this.data, {this.refreshFailed = false});
  final MountainList data;

  /// The cached list is shown but checking for a newer one failed.
  final bool refreshFailed;
}
