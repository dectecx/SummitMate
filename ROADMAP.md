# SummitMate 開發路線圖 (Development Roadmap)

## 開發原則

**TDD (Test-Driven Development)** 為核心開發策略：
1. **Red**: 先撰寫失敗的測試
2. **Green**: 撰寫最少量程式碼使測試通過
3. **Refactor**: 重構程式碼，保持測試通過

---

## Phase 0: 專案初始化 (Week 0)

### 目標
建立專案基礎架構與開發環境。

### 任務
- [x] 規格文件審閱 (README, ARCHITECTURE, UI_UX_FLOW, UI_WIREFRAMES)
- [x] `.gitignore` 配置
- [x] 開發路線圖 (ROADMAP.md)
- [ ] Flutter 專案初始化 (`flutter create`)
- [ ] 依賴套件配置 (`pubspec.yaml`)
- [ ] 專案目錄結構建立

### 交付物
```
summitmate/
├── lib/
│   ├── main.dart
│   ├── core/
│   ├── data/
│   ├── domain/
│   ├── presentation/
│   └── services/
├── test/
├── assets/
└── pubspec.yaml
```

---

## Phase 1: 資料層 - TDD (Week 1)

### 目標
建立 Isar 資料庫 Schema 與 Repository Pattern。

### 任務
1. **Model 設計與測試**
   - [ ] `Settings` Collection
   - [ ] `ItineraryItem` Collection
   - [ ] `Message` Collection
   - [ ] `GearItem` Collection
   - [ ] Model 單元測試 (序列化、驗證)

2. **Repository 實作**
   - [ ] `SettingsRepository`
   - [ ] `ItineraryRepository`
   - [ ] `MessageRepository`
   - [ ] `GearRepository`
   - [ ] Repository 整合測試

### 測試覆蓋
- Model 欄位驗證
- CRUD 操作
- 查詢功能

---

## Phase 2: 服務層 - TDD (Week 2)

### 目標
實作 Google Sheets API 與同步機制。

### 任務
1. **API 服務**
   - [ ] `GoogleSheetsApiService` (HTTP 封裝)
   - [ ] API 回應解析
   - [ ] 錯誤處理與重試機制

2. **同步服務**
   - [ ] `SyncService` (雙向同步邏輯)
   - [ ] 衝突解決策略
   - [ ] 離線佇列管理

3. **本地服務**
   - [ ] `IsarService` (資料庫操作封裝)
   - [ ] `SharedPreferencesService` (設定管理)

### 測試覆蓋
- Mock API 回應測試
- 同步邏輯單元測試
- 離線模式測試

---

## Phase 3: 狀態管理 (Week 2-3)

### 目標
使用 Provider 實作 MVVM 架構。

### 任務
- [ ] `SettingsProvider`
- [ ] `ItineraryProvider`
- [ ] `MessageProvider`
- [ ] `GearProvider`
- [ ] `SyncProvider`

### 測試覆蓋
- Provider 狀態變更測試
- 業務邏輯測試

---

## Phase 4: UI 實作 (Week 3-4)

### 目標
依據 UI_WIREFRAMES.md 實作所有畫面。

### 任務
1. **基礎架構**
   - [ ] 主題配置 (Dark Mode)
   - [ ] 導覽架構 (Bottom Navigation)
   - [ ] 共用元件 (按鈕、卡片、Dialog)

2. **啟動流程**
   - [ ] Splash Screen
   - [ ] Onboarding Dialog (暱稱設定)

3. **Tab 1: 行程頁**
   - [ ] 日期切換標籤 (D0/D1/D2)
   - [ ] 時間軸列表
   - [ ] 打卡功能 (ActionSheet)
   - [ ] 圖片檢視 (PhotoView)

4. **Tab 2: 協作頁**
   - [ ] 分類標籤 (裝備/行程/其他)
   - [ ] 留言列表 (支援巢狀)
   - [ ] 新增/刪除留言
   - [ ] 同步按鈕

5. **Tab 3: 工具頁**
   - [ ] 外部天氣連結
   - [ ] 個人裝備清單 (CRUD)
   - [ ] 設定區域

### 測試覆蓋
- Widget 測試
- Golden 測試 (可選)

---

## Phase 5: 整合與驗證 (Week 4-5)

### 目標
端對端測試與效能優化。

### 任務
- [ ] Integration 測試
- [ ] 離線模式驗證
- [ ] 效能優化 (懶加載、快取)
- [ ] 使用者測試回饋

---

## Phase 6: 發布準備 (Week 5+)

### 目標
準備 App Store / Google Play 發布。

### 任務
- [ ] App Icon 設計
- [ ] Splash Screen 品牌化
- [ ] 版本號管理
- [ ] 隱私權政策
- [ ] App Store 資料準備

---

## 技術建議

### 1. 專案結構
採用 **Feature-First** 目錄結構：
```
lib/
├── core/           # 共用工具、常數、主題
├── data/           # 資料層 (Models, Repositories)
├── domain/         # 業務邏輯 (Services)
├── presentation/   # UI 層 (Screens, Widgets, Providers)
└── main.dart
```

### 2. 測試策略
遵循 **Testing Pyramid**：
- **Unit Tests (70%)**: Models, Services, Providers
- **Widget Tests (20%)**: 單一元件行為
- **Integration Tests (10%)**: 完整流程

### 3. 依賴注入
建議使用 `get_it` 或 `riverpod` 進行 DI，提升可測試性。

### 4. 程式碼品質
- 使用 `flutter_lints` 強制程式碼規範
- 提交前執行 `flutter analyze`
- 使用 `lcov` 追蹤測試覆蓋率

---

## 風險與緩解

| 風險 | 影響 | 緩解策略 |
|------|------|----------|
| Isar 版本相容性 | 高 | 鎖定穩定版本 ^3.1.0 |
| Google Sheets API 限流 | 中 | 實作指數退避重試 |
| 離線同步衝突 | 高 | 採用 Last-Write-Wins with UUID |
| Flutter 版本升級 | 低 | 使用 FVM 管理版本 |
