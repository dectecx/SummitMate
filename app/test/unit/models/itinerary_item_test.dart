import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/domain/entities/itinerary_item.dart';

void main() {
  group('ItineraryItem Model Tests', () {
    test('should create with default values', () {
      const item = ItineraryItem(id: 'id-1', tripId: 'trip_1', day: 'D1', name: '', estTime: '');

      expect(item.day, equals('D1'));
      expect(item.name, isEmpty);
      expect(item.estTime, isEmpty);
      expect(item.actualTime, isNull);
      expect(item.altitude, equals(0));
      expect(item.distance, equals(0.0));
      expect(item.note, isEmpty);
      expect(item.imageAsset, isNull);
    });

    test('should create an instance with provided values', () {
      const item = ItineraryItem(
        id: 'id-1',
        tripId: 'trip_1',
        day: 'D1',
        name: '向陽登山口',
        estTime: '08:00',
      );

      expect(item.day, equals('D1'));
      expect(item.name, equals('向陽登山口'));
      expect(item.estTime, equals('08:00'));
    });

    test('should create with named parameters', () {
      final item = ItineraryItem(
        id: 'id-2',
        tripId: 'trip_1',
        day: 'D1',
        name: '向陽山屋',
        estTime: '11:30',
        altitude: 2850,
        distance: 4.3,
        note: '午餐點',
      );

      expect(item.day, equals('D1'));
      expect(item.name, equals('向陽山屋'));
      expect(item.estTime, equals('11:30'));
      expect(item.altitude, equals(2850));
      expect(item.distance, equals(4.3));
      expect(item.note, equals('午餐點'));
    });

    test('should report not checked in when actualTime is null', () {
      const item = ItineraryItem(id: 'id-3', tripId: 'trip_1', day: 'D1', name: '', estTime: '');

      expect(item.isCheckedIn, isFalse);
    });

    test('should report checked in when isCheckedIn is true', () {
      final item = const ItineraryItem(id: 'id-4', tripId: 'trip_1', day: 'D1', name: '', estTime: '').copyWith(
        isCheckedIn: true,
        checkedInAt: DateTime.now(),
      );

      expect(item.isCheckedIn, isTrue);
    });

    test('should validate day format', () {
      const item = ItineraryItem(id: 'id-5', tripId: 'trip_1', day: 'D1', name: '', estTime: '');

      expect(item.day, matches(RegExp(r'^D\d$')));
    });

    test('should convert to/from JSON', () {
      const item = ItineraryItem(
        id: 'id-6',
        tripId: 'trip_1',
        day: 'D1',
        name: '向陽山屋',
        estTime: '11:30',
        altitude: 2850,
        distance: 4.3,
        note: '午餐點',
      );

      final json = item.toJson();
      final restored = ItineraryItem.fromJson(json);

      expect(restored.day, equals(item.day));
      expect(restored.name, equals(item.name));
      expect(restored.estTime, equals(item.estTime));
      expect(restored.altitude, equals(item.altitude));
      expect(restored.distance, equals(item.distance));
      expect(restored.note, equals(item.note));
    });
  });
}
