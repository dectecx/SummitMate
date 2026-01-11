# App 資料架構與同步策略設計指引

## 1. 系統架構背景 (Context)

* **後端 (Backend):** 採用關聯式資料庫 (RDBMS/SQL)，強調資料完整性與複雜關聯查詢。
* **前端 (Mobile App):** 使用 **Hive (NoSQL/Key-Value)** 作為本地存儲，主要目標是 **「快速響應」** 與 **「離線優先 (Offline-first)」**。
* **通訊媒介:** 透過 RESTful API 進行 JSON 資料交換。後端 API 負責處理大部分的 `JOIN` 運算，並回傳扁平化或適度嵌套的資料。

## 2. 資料建模原則 (Data Modeling)

在 NoSQL 環境下，AI 進行設計時應考慮以下權衡：

* **去正規化 (Denormalization):** 不同於 SQL 追求減少冗餘，App 端鼓勵為了讀取效能而適度重複資料。例如：在 `Order` 物件中直接嵌入 `UserName`，以避免跨 Box 查詢。
* **聚合根 (Aggregate Root) 設計:** 避免建立過於龐大的單一嵌套物件。Hive 的寫入是 **「整塊覆蓋 (Whole-object overwrite)」**。
* *建議:* 將頻繁更新的欄位（如同步狀態、計數器）與靜態資料分離，或將大型列表拆分為獨立的 Key-Value 對。

## 3. 離線同步機制 (Offline Sync Strategy)

為支持離線操作與地端新增，資料模型應包含以下核心欄位：

* **Local ID (UUID):** 由客戶端生成，作為地端唯一識別碼，避免回傳後端時 ID 衝突。
* **Sync Status:** 標記資料狀態（例如：`synced`, `pending_create`, `pending_update`）。
* **Timestamp:** 使用 `updated_at` 進行「最後寫入者勝 (Last Write Wins)」或衝突檢測。

## 4. 效能與資安考量 (Performance & Security)

* **讀寫特性:** Hive 適合讀多寫少的操作。對於高頻率、小範圍的局部更新，AI 應評估是否需將資料結構拆分得更細（Granularity）。
* **靜態加密 (Encryption at Rest):** 不論選擇 Hive 或 SQLite，必須實作 AES 加密。金鑰應配合 Android Keystore 系統管理。
* **替代方案評估:** 若業務邏輯出現極度複雜的「多對多關聯」或「地端大數據篩選」，AI 可評估導入合適的套件(但需要先進行討論及優缺點分析)。

## 5. 給 AI Agent 的分析建議方向

在處理具體功能模組時，請針對以下三點進行分析：

1. **資料顆粒度:** 該功能適合存在一個大 Box 的單一 Key 裡，還是拆分成多個 Key 以優化寫入效能？
2. **Mapping 成本:** 從 API JSON 到 Hive Object 再到 UI Model 的轉換邏輯是否過於複雜？
3. **離線可用性:** 使用者在無網路環境下，是否具備足夠的冗餘資料來維持完整 UI 體驗？
