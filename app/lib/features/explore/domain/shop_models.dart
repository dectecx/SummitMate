import 'dart:convert';

/// What a shop sells, in the order the filter shows them.
const shopCategories = ['登山裝備', '服飾', '食物', '露營', '潛水', '攀岩', '其他'];

class Shop {
  const Shop({
    required this.id,
    required this.name,
    required this.city,
    required this.district,
    required this.address,
    required this.phone,
    required this.googleMapsUrl,
    required this.hours,
    required this.categories,
    required this.rating,
    required this.ratingCount,
    required this.checkedOn,
  });

  final String id;
  final String name;
  final String city;
  final String district;
  final String address;
  final String? phone;
  final String googleMapsUrl;
  final String? hours;
  final List<String> categories;
  final double rating;
  final int? ratingCount;
  final String checkedOn;

  factory Shop.fromJson(Map<String, dynamic> j) => Shop(
    id: j['id'] as String,
    name: j['name'] as String,
    city: j['city'] as String,
    district: (j['district'] as String?) ?? '',
    address: j['address'] as String,
    phone: j['phone'] as String?,
    googleMapsUrl: j['google_maps_url'] as String,
    hours: j['hours'] as String?,
    categories: [for (final c in (j['categories'] as List? ?? const [])) c as String],
    rating: (j['rating'] as num).toDouble(),
    ratingCount: (j['rating_count'] as num?)?.toInt(),
    checkedOn: (j['checked_on'] as String?) ?? '',
  );

  /// The number to dial: digits and a leading plus only.
  String? get dialNumber => phone?.replaceAll(RegExp(r'[^0-9+]'), '');
}

class ShopList {
  const ShopList({required this.version, required this.shops});
  final String version;
  final List<Shop> shops;

  factory ShopList.parse(String payload) {
    final j = jsonDecode(payload) as Map<String, dynamic>;
    return ShopList(
      version: j['version'] as String,
      shops: [for (final s in j['shops'] as List) Shop.fromJson((s as Map).cast<String, dynamic>())],
    );
  }

  /// The counties and cities that have shops, in the order of the list.
  List<String> get cities => {for (final s in shops) s.city}.toList();
}

/// Shops matching the text (name, address, district) and the chosen city and category (null means any).
List<Shop> searchShops(List<Shop> shops, {String query = '', String? city, String? category}) {
  final q = query.trim().toLowerCase();
  return [
    for (final s in shops)
      if ((city == null || s.city == city) &&
          (category == null || s.categories.contains(category)) &&
          (q.isEmpty || s.name.toLowerCase().contains(q) || s.address.toLowerCase().contains(q) || s.district.contains(q)))
        s,
  ];
}

sealed class ShopsState {
  const ShopsState();
}

class ShopsLoading extends ShopsState {
  const ShopsLoading();
}

class ShopsUnavailable extends ShopsState {
  const ShopsUnavailable();
}

class ShopsReady extends ShopsState {
  const ShopsReady(this.data, {this.refreshFailed = false});
  final ShopList data;
  final bool refreshFailed;
}
