import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:summitmate/core/di.dart';
import 'package:summitmate/data/models/gear_item.dart';
import 'package:summitmate/data/models/gear_library_item.dart';
import 'package:summitmate/data/repositories/interfaces/i_gear_library_repository.dart';
import 'package:summitmate/data/repositories/interfaces/i_gear_repository.dart';
import 'package:summitmate/presentation/providers/gear_library_provider.dart';
import 'package:summitmate/presentation/providers/gear_provider.dart';
import 'package:summitmate/data/repositories/interfaces/i_trip_repository.dart';
import 'package:summitmate/data/models/trip.dart';

import 'gear_library_provider_test.mocks.dart';

// Generate Mocks
@GenerateMocks([IGearRepository, IGearLibraryRepository, ITripRepository])
void main() {
  late MockIGearRepository mockGearRepo;
  late MockIGearLibraryRepository mockLibraryRepo;
  late MockITripRepository mockTripRepo;
  late GearProvider gearProvider;
  late GearLibraryProvider libraryProvider;

  setUpAll(() async {
    // Hive checks can be mocked or skipped if Repositories are mocked correctly.
    // Since we use HiveObject.save() in the provider, we might need real Hive setup or mock the item.save().
    // However, GearItem extends HiveObject. save() calls delete()/put().
    // We can't easily mock HiveObject extension methods unless we wrap them.
    // BUT: The Provider calls `item.save()`. This will fail if box is not open.
    // Strategy: Use Hive.init with temp dir for real Hive behavior on items.
    // Create a temp dir
    final tempDir = await Directory.systemTemp.createTemp();
    Hive.init(tempDir.path);
    Hive.registerAdapter(GearItemAdapter());
    Hive.registerAdapter(GearLibraryItemAdapter());
  });

  setUp(() async {
    await getIt.reset();

    mockGearRepo = MockIGearRepository();
    mockLibraryRepo = MockIGearLibraryRepository();
    mockTripRepo = MockITripRepository();

    // Register mocks needed by Providers
    getIt.registerSingleton<IGearRepository>(mockGearRepo);
    getIt.registerSingleton<IGearLibraryRepository>(mockLibraryRepo);
    getIt.registerSingleton<ITripRepository>(mockTripRepo);

    // Setup Providers in DI because GearLibraryProvider uses getIt<GearProvider>
    // Note: Providers usually shouldn't be singletons in DI if they are ChangeNotifier,
    // but here we register them for cross-access.
    // In app, they are provided by MultiProvider. GearLibraryProvider uses getIt to find GearProvider?
    // Let's check GearLibraryProvider implementation: `final gearProvider = getIt<GearProvider>();`
    // Yes, it uses getIt. So we must register GearProvider.

    // We need to initialize them.
    // Mock getAllItems to return empty list initially
    when(mockGearRepo.getAllItems()).thenReturn([]);
    when(mockLibraryRepo.getAllItems()).thenReturn([]);
    when(mockTripRepo.getActiveTrip()).thenReturn(null);

    gearProvider = GearProvider(repository: mockGearRepo);
    libraryProvider = GearLibraryProvider(
      repository: mockLibraryRepo,
      gearRepository: mockGearRepo,
      tripRepository: mockTripRepo,
    );

    getIt.registerSingleton<GearProvider>(gearProvider);
    getIt.registerSingleton<GearLibraryProvider>(libraryProvider);
  });

  test('Sync linked gear when library item updates', () async {
    // 1. Setup Library Item
    final libItem = GearLibraryItem(name: 'Sleeping Bag', weight: 1000, category: 'Sleep');
    when(mockLibraryRepo.updateItem(libItem)).thenAnswer((_) async {});
    when(mockLibraryRepo.getAllItems()).thenReturn([libItem]);

    // Setup Active Trip
    final activeTrip = Trip(
      id: 'trip1',
      name: 'Test Trip',
      startDate: DateTime.now(),
      isActive: true,
      createdAt: DateTime.now(),
    );
    when(mockTripRepo.getTripById('trip1')).thenReturn(activeTrip);
    when(mockTripRepo.getActiveTrip()).thenReturn(activeTrip);

    // 2. Setup Linked Gear Item (e.g. in a trip)
    // We need a real Hive box for .save() to work?
    // HiveObject.save() relies on being in a box.
    // If we can't open box easily, we might get error.
    // Let's rely on manual property check first, assuming save() is called.
    // Or we stub Hive behavior.
    // Actually, `gear.save()` might throw if not in box.
    // Let's Open a temporary box.
    final boxName = 'test_gear_sync';
    if (Hive.isBoxOpen(boxName)) await Hive.box(boxName).deleteFromDisk();
    final box = await Hive.openBox<GearItem>(boxName);

    final gearItem = GearItem(
      name: 'Sleeping Bag',
      weight: 1000,
      category: 'Sleep',
      isChecked: false,
      libraryItemId: libItem.uuid,
      tripId: 'trip1',
    );
    await box.add(gearItem);

    // Inject this item into GearProvider
    // GearProvider loads from repo.
    when(mockGearRepo.getAllItems()).thenReturn([gearItem]);

    // Must set trip context for GearProvider to load items!
    gearProvider.setTripId('trip1');
    gearProvider.reload();

    expect(gearProvider.allItems.first.weight, 1000);

    // 3. Update Library Item
    libItem.weight = 800; // Updated weight (lighter!)
    libItem.name = 'Ultra Light Bag';

    // 4. Trigger Update in Provider
    await libraryProvider.updateItem(libItem);

    // 5. Verify Linked Gear is updated
    // The provider calls `gearItem.save()`.
    // The in-memory object `gearItem` should be mutated.
    expect(gearItem.weight, 800);
    expect(gearItem.name, 'Ultra Light Bag');

    // Clean up
    await box.deleteFromDisk();
  });

  test('Do NOT sync linked gear if trip is archived', () async {
    // 1. Setup Library Item
    final libItem = GearLibraryItem(name: 'Old Tent', weight: 2000, category: 'Shelter');
    when(mockLibraryRepo.updateItem(libItem)).thenAnswer((_) async {});
    when(mockLibraryRepo.getAllItems()).thenReturn([libItem]);

    // 2. Setup Archived Trip
    final archivedTrip = Trip(
      id: 'trip_archived',
      name: 'Old Trip',
      startDate: DateTime(2020, 1, 1),
      endDate: DateTime(2020, 1, 5),
      isActive: false,
      createdAt: DateTime(2019, 12, 1),
    );
    when(mockTripRepo.getTripById('trip_archived')).thenReturn(archivedTrip);
    when(mockTripRepo.getActiveTrip()).thenReturn(archivedTrip);

    // 3. Setup Linked Gear Item
    final boxName = 'test_gear_sync_archive';
    if (Hive.isBoxOpen(boxName)) await Hive.box(boxName).deleteFromDisk();
    final box = await Hive.openBox<GearItem>(boxName);

    final gearItem = GearItem(
      name: 'Old Tent',
      weight: 2000,
      category: 'Shelter',
      isChecked: true,
      libraryItemId: libItem.uuid,
      tripId: 'trip_archived',
    );
    await box.add(gearItem);

    // Inject into Repo
    when(mockGearRepo.getAllItems()).thenReturn([gearItem]);

    // Set trip context
    gearProvider.setTripId('trip_archived');
    gearProvider.reload();

    expect(gearProvider.allItems.first.weight, 2000);

    // 4. Trigger Update
    libItem.weight = 1500;
    await libraryProvider.updateItem(libItem);

    // 5. Verify Gear Item is UNCHANGED
    expect(gearItem.weight, 2000); // Should still be 2000 (Protected)

    await box.deleteFromDisk();
  });
}
