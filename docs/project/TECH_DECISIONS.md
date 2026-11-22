# 重建技術決策（Tech Decisions）

> 2026-11-21 確認。與 `REBUILD_INVENTORY.md` 搭配閱讀。舊程式碼在 `legacy/`，僅作參考。

## 範圍
- 第一版：行程、節點、地圖、裝備、餐食、天氣、山岳資訊；保留訪客模式與廣告。
- 延後：揪團、投票、留言、收藏。
- 平台：iOS / Android（Web/PWA 移除）。
- 前後端同步開發：做一個前端功能，就寫（或自舊後端搬入）對應的後端功能。

## 前端（`app/`）
| 項目 | 決定 |
| :-- | :-- |
| 狀態管理與 DI | Riverpod（取代 Cubit、GetIt、Injectable） |
| 架構 | 按功能分資料夾，每個功能 `ui / data / domain`；共用放 `core/` |
| 本地資料庫 | Drift（僅行動端） |
| 同步 | Outbox 模式，本地資料庫為單一事實來源 |
| 網路 | Dio + 手寫 API 類別（不用 Retrofit） |
| 資料類別 | Dart 3 sealed class / record；序列化用 json_serializable（不用 Freezed） |
| 導覽 | go_router |
| 地圖 | flutter_map；瀏覽快取用 flutter_map_tile_caching，離線區域圖磚以檔案存放（`offline_tiles/<區域>/<z>/<x>/<y>.tile`），由 background_downloader 9.6.6 下載（系統背景傳輸，App 切到背景仍繼續） |
| 字型/圖示 | 字型打包進 App；圖示只用 Material Icons |
| 連線 | 不提供「離線模式」開關；以請求成敗與 connectivity_plus 作提示 |
| 廣告 | google_mobile_ads，包在 `AdService` 後；列表/資訊頁底部橫幅，地圖與編輯頁不放，不用插頁廣告 |
| 認證儲存 | flutter_secure_storage |

### 同步設計
- 使用者操作先寫本地，同時寫入 `outbox`（實體、操作、內容、重試次數）。
- 畫面的「N 筆未上傳」= outbox 筆數；不使用逐列 syncStatus 推導。
- 同步引擎：先送 outbox，再以游標拉取伺服器變更。
- 伺服器分配 `updated_at` / `version`，衝突以伺服器為準（last-write-wins）；刪除使用 tombstone；ID 由 client 產生 UUID；寫入必須冪等。
- 訪客模式 = 無登入的本地使用者；登入後「認領」本地資料並上傳（後端需對應流程）。
- 僅離線優先資料（行程、節點、裝備、餐食）走 outbox，其餘功能在線讀取。

## 後端（`backend/`）
| 項目 | 決定 |
| :-- | :-- |
| 技術棧 | Go + Chi + pgx + PostgreSQL，OpenAPI spec-first（oapi-codegen） |
| SQL | sqlc（型別安全查詢） |
| 分層 | Handler → Service → Repository，去除不必要抽象 |
| 權限 | `trip_members.role` + 程式內判斷，取代 roles/permissions/role_permissions 三表 |
| 裝備 | 裝備與餐食為個人資料（每筆有 `user_id`，僅本人可編輯）；可分享的「裝備組合」之後再做 |
| 同步 API | `GET /sync/changes`（時間游標 + tombstone）與 `POST /sync/push`（op_id 冪等、欄位層級 LWW） |
| 第一版不做 | feature flag、heartbeat、遠端 logs、揪團、投票、留言、收藏；天氣僅做快取代理 |
| 快取 / 限流 | 第一版不用 Redis；以介面抽象，預設記憶體實作，需要時再替換 |
| 遷移 | 開發期只修改 `000001_init_schema.up.sql` |

## 目錄
- `legacy/app_legacy/`、`legacy/backend_legacy/`：舊碼，唯讀參考。
- `app/`、`backend/`：新專案。
