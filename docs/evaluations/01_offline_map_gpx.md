# 技術評估報告：離線地圖與 GPX 軌跡整合

**日期**: 2025-12-25
**作者**: Antigravity (AI Assistant)
**狀態**: 評估完成 (Completed)

## 1. 目標 (Objective)

在 SummitMate 中實作「離線地圖」與「GPX 軌跡顯示」功能，讓使用者能在無網路環境下查看地形圖並載入登山軌跡。

## 2. 技術選型 (Technology Selection)

針對 Flutter 生態系的評估結果如下：

### 2.1 地圖核心 (Map Engine)

- **選擇**: `flutter_map`
- **比較**:
  - **flutter_map**: 開源、高度客製化、**原生支援離線圖資** (Tile Caching/MBTiles)、支援多種圖源 (OpenStreetMap, OpenTopoMap)。對於戶外登山應用 (Outdoor App) 是業界標準首選。
  - **google_maps_flutter**: 雖然官方支援度高，但**缺乏程式化的離線地圖下載 API**，且客製化圖層 (如等高線圖) 較為困難，不適合登山情境。
- **結論**: 採用 `flutter_map`。

### 2.2 GPX 解析 (GPX Parsing)

- **選擇**: `gpx` 套件
- **理由**: Dart 官方與社群推薦的標準解析器，支援讀寫 GPX 1.0/1.1 格式，能輕鬆轉換為 `LatLng` 列表供地圖繪製。

### 2.3 離線地圖方案 (Offline Strategy)

我們評估了兩種主要方案，建議**以方案 A 為主，保留方案 B 為進階功能**。

#### 方案 A: 線上瀏覽並快取 (Recommended)

- **工具**: `flutter_map_tile_caching` (FMTC)
- **機制**:
  1. 使用者在有網路時瀏覽地圖，系統自動快取瀏覽過的區域。
  2. 提供「下載區域」功能，讓使用者框選特定區域 (如「玉山主峰周邊」) 進行批次下載。
- **優點**: 使用體驗直覺，無需使用者自行尋找地圖檔。
- **缺點**: 需注意圖資伺服器 (Tile Server) 的使用規範 (Bulk Download Policy)。

#### 方案 B: 匯入圖資檔 (MBTiles)

- **工具**: `flutter_map_mbtiles`
- **機制**: 使用者自行將 `.mbtiles` 檔案 (如魯地圖) 放入手機，App 直接讀取 SQLite 檔案顯示。
- **優點**: 完全離線，可使用社群製作的高品質台灣登山圖資 (如魯地圖)。
- **缺點**: 檔案管理對一般使用者門檻較高。

## 3. 實作計畫 (Implementation Plan)

### 第一階段：基礎整合 (POC)

1.  引入 `flutter_map` 與 `gpx` 套件。
2.  建立 `MapScreen`，串接 OpenStreetMap 顯示基礎地圖。
3.  實作「匯入 GPX」功能：
    - 使用 `file_picker` 選取手機內的 GPX 檔。
    - 使用 `gpx` 解析檔案。
    - 使用 `PolylineLayer` 將軌跡繪製於地圖上。

### 第二階段：離線能力 (Offline Capability)

1.  引入 `flutter_map_tile_caching`。
2.  設定 Store (儲顯空間) 與 Caching Strategy。
3.  實作「地圖下載管理頁面」，顯示已下載的區域與佔用空間。

### 第三階段：進階優化

1.  支援顯示 Waypoints (航點) 與圖示。
2.  加入「我的位置」定位與指南針方向 (使用 `geolocator` 與 `flutter_compass`)。
3.  (Optional) 支援 MBTiles 匯入功能 (針對進階山友)。

## 4. 風險與挑戰 (Risks & Challenges)

- **圖資版權與流量**: 批次下載地圖磚 (Raster Tiles) 會消耗大量伺服器頻寬。需確認所選圖源 (如 OSM, OpenTopoMap) 的使用條款，或考慮架設自己的 Tile Server / 使用 Mapbox (需付費)。
- **儲存空間**: 離線地圖檔案極大，需實作良好的快取清理機制。
- **效能**: 繪製過長軌跡 (數萬點) 可能導致地圖卡頓，需進行點位抽稀 (Douglas-Peucker algorithm) 優化。

## 5. 結論

技術可行性高，推薦立即啟動第一階段 (POC) 開發。
