# 介面流程與互動規範 (UI/UX Specification)

## 1. 啟動流程 (Onboarding)

1. **Splash Screen**: 檢查 `SharedPreferences` 是否有 `username`。
2. **Case A (無 Username)**: 
   * 顯示全螢幕 Dialog (不可關閉)。
   * 標題：「歡迎使用 SummitMate」。
   * 輸入框：「請輸入你的暱稱 (供隊友識別)」。
   * 按鈕：「開始」。
3. **Case B (有 Username)**: 直接進入主畫面。

## 2. 主導覽列 (Bottom Navigation)

### Tab 1: 行程 (Itinerary) - [預設首頁]

* **頂部**: D0 / D1 / D2 切換標籤。
* **列表**: 垂直時間軸。
* **Item 狀態**:
  * *未打卡*: 顯示 `預計: HH:mm`。
  * *已打卡*: 顯示 `實際: HH:mm` (綠色高亮)。
* **互動**:
  * **點擊 Item**: 展開 ActionSheet。
    * `現在時間打卡`: 寫入 `DateTime.now()`。
    * `指定時間`: 跳出 TimePicker。
    * `清除`: 將 `actualTime` 設為 null。
  * **點擊縮圖**: 開啟 PhotoView (讀取 assets)。

### Tab 2: 協作 (Collaboration)

* **頂部**: 右上角「同步按鈕 (Sync)」。
* **次級導覽**: 裝備 (Gear) / 行程 (Plan) / 其他 (Misc)。
* **列表**:
  * 顯示留言卡片。
  * 若有 `parentId`，則縮排顯示於父留言下方。
  * 若 `message.user == me`，顯示「垃圾桶」圖示。
* **新增**: 右下角 FAB (+) -> 彈窗輸入內容。

### Tab 3: 工具 (Tools)

* **Section 1: 天氣**
  * 按鈕：`Windy (向陽)` -> `launchUrl(windy_url)`。
  * 按鈕：`CWA (海端鄉)` -> `launchUrl(cwa_url)`。
* **Section 2: 個人裝備 (Offline)**
  * 列表：顯示 `GearItem`。
  * 功能：新增/編輯/刪除。
  * **底部**: 固定顯示 `總重量: X.XX kg`。
* **Section 3: 設定**
  * 修改暱稱。
  * 完全重置資料庫 (Debug用)。

## 3. UI 設計準則 (Design Guidelines)

* **Theme**: 強制深色模式 (Dark Mode) 以適應夜間攀登。
  * Background: `#121212`
  * Text: `#E0E0E0`
  * Accent: `#FFC107` (Amber) for actions.
* **Typography**:
  * 關鍵數值 (海拔、時間) 需大於 18sp。
  * 避免細明體，使用無襯線黑體。
