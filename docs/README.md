# SummitMate 文件索引（重建版）

> 專案正在重建。舊版文件與 skill 保存在 `legacy/docs/`、`legacy/skills/`，僅作參考，內容可能與新設計不一致。

> 功能清單、進度與待辦屬於開發過程紀錄，只放在本機 `_local_docs/`（不進版控）：`_local_docs/project/FEATURE_STATUS.md`（功能與待辦總表）、`_local_docs/PROGRESS.md`（接續指引）。

## 目前有效的文件

| 文件 | 說明 |
| :-- | :-- |
| [技術決策](./project/TECH_DECISIONS.md) | 前後端技術選型 |
| [新手引導與導覽](./ui/ONBOARDING_NAVIGATION.md) | 導覽結構、歡迎頁、情境提示 |
| [裝備庫、範本與雲端分享](./architecture/GEAR_LIBRARY.md) | 個人裝備庫、範本、雲端分享（已完成） |
| [揪團活動](./architecture/GROUP_EVENTS.md) | 第二期：揪團的規則、資料表、API |
| [行程討論與收藏](./architecture/TRIP_COLLAB_FAVORITES.md) | 第二期：留言、投票、山岳收藏 |
| [資料庫、同步與 Auth](./architecture/DATA_SYNC_AUTH.md) | 資料表、Outbox 同步、認證與訪客模式 |
| [前端資料層](./architecture/FRONTEND_DATA.md) | Drift 資料表、outbox 規則、SyncEngine、帳號切換 |
| [隱私權政策](./security/PRIVACY_POLICY.md) | |

## 單一可信源（SSOT）

- 資料庫結構：`backend/migrations/000001_init_schema.up.sql`
- API 契約：`backend/api/openapi.yaml`
- 設計與決策：上表文件（程式碼完成後，會補上對應的結構說明）
