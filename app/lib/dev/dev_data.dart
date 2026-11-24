import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/events/data/events_api.dart';
import '../features/events/providers.dart';
import '../features/gear/domain/gear_logic.dart';
import '../features/gear/providers.dart';
import '../features/meals/domain/meal_logic.dart';
import '../features/meals/providers.dart';
import '../features/trips/domain/trip_logic.dart';
import '../features/trips/providers.dart';

/// Makes random but plausible test data (trips, gear, meals, group events) through the real repositories,
/// so everything it creates syncs like data typed by hand. Pass a seeded [Random] for repeatable results.
class DevDataFactory {
  DevDataFactory(this._ref, {Random? random}) : _random = random ?? Random();
  final Ref _ref;
  final Random _random;

  static const _places = [
    ('嘉明湖', 3310, '台東海端'),
    ('雪山主東線', 3886, '台中和平'),
    ('玉山主峰', 3952, '南投信義'),
    ('合歡北峰', 3422, '南投仁愛'),
    ('南湖大山', 3742, '宜蘭大同'),
    ('能高越嶺', 2900, '花蓮萬榮'),
    ('大霸尖山', 3492, '新竹尖石'),
    ('向陽山', 3603, '台東海端'),
    ('北大武山', 3092, '屏東泰武'),
    ('鳶嘴稍來', 2100, '南投仁愛'),
  ];
  static const _suffix = ['兩天一夜', '三天兩夜', '單日行程', '四天三夜'];
  static const _gear = [
    ('羽絨睡袋', 'sleep', 900.0),
    ('睡墊', 'sleep', 450.0),
    ('登山爐頭', 'cook', 90.0),
    ('瓦斯罐', 'cook', 350.0),
    ('鈦杯', 'cook', 60.0),
    ('防水外套', 'clothing', 380.0),
    ('排汗衣', 'clothing', 150.0),
    ('登山杖', 'pack', 480.0),
    ('55L 背包', 'pack', 1800.0),
    ('頭燈', 'electronics', 90.0),
    ('行動電源', 'electronics', 280.0),
    ('急救包', 'safety', 250.0),
    ('哨子', 'safety', 15.0),
    ('雨衣', 'clothing', 220.0),
  ];
  static const _meals = [
    ('燕麥粥', 'breakfast', 80.0, 320.0),
    ('吐司夾蛋', 'breakfast', 120.0, 380.0),
    ('乾燥飯', 'lunch', 100.0, 450.0),
    ('御飯糰', 'lunch', 110.0, 240.0),
    ('泡麵加蛋', 'dinner', 110.0, 500.0),
    ('火鍋料理包', 'dinner', 300.0, 600.0),
    ('能量棒', 'snack', 50.0, 220.0),
    ('堅果', 'snack', 40.0, 250.0),
    ('巧克力', 'snack', 30.0, 160.0),
  ];

  T _pick<T>(List<T> list) => list[_random.nextInt(list.length)];

  /// A random trip with an itinerary, a packing list and meals. Returns its id.
  Future<String> randomTrip() async {
    final (place, altitude, _) = _pick(_places);
    final days = 1 + _random.nextInt(3);
    final start = DateTime.now().add(Duration(days: 3 + _random.nextInt(60)));
    final trips = _ref.read(tripRepositoryProvider);
    final id = await trips.create(
      name: '$place${_pick(_suffix)}',
      start: DateTime(start.year, start.month, start.day),
      end: DateTime(start.year, start.month, start.day + days - 1),
      description: '測試資料（由開發面板產生）',
    );
    final itinerary = _ref.read(itineraryRepositoryProvider);
    for (var day = 1; day <= days; day++) {
      await itinerary.add(id, dayIndex: day, name: day == 1 ? '$place登山口' : '營地 $day', estMinutes: 6 * 60 + _random.nextInt(120), altitude: altitude - 600 + day * 150);
      await itinerary.add(id, dayIndex: day, name: '$place山屋', estMinutes: 12 * 60, altitude: altitude - 300 + day * 100, distance: 2.5 + _random.nextInt(60) / 10);
    }
    await randomGear(id);
    await randomMeals(id, days: days);
    return id;
  }

  /// Adds 4–8 random gear items to [tripId].
  Future<void> randomGear(String tripId) async {
    final gear = _ref.read(gearRepositoryProvider);
    final items = [..._gear]..shuffle(_random);
    for (final (name, category, grams) in items.take(4 + _random.nextInt(5))) {
      assert(GearCategory.values.any((c) => c.key == category));
      await gear.add(tripId, name: name, weight: grams, category: category, quantity: 1 + _random.nextInt(2));
    }
  }

  /// Adds 2–3 random meals to each of the first [days] days of [tripId].
  Future<void> randomMeals(String tripId, {required int days}) async {
    final meals = _ref.read(mealRepositoryProvider);
    for (var day = 1; day <= days; day++) {
      final items = [..._meals]..shuffle(_random);
      for (final (name, type, grams, kcal) in items.take(2 + _random.nextInt(2))) {
        assert(MealType.values.any((t) => t.key == type));
        await meals.add(tripId, dayIndex: day, name: name, mealType: type, weight: grams, calories: kcal);
      }
    }
  }

  /// A random group event (needs a signed-in account and a connection). Returns its id.
  Future<String> randomEvent() async {
    final (place, _, location) = _pick(_places);
    final start = DateTime.now().add(Duration(days: 7 + _random.nextInt(60)));
    final input = EventInput(
      title: '$place揪團 ${1 + _random.nextInt(99)}',
      category: _pick(EventCategory.values),
      location: location,
      startDate: formatDate(start),
      endDate: formatDate(start.add(Duration(days: _random.nextInt(3)))),
      maxMembers: 4 + _random.nextInt(9),
      approvalRequired: _random.nextBool(),
      description: '測試資料（由開發面板產生）。',
    );
    return (await _ref.read(eventsApiProvider).create(input)).id;
  }
}

final devDataFactoryProvider = Provider((ref) => DevDataFactory(ref));
