import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/features/map/domain/offline_regions.dart';

void main() {
  test('a point is matched to the detailed area that covers it', () {
    expect(offlineRegionFor(23.47, 120.96)?.id, 'yushan');
    expect(offlineRegionFor(22.63, 120.76)?.id, 'beidawu');
  });

  test('a point outside every detailed area gets none, and overlaps go to the nearest centre', () {
    expect(offlineRegionFor(25.0, 121.5), isNull);
    // Between 嘉明湖與向陽 (23.29, 121.00) and 秀姑巒 (23.50, 121.05): nearest centre wins.
    expect(offlineRegionFor(23.45, 121.06)?.id, 'xiuguluan');
    expect(offlineRegionFor(23.33, 121.01)?.id, 'jiaming');
  });
}
