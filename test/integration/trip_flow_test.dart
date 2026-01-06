import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:summitmate/data/models/trip.dart';
import 'package:summitmate/data/models/gear_item.dart';
import 'package:summitmate/data/repositories/interfaces/i_trip_repository.dart';
import 'package:summitmate/data/repositories/interfaces/i_gear_repository.dart';
import 'package:summitmate/presentation/providers/trip_provider.dart';
import 'package:summitmate/presentation/providers/gear_provider.dart';

// === Mocks ===

class MockTripRepository implements ITripRepository {
  final List<Trip> _trips = [];
  String? _activeTripId;
  DateTime? _lastSyncTime;

  @override
  Future<void> init() async {}

  @override
  List<Trip> getAllTrips() => _trips;

  @override
  Trip? getActiveTrip() {
    if (_activeTripId == null) return null;
    return _trips.cast<Trip?>().firstWhere((t) => t!.id == _activeTripId, orElse: () => null);
  }

  @override
  Trip? getTripById(String id) {
    return _trips.cast<Trip?>().firstWhere((t) => t!.id == id, orElse: () => null);
  }

  @override
  Future<void> addTrip(Trip trip) async {
    _trips.add(trip);
  }

  @override
  Future<void> updateTrip(Trip trip) async {
    final index = _trips.indexWhere((t) => t.id == trip.id);
    if (index != -1) {
      _trips[index] = trip;
    }
  }

  @override
  Future<void> deleteTrip(String id) async {
    _trips.removeWhere((t) => t.id == id);
  }

  @override
  Future<void> setActiveTrip(String tripId) async {
    _activeTripId = tripId;
  }

  @override
  DateTime? getLastSyncTime() => _lastSyncTime;

  @override
  Future<void> saveLastSyncTime(DateTime time) async {
    _lastSyncTime = time;
  }
}

class MockGearRepository implements IGearRepository {
  final List<GearItem> _items = [];

  @override
  Future<void> init() async {}

  @override
  List<GearItem> getAllItems() => _items;

  @override
  List<GearItem> getItemsByCategory(String category) {
    return _items.where((i) => i.category == category).toList();
  }

  @override
  List<GearItem> getUncheckedItems() {
    return _items.where((i) => !i.isChecked).toList();
  }

  @override
  Future<int> addItem(GearItem item) async {
    _items.add(item);
    return _items.length - 1; // Return fake key
  }

  @override
  Future<void> updateItem(GearItem item) async {
    final index = _items.indexWhere((i) => i.uuid == item.uuid);
    if (index != -1) {
      _items[index] = item;
    }
  }

  @override
  Future<void> deleteItem(dynamic key) async {
    // Mock: Can't easily delete by Hive key since we don't have it.
    // Assuming key is int in real implementation, but here we ignore
    // or try to find by index if key is int.
    if (key is int && key < _items.length) {
      _items.removeAt(key);
    }
  }

  @override
  Future<void> clearByTripId(String tripId) async {
    _items.removeWhere((i) => i.tripId == tripId);
  }

  @override
  Future<void> clearAll() async {
    _items.clear();
  }

  @override
  double getTotalWeight() {
    return _items.fold(0.0, (sum, item) => sum + (item.weight * item.quantity));
  }

  @override
  double getCheckedWeight() {
    return _items.where((i) => i.isChecked).fold(0.0, (sum, item) => sum + (item.weight * item.quantity));
  }

  @override
  Future<void> toggleChecked(dynamic key) async {}

  @override
  Map<String, double> getWeightByCategory() => {};

  @override
  Stream<BoxEvent> watchAllItems() => Stream.empty();

  @override
  Future<void> resetAllChecked() async {
    for (var item in _items) {
      item.isChecked = false;
    }
  }

  @override
  Future<void> updateItemsOrder(List<GearItem> items) async {}
}

void main() {
  late TripProvider testTripProvider;
  late GearProvider testGearProvider;
  late MockTripRepository tripRepo;
  late MockGearRepository gearRepo;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    tripRepo = MockTripRepository();
    gearRepo = MockGearRepository();

    testTripProvider = TripProvider(repository: tripRepo);
    testGearProvider = GearProvider(repository: gearRepo);
  });

  test('Integration: Create Trip, Switch Context, Add Gear', () async {
    // Setup initial data since MockRepo starts empty
    final initialTrip = Trip(
      id: 'default_trip',
      name: '我的登山行程',
      startDate: DateTime.now(),
      isActive: true,
      createdAt: DateTime.now(),
    );
    await tripRepo.addTrip(initialTrip);
    await tripRepo.setActiveTrip(initialTrip.id);

    // Create provider and wait for initial load
    testTripProvider = TripProvider(repository: tripRepo);

    // Re-initialize gear provider to match context if needed (though it's independent)
    testGearProvider = GearProvider(repository: gearRepo);

    // 1. Initial State
    expect(testTripProvider.trips.isNotEmpty, true);
    final defaultTrip = testTripProvider.activeTrip!;
    expect(defaultTrip.name, '我的登山行程');

    // 2. Create a specific new trip
    final newTripName = 'Integration Test Mountain';
    await testTripProvider.addTrip(name: newTripName, startDate: DateTime.now(), setAsActive: true);

    // Verify trip is active
    expect(testTripProvider.activeTrip?.name, newTripName);
    final newTripId = testTripProvider.activeTrip!.id;

    // 3. Switch GearProvider context to the new trip
    testGearProvider.setTripId(newTripId);

    // 4. Add Gear
    await testGearProvider.addItem(name: 'Tent', weight: 1500, category: 'Camping');

    // 5. Verify Gear is stored with correct Trip ID
    final items = gearRepo.getAllItems();
    final addedItem = items.last;

    expect(addedItem.name, 'Tent');
    expect(addedItem.weight, 1500.0);
    expect(addedItem.tripId, newTripId);

    // 6. Switch back to Default Trip
    await testTripProvider.setActiveTrip(defaultTrip.id);
    testGearProvider.setTripId(defaultTrip.id);

    // 7. Verify items in Repo still exist but would be filtered by Provider login
    final allItems = gearRepo.getAllItems();
    expect(allItems.any((i) => i.tripId == newTripId), true);
    expect(allItems.length, 1);
  });
}
