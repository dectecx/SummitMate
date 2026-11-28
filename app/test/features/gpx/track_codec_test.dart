import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/features/gpx/domain/gpx_models.dart';
import 'package:summitmate/features/trips/domain/track_codec.dart';

void main() {
  test('a stored track is simplified to at most 500 points and survives encoding; damaged text gives an empty track', () {
    final many = [for (var i = 0; i < 5000; i++) GpxPoint(lat: 23 + i / 100000, lng: 121, ele: 1000 + i / 10)];
    final simple = simplifyTrack(many);
    expect(simple.length, 500);
    expect([simple.first.lat, simple.last.lat], [many.first.lat, many.last.lat]);
    final json = encodeTrack(simple);
    expect(json.length, lessThan(20000), reason: 'small enough to sync inside the trip row');
    final back = decodeTrack(json);
    expect(back.length, 500);
    expect(back.first.ele, 1000);
    expect(decodeTrack('not json'), isEmpty);
    expect(decodeTrack(null), isEmpty);
  });
}
