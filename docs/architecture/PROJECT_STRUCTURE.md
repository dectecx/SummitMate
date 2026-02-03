# 專案結構 (Project Structure)

```
lib/
├── app.dart                           # App 根元件 (MaterialApp 設定)
├── main.dart                          # 程式進入點
│
├── core/                              # 核心工具層
│   ├── core.dart                      # Barrel export
│   ├── constants.dart                 # API Actions, Box Names 等常數
│   ├── constants/                     # 常數子目錄
│   │   └── role_constants.dart        # 角色代碼定義 (admin, leader, guide, member)
│   ├── config/                        # 配置
│   │   └── env_config.dart            # 環境變數配置
│   ├── di.dart                        # 依賴注入 (GetIt)
│   ├── error/                         # 錯誤處理
│   │   └── result.dart                # Result<T, E> 型別 (Success/Failure)
│   ├── extensions.dart                # Dart 擴展方法
│   ├── gear_helpers.dart              # 裝備分類工具 (Icon, Name, Color)
│   ├── gpx_utils.dart                 # GPX 解析工具
│   ├── location/                      # 定位相關
│   │   ├── i_location_resolver.dart
│   │   └── township_location_resolver.dart
│   ├── services/                      # 核心服務
│   │   └── permission_service.dart    # 權限判斷邏輯
│   ├── theme/                         # 主題定義
│   │   ├── app_theme.dart             # 主題工廠
│   │   ├── *_theme.dart               # 各主題實作 (Summit, Ocean, Forest, etc.)
│   │   └── theme_provider.dart        # 主題狀態管理
│   └── offline_config.dart            # 離線圖磚配置
│
├── data/                              # 資料層
│   ├── data.dart                      # Barrel export
│   ├── cwa/                           # 氣象局資料結構
│   ├── models/                        # 資料模型 (HiveType)
│   │   ├── enums/                     # 列舉 (SyncStatus, FavoriteType)
│   │   ├── settings.dart              # [TypeId: 0] 全域設定
│   │   ├── itinerary_item.dart        # [TypeId: 1] 行程節點
│   │   ├── message.dart               # [TypeId: 2] 留言
│   │   ├── gear_item.dart             # [TypeId: 3] 個人裝備
│   │   ├── weather_data.dart          # [TypeId: 4,5] 氣象資料
│   │   ├── poll.dart                  # [TypeId: 6,7] 投票
│   │   ├── trip.dart                  # [TypeId: 8] 行程
│   │   ├── user_profile.dart          # [TypeId: 10] 用戶資料
│   │   ├── gear_library_item.dart     # [TypeId: 11] 裝備庫
│   │   ├── group_event.dart           # [TypeId: 12] 揪團
│   │   ├── group_event_application.dart # [TypeId: 13] 報名
│   │   ├── favorite.dart              # [TypeId: 14] 最愛
│   │   ├── gear_set.dart              # 雲端裝備組合 (非 Hive)
│   │   └── meal_item.dart             # 菜單項目 (記憶體)
│   ├── datasources/                   # 資料來源層 (Offline-First)
│   │   ├── interfaces/                # DataSource 介面
│   │   ├── local/                     # 本地儲存實作 (Hive)
│   │   └── remote/                    # 遠端 API 實作
│   └── repositories/                  # Repository 層 (DataSource 協調)
│       ├── interfaces/                # Repository 介面
│       └── *.dart                     # 具體實作
│
├── domain/                            # 領域層 (業務邏輯介面)
│   ├── domain.dart                    # Barrel export
│   ├── interfaces/                    # 服務介面定義
│   │   ├── i_auth_service.dart
│   │   ├── i_sync_service.dart
│   │   ├── i_data_service.dart
│   │   ├── i_poll_service.dart
│   │   ├── i_weather_service.dart
│   │   ├── i_gear_cloud_service.dart
│   │   ├── i_connectivity_service.dart
│   │   ├── i_geolocator_service.dart
│   │   ├── i_api_client.dart
│   │   └── i_token_validator.dart
│   ├── dto/                           # Data Transfer Objects
│   │   └── auth_result.dart
│   └── failures/                      # 領域失敗類型
│       └── failures.dart
│
├── infrastructure/                    # 基礎設施層 (外部服務實作)
│   ├── infrastructure.dart            # Barrel export
│   ├── adapters/                      # Hive 型別轉接器
│   ├── clients/                       # HTTP 客戶端
│   │   ├── gas_api_client.dart        # GAS REST 客戶端
│   │   └── network_aware_client.dart  # 離線攔截裝飾器
│   ├── interceptors/                  # Dio 攔截器
│   │   └── auth_interceptor.dart      # 認證攔截器
│   ├── services/                      # 服務實作
│   │   ├── gas_auth_service.dart      # 會員認證 (IAuthService)
│   │   ├── sync_service.dart          # 雙向同步 (ISyncService)
│   │   ├── google_sheets_service.dart # API Gateway (IDataService)
│   │   ├── gear_cloud_service.dart    # 雲端裝備 (IGearCloudService)
│   │   ├── poll_service.dart          # 投票 API (IPollService)
│   │   ├── weather_service.dart       # 氣象服務 (IWeatherService)
│   │   ├── connectivity_service.dart  # 網路狀態 (IConnectivityService)
│   │   ├── geolocator_service.dart    # 定位服務
│   │   ├── jwt_token_validator.dart   # JWT 驗證
│   │   └── ad_service.dart            # 廣告服務
│   ├── tools/                         # 工具服務
│   │   ├── log_service.dart           # 日誌與上傳
│   │   ├── toast_service.dart         # UI 通知
│   │   ├── tutorial_service.dart      # 教學導覽
│   │   ├── hive_service.dart          # Hive 初始化
│   │   └── usage_tracking_service.dart # Web 使用追蹤
│   ├── mock/                          # 測試用 Mock 實作
│   └── observers/                     # Bloc 觀察器
│
└── presentation/                      # 表現層
    ├── cubits/                        # 狀態管理 (Cubit) - 13 modules
    │   ├── auth/                      # 認證 (AuthCubit)
    │   ├── sync/                      # 同步 (SyncCubit)
    │   ├── trip/                      # 行程 (TripCubit)
    │   ├── itinerary/                 # 行程節點 (ItineraryCubit)
    │   ├── gear/                      # 個人裝備 (GearCubit)
    │   ├── gear_library/              # 裝備庫 (GearLibraryCubit)
    │   ├── message/                   # 留言板 (MessageCubit)
    │   ├── poll/                      # 投票 (PollCubit)
    │   ├── meal/                      # 餐點規劃 (MealCubit)
    │   ├── group_event/               # 揪團 (GroupEventCubit)
    │   ├── favorites/                 # 最愛 (FavoritesCubit)
    │   ├── settings/                  # 設定 (SettingsCubit)
    │   └── map/                       # 地圖 (MapCubit, OfflineMapCubit)
    ├── providers/                     # Provider (逐步遷移至 Cubit)
    ├── screens/                       # 畫面 (41+ 檔案)
    │   ├── main_navigation_screen.dart
    │   ├── trip_list_screen.dart
    │   ├── member_management_screen.dart
    │   ├── auth/                      # 認證相關
    │   └── ...
    ├── widgets/                       # 可重用元件
    │   ├── common/                    # 通用元件 (SummitAppBar, ModernSliverAppBar)
    │   ├── gear/                      # 裝備相關
    │   ├── info/                      # 資訊卡片
    │   ├── itinerary/                 # 行程節點
    │   ├── weather/                   # 天氣元件
    │   ├── group_event/               # 揪團元件
    │   ├── settings/                  # 設定元件
    │   ├── app_drawer.dart            # 側邊抽屜
    │   └── tutorial_overlay.dart      # 教學覆蓋層
    └── utils/                         # UI 工具
        └── tutorial_keys.dart         # 教學錨點 Key
```

---

## 分層架構

| Layer              | 職責                 | 位置                  |
| :----------------- | :------------------- | :-------------------- |
| **Presentation**   | UI, 狀態管理         | `lib/presentation/`   |
| **Domain**         | 業務邏輯介面         | `lib/domain/`         |
| **Infrastructure** | 外部服務實作         | `lib/infrastructure/` |
| **Data**           | 資料模型, Repository | `lib/data/`           |
| **Core**           | 共用工具, DI         | `lib/core/`           |
