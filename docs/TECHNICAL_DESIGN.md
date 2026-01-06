# 技術設計與架構文件 (Technical Design & Architecture)

本文件記錄 SummitMate 應用程式的關鍵技術決策、架構模式以及已知的技術限制。

## 1. 身份驗證系統 (Authentication System)

### 1.1 架構概覽
身份驗證系統的設計旨在解決循環依賴問題，並提供整潔、穩健的架構。
- **資料層 (Data Layer - `AuthSessionRepository`)**: 使用 `FlutterSecureStorage` 管理會話資料 (Token, 用戶個人資料) 的持久化。
- **網路層 (Network Layer - `GasApiClient`)**: 依賴 `IAuthTokenProvider` 介面 (由 Repository 實作) 來獲取 Token。
- **服務層 (Service Layer - `AuthService`)**: 協調高層級的驗證動作 (登入、註冊) 並更新 Repository。

### 1.2 限制：GAS CORS 與 Auth Token 位置
> [!IMPORTANT]
> **限制**：身份驗證 Token (Auth Token) 必須注入到 **請求主體 (Request Body)** 中，而不是請求標頭 (Request Header)。

**背景 (Context)**：
後端託管於 Google Apps Script (GAS)。當從網頁瀏覽器或某些行動網路堆疊存取時，GAS 對於跨來源資源共享 (CORS) 有特定的限制。

**問題 (Problem)**：
1.  **標頭過濾 (Header Stripping)**：GAS 經常在腳本執行開始前，剝離或忽略自定義的標頭 (例如 `Authorization: Bearer ...`)。
2.  **預檢請求失敗 (Preflight Failures)**：發送帶有自定義標頭的請求會觸發瀏覽器的 `OPTIONS` 預檢請求。GAS Web Apps 歷來難以正確或一致地處理這些請求，導致客戶端出現 CORS 錯誤。

**解決方案 (Solution)**：
我們使用 **`AuthInterceptor`** 將 `authToken` 注入到每一個 `POST` 請求的 Body 中。

```dart
// lib/services/interceptors/auth_interceptor.dart
if (options.method == 'POST' && options.data is Map<String, dynamic>) {
  // 注入到 Body
  (options.data as Map<String, dynamic>)['authToken'] = token;
}
```

**影響 (Implication)**：
- 所有需要驗證的 GAS 端點 (Endpoint) 都必須設計為從 JSON Payload (`doPost(e)` 的內容) 中接收 `authToken` 參數。
- **切勿**嘗試重構為使用 HTTP Header 傳遞 Token，除非已確認 Google 更新了 GAS 以支援 Web Apps 的標準 CORS 預檢請求。
