package e2e

import (
	"bytes"
	"encoding/json"
	"fmt"
	"math/rand"
	"net/http"
	"time"

	"summitmate/api"

	openapi_types "github.com/oapi-codegen/runtime/types"
)

// randomEmail 產生不重複的測試用 Email。
func randomEmail() string {
	return fmt.Sprintf("test_%d_%d@example.com", time.Now().UnixNano(), rand.Intn(10000))
}

// ============================================================
// Health Check (健康檢查)
// ============================================================

func (s *APITestSuite) TestHealthCheck_Success() {
	resp, err := http.Get(s.baseURL + "/health")
	s.Require().NoError(err, "Health 請求不應有錯誤")
	defer resp.Body.Close()

	s.Equal(http.StatusOK, resp.StatusCode)

	var body map[string]string
	json.NewDecoder(resp.Body).Decode(&body)
	s.Equal("ok", body["status"])
	s.T().Logf("✅ Health: status=%s, version=%s", body["status"], body["version"])
}

// ============================================================
// Register (使用者註冊)
// ============================================================

func (s *APITestSuite) TestRegister_Success() {
	email := randomEmail()

	payload := api.RegisterRequest{
		Email:       openapi_types.Email(email),
		Password:    "Password123!",
		DisplayName: "測試使用者",
	}
	body, _ := json.Marshal(payload)

	resp, err := http.Post(s.baseURL+"/auth/register", "application/json", bytes.NewReader(body))
	s.Require().NoError(err, "註冊請求不應有錯誤")
	defer resp.Body.Close()

	s.Require().Equal(http.StatusCreated, resp.StatusCode, "應回傳 201 Created")

	var authResp api.AuthResponse
	json.NewDecoder(resp.Body).Decode(&authResp)

	s.NotEmpty(authResp.Token, "Token 不應為空")
	s.Equal(email, string(authResp.User.Email), "Email 應相符")
	s.Equal("測試使用者", authResp.User.DisplayName, "顯示名稱應相符")
	s.Equal("MEMBER", authResp.User.Role, "新註冊使用者角色應預設為 MEMBER")
	s.NotEmpty(authResp.User.Id.String(), "User ID 不應為空")

	s.T().Logf("✅ 註冊成功: id=%s, email=%s", authResp.User.Id.String(), authResp.User.Email)
}

func (s *APITestSuite) TestRegister_DuplicateEmail() {
	email := randomEmail()

	payload := api.RegisterRequest{
		Email:       openapi_types.Email(email),
		Password:    "Password123!",
		DisplayName: "使用者一",
	}
	body, _ := json.Marshal(payload)

	// 第一次註冊
	resp1, err := http.Post(s.baseURL+"/auth/register", "application/json", bytes.NewReader(body))
	s.Require().NoError(err)
	var firstResp api.AuthResponse
	json.NewDecoder(resp1.Body).Decode(&firstResp)
	resp1.Body.Close()

	// 第二次註冊相同 Email
	body, _ = json.Marshal(payload)
	resp2, err := http.Post(s.baseURL+"/auth/register", "application/json", bytes.NewReader(body))
	s.Require().NoError(err)
	defer resp2.Body.Close()

	s.Equal(http.StatusConflict, resp2.StatusCode, "重複 Email 應回傳 409")

	var errResp api.ErrorResponse
	json.NewDecoder(resp2.Body).Decode(&errResp)
	s.T().Logf("✅ 重複 Email 已被擋: %s", errResp.Error.Message)
}

func (s *APITestSuite) TestRegister_PasswordTooShort() {
	payload := api.RegisterRequest{
		Email:       openapi_types.Email(randomEmail()),
		Password:    "short",
		DisplayName: "密碼太短",
	}
	body, _ := json.Marshal(payload)

	resp, err := http.Post(s.baseURL+"/auth/register", "application/json", bytes.NewReader(body))
	s.Require().NoError(err)
	defer resp.Body.Close()

	s.Equal(http.StatusBadRequest, resp.StatusCode, "密碼太短應回傳 400")
	s.T().Log("✅ 密碼太短已被擋")
}

// ============================================================
// Login (使用者登入)
// ============================================================

func (s *APITestSuite) TestLogin_Success() {
	email := randomEmail()
	password := "MySecurePass99!"

	// 先註冊
	regPayload, _ := json.Marshal(api.RegisterRequest{
		Email: openapi_types.Email(email), Password: password, DisplayName: "登入測試者",
	})
	regResp, err := http.Post(s.baseURL+"/auth/register", "application/json", bytes.NewReader(regPayload))
	s.Require().NoError(err)
	regResp.Body.Close()

	// 登入
	loginPayload, _ := json.Marshal(api.LoginRequest{Email: openapi_types.Email(email), Password: password})
	resp, err := http.Post(s.baseURL+"/auth/login", "application/json", bytes.NewReader(loginPayload))
	s.Require().NoError(err)
	defer resp.Body.Close()

	s.Require().Equal(http.StatusOK, resp.StatusCode, "登入應回傳 200")

	var authResp api.AuthResponse
	json.NewDecoder(resp.Body).Decode(&authResp)

	s.NotEmpty(authResp.Token, "Token 不應為空")
	s.Equal(email, string(authResp.User.Email), "Email 應相符")
	s.T().Logf("✅ 登入成功: email=%s", authResp.User.Email)
}

func (s *APITestSuite) TestLogin_InvalidPassword() {
	email := randomEmail()

	// 先註冊
	regPayload, _ := json.Marshal(api.RegisterRequest{
		Email: openapi_types.Email(email), Password: "CorrectPassword1!", DisplayName: "密碼錯誤測試",
	})
	regResp, _ := http.Post(s.baseURL+"/auth/register", "application/json", bytes.NewReader(regPayload))
	regResp.Body.Close()

	// 用錯誤密碼登入
	loginPayload, _ := json.Marshal(api.LoginRequest{Email: openapi_types.Email(email), Password: "WrongPassword1!"})
	resp, err := http.Post(s.baseURL+"/auth/login", "application/json", bytes.NewReader(loginPayload))
	s.Require().NoError(err)
	defer resp.Body.Close()

	s.Equal(http.StatusUnauthorized, resp.StatusCode, "密碼錯誤應回傳 401")
	s.T().Log("✅ 密碼錯誤已被擋")
}

func (s *APITestSuite) TestLogin_AccountNotFound() {
	loginPayload, _ := json.Marshal(api.LoginRequest{
		Email: "nonexistent@example.com", Password: "SomePassword1!",
	})
	resp, err := http.Post(s.baseURL+"/auth/login", "application/json", bytes.NewReader(loginPayload))
	s.Require().NoError(err)
	defer resp.Body.Close()

	s.Equal(http.StatusUnauthorized, resp.StatusCode, "帳號不存在應回傳 401")
	s.T().Log("✅ 帳號不存在已被擋")
}

// ============================================================
// Get Current User (/auth/me)
// ============================================================

func (s *APITestSuite) TestGetMe_Success() {
	email := randomEmail()
	password := "TokenTestPass1!"

	// 先註冊取得 Token
	regPayload, _ := json.Marshal(api.RegisterRequest{
		Email: openapi_types.Email(email), Password: password, DisplayName: "Me 測試者",
	})
	regResp, err := http.Post(s.baseURL+"/auth/register", "application/json", bytes.NewReader(regPayload))
	s.Require().NoError(err)
	var authResp api.AuthResponse
	json.NewDecoder(regResp.Body).Decode(&authResp)
	regResp.Body.Close()

	// 帶 Token 呼叫 /auth/me
	req, _ := http.NewRequest("GET", s.baseURL+"/auth/me", nil)
	req.Header.Set("Authorization", "Bearer "+authResp.Token)

	resp, err := http.DefaultClient.Do(req)
	s.Require().NoError(err)
	defer resp.Body.Close()

	s.Require().Equal(http.StatusOK, resp.StatusCode, "/auth/me 應回傳 200")

	var user api.User
	json.NewDecoder(resp.Body).Decode(&user)

	s.Equal(email, string(user.Email), "Email 應相符")
	s.Equal("Me 測試者", user.DisplayName, "顯示名稱應相符")
	s.Equal("MEMBER", user.Role, "使用者角色應為 MEMBER")
	s.T().Logf("✅ GetMe 成功: id=%s, email=%s, name=%s", user.Id.String(), user.Email, user.DisplayName)
}

func (s *APITestSuite) TestGetMe_NoToken() {
	resp, err := http.Get(s.baseURL + "/auth/me")
	s.Require().NoError(err)
	defer resp.Body.Close()

	s.Equal(http.StatusUnauthorized, resp.StatusCode, "無 Token 應回傳 401")
	s.T().Log("✅ 無 Token 呼叫 /auth/me 已被擋")
}

// ============================================================
// Refresh Token (/auth/refresh)
// ============================================================

func (s *APITestSuite) TestRefreshToken_Success() {
	email := randomEmail()
	password := "RefreshTest123!"

	// 1. 註冊取得初始 Tokens
	regPayload, _ := json.Marshal(api.RegisterRequest{
		Email: openapi_types.Email(email), Password: password, DisplayName: "Refresh 測試者",
	})
	regResp, err := http.Post(s.baseURL+"/auth/register", "application/json", bytes.NewReader(regPayload))
	s.Require().NoError(err)
	var authResp api.AuthResponse
	json.NewDecoder(regResp.Body).Decode(&authResp)
	regResp.Body.Close()

	s.NotEmpty(authResp.RefreshToken, "註冊後應取得 Refresh Token")
	oldToken := authResp.Token

	// 稍等一下確保時間戳不同 (如果 Token 有包含過期時間)
	time.Sleep(1 * time.Second)

	// 2. 使用 Refresh Token 換發新 Token
	refreshPayload, _ := json.Marshal(api.RefreshTokenRequest{
		RefreshToken: authResp.RefreshToken,
	})
	refreshResp, err := http.Post(s.baseURL+"/auth/refresh", "application/json", bytes.NewReader(refreshPayload))
	s.Require().NoError(err)
	defer refreshResp.Body.Close()

	s.Require().Equal(http.StatusOK, refreshResp.StatusCode, "Refresh 應回傳 200")

	var newAuthResp api.AuthResponse
	json.NewDecoder(refreshResp.Body).Decode(&newAuthResp)

	s.NotEmpty(newAuthResp.Token, "應取得新的 Access Token")
	s.NotEmpty(newAuthResp.RefreshToken, "應取得新的 Refresh Token")
	s.NotEqual(oldToken, newAuthResp.Token, "新舊 Access Token 應不同")

	// 3. 驗證新 Token 可用性
	req, _ := http.NewRequest("GET", s.baseURL+"/auth/me", nil)
	req.Header.Set("Authorization", "Bearer "+newAuthResp.Token)
	resp, err := http.DefaultClient.Do(req)
	s.Require().NoError(err)
	defer resp.Body.Close()

	s.Equal(http.StatusOK, resp.StatusCode, "新 Token 呼叫 /auth/me 應成功")
	s.T().Log("✅ Refresh Token 流程驗證成功")
}
