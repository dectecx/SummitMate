# SummitMate 文件索引（重建版）

> 專案正在重建。舊版文件與 skill 保存在 `legacy/docs/`、`legacy/skills/`，僅作參考，內容可能與新設計不一致。

## 目前有效的文件

| 文件 | 說明 |
| :-- | :-- |
| [功能清單與進度](./project/FEATURE_STATUS.md) | **要開發什麼、做到哪**：舊功能對照、延後項目、待決定、上線前待辦 |
| [重建盤點](./project/REBUILD_INVENTORY.md) | 舊系統功能盤點與取捨決策 |
| [技術決策](./project/TECH_DECISIONS.md) | 前後端技術選型 |
| [新手引導與導覽](./ui/ONBOARDING_NAVIGATION.md) | 導覽結構、歡迎頁、情境提示 |
| [資料庫、同步與 Auth](./architecture/DATA_SYNC_AUTH.md) | 資料表、Outbox 同步、認證與訪客模式 |
| [前端資料層](./architecture/FRONTEND_DATA.md) | Drift 資料表、outbox 規則、SyncEngine、帳號切換 |
| [隱私權政策](./security/PRIVACY_POLICY.md) | |

## 單一可信源（SSOT）

- 資料庫結構：`backend/migrations/000001_init_schema.up.sql`
- API 契約：`backend/api/openapi.yaml`
- 設計與決策：上表文件（程式碼完成後，會補上對應的結構說明）
