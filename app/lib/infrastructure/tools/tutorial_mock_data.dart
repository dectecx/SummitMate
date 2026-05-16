import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/core/constants/domain_constants.dart';

/// 教學模式的完整 Mock 資料快照
///
/// 由 [TutorialMockData.createSnapshot] 建立，直接存入 [TutorialActive] state，
/// 讓 UI 層的 TutorialAwareBuilder 讀取。
class TutorialMockSnapshot {
  final Trip trip;
  final List<ItineraryItem> itineraryItems;
  final List<String> dayNames;
  final List<GearItem> gearItems;
  final List<DailyMealPlan> mealPlans;

  const TutorialMockSnapshot({
    required this.trip,
    required this.itineraryItems,
    required this.dayNames,
    required this.gearItems,
    required this.mealPlans,
  });
}

/// 教學模式使用的 Mock 資料工廠
///
/// 提供示範用的行程、行程項目與裝備資料。
/// 所有資料均不寫入 DB，僅存活於 TutorialActive state。
class TutorialMockData {
  TutorialMockData._();

  static const String _mockTripId = 'tutorial-mock-trip-001';
  static const String _mockUserId = 'tutorial-mock-user';

  /// 建立示範行程（嘉明湖 3 天 2 夜）
  static Trip createMockTrip() {
    final now = DateTime.now();
    return Trip(
      id: _mockTripId,
      userId: _mockUserId,
      name: '🏔️ 嘉明湖 3 天 2 夜（教學範例）',
      description: '南二段經典路線，造訪天使的眼淚——嘉明湖',
      startDate: now.add(const Duration(days: 14)),
      endDate: now.add(const Duration(days: 16)),
      isActive: true,
      dayNames: const ['向陽山莊', '嘉明湖', '嘉明湖往返'],
      syncStatus: SyncStatus.synced,
      cloudSyncedAt: now,
      createdAt: now,
      createdBy: _mockUserId,
      updatedAt: now,
      updatedBy: _mockUserId,
    );
  }

  /// 建立示範行程項目
  static List<ItineraryItem> createMockItineraryItems() {
    final now = DateTime.now();
    return [
      // D1
      ItineraryItem(
        id: 'mock-itin-01',
        tripId: _mockTripId,
        day: 'D1',
        name: '向陽停車場',
        estTime: '08:00',
        altitude: 2580,
        distance: 0,
        note: '集合點，確認裝備',
        createdAt: now,
        updatedAt: now,
      ),
      ItineraryItem(
        id: 'mock-itin-02',
        tripId: _mockTripId,
        day: 'D1',
        name: '向陽山莊',
        estTime: '12:30',
        altitude: 2850,
        distance: 5.2,
        note: '午餐、休息',
        createdAt: now,
        updatedAt: now,
      ),
      ItineraryItem(
        id: 'mock-itin-03',
        tripId: _mockTripId,
        day: 'D1',
        name: '嘉明湖山屋',
        estTime: '16:00',
        altitude: 3310,
        distance: 4.8,
        note: '今晚紮營處',
        createdAt: now,
        updatedAt: now,
      ),
      // D2
      ItineraryItem(
        id: 'mock-itin-04',
        tripId: _mockTripId,
        day: 'D2',
        name: '嘉明湖',
        estTime: '07:00',
        altitude: 3310,
        distance: 0.8,
        note: '天使的眼淚，日出最美',
        createdAt: now,
        updatedAt: now,
      ),
      ItineraryItem(
        id: 'mock-itin-05',
        tripId: _mockTripId,
        day: 'D2',
        name: '三叉山',
        estTime: '10:00',
        altitude: 3496,
        distance: 3.1,
        note: '百岳之一，視野極佳',
        createdAt: now,
        updatedAt: now,
      ),
      // D3
      ItineraryItem(
        id: 'mock-itin-06',
        tripId: _mockTripId,
        day: 'D3',
        name: '向陽停車場（返程）',
        estTime: '14:00',
        altitude: 2580,
        distance: 10.0,
        note: '原路返回',
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  /// 建立示範裝備清單
  static List<GearItem> createMockGearItems() {
    final now = DateTime.now();
    return [
      GearItem(
        id: 'mock-gear-01',
        tripId: _mockTripId,
        name: '登山背包 65L',
        weight: 1800,
        category: GearCategory.wear,
        quantity: 1,
        createdAt: now,
        updatedAt: now,
      ),
      GearItem(
        id: 'mock-gear-02',
        tripId: _mockTripId,
        name: '三季睡袋',
        weight: 1200,
        category: GearCategory.sleep,
        quantity: 1,
        createdAt: now,
        updatedAt: now,
      ),
      GearItem(
        id: 'mock-gear-03',
        tripId: _mockTripId,
        name: '輕量帳篷',
        weight: 1500,
        category: GearCategory.sleep,
        quantity: 1,
        createdAt: now,
        updatedAt: now,
      ),
      GearItem(
        id: 'mock-gear-04',
        tripId: _mockTripId,
        name: '登山雨衣（上衣）',
        weight: 400,
        category: GearCategory.wear,
        quantity: 1,
        createdAt: now,
        updatedAt: now,
      ),
      GearItem(
        id: 'mock-gear-05',
        tripId: _mockTripId,
        name: '行動電源 20000mAh',
        weight: 450,
        category: '電子',
        quantity: 1,
        createdAt: now,
        updatedAt: now,
      ),
      GearItem(
        id: 'mock-gear-06',
        tripId: _mockTripId,
        name: '登山杖',
        weight: 300,
        category: '輔助',
        quantity: 2,
        createdAt: now,
        updatedAt: now,
      ),
      GearItem(
        id: 'mock-gear-07',
        tripId: _mockTripId,
        name: '高山糧食（3 天份）',
        weight: 2400,
        category: '糧食',
        quantity: 1,
        createdAt: now,
        updatedAt: now,
      ),
      GearItem(
        id: 'mock-gear-08',
        tripId: _mockTripId,
        name: '急救包',
        weight: 200,
        category: '安全',
        quantity: 1,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  /// 建立示範糧食計畫
  static List<DailyMealPlan> createMockDailyMealPlans() {
    return [
      DailyMealPlan(
        dayInfo: const MealPlanDay(id: 'mock-meal-day-1', name: '出發日', linkedItineraryDay: 'D1'),
        meals: {
          MealType.breakfast: [
            MealItem(id: 'mock-meal-1', name: '飯糰', weight: 150, calories: 350, quantity: 1),
            MealItem(id: 'mock-meal-2', name: '豆漿', weight: 250, calories: 150, quantity: 1),
          ],
          MealType.lunch: [MealItem(id: 'mock-meal-3', name: '肉包', weight: 120, calories: 300, quantity: 2)],
          MealType.dinner: [MealItem(id: 'mock-meal-4', name: '排骨飯', weight: 400, calories: 800, quantity: 1)],
          MealType.action: [MealItem(id: 'mock-meal-5', name: '能量棒', weight: 50, calories: 200, quantity: 2)],
        },
      ),
      DailyMealPlan(
        dayInfo: const MealPlanDay(id: 'mock-meal-day-2', name: '攻頂日', linkedItineraryDay: 'D2'),
        meals: {
          MealType.breakfast: [
            MealItem(id: 'mock-meal-6', name: '麵包', weight: 100, calories: 300, quantity: 2),
            MealItem(id: 'mock-meal-7', name: '熱可可', weight: 25, calories: 100, quantity: 1),
          ],
          MealType.lunch: [MealItem(id: 'mock-meal-8', name: '乾燥飯', weight: 100, calories: 400, quantity: 1)],
          MealType.dinner: [
            MealItem(id: 'mock-meal-9', name: '泡麵', weight: 100, calories: 450, quantity: 2),
            MealItem(id: 'mock-meal-10', name: '茶包', weight: 10, calories: 0, quantity: 2),
          ],
          MealType.action: [MealItem(id: 'mock-meal-11', name: '堅果', weight: 100, calories: 600, quantity: 1)],
        },
      ),
    ];
  }

  /// Mock Trip ID（可供其他模組識別是否為教學資料）
  static String get mockTripId => _mockTripId;

  /// 建立完整的 Mock 資料快照（供 TutorialCubit 使用）
  ///
  /// 將所有 Mock 資料整合成一個 [TutorialMockSnapshot]，
  /// 直接存入 [TutorialActive] state，避免推送至各業務 Cubit。
  static TutorialMockSnapshot createSnapshot() {
    final trip = createMockTrip();
    return TutorialMockSnapshot(
      trip: trip,
      itineraryItems: createMockItineraryItems(),
      dayNames: trip.dayNames,
      gearItems: createMockGearItems(),
      mealPlans: createMockDailyMealPlans(),
    );
  }
}
