import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/data/models/trip.dart';

void main() {
  group('Trip Model Tests', () {
    group('Constructor', () {
      test('creates Trip with required fields', () {
        final trip = Trip(id: 'trip-123', name: '嘉明湖三日', startDate: DateTime(2024, 1, 15));

        expect(trip.id, 'trip-123');
        expect(trip.name, '嘉明湖三日');
        expect(trip.startDate, DateTime(2024, 1, 15));
        expect(trip.endDate, isNull);
        expect(trip.isActive, false);
        expect(trip.createdAt, isNotNull);
      });

      test('creates Trip with all optional fields', () {
        final trip = Trip(
          id: 'trip-456',
          name: '玉山單攻',
          startDate: DateTime(2024, 3, 1),
          endDate: DateTime(2024, 3, 1),
          description: '玉山主峰單日攻頂',
          coverImage: 'assets/yushan.jpg',
          isActive: true,
          createdAt: DateTime(2024, 2, 1),
        );

        expect(trip.id, 'trip-456');
        expect(trip.name, '玉山單攻');
        expect(trip.endDate, DateTime(2024, 3, 1));
        expect(trip.description, '玉山主峰單日攻頂');
        expect(trip.coverImage, 'assets/yushan.jpg');
        expect(trip.isActive, true);
        expect(trip.createdAt, DateTime(2024, 2, 1));
      });
    });

    group('durationDays', () {
      test('returns 1 when endDate is null', () {
        final trip = Trip(id: 'trip-1', name: 'Test', startDate: DateTime(2024, 1, 1));

        expect(trip.durationDays, 1);
      });

      test('calculates correct duration for same-day trip', () {
        final trip = Trip(id: 'trip-1', name: 'Test', startDate: DateTime(2024, 1, 1), endDate: DateTime(2024, 1, 1));

        expect(trip.durationDays, 1);
      });

      test('calculates correct duration for multi-day trip', () {
        final trip = Trip(id: 'trip-1', name: 'Test', startDate: DateTime(2024, 1, 1), endDate: DateTime(2024, 1, 3));

        expect(trip.durationDays, 3);
      });
    });

    group('fromJson', () {
      test('parses complete JSON correctly', () {
        final json = {
          'trip_id': 'trip-abc',
          'name': '嘉明湖三日',
          'start_date': '2024-01-15T00:00:00.000Z',
          'end_date': '2024-01-17T00:00:00.000Z',
          'description': '向陽山屋 → 嘉明湖',
          'cover_image': 'assets/jiaming.jpg',
          'is_active': true,
          'created_at': '2024-01-01T00:00:00.000Z',
        };

        final trip = Trip.fromJson(json);

        expect(trip.id, 'trip-abc');
        expect(trip.name, '嘉明湖三日');
        expect(trip.description, '向陽山屋 → 嘉明湖');
        expect(trip.coverImage, 'assets/jiaming.jpg');
        expect(trip.isActive, true);
      });

      test('parses JSON with "id" instead of "trip_id"', () {
        final json = {'id': 'trip-xyz', 'name': 'Test Trip', 'start_date': '2024-01-01T00:00:00.000Z'};

        final trip = Trip.fromJson(json);
        expect(trip.id, 'trip-xyz');
      });

      test('handles missing optional fields', () {
        final json = {'trip_id': 'trip-min', 'name': 'Minimal Trip'};

        final trip = Trip.fromJson(json);

        expect(trip.id, 'trip-min');
        expect(trip.name, 'Minimal Trip');
        expect(trip.endDate, isNull);
        expect(trip.description, isNull);
        expect(trip.coverImage, isNull);
        expect(trip.isActive, false);
      });

      test('handles is_active as "TRUE" string', () {
        final json = {'trip_id': 'trip-str', 'name': 'Test', 'is_active': 'TRUE'};

        final trip = Trip.fromJson(json);
        expect(trip.isActive, true);
      });
    });

    group('toJson', () {
      test('serializes to JSON correctly', () {
        final trip = Trip(
          id: 'trip-ser',
          name: '合歡山群峰',
          startDate: DateTime.utc(2024, 2, 1),
          endDate: DateTime.utc(2024, 2, 2),
          description: '合歡主峰、東峰、西峰',
          coverImage: 'assets/hehuan.jpg',
          isActive: true,
          createdAt: DateTime.utc(2024, 1, 15),
        );

        final json = trip.toJson();

        expect(json['trip_id'], 'trip-ser');
        expect(json['name'], '合歡山群峰');
        expect(json['start_date'], '2024-02-01T00:00:00.000Z');
        expect(json['end_date'], '2024-02-02T00:00:00.000Z');
        expect(json['description'], '合歡主峰、東峰、西峰');
        expect(json['cover_image'], 'assets/hehuan.jpg');
        expect(json['is_active'], true);
        expect(json['created_at'], '2024-01-15T00:00:00.000Z');
      });

      test('serializes null endDate as null', () {
        final trip = Trip(id: 'trip-null', name: 'No End', startDate: DateTime.utc(2024, 1, 1));

        final json = trip.toJson();
        expect(json['end_date'], isNull);
      });
    });

    group('toString', () {
      test('returns formatted string', () {
        final trip = Trip(id: 'trip-str', name: 'Test Trip', startDate: DateTime.now(), isActive: true);

        expect(trip.toString(), 'Trip(id: trip-str, name: Test Trip, isActive: true)');
      });
    });
  });
}
