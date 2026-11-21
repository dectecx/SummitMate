//go:build integration

package e2e

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"

	"summitmate/api"

	openapi_types "github.com/oapi-codegen/runtime/types"
)

func toEmail(s string) openapi_types.Email { return openapi_types.Email(s) }

func mustMarshal(v any) []byte {
	b, err := json.Marshal(v)
	if err != nil {
		panic(err)
	}
	return b
}

// verifyUser 直接在資料庫標記 Email 已驗證（測試環境不寄信、也不取驗證碼）。
func (s *APITestSuite) verifyUser(email string) {
	_, err := s.dbPool.Exec(context.Background(), "UPDATE users SET is_verified = true WHERE email = $1", email)
	s.Require().NoError(err, "標記使用者已驗證失敗")
}

// registerUser 註冊並回傳使用者資料（不含 Token）。
func (s *APITestSuite) registerUser(email, password, displayName string) api.User {
	payload, _ := json.Marshal(api.RegisterRequest{
		Email: openapi_types.Email(email), Password: password, DisplayName: displayName,
	})
	resp, err := http.Post(s.baseURL+"/auth/register", "application/json", bytes.NewReader(payload))
	s.Require().NoError(err)
	defer resp.Body.Close()
	s.Require().Equal(http.StatusCreated, resp.StatusCode, "註冊應回傳 201")

	var reg api.RegisterResponse
	s.Require().NoError(json.NewDecoder(resp.Body).Decode(&reg))
	return reg.User
}

// login 以帳密登入，回傳 HTTP 狀態碼與（成功時的）Token。
func (s *APITestSuite) login(email, password string) (int, api.AuthResponse) {
	payload, _ := json.Marshal(api.LoginRequest{Email: openapi_types.Email(email), Password: password})
	resp, err := http.Post(s.baseURL+"/auth/login", "application/json", bytes.NewReader(payload))
	s.Require().NoError(err)
	defer resp.Body.Close()

	var authResp api.AuthResponse
	if resp.StatusCode == http.StatusOK {
		s.Require().NoError(json.NewDecoder(resp.Body).Decode(&authResp))
	}
	return resp.StatusCode, authResp
}

// registerVerifiedAndLogin 註冊、標記已驗證並登入，回傳 Token。
func (s *APITestSuite) registerVerifiedAndLogin(email, password, displayName string) api.AuthResponse {
	s.registerUser(email, password, displayName)
	s.verifyUser(email)
	status, authResp := s.login(email, password)
	s.Require().Equal(http.StatusOK, status, "驗證後登入應回傳 200")
	return authResp
}
