# SummitMate 開發路線圖 (Development Roadmap)

## 開發原則

**TDD (Test-Driven Development)** 為核心開發策略：
1. **Red**: 先撰寫失敗的測試
2. **Green**: 撰寫最少量程式碼使測試通過
3. **Refactor**: 重構程式碼，保持測試通過

---

## Phase 0: 專案初始化 ✅

### 目標
建立專案基礎架構與開發環境。

### 任務
- [x] 規格文件審閱 (README, ARCHITECTURE, UI_UX_FLOW, UI_WIREFRAMES)
- [x] `.gitignore` 配置
- [x] 開發路線圖 (ROADMAP.md)
- [x] Flutter 專案初始化 (`flutter create`)
- [x] 依賴套件配置 (`pubspec.yaml`)
- [x] 專案目錄結構建立

---

## Phase 1: 資料層 ✅

### 目標
建立 Hive 資料庫 Schema 與 Repository Pattern。

### 任務
1. **Model 設計與測試**
   - [x] `Settings` Model
   - [x] `ItineraryItem` Model
   - [x] `Message` Model
   - [x] `GearItem` Model
   - [x] Model 單元測試 (序列化、驗證)

2. **Repository 實作**
   - [x] `SettingsRepository`
   - [x] `ItineraryRepository`
   - [x] `MessageRepository`
   - [x] `GearRepository`
   - [x] Repository 整合測試

---

## Phase 2: 服務層 ✅

### 目標
實作 Google Sheets API 與同步機制。

### 任務
1. **API 服務**
   - [x] `GoogleSheetsService` (HTTP 封裝)
   - [x] API 回應解析
   - [x] 錯誤處理

2. **同步服務**
   - [x] `SyncService` (雙向同步邏輯)
   - [x] 衝突解決策略 (Last-Write-Wins)

3. **本地服務**
   - [x] `HiveService` (資料庫操作封裝)
   - [x] `ToastService` (通知服務)
   - [x] `LogService` (日誌服務)

---

## Phase 3: 狀態管理 ✅

### 目標
使用 Provider 實作 MVVM 架構。

### 任務
- [x] `SettingsProvider`
- [x] `ItineraryProvider`
- [x] `MessageProvider`
- [x] `GearProvider`
- [x] 依賴注入 (GetIt)

---

## Phase 4: UI 實作 ✅

### 目標
實作所有畫面。

### 任務
1. **基礎架構**
   - [x] 主題配置 (大自然淺色主題)
   - [x] 導覽架構 (4 Tab Bottom Navigation)
   - [x] 頁面切換動畫 (AnimatedSwitcher)

2. **啟動流程**
   - [x] Onboarding Dialog (暱稱設定)

3. **Tab 1: 行程頁**
   - [x] 日期切換標籤 (D0/D1/D2)
   - [x] 時間軸列表 (累積距離顯示)
   - [x] 打卡功能 (ModalBottomSheet)
   - [x] 行程節點展開詳情

4. **Tab 2: 協作頁**
   - [x] 分類標籤 (裝備/行程/其他)
   - [x] 留言列表 (支援巢狀)
   - [x] 新增/刪除留言
   - [x] 同步按鈕

5. **Tab 3: 裝備頁** (獨立頁籤)
   - [x] 裝備清單 (分類展開)
   - [x] 新增裝備 (FAB)
   - [x] 總重量顯示

6. **Tab 4: 資訊頁**
   - [x] 外部天氣連結 (Windy, CWA)
   - [x] 電話訊號資訊
   - [x] 設定區域 (暱稱、查看日誌)

---

## Phase 5: 整合與驗證 ✅

### 目標
端對端測試與效能優化。

### 任務
- [x] 單元測試 (36 個通過)
- [x] 離線模式驗證
- [x] 環境配置分離 (.env.dev / .env.prod)

---

## Phase 6: 發布準備 (進行中)

### 目標
準備 App Store / Google Play 發布。

### 任務
- [x] App Icon 設計 (已更新)
- [ ] Splash Screen 品牌化
- [ ] 版本號管理
- [ ] 隱私權政策
- [ ] App Store 資料準備

---

## Phase 7: 未來功能 (規劃中)

### 可能的擴展
- [ ] 離線地圖整合
- [ ] GPS 軌跡記錄
- [ ] 照片上傳功能
- [ ] 多行程支援
- [ ] 天氣預報整合

---

## 技術架構

### 專案結構
```
lib/
├── core/           # 共用工具、常數、主題、DI、環境配置
├── data/           # 資料層 (Models, Repositories)
├── services/       # 服務層 (API, Sync, Log, Toast)
├── presentation/   # UI 層 (Providers)
└── main.dart
```

### 測試策略
- **Unit Tests (70%)**: Models, Services, Providers
- **Widget Tests (20%)**: 單一元件行為
- **Integration Tests (10%)**: 完整流程

### 依賴注入
使用 `get_it` 進行 DI，提升可測試性。

---

## 風險與緩解

| 風險 | 影響 | 緩解策略 |
|------|------|----------|
| ~~Isar 版本相容性~~ | ~~高~~ | 已遷移至 Hive |
| Google Sheets API 限流 | 中 | 實作錯誤處理 |
| 離線同步衝突 | 高 | 採用 Last-Write-Wins with UUID |
| Flutter 版本升級 | 低 | 使用穩定版本 |
