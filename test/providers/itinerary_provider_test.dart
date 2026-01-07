import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:summitmate/core/constants.dart';
import 'package:summitmate/data/models/itinerary_item.dart';
import 'package:summitmate/data/models/trip.dart';
import 'package:summitmate/data/repositories/interfaces/i_itinerary_repository.dart';
import 'package:summitmate/data/repositories/interfaces/i_trip_repository.dart';
import 'package:summitmate/presentation/providers/itinerary_provider.dart';

// ============================================================
// === MOCKS ===
// ============================================================

/// Mock Itinerary Repository
class MockItineraryRepository implements IItineraryRepository {
  List<ItineraryItem> items = [];
  DateTime? lastSyncTime;

  @override
  Future<void> init() async {}

  @override
  List<ItineraryItem> getAllItems() => items;

  @override
  List<ItineraryItem> getItemsByDay(String day) =>
      items.where((item) => item.day == day).toList();

  @override
  ItineraryItem? getItemByKey(dynamic key) {
    try {
      return items.firstWhere((item) => item.uuid == key);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> checkIn(dynamic key, DateTime time) async {
    final index = items.indexWhere((item) => item.uuid == key);
    if (index >= 0) {
      items[index] = ItineraryItem(
        uuid: items[index].uuid,
        tripId: items[index].tripId,
        day: items[index].day,
        name: items[index].name,
        estTime: items[index].estTime,
        altitude: items[index].altitude,
        distance: items[index].distance,
        note: items[index].note,
        isCheckedIn: true,
        checkedInAt: time,
      );
    }
  }

  @override
  Future<void> clearCheckIn(dynamic key) async {
    final index = items.indexWhere((item) => item.uuid == key);
    if (index >= 0) {
      items[index] = ItineraryItem(
        uuid: items[index].uuid,
        tripId: items[index].tripId,
        day: items[index].day,
        name: items[index].name,
        estTime: items[index].estTime,
        altitude: items[index].altitude,
        distance: items[index].distance,
        note: items[index].note,
        isCheckedIn: false,
        checkedInAt: null,
      );
    }
  }

  @override
  Future<void> syncFromCloud(List<ItineraryItem> cloudItems) async {
    items = cloudItems;
  }

  @override
  Stream<BoxEvent> watchAllItems() => const Stream.empty();

  @override
  Future<void> resetAllCheckIns() async {
    for (var i = 0; i < items.length; i++) {
      items[i] = ItineraryItem(
        uuid: items[i].uuid,
        tripId: items[i].tripId,
        day: items[i].day,
        name: items[i].name,
        estTime: items[i].estTime,
        altitude: items[i].altitude,
        distance: items[i].distance,
        note: items[i].note,
        isCheckedIn: false,
        checkedInAt: null,
      );
    }
  }

  @override
  Future<void> addItem(ItineraryItem item) async {
    items.add(item);
  }

  @override
  Future<void> updateItem(dynamic key, ItineraryItem item) async {
    final index = items.indexWhere((i) => i.uuid == key);
    if (index >= 0) {
      items[index] = item;
    }
  }

  @override
  Future<void> saveLastSyncTime(DateTime time) async {
    lastSyncTime = time;
  }

  @override
  DateTime? getLastSyncTime() => lastSyncTime;

  @override
  Future<void> deleteItem(dynamic key) async {
    items.removeWhere((item) => item.uuid == key);
  }
}

/// Mock Trip Repository
class MockTripRepository implements ITripRepository {
  List<Trip> trips = [];
  Trip? activeTrip;

  @override
  Future<void> init() async {}

  @override
  List<Trip> getAllTrips() => trips;

  @override
  Trip? getActiveTrip() => activeTrip;

  @override
  Trip? getTripById(String id) {
    try {
      return trips.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> addTrip(Trip trip) async {
    trips.add(trip);
  }

  @override
  Future<void> updateTrip(Trip trip) async {
    final index = trips.indexWhere((t) => t.id == trip.id);
    if (index >= 0) {
      trips[index] = trip;
    }
  }

  @override
  Future<void> deleteTrip(String id) async {
    trips.removeWhere((t) => t.id == id);
  }

  @override
  Future<void> setActiveTrip(String tripId) async {
    activeTrip = getTripById(tripId);
  }

  @override
  DateTime? getLastSyncTime() => null;

  @override
  Future<void> saveLastSyncTime(DateTime time) async {}
}

// ============================================================
// === TEST DATA ===
// ============================================================

ItineraryItem createTestItem({
  String uuid = 'item-1',
  String tripId = 'trip-1',
  String day = 'D1',
  String name = 'Test Location',
  String estTime = '08:00',
  int altitude = 2000,
  double distance = 5.0,
  bool isCheckedIn = false,
}) {
  return ItineraryItem(
    uuid: uuid,
    tripId: tripId,
    day: day,
    name: name,
    estTime: estTime,
    altitude: altitude,
    distance: distance,
    isCheckedIn: isCheckedIn,
  );
}

Trip createTestTrip({String id = 'trip-1', String name = 'Test Trip'}) {
  return Trip(
    id: id,
    name: name,
    startDate: DateTime.now(),
    isActive: true,
    createdAt: DateTime.now(),
  );
}

// ============================================================
// === TESTS ===
// ============================================================

void main() {
  late MockItineraryRepository mockItineraryRepo;
  late MockTripRepository mockTripRepo;

  setUp(() {
    mockItineraryRepo = MockItineraryRepository();
    mockTripRepo = MockTripRepository();
    mockTripRepo.activeTrip = createTestTrip();
  });

  group('ItineraryProvider initialization', () {
    test('loads items on initialization', () async {
      mockItineraryRepo.items = [
        createTestItem(uuid: 'item-1'),
        createTestItem(uuid: 'item-2'),
      ];

      final provider = ItineraryProvider(
        repository: mockItineraryRepo,
        tripRepository: mockTripRepo,
      );

      // Wait for async _loadItems
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.allItems, hasLength(2));
      expect(provider.isLoading, isFalse);
    });

    test('sets selectedDay to D1 by default', () async {
      final provider = ItineraryProvider(
        repository: mockItineraryRepo,
        tripRepository: mockTripRepo,
      );

      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.selectedDay, ItineraryDay.d1);
    });
  });

  group('ItineraryProvider.selectDay', () {
    test('changes selected day', () async {
      final provider = ItineraryProvider(
        repository: mockItineraryRepo,
        tripRepository: mockTripRepo,
      );
      await Future.delayed(const Duration(milliseconds: 50));

      provider.selectDay(ItineraryDay.d2);

      expect(provider.selectedDay, ItineraryDay.d2);
    });
  });

  group('ItineraryProvider.currentDayItems', () {
    test('filters items by selected day', () async {
      mockItineraryRepo.items = [
        createTestItem(uuid: 'item-1', day: 'D1', name: 'Day 1 Item'),
        createTestItem(uuid: 'item-2', day: 'D2', name: 'Day 2 Item'),
        createTestItem(uuid: 'item-3', day: 'D1', name: 'Another D1 Item'),
      ];

      final provider = ItineraryProvider(
        repository: mockItineraryRepo,
        tripRepository: mockTripRepo,
      );
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.currentDayItems, hasLength(2));
      expect(provider.currentDayItems.every((item) => item.day == 'D1'), isTrue);
    });

    test('sorts items by estTime', () async {
      mockItineraryRepo.items = [
        createTestItem(uuid: 'item-1', day: 'D1', estTime: '10:00'),
        createTestItem(uuid: 'item-2', day: 'D1', estTime: '08:00'),
        createTestItem(uuid: 'item-3', day: 'D1', estTime: '09:00'),
      ];

      final provider = ItineraryProvider(
        repository: mockItineraryRepo,
        tripRepository: mockTripRepo,
      );
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.currentDayItems[0].estTime, '08:00');
      expect(provider.currentDayItems[1].estTime, '09:00');
      expect(provider.currentDayItems[2].estTime, '10:00');
    });
  });


  // Note: checkIn and clearCheckIn tests are skipped because the provider
  // uses item.key (Hive key) which is null without real Hive initialization.


  group('ItineraryProvider.progress', () {
    test('calculates progress correctly', () async {
      mockItineraryRepo.items = [
        createTestItem(uuid: 'item-1', isCheckedIn: true),
        createTestItem(uuid: 'item-2', isCheckedIn: true),
        createTestItem(uuid: 'item-3', isCheckedIn: false),
        createTestItem(uuid: 'item-4', isCheckedIn: false),
      ];

      final provider = ItineraryProvider(
        repository: mockItineraryRepo,
        tripRepository: mockTripRepo,
      );
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.progress, 0.5); // 2/4 = 50%
    });

    test('returns 0 when no items', () async {
      mockItineraryRepo.items = [];

      final provider = ItineraryProvider(
        repository: mockItineraryRepo,
        tripRepository: mockTripRepo,
      );
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.progress, 0);
    });
  });

  group('ItineraryProvider.currentTarget', () {
    test('returns first unchecked item in current day', () async {
      mockItineraryRepo.items = [
        createTestItem(uuid: 'item-1', day: 'D1', estTime: '08:00', isCheckedIn: true),
        createTestItem(uuid: 'item-2', day: 'D1', estTime: '09:00', isCheckedIn: false),
        createTestItem(uuid: 'item-3', day: 'D1', estTime: '10:00', isCheckedIn: false),
      ];

      final provider = ItineraryProvider(
        repository: mockItineraryRepo,
        tripRepository: mockTripRepo,
      );
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.currentTarget?.uuid, 'item-2');
    });

    test('returns null when all items checked', () async {
      mockItineraryRepo.items = [
        createTestItem(uuid: 'item-1', day: 'D1', isCheckedIn: true),
        createTestItem(uuid: 'item-2', day: 'D1', isCheckedIn: true),
      ];

      final provider = ItineraryProvider(
        repository: mockItineraryRepo,
        tripRepository: mockTripRepo,
      );
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.currentTarget, isNull);
    });
  });

  group('ItineraryProvider.toggleEditMode', () {
    test('toggles edit mode', () async {
      final provider = ItineraryProvider(
        repository: mockItineraryRepo,
        tripRepository: mockTripRepo,
      );
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.isEditMode, isFalse);

      provider.toggleEditMode();
      expect(provider.isEditMode, isTrue);

      provider.toggleEditMode();
      expect(provider.isEditMode, isFalse);
    });
  });

  // Note: Tests for checkIn, clearCheckIn, addItem, deleteItem are skipped
  // because they rely on item.key (Hive key) which is null without real Hive.
  // These would require integration tests with actual Hive initialization.
}
