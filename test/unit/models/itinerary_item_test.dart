import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/data/models/itinerary_item.dart';

void main() {
  group('ItineraryItem Model Tests', () {
    test('should create itinerary item with required fields', () {
      final item = ItineraryItem()
        ..day = 'D1'
        ..name = '向陽山屋'
        ..estTime = '11:30'
        ..altitude = 2850
        ..distance = 4.3
        ..note = '午餐點';

      expect(item.day, 'D1');
      expect(item.name, '向陽山屋');
      expect(item.estTime, '11:30');
      expect(item.altitude, 2850);
      expect(item.distance, 4.3);
      expect(item.note, '午餐點');
      expect(item.actualTime, isNull);
      expect(item.imageAsset, isNull);
    });

    test('should handle check-in with actualTime', () {
      final checkInTime = DateTime(2024, 12, 15, 11, 35);
      final item = ItineraryItem()
        ..day = 'D1'
        ..name = '向陽山屋'
        ..estTime = '11:30';

      item.actualTime = checkInTime;

      expect(item.actualTime, checkInTime);
    });

    test('should clear check-in by setting actualTime to null', () {
      final item = ItineraryItem()
        ..day = 'D1'
        ..name = '向陽山屋'
        ..estTime = '11:30'
        ..actualTime = DateTime.now();

      item.actualTime = null;

      expect(item.actualTime, isNull);
    });

    test('should support image asset', () {
      final item = ItineraryItem()
        ..day = 'D1'
        ..name = '向陽登山口'
        ..imageAsset = 'trailhead.jpg';

      expect(item.imageAsset, 'trailhead.jpg');
    });

    test('should validate day format', () {
      final item = ItineraryItem()..day = 'D0';
      expect(['D0', 'D1', 'D2'].contains(item.day), isTrue);

      item.day = 'InvalidDay';
      expect(['D0', 'D1', 'D2'].contains(item.day), isFalse);
    });
  });
}
