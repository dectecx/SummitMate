# 介面流程與互動規範 (UI/UX Specification)

## 1. 啟動流程 (Onboarding)

1. **App 啟動**: 初始化 Hive 資料庫與依賴注入。
2. **Case A (無 Username)**: 
   * 顯示全螢幕 Dialog (不可關閉)。
   * 標題：「歡迎使用 SummitMate」。
   * 輸入框：「請輸入你的暱稱 (供隊友識別)」。
   * 按鈕：「開始使用」。
3. **Case B (有 Username)**: 直接進入主畫面。

## 2. 主導覽列 (Bottom Navigation - 4 Tabs)

### Tab 1: 行程 (Itinerary) - [預設首頁]

* **頂部 AppBar**: 
  * 標題：「SummitMate」
  * 右上角區塊：
    * **新增按鈕 (+)**: 開啟行程編輯頁面 (新增模式)
    * **雲端上傳 (☁️)**: 觸發與 Google Sheets 的同步與衝突檢測
    * **設定 (⚙️)**: 開啟設定對話框
* **日期切換**: D0 / D1 / D2 標籤按鈕
* **列表**: 垂直時間軸，顯示累積距離
* **Item 狀態**:
  * *未打卡*: 顯示 `預計: HH:mm`
  * *已打卡*: 顯示 `實際: HH:mm` (綠色高亮)
* **互動**:
  * **點擊 Item**: 展開 ModalBottomSheet
    * 顯示詳情 (海拔、距離、備註)
    * **Action Bar**:
      * `現在時間打卡`: 寫入 `DateTime.now()`
      * `指定時間`: 跳出 TimePicker
      * `清除`: 將 `actualTime` 設為 null
      * `編輯`: 進入行程編輯頁面
      * `刪除`: 移除此節點
  * **Toast 通知**: 打卡成功/失敗

### Tab 2: 協作 (Collaboration)

* **頂部**: 右上角「同步按鈕 (🔄)」
* **次級導覽**: 裝備 (Gear) / 行程 (Plan) / 其他 (Misc)
* **列表**:
  * 顯示留言卡片
  * 若有 `parentId`，則縮排顯示於父留言下方
  * 若 `message.user == me`，顯示「垃圾桶」圖示
* **新增**: 右下角 FAB (+) -> 彈窗輸入內容
* **同步狀態**: Toast 顯示同步成功/失敗

### Tab 3: 裝備 (Gear) - [獨立頁籤]

* **總重量卡片**: 顯示當前總重量 (kg)
* **分類列表**: 
  * 睡眠系統 / 炊具與飲食 / 穿著 / 其他
  * 使用 ExpansionTile 可展開收合
  * 每項顯示名稱、重量、打包狀態
* **新增**: 右下角 FAB (+)
  * 輸入名稱、重量、選擇分類
* **互動**:
  * 勾選/取消勾選打包狀態
  * 長按可刪除

### Tab 4: 資訊 (Info)

* **Section 1: 外部資訊** (可摺疊)
  * 按鈕：`Windy (嘉明湖)` -> `launchUrl(windy_url)`
  * 按鈕：`中央氣象署 (三叉山)` -> `launchUrl(cwa_url)`
* **Section 2: 電話訊號資訊** (可摺疊)
  * 顯示各路段通訊覆蓋情況
  * 建議使用電信商

## 3. 次級頁面 (Sub-Pages)

### 行程編輯頁面 (Itinerary Edit Screen)
* **進入點**: Tab 1 右上角 (+) 或 BottomSheet 編輯按鈕。
* **表單欄位**:
  * 天數 (D0, D1...)
  * 名稱 (必填)
  * 預計時間 (TimePicker)
  * 海拔 (選填)
  * 里程 (選填)
  * 備註 (多行輸入)
* **動作**:
  * 儲存: 驗證並寫入 Hive。
  * 取消: 返回上一頁。

## 4. 設定與工具

### 設定對話框 (Settings Dialog)
透過 AppBar 右上角齒輪圖示開啟：
* 修改暱稱
* 上次同步時間
* 查看日誌 (開啟 Log Viewer)

### 日誌查看器 (Log Viewer)
* **觸發**: 設定 -> 查看日誌
* **顯示**: ModalBottomSheet (可拖曳調整高度)
* **功能**:
  * 顯示最近 100 條日誌
  * 按等級區分圖示 (debug/info/warning/error)
  * 上傳到雲端按鈕 (Web 相容)
  * 清除所有日誌

## 5. Web 版適配 (Responsive Design)

### Desktop / Large Screen
當螢幕寬度 > 600px 時：
* **Layout Wrapper**: 整個 App 內容被限制在 `maxWidth: 600px` 的容器中。
* **置中顯示**: 容器水平置中。
* **背景**: 兩側顯示背景色，模擬手機長寬比體驗。
* **目的**: 避免列表在寬螢幕上過度拉伸，保持單手操作的 UI 邏輯。

## 6. UI 設計準則 (Design Guidelines)

* **Theme**: 大自然淺色主題
  * Primary: 森林綠 `#2E7D32`
  * Background: 米色 `#FAF8F5`
  * Text: 深灰 `#1B1B1B`
  * Accent: 山脈藍 `#1565C0`
* **Typography**:
  * 關鍵數值 (海拔、時間) 需大於 18sp
  * 使用無襯線字體
* **動畫**:
  * 頁面切換使用 AnimatedSwitcher (250ms 淡入)
* **通知**:
  * 使用 SnackBar (Toast) 顯示操作結果
  * 成功：綠色 / 失敗：紅色 / 警告：橙色 / 資訊：藍色
