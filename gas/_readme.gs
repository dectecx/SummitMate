/**
 * ============================================================
 * SummitMate - Google Apps Script API
 * 登山行程協作應用程式後端
 * ============================================================
 *
 * @fileoverview 專案說明文件 (README)
 * @version 3.1.0
 * @lastModified 2026-01
 *
 * ============================================================
 * 檔案結構
 * ============================================================
 *
 * _readme.gs          - 專案說明 (本檔案)
 * _config.gs          - 常數與設定 (Sheet Names, Headers)
 * _codes.gs           - API 回應碼定義
 * _core.gs            - Router (doGet/doPost) + 工具函式
 * _mapper.gs          - 資料轉換層 (DTO ↔ Persistence)
 *
 * api_auth.gs         - 會員驗證 (註冊、登入、驗證碼)
 * api_roles.gs        - 角色與權限 (RBAC)
 * api_trips.gs        - 行程管理 CRUD
 * api_itinerary.gs    - 行程節點 CRUD
 * api_messages.gs     - 留言板 CRUD
 * api_gear.gs         - 雲端裝備組合 CRUD
 * api_gear_library.gs - 個人裝備庫 CRUD
 * api_polls.gs        - 投票功能 CRUD
 * api_logs.gs         - 日誌上傳
 * api_heartbeat.gs    - 使用狀態追蹤
 *
 * svc_weather.gs      - 氣象 ETL (中央氣象署)
 * jwt_utils.gs        - JWT Token 工具
 *
 * setup.gs            - 初始化工作表 (首次執行)
 *
 * ============================================================
 * 命名慣例
 * ============================================================
 *
 * 檔案命名:
 *   _*.gs           - 優先載入 (config, core, codes, mapper)
 *   api_*.gs        - API 功能模組
 *   svc_*.gs        - 服務/工具模組 (非 API)
 *   setup.gs        - 初始化腳本
 *
 * 函式命名:
 *   doGet/doPost    - HTTP 入口點
 *   get[Plural]     - 取得列表資料
 *   createXxx       - 新增資料
 *   updateXxx       - 更新資料
 *   deleteXxx       - 刪除資料
 *   [verb]Xxx       - 其他操作 (e.g. loginUser)
 *   _xxx            - 內部輔助函式 (不應手動執行)
 *   Mapper.Xxx      - 資料轉換器
 *
 * ============================================================
 * 資料轉換層 (Mapper)
 * ============================================================
 *
 * 所有 API 函式使用 Mapper 進行資料轉換:
 *   - Mapper.Xxx.toDTO(...)          - Sheet 資料 → API 回應
 *   - Mapper.Xxx.toPersistence(...)  - API 請求 → Sheet 資料
 *
 * 支援的 Mapper:
 *   Trip, Itinerary, Message, GearSet, GearLibrary,
 *   User, Poll, TripMember
 *
 * ============================================================
 * 工作表結構
 * ============================================================
 *
 * 所有表格標準稽核欄位: created_at, created_by, updated_at, updated_by
 * 欄位順序: PK → FK → Required → Optional → Audit
 *
 * 核心模組:
 *   - Trips, TripMembers, Itinerary, Messages
 *
 * 裝備模組:
 *   - GearSets, TripGear, GearLibrary
 *
 * 互動模組:
 *   - Polls, PollOptions, PollVotes
 *
 * 會員模組:
 *   - Users, Roles, Permissions, RolePermissions
 *
 * 系統監控:
 *   - Logs, Heartbeat, Weather_Hiking_App
 *
 * ============================================================
 * 部署步驟
 * ============================================================
 *
 * 1. 建立 Google Sheets 試算表
 * 2. 開啟「擴充功能」→「Apps Script」
 * 3. 將所有 .gs 檔案內容複製到專案
 * 4. 執行 setupSheets() 初始化工作表
 * 5. 部署為網頁應用程式:
 *    - 執行身分: 我 (Me)
 *    - 存取權限: 所有人 (Anyone)
 * 6. 將 API URL 更新至 Flutter App
 *
 * ============================================================
 */

// 此檔案僅供文件說明，不包含可執行程式碼
