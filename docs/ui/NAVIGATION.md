# 導航流程

## 主要導航架構

```mermaid
flowchart TB
    subgraph Entry[入口]
        Splash[啟動畫面]
    end

    subgraph Auth[認證區]
        Login[登入]
        Register[註冊]
        Verify[Email 驗證]
    end

    subgraph Main[主畫面]
        Nav[BottomNav]
        Trip[行程 Tab]
        Collab[協作 Tab]
        Gear[裝備 Tab]
        Info[資訊 Tab]
    end

    subgraph Trip_Sub[行程子頁]
        TripList[行程列表]
        TripDetail[行程詳情]
        TripEdit[編輯行程]
        Members[成員管理]
    end

    subgraph Collab_Sub[協作子頁]
        Messages[留言板]
        Polls[投票]
        CreatePoll[建立投票]
        Meals[菜單]
    end

    subgraph Gear_Sub[裝備子頁]
        GearList[裝備清單]
        GearCloud[雲端裝備庫]
        GearPreview[預覽]
    end

    Splash --> |已登入| Main
    Splash --> |未登入| Login
    Login --> |註冊| Register
    Login --> |登入成功但未驗證| Verify
    Register --> Verify
    Verify --> Main

    Nav --> Trip & Collab & Gear & Info

    Trip --> TripList --> TripDetail
    TripDetail --> TripEdit & Members

    Collab --> Messages & Polls & Meals
    Polls --> CreatePoll

    Gear --> GearList --> GearCloud --> GearPreview
```

---

## Tab 導航結構

```mermaid
flowchart LR
    subgraph BottomNav
        T1[🗻 行程]
        T2[💬 協作]
        T3[🎒 裝備]
        T4[ℹ️ 資訊]
    end

    subgraph T2_Sub[協作子頁籤]
        留言板
        投票
        菜單
    end

    T2 --> T2_Sub
```

---

## Drawer 導航

| 項目       | 目的地             | 條件   |
| :--------- | :----------------- | :----- |
| 管理行程   | TripListScreen     | 已登入 |
| 揪團活動   | GroupEventScreen   | -      |
| 雲端裝備庫 | GearCloudScreen    | -      |
| 離線地圖   | MapViewerScreen    | -      |
| 設定       | SettingsScreen     | -      |
| 登入/登出  | LoginScreen / 登出 | 依狀態 |

---

## 畫面清單

| 畫面       | 檔案                            | 說明               |
| :--------- | :------------------------------ | :----------------- |
| 主導航     | `main_navigation_screen.dart`   | BottomNav + 4 Tabs |
| 行程列表   | `trip_list_screen.dart`         | 使用者的行程       |
| 行程詳情   | `trip_detail_screen.dart`       | 行程節點時間軸     |
| 成員管理   | `member_management_screen.dart` | 團長/嚮導/隊員     |
| 留言板     | `message_board_screen.dart`     | 巢狀留言           |
| 投票       | `poll_list_screen.dart`         | 投票列表           |
| 裝備       | `gear_tab.dart`                 | 個人裝備清單       |
| 雲端裝備庫 | `gear_cloud_screen.dart`        | 分享裝備組合       |
| 地圖       | `map_viewer_screen.dart`        | GPX + 離線         |
| 登入       | `auth/login_screen.dart`        | Email 登入         |
| 註冊       | `auth/register_screen.dart`     | 新用戶註冊         |
| 驗證       | `auth/verification_screen.dart` | 6 位數驗證碼       |
