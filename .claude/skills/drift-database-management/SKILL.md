---
name: drift-database-management
description: Manages Drift database modifications, schema changes, and migration strategies. Restricts migrations in development and defines safe migration policies for production.
---

# Skill: Drift Database Management & Migration

## Overview
本技能旨在規範 SummitMate 專案中 Drift 資料庫的設計、修改與遷移 (Migration) 策略。
特別是在開發期與正式上線期，採取不同的資料庫變更應對模式，以保持程式碼乾淨並降低維護成本。

## Rules

### 1. 開發階段規則 (Development Phase - 預設行為)
* **首次版本修改模式**：目前專案仍在開發中，尚無真實使用者。在正式開放/上線以前，所有的資料結構變更均以「首次版本 (First Version)」進行修改。
* **禁止撰寫 Schema 升級遷移邏輯**：**不要**增加 `schemaVersion`（保持為 `1` 或目前基礎版本），**不要**在 `onUpgrade` 中撰寫增量遷移程式碼（如 `m.addColumn` 等）。
* **直接修改 Model 與重建**：直接修改 `app/lib/data/models/` 底下的 Table 類別，然後執行代碼生成工具。本地測試或開發時，若結構變更導致 SQLite 報錯，直接刪除本地資料庫檔案重新建立即可。
* **直到特別強調才處理**：除非使用者在 Prompt 中**特別強調**「這次需要處理正式遷移 (Migration)」，否則一律遵循上述開發階段規則。

### 2. 生產階段遷移策略 (Production Migration Strategy)
當專案正式上線後，若發生破壞性 Schema 變更且需要保留使用者手機上的本地資料時，採用以下策略：

* **破壞性升級與本地資料移轉 (Destructive Upgrade with Local Handover - 方案 B 延伸版)**：
  1. **資料庫備份**：在初始化資料庫時，若檢測到版本需要更新，先將舊資料庫檔案（如 `summitmate_db.sqlite`）備份/複製至一個暫存檔案（如 `summitmate_db_backup.sqlite`）。
  2. **乾淨重建**：刪除或重置主資料庫，並使用最新的 Schema 乾淨地重新建立所有資料表（維持程式碼結構乾淨，不留大量歷史 SQL 升級指令）。
  3. **資料映射與匯入**：啟動一個獨立的唯讀連接讀取備份資料庫，並在主資料庫中執行資料對應與寫入。將舊結構的資料對應為新結構的模型並寫入新庫。
  4. **清理備份**：完成資料移植後，刪除暫存的備份資料庫檔案。

### 3. 容錯與復原機制 (Fault Tolerance & Recovery)
為了避免移轉到一半 App 被使用者關閉或發生意外中斷導致資料損毀，資料移轉必須具備以下機制：
* **狀態標記 (Migration State)**：使用輕量級 Key-Value（如 `SharedPreferences`）紀錄遷移狀態：`migration_status`（可為 `idle`, `started`, `completed`）與 `backup_file_path`。
* **事務保護 (Transaction)**：整個資料映射與寫入流程必須在一個資料庫 Transaction 中執行。
* **中斷續傳與重試流程**：
  * 當 App 啟動時，優先檢查 `migration_status`。
  * 如果 `migration_status == started`，代表上一次遷移因意外中斷（如 Crash 或 App 被強退）。
  * **復原操作**：清空主資料庫中已寫入的半殘資料，從 `backup_file_path` 的備份庫中重新發起資料移轉，確保不會有重複或毀損的資料產生。
  * 遷移成功後，更新 `migration_status = completed` 並刪除備份檔案，恢復正常啟動流程。

## Trigger Conditions
當變更涉及以下檔案類型或目錄時，應觸發此 Skill：
* `app/lib/data/models/*_table.dart` (Drift Table 定義)
* `app/lib/infrastructure/database/app_database.dart` (資料庫配置與初始化)
* 執行 `flutter pub run build_runner build`
* 涉及本地資料庫結構變更或資料移轉邏輯。

## Workflow for Table Schema Modification
1. **修改 Table 模型**：在 `app/lib/data/models/` 修改對應的 Table 類別（例如新增欄位、修改型態）。
2. **執行代碼生成**：執行 `flutter pub run build_runner build --delete-conflicting-outputs` 重新生成 `app_database.g.dart`。
3. **本地開發重置**：若在模擬器中運行時因 Schema 不一致報錯，直接解除安裝 App 或在 App 中清除資料庫快取重建。
