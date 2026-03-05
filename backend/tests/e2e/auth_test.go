// Package e2e 包含端對端測試，測試 API Server 的完整請求/回應流程。
//
// 前置條件：
//   - PostgreSQL 已啟動 (docker compose up -d db)
//   - Migration 已執行 (go run ./cmd/migrate up)
//   - API Server 已啟動 (go run ./cmd/api)
//
// 執行：
//
//	go test ./tests/e2e/... -v
//
// 環境變數：
//   - E2E_BASE_URL: API Server 的 Base URL (預設 http://localhost:8080/api/v1)
package e2e

import (
	"bytes"
	"encoding/json"
	"fmt"
	"math/rand"
	"net/http"
	"os"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// getBaseURL 從環境變數取得 API Base URL，若未設定則使用預設值。
func getBaseURL() string {
	if url := os.Getenv("E2E_BASE_URL"); url != "" {
		return url
	}
	return "http://localhost:8080/api/v1"
}

// --- 請求/回應結構 ---

type registerRequest struct {
	Email       string `json:"email"`
	Password    string `json:"password"`
	DisplayName string `json:"display_name"`
}

type loginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type authResponse struct {
	Token string `json:"token"`
	User  struct {
		ID          string `json:"id"`
		Email       string `json:"email"`
		DisplayName string `json:"display_name"`
		Avatar      string `json:"avatar"`
		IsActive    bool   `json:"is_active"`
		IsVerified  bool   `json:"is_verified"`
		Role        string `json:"role"`
	} `json:"user"`
}

type errorResponse struct {
	Message string `json:"message"`
}

// randomEmail 產生不重複的測試用 Email。
func randomEmail() string {
	return fmt.Sprintf("test_%d_%d@example.com", time.Now().UnixNano(), rand.Intn(10000))
}

// deleteTestUser 透過直接呼叫 DB 刪除測試使用者，清理測試資料。
// 這裡使用 API 的方式：依據 token 取得 user id 後刪除。
// 未來可改為直接連 DB 清理。
func deleteTestUser(t *testing.T, userID string) {
	t.Helper()

	baseURL := getBaseURL()
	// 目前以 SQL 直接清理的方式較複雜，先記錄 user ID 供日後批次清理
	// 也可在 TestMain 中加入清理邏輯
	t.Logf("🗑️ 應清理測試使用者: %s (URL: %s)", userID, baseURL)
}

// ============================================================
// Health Check (健康檢查)
// ============================================================

func TestHealthCheck_Success(t *testing.T) {
	baseURL := getBaseURL()

	resp, err := http.Get(baseURL + "/health")
	require.NoError(t, err, "Health 請求不應有錯誤")
	defer resp.Body.Close()

	assert.Equal(t, http.StatusOK, resp.StatusCode)

	var body map[string]string
	json.NewDecoder(resp.Body).Decode(&body)
	assert.Equal(t, "ok", body["status"])
	t.Logf("✅ Health: status=%s, version=%s", body["status"], body["version"])
}

// ============================================================
// Register (使用者註冊)
// ============================================================

func TestRegister_Success(t *testing.T) {
	baseURL := getBaseURL()
	email := randomEmail()

	payload := registerRequest{
		Email:       email,
		Password:    "Password123!",
		DisplayName: "測試使用者",
	}
	body, _ := json.Marshal(payload)

	resp, err := http.Post(baseURL+"/auth/register", "application/json", bytes.NewReader(body))
	require.NoError(t, err, "註冊請求不應有錯誤")
	defer resp.Body.Close()

	require.Equal(t, http.StatusCreated, resp.StatusCode, "應回傳 201 Created")

	var authResp authResponse
	json.NewDecoder(resp.Body).Decode(&authResp)

	assert.NotEmpty(t, authResp.Token, "Token 不應為空")
	assert.Equal(t, email, authResp.User.Email, "Email 應相符")
	assert.Equal(t, "測試使用者", authResp.User.DisplayName, "顯示名稱應相符")
	assert.NotEmpty(t, authResp.User.ID, "User ID 不應為空")

	// 記錄待清理的測試使用者
	t.Cleanup(func() { deleteTestUser(t, authResp.User.ID) })

	t.Logf("✅ 註冊成功: id=%s, email=%s", authResp.User.ID, authResp.User.Email)
}

func TestRegister_DuplicateEmail(t *testing.T) {
	baseURL := getBaseURL()
	email := randomEmail()

	payload := registerRequest{
		Email:       email,
		Password:    "Password123!",
		DisplayName: "使用者一",
	}
	body, _ := json.Marshal(payload)

	// 第一次註冊
	resp1, err := http.Post(baseURL+"/auth/register", "application/json", bytes.NewReader(body))
	require.NoError(t, err)
	var firstResp authResponse
	json.NewDecoder(resp1.Body).Decode(&firstResp)
	resp1.Body.Close()
	t.Cleanup(func() { deleteTestUser(t, firstResp.User.ID) })

	// 第二次註冊相同 Email
	body, _ = json.Marshal(payload)
	resp2, err := http.Post(baseURL+"/auth/register", "application/json", bytes.NewReader(body))
	require.NoError(t, err)
	defer resp2.Body.Close()

	assert.Equal(t, http.StatusBadRequest, resp2.StatusCode, "重複 Email 應回傳 400")

	var errResp errorResponse
	json.NewDecoder(resp2.Body).Decode(&errResp)
	t.Logf("✅ 重複 Email 已被擋: %s", errResp.Message)
}

func TestRegister_PasswordTooShort(t *testing.T) {
	baseURL := getBaseURL()

	payload := registerRequest{
		Email:       randomEmail(),
		Password:    "short",
		DisplayName: "密碼太短",
	}
	body, _ := json.Marshal(payload)

	resp, err := http.Post(baseURL+"/auth/register", "application/json", bytes.NewReader(body))
	require.NoError(t, err)
	defer resp.Body.Close()

	assert.Equal(t, http.StatusBadRequest, resp.StatusCode, "密碼太短應回傳 400")
	t.Log("✅ 密碼太短已被擋")
}

// ============================================================
// Login (使用者登入)
// ============================================================

func TestLogin_Success(t *testing.T) {
	baseURL := getBaseURL()
	email := randomEmail()
	password := "MySecurePass99!"

	// 先註冊
	regPayload, _ := json.Marshal(registerRequest{
		Email: email, Password: password, DisplayName: "登入測試者",
	})
	regResp, err := http.Post(baseURL+"/auth/register", "application/json", bytes.NewReader(regPayload))
	require.NoError(t, err)
	var regAuth authResponse
	json.NewDecoder(regResp.Body).Decode(&regAuth)
	regResp.Body.Close()
	t.Cleanup(func() { deleteTestUser(t, regAuth.User.ID) })

	// 登入
	loginPayload, _ := json.Marshal(loginRequest{Email: email, Password: password})
	resp, err := http.Post(baseURL+"/auth/login", "application/json", bytes.NewReader(loginPayload))
	require.NoError(t, err)
	defer resp.Body.Close()

	require.Equal(t, http.StatusOK, resp.StatusCode, "登入應回傳 200")

	var authResp authResponse
	json.NewDecoder(resp.Body).Decode(&authResp)

	assert.NotEmpty(t, authResp.Token, "Token 不應為空")
	assert.Equal(t, email, authResp.User.Email, "Email 應相符")
	t.Logf("✅ 登入成功: email=%s", authResp.User.Email)
}

func TestLogin_InvalidPassword(t *testing.T) {
	baseURL := getBaseURL()
	email := randomEmail()

	// 先註冊
	regPayload, _ := json.Marshal(registerRequest{
		Email: email, Password: "CorrectPassword1!", DisplayName: "密碼錯誤測試",
	})
	regResp, _ := http.Post(baseURL+"/auth/register", "application/json", bytes.NewReader(regPayload))
	var regAuth authResponse
	json.NewDecoder(regResp.Body).Decode(&regAuth)
	regResp.Body.Close()
	t.Cleanup(func() { deleteTestUser(t, regAuth.User.ID) })

	// 用錯誤密碼登入
	loginPayload, _ := json.Marshal(loginRequest{Email: email, Password: "WrongPassword1!"})
	resp, err := http.Post(baseURL+"/auth/login", "application/json", bytes.NewReader(loginPayload))
	require.NoError(t, err)
	defer resp.Body.Close()

	assert.Equal(t, http.StatusUnauthorized, resp.StatusCode, "密碼錯誤應回傳 401")
	t.Log("✅ 密碼錯誤已被擋")
}

func TestLogin_AccountNotFound(t *testing.T) {
	baseURL := getBaseURL()

	loginPayload, _ := json.Marshal(loginRequest{
		Email: "nonexistent@example.com", Password: "SomePassword1!",
	})
	resp, err := http.Post(baseURL+"/auth/login", "application/json", bytes.NewReader(loginPayload))
	require.NoError(t, err)
	defer resp.Body.Close()

	assert.Equal(t, http.StatusUnauthorized, resp.StatusCode, "帳號不存在應回傳 401")
	t.Log("✅ 帳號不存在已被擋")
}

// ============================================================
// Get Current User (/auth/me)
// ============================================================

func TestGetMe_Success(t *testing.T) {
	baseURL := getBaseURL()
	email := randomEmail()
	password := "TokenTestPass1!"

	// 先註冊取得 Token
	regPayload, _ := json.Marshal(registerRequest{
		Email: email, Password: password, DisplayName: "Me 測試者",
	})
	regResp, err := http.Post(baseURL+"/auth/register", "application/json", bytes.NewReader(regPayload))
	require.NoError(t, err)
	var authResp authResponse
	json.NewDecoder(regResp.Body).Decode(&authResp)
	regResp.Body.Close()
	t.Cleanup(func() { deleteTestUser(t, authResp.User.ID) })

	// 帶 Token 呼叫 /auth/me
	req, _ := http.NewRequest("GET", baseURL+"/auth/me", nil)
	req.Header.Set("Authorization", "Bearer "+authResp.Token)

	resp, err := http.DefaultClient.Do(req)
	require.NoError(t, err)
	defer resp.Body.Close()

	require.Equal(t, http.StatusOK, resp.StatusCode, "/auth/me 應回傳 200")

	var user struct {
		ID          string `json:"id"`
		Email       string `json:"email"`
		DisplayName string `json:"display_name"`
	}
	json.NewDecoder(resp.Body).Decode(&user)

	assert.Equal(t, email, user.Email, "Email 應相符")
	assert.Equal(t, "Me 測試者", user.DisplayName, "顯示名稱應相符")
	t.Logf("✅ GetMe 成功: id=%s, email=%s, name=%s", user.ID, user.Email, user.DisplayName)
}

func TestGetMe_NoToken(t *testing.T) {
	baseURL := getBaseURL()

	resp, err := http.Get(baseURL + "/auth/me")
	require.NoError(t, err)
	defer resp.Body.Close()

	assert.Equal(t, http.StatusUnauthorized, resp.StatusCode, "無 Token 應回傳 401")
	t.Log("✅ 無 Token 呼叫 /auth/me 已被擋")
}
