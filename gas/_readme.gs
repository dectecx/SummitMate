/**
 * ============================================================
 * SummitMate - Google Apps Script API
 * 登山行程協作應用程式後端
 * ============================================================
 *
 * @fileoverview 專案說明文件 (README)
 * @version 3.0.0
 * @lastModified 2026-01
 *
 * ============================================================
 * 檔案結構
 * ============================================================
 *
 * _readme.gs          - 專案說明 (本檔案)
 * _config.gs          - 常數與設定
 * _core.gs            - Router (doGet/doPost) + 工具函式
 *
 * api_auth.gs         - 會員驗證 (註冊、登入、驗證碼)
 * api_itinerary.gs    - 行程節點 CRUD
 * api_messages.gs     - 留言板 CRUD
 * api_trips.gs        - 多行程管理 CRUD
 * api_gear.gs         - 雲端裝備組合 CRUD
 * api_gear_library.gs - 個人裝備庫 CRUD
 * api_logs.gs         - 日誌上傳
 * api_heartbeat.gs    - 使用狀態追蹤
 *
 * svc_weather.gs      - 氣象 ETL (中央氣象署)
 * svc_polls.gs        - 投票功能
 *
 * setup.gs            - 初始化工作表 (首次執行)
 *
 * ============================================================
 * 命名慣例
 * ============================================================
 *
 * 檔案命名:
 *   _*.gs           - 優先載入 (config, core)
 *   api_*.gs        - API 功能模組
 *   svc_*.gs        - 服務/工具模組
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
 *   testXxx         - 測試函式
 *
 * ============================================================
 * API 端點
 * ============================================================
 *
 * GET 請求:
 *   ?action=trip_list                - 取得所有行程
 *   ?action=trip_get_full[&trip_id]  - 取得行程+留言
 *   ?action=itinerary_list[&trip_id] - 僅取得行程節點
 *   ?action=message_list[&trip_id]   - 僅取得留言
 *   ?action=poll_list                - 取得投票列表
 *   ?action=weather_get              - 取得氣象資料
 *   ?action=system_health            - 健康檢查
 *
 * POST 請求:
 *   // 會員驗證 (Auth)
 *   { action: 'auth_register', email, password, displayName, avatar? }
 *   { action: 'auth_login', email, password }
 *   { action: 'auth_validate', accessToken }
 *   { action: 'auth_delete_user', accessToken }
 *   { action: 'auth_verify_email', email, code }
 *   { action: 'auth_resend_code', email }
 *
 *   // 行程 (Trips)
 *   { action: 'trip_create', ... }
 *   { action: 'trip_update', id: '...', ... }
 *   { action: 'trip_delete', id: '...' }
 *   { action: 'trip_set_active', id: '...' }
 *
 *   // 行程節點 (Itinerary)
 *   { action: 'itinerary_update', data: [...], trip_id: '...' }
 *
 *   // 留言 (Messages)
 *   { action: 'message_create', data: {...} }
 *   { action: 'message_create_batch', data: [...] }
 *   { action: 'message_delete', uuid: '...' }
 *
 *   // 裝備組合 (Gear Sets)
 *   { action: 'gear_set_list' }
 *   { action: 'gear_set_upload', ... }
 *   { action: 'gear_set_download', uuid: '...', key: '...' }
 *   { action: 'gear_set_delete', uuid: '...', key: '...' }
 *
 *   // 個人裝備庫 (Gear Library)
 *   { action: 'gear_library_upload', accessToken: '...', items: [...] }
 *   { action: 'gear_library_download', accessToken: '...' }
 *
 *   // 投票 (Polls)
 *   { action: 'poll_create', ... }
 *   { action: 'poll_vote', ... }
 *   { action: 'poll_close', ... }
 *
 *   // 監控
 *   { action: 'log_upload', logs: [...] }
 *   { action: 'system_heartbeat', ... }
 *
 * ============================================================
 * 工作表結構
 * ============================================================
 *
 * Users:
 *   uuid, email, password_hash, display_name, avatar, role,
 *   is_active, is_verified, verification_code, verification_expiry,
 *   created_at, updated_at, last_login_at
 *
 * Trips:
 *   id, name, start_date, end_date, description, cover_image, is_active, created_at
 *
 * Itinerary:
 *   uuid, trip_id, day, name, est_time, altitude, distance, note, image_asset,
 *   is_checked_in, checked_in_at
 *
 * Messages:
 *   uuid, trip_id, parent_id, user, category, content, timestamp, avatar
 *
 * GearSets:
 *   uuid, trip_id, title, author, visibility, key, total_weight, item_count,
 *   uploaded_at, items_json, meals_json
 *
 * TripGear (每筆裝備為一列):
 *   uuid, trip_id, name, weight, category, is_checked, quantity
 *
 * GearLibrary (每筆裝備為一列):
 *   uuid, user_id, name, weight, category, notes, created_at, updated_at
 *
 * Logs:
 *   upload_time, device_id, device_name, timestamp, level, source, message
 *
 * Heartbeat:
 *   user, avatar, last_seen, view, platform
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
