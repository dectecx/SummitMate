import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:summitmate/core/constants.dart';
import 'package:summitmate/services/hive_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    // 使用系統暫存目錄建立獨立測試空間
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);

    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    try {
      await Hive.close();
    } catch (_) {}

    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  Future<void> createBox(String name) async {
    var box = await Hive.openBox(name);
    await box.put('key', 'value');
    await box.close();
  }

  test('clearItinerary deletes ONLY itinerary box', () async {
    await createBox(HiveBoxNames.itinerary);
    await createBox(HiveBoxNames.trips);

    expect(await Hive.boxExists(HiveBoxNames.itinerary), isTrue);
    expect(await Hive.boxExists(HiveBoxNames.trips), isTrue);

    await HiveService().clearSelectedData(clearItinerary: true);

    expect(await Hive.boxExists(HiveBoxNames.itinerary), isFalse);
    expect(await Hive.boxExists(HiveBoxNames.trips), isTrue); // Should still exist
  });

  test('clearTrips deletes ONLY trips box', () async {
    await createBox(HiveBoxNames.itinerary);
    await createBox(HiveBoxNames.trips);

    expect(await Hive.boxExists(HiveBoxNames.itinerary), isTrue);
    expect(await Hive.boxExists(HiveBoxNames.trips), isTrue);

    await HiveService().clearSelectedData(clearTrips: true);

    expect(await Hive.boxExists(HiveBoxNames.itinerary), isTrue); // Should still exist
    expect(await Hive.boxExists(HiveBoxNames.trips), isFalse);
  });

  test('clearGear deletes ONLY gear box', () async {
    await createBox(HiveBoxNames.gear);
    await createBox(HiveBoxNames.gearLibrary);

    expect(await Hive.boxExists(HiveBoxNames.gear), isTrue);
    expect(await Hive.boxExists(HiveBoxNames.gearLibrary), isTrue);

    await HiveService().clearSelectedData(clearGear: true);

    expect(await Hive.boxExists(HiveBoxNames.gear), isFalse);
    expect(await Hive.boxExists(HiveBoxNames.gearLibrary), isTrue); // Should still exist
  });

  test('clearGearLibrary deletes ONLY gearLibrary box', () async {
    await createBox(HiveBoxNames.gear);
    await createBox(HiveBoxNames.gearLibrary);

    await HiveService().clearSelectedData(clearGearLibrary: true);

    expect(await Hive.boxExists(HiveBoxNames.gear), isTrue); // Should still exist
    expect(await Hive.boxExists(HiveBoxNames.gearLibrary), isFalse);
  });

  test('clearPolls deletes polls box', () async {
    await createBox(HiveBoxNames.polls);
    expect(await Hive.boxExists(HiveBoxNames.polls), isTrue);
    await HiveService().clearSelectedData(clearPolls: true);
    expect(await Hive.boxExists(HiveBoxNames.polls), isFalse);
  });

  test('clearLogs deletes logs box', () async {
    await createBox(HiveBoxNames.logs);
    await HiveService().clearSelectedData(clearLogs: true);
    expect(await Hive.boxExists(HiveBoxNames.logs), isFalse);
  });

  test('clearSettings deletes settings box and clears SharedPreferences', () async {
    await createBox(HiveBoxNames.settings);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.username, 'test_user');

    expect(await Hive.boxExists(HiveBoxNames.settings), isTrue);
    expect(prefs.getString(PrefKeys.username), 'test_user');

    await HiveService().clearSelectedData(clearSettings: true);

    expect(await Hive.boxExists(HiveBoxNames.settings), isFalse);
    expect(prefs.getString(PrefKeys.username), isNull);
  });

  test('Combined flags clear multiple boxes', () async {
    await createBox(HiveBoxNames.itinerary);
    await createBox(HiveBoxNames.trips);
    await createBox(HiveBoxNames.gear);
    await createBox(HiveBoxNames.gearLibrary);

    await HiveService().clearSelectedData(
      clearItinerary: true,
      clearTrips: true,
      clearGear: true,
      clearGearLibrary: true,
    );

    expect(await Hive.boxExists(HiveBoxNames.itinerary), isFalse);
    expect(await Hive.boxExists(HiveBoxNames.trips), isFalse);
    expect(await Hive.boxExists(HiveBoxNames.gear), isFalse);
    expect(await Hive.boxExists(HiveBoxNames.gearLibrary), isFalse);
  });
}
