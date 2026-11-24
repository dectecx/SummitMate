import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:summitmate/features/explore/data/mountain_repository.dart' show MountainsResponse;
import 'package:summitmate/features/explore/data/shop_repository.dart';
import 'package:summitmate/features/explore/domain/shop_models.dart';
import 'package:summitmate/features/explore/providers.dart';
import 'package:summitmate/shared/open_link.dart';

import 'explore_test.dart' show FakeExploreApi, m, payloadOf;
import 'harness.dart';

Map<String, dynamic> shop(String id, String name, String city, List<String> cats, {String? phone, double rating = 4.4}) => {
  'id': id,
  'name': name,
  'city': city,
  'district': '',
  'address': '中山路1號',
  'phone': phone,
  'google_maps_url': 'https://www.google.com/maps/search/?api=1&query=$id',
  'hours': null,
  'categories': cats,
  'rating': rating,
  'rating_count': 120,
  'checked_on': '2026-11-25',
};

class FakeShopsApi implements ShopsApi {
  FakeShopsApi(this.payload);
  final String payload;
  @override
  Future<MountainsResponse> fetchShops({String? etag}) async => MountainsResponse.fresh(payload, '"s1"');
}

void main() {
  final payload = jsonEncode({
    'version': 'v1',
    'shops': [
      shop('a', '北山登山店', '臺北市', ['登山裝備', '服飾'], phone: '02 2345 6789'),
      shop('b', '中部露營坊', '臺中市', ['露營']),
      shop('c', '深藍潛水', '高雄市', ['潛水']),
    ],
  });

  test('searchShops combines text, city and category', () {
    final shops = ShopList.parse(payload).shops;
    expect(searchShops(shops).length, 3);
    expect(searchShops(shops, city: '臺中市').map((s) => s.id), ['b']);
    expect(searchShops(shops, category: '潛水').map((s) => s.id), ['c']);
    expect(searchShops(shops, query: '北山').map((s) => s.id), ['a']);
    expect(searchShops(shops, city: '臺北市', category: '露營'), isEmpty);
    expect(shops.first.dialNumber, '0223456789');
    expect(ShopList.parse(payload).cities, ['臺北市', '臺中市', '高雄市']);
  });

  testWidgets('the 用品店 segment lists shops, filters them, and opens map and phone links', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final opened = <Uri>[];
    final app = await AppHarness.start(
      tester,
      welcomeSeen: true,
      overrides: [
        shopsApiProvider.overrideWithValue(FakeShopsApi(payload)),
        exploreApiProvider.overrideWithValue(FakeExploreApi(payloadOf([m('yushan-main', '玉山', 3952)]))),
        linkOpenerProvider.overrideWithValue((u) async {
          opened.add(u);
          return true;
        }),
      ],
    );
    await tapText(tester, '探索');
    await tapText(tester, '用品店');
    await settleUntil(tester, find.byKey(const ValueKey('shop-a')));
    expect(find.byKey(const ValueKey('shop-b')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('shop-cat-潛水')));
    await settle(tester);
    expect(find.byKey(const ValueKey('shop-c')), findsOneWidget);
    expect(find.byKey(const ValueKey('shop-a')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('shop-cat-all')));
    await settle(tester);
    expect(find.byKey(const ValueKey('shop-a')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('shop-map-a')));
    await tester.tap(find.byKey(const ValueKey('shop-call-a')));
    await settle(tester);
    expect(opened.map((u) => u.scheme), ['https', 'tel']);
    expect(opened.last.path, '0223456789');
    expect(find.byKey(const ValueKey('shop-call-b')), findsNothing, reason: 'no phone, no call button');
    await app.dispose(tester);
  });
}
