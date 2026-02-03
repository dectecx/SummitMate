# 設計準則 (Design Guidelines)

## 色彩主題

SummitMate 支援多種主題切換：

| 主題          | 主色調 | 適用場景 |
| :------------ | :----- | :------- |
| Summit (預設) | 山岳綠 | 一般使用 |
| Ocean         | 海洋藍 | 海濱活動 |
| Forest        | 森林綠 | 林道健行 |
| Night         | 深色   | 夜間模式 |
| Minimalist    | 黑白   | 簡約風格 |

---

## 排版規範

### 間距

| 元素       | 間距 |
| :--------- | :--- |
| 頁面邊距   | 16px |
| 卡片間距   | 12px |
| 列表項目   | 8px  |
| 圖示與文字 | 8px  |

### 字型大小

| 用途        | 大小 |
| :---------- | :--- |
| 標題 (H1)   | 24sp |
| 副標題 (H2) | 20sp |
| 內文        | 16sp |
| 說明文字    | 14sp |
| 標籤        | 12sp |

---

## 元件規範

### AppBar

- 使用 `SummitAppBar` 或 `ModernSliverAppBar`
- 標題置中，字型粗體
- 右側放置動作按鈕 (最多 2 個)

### 卡片

- 圓角: 12px
- 陰影: elevation 2
- 內距: 16px

### 按鈕

| 類型                 | 用途      |
| :------------------- | :-------- |
| FilledButton         | 主要動作  |
| OutlinedButton       | 次要動作  |
| TextButton           | 取消/連結 |
| FloatingActionButton | 新增操作  |

### 表單

- Label 置於 TextField 上方
- 錯誤訊息顯示於下方 (紅色)
- 必填欄位標記 `*`

---

## 響應式設計

### 寬度斷點

| 裝置       | 寬度    | 處理                     |
| :--------- | :------ | :----------------------- |
| Mobile     | < 600px | 原生佈局                 |
| Tablet/Web | > 600px | 限制最大寬度 600px，置中 |

### Web 適配

```dart
Center(
  child: ConstrainedBox(
    constraints: BoxConstraints(maxWidth: 600),
    child: content,
  ),
)
```

---

## 動畫

| 場景     | 動畫             | 持續時間 |
| :------- | :--------------- | :------- |
| 頁面切換 | SlideTransition  | 300ms    |
| 列表載入 | FadeIn           | 200ms    |
| 按鈕點擊 | Scale            | 100ms    |
| 下拉刷新 | RefreshIndicator | 系統預設 |

---

## 無障礙

- 所有圖示需有 `semanticLabel`
- 可點擊區域最小 48x48
- 對比度符合 WCAG AA
- 支援螢幕閱讀器
