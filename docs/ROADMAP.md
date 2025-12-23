# SummitMate 開發路線圖 (Development Roadmap)

## 開發原則

**TDD (Test-Driven Development)** 為核心開發策略：
1. **Red**: 先撰寫失敗的測試
2. **Green**: 撰寫最少量程式碼使測試通過
3. **Refactor**: 重構程式碼，保持測試通過

---

## Phase 0-5: 核心功能與基礎建設 ✅ (已完成)

包含專案初始化、Hive 資料層、MVVM 架構、UI 實作、單元測試 (36 Tests)。

---

## Phase 6: 發布準備 ✅

### 目標
準備 App Store / Google Play 發布資源。

### 任務
- [x] App Icon 設計與生成
- [x] Splash Screen 品牌化 (Native Splash)
- [x] Web Favicon 與 Icons 生成

---

## Phase 8: 行程編輯功能 (Itinerary Editing) ✅

### 目標
讓使用者能在 App 內自由新增、修改、刪除行程節點。

### 任務
- [x] `ItineraryEditScreen` 實作
- [x] CRUD 邏輯 (Repository Layer)
- [x] 拖曳排序 (ReorderableListView)
- [x] 時間自動計算 (Estimated Time Logic)

---

## Phase 11: 行程雲端同步 (Cloud Sync) ✅

### 目標
將本地修改後的行程上傳至 Google Sheets，實現雙向資料流。

### 任務
- [x] 行程上傳 API (`updateItinerary`)
- [x] 衝突檢測機制 (本地 vs 雲端)
- [x] 上傳確認 UI (Alert Dialog)
- [x] 雲端備份覆寫邏輯

---

## Phase 12-13: 資料標準化與效能優化 ✅

### 目標
解決時區問題與提升同步速度。

### 任務
- [x] 時間格式統一 (String-First Strategy, UTC ISO8601)
- [x] 批次上傳 API (`batchAddMessages`) 解決 N+1 問題
- [x] `SyncService` 效能調優

---

## Phase 15: Web & PWA 支援 ✅

### 目標
啟用 Web 版輸出，支援 iOS PWA 安裝，將 App 延伸至電腦端。

### 任務
- [x] Web 相容性修正 (Hive, dart:io 替代方案)
- [x] API CORS 解決方案 (text/plain POST)
- [x] PWA Manifest 配置 (Standalone, Theme Color)
- [x] iOS Meta Tags 優化 (Add to Home Screen)
- [x] 響應式 UI Wrapper (Max-width 600px for Desktop)

---

## Phase 17: 雲端裝備庫 (Cloud Gear Library) ✅

### 目標
讓山友能分享裝備清單，並能下載他人的組合參考。

### 任務
- [x] GearSets Sheet Schema 設計
- [x] 三層可見性 (Public/Protected/Private)
- [x] 4 位數 Key 保護機制
- [x] 上傳裝備組合 API
- [x] 預覽對話框 (分類縮合顯示)
- [x] 本地 Key 儲存 (SharedPreferences)
- [x] 刪除組合功能
- [x] 防連點機制

---

## Phase 18: 投票功能 (Polls) ✅

### 目標
讓團隊能快速投票決定行程細節。

### 任務
- [x] Polls/PollOptions/PollVotes Sheet Schema
- [x] 建立投票 (標題、選項、截止時間)
- [x] 單選/多選支援
- [x] 允許/禁止新增選項
- [x] 即時/盲投顯示模式
- [x] 投票者列表顯示
- [x] 關閉/刪除投票

---

## Phase 19: 教學導覽 (Tutorial Overlay) ✅

### 目標
引導新用戶熟悉 App 各項功能。

### 任務
- [x] TutorialService 步驟定義
- [x] TutorialOverlay Widget (Spotlight 效果)
- [x] 9 步驟互動式引導
- [x] 首次使用自動觸發

---

## Phase 20: 進階功能 (Future Plans) 🚀

### 目標
增強戶外實用性與社群功能。

### 規劃任務
1. **離線地圖 (GPX)**
   - 需進行技術評估，確認實作方式、複雜度、困難度及可行性。
   - 目標：整合 GPX 軌跡顯示與 Leavelet/Mapbox。

2. **照片上傳**
   - 允許在留言或行程中附加照片 (上傳至 Imgur 或 Google Drive)。

3. **天氣預警**
   - 整合 CWA (氣象署) API 自動發送降雨警報推播。

4. **Web PWA 測試**
   - 確保 iOS Safari 的 Add to Home Screen 功能正常運作。

5. **多行程管理** (⭐ 重要 / 大工程)
   - 支援使用者建立與管理多個不同的登山計畫。
   - **核心原則**：保留架構彈性，避免未來難以擴充此功能。

---

## 技術架構概觀

### 專案結構
```
lib/
├── core/           # 共用工具、常數、主題、DI、環境配置
├── data/           # 資料層 (Models, Repositories)
├── services/       # 服務層 (API, Sync, Log, Toast, Weather, Poll, Gear)
├── presentation/   # UI 層 (Providers, Screens, Widgets)
└── main.dart
```

### 測試策略
- **Unit Tests**: 保持高覆蓋率 (Models, Services, Providers) - 76 Tests
- **Integration Tests**: 關鍵流程驗證
- **Manual QA**: 實地登山測試 (Field Test)

### 風險管理
| 風險 | 狀態 | 緩解策略 |
|------|------|----------|
| Isar 相容性 | 已解決 | 遷移至 Hive |
| Google Sheets 限流 | 監控中 | 實作批次上傳與錯誤重試 |
| Web CORS 問題 | 已解決 | 調整 Content-Type 為 text/plain |
| GAS 響應慢 | 已解決 | 防連點機制、Loading 狀態管理 |
