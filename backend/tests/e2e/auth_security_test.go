//go:build integration

package e2e

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"strings"
	"time"

	"summitmate/api"
)

func (s *APITestSuite) TestLogin_UnverifiedEmailIsRejected() {
	s.Run("Given a registered but unverified user, When logging in, Then it returns 403 without tokens", func() {
		email := randomEmail()
		s.registerUser(email, "Password123!", "未驗證")

		status, authResp := s.login(email, "Password123!")

		s.Equal(http.StatusForbidden, status)
		s.Empty(authResp.Token)
	})
}

func (s *APITestSuite) TestLogin_DisabledAccountIsRejected() {
	s.Run("Given a disabled account, When logging in, Then it returns 403", func() {
		email := randomEmail()
		s.registerUser(email, "Password123!", "已停用")
		s.verifyUser(email)
		_, err := s.dbPool.Exec(context.Background(), "UPDATE users SET is_active = false WHERE email = $1", email)
		s.Require().NoError(err)

		status, _ := s.login(email, "Password123!")

		s.Equal(http.StatusForbidden, status)
	})
}

func (s *APITestSuite) TestLogin_EmailIsCaseInsensitive() {
	s.Run("Given a user registered in lower case, When logging in with another case, Then it succeeds", func() {
		email := randomEmail()
		s.registerVerifiedAndLogin(email, "Password123!", "大小寫")

		status, _ := s.login(strings.ToUpper(email), "Password123!")

		s.Equal(http.StatusOK, status)
	})

	s.Run("Given an existing email, When registering the same email in another case, Then it is a duplicate", func() {
		email := randomEmail()
		s.registerUser(email, "Password123!", "原始")

		payload, _ := json.Marshal(api.RegisterRequest{Email: toEmail(strings.ToUpper(email)), Password: "Password123!", DisplayName: "重複"})
		resp, err := http.Post(s.baseURL+"/auth/register", "application/json", bytes.NewReader(payload))
		s.Require().NoError(err)
		defer resp.Body.Close()

		s.Equal(http.StatusConflict, resp.StatusCode)
	})
}

func (s *APITestSuite) TestLogout_RevokesRefreshToken() {
	s.Run("Given a logout that includes the refresh token, When refreshing afterwards, Then it is rejected", func() {
		authResp := s.registerVerifiedAndLogin(randomEmail(), "Password123!", "登出測試")

		body, _ := json.Marshal(map[string]string{"refresh_token": authResp.RefreshToken})
		req, _ := http.NewRequest(http.MethodPost, s.baseURL+"/auth/logout", bytes.NewReader(body))
		req.Header.Set("Authorization", "Bearer "+authResp.Token)
		req.Header.Set("Content-Type", "application/json")
		resp, err := http.DefaultClient.Do(req)
		s.Require().NoError(err)
		resp.Body.Close()
		s.Require().Equal(http.StatusOK, resp.StatusCode)

		refreshBody, _ := json.Marshal(api.RefreshTokenRequest{RefreshToken: authResp.RefreshToken})
		refreshResp, err := http.Post(s.baseURL+"/auth/refresh", "application/json", bytes.NewReader(refreshBody))
		s.Require().NoError(err)
		defer refreshResp.Body.Close()
		s.Equal(http.StatusUnauthorized, refreshResp.StatusCode)

		meReq, _ := http.NewRequest(http.MethodGet, s.baseURL+"/auth/me", nil)
		meReq.Header.Set("Authorization", "Bearer "+authResp.Token)
		meResp, err := http.DefaultClient.Do(meReq)
		s.Require().NoError(err)
		defer meResp.Body.Close()
		s.Equal(http.StatusUnauthorized, meResp.StatusCode, "access token must be revoked too")
	})

	s.Run("Given a logout without a body, When it is called, Then it still succeeds", func() {
		authResp := s.registerVerifiedAndLogin(randomEmail(), "Password123!", "無 body 登出")

		req, _ := http.NewRequest(http.MethodPost, s.baseURL+"/auth/logout", nil)
		req.Header.Set("Authorization", "Bearer "+authResp.Token)
		resp, err := http.DefaultClient.Do(req)
		s.Require().NoError(err)
		defer resp.Body.Close()

		s.Equal(http.StatusOK, resp.StatusCode)
	})
}

func (s *APITestSuite) TestChangePassword_RevokesOldSessions() {
	s.Run("Given a password change, When using an old refresh token, Then it is rejected", func() {
		email := randomEmail()
		authResp := s.registerVerifiedAndLogin(email, "Password123!", "改密碼")
		time.Sleep(1100 * time.Millisecond) // JWT iat has one-second resolution

		body, _ := json.Marshal(api.ChangePasswordRequest{OldPassword: "Password123!", NewPassword: "NewPassword456!"})
		req, _ := http.NewRequest(http.MethodPost, s.baseURL+"/auth/change-password", bytes.NewReader(body))
		req.Header.Set("Authorization", "Bearer "+authResp.Token)
		req.Header.Set("Content-Type", "application/json")
		resp, err := http.DefaultClient.Do(req)
		s.Require().NoError(err)
		resp.Body.Close()
		s.Require().Equal(http.StatusOK, resp.StatusCode)

		refreshBody, _ := json.Marshal(api.RefreshTokenRequest{RefreshToken: authResp.RefreshToken})
		refreshResp, err := http.Post(s.baseURL+"/auth/refresh", "application/json", bytes.NewReader(refreshBody))
		s.Require().NoError(err)
		defer refreshResp.Body.Close()
		s.Equal(http.StatusUnauthorized, refreshResp.StatusCode)

		status, _ := s.login(email, "NewPassword456!")
		s.Equal(http.StatusOK, status, "the new password must work")
	})
}

func (s *APITestSuite) TestLogin_RateLimitOnlyCountsFailures() {
	s.Run("Given many successful logins, When logging in again, Then it is not rate limited", func() {
		email := randomEmail()
		s.registerVerifiedAndLogin(email, "Password123!", "頻繁登入")

		for i := 0; i < 12; i++ {
			status, _ := s.login(email, "Password123!")
			s.Require().Equal(http.StatusOK, status)
		}
	})
}

func (s *APITestSuite) TestSystemFlags_AdminOnly() {
	updateFlag := func(token, key string, value bool) int {
		body, _ := json.Marshal(map[string]any{"key": key, "value": value})
		req, _ := http.NewRequest(http.MethodPost, s.baseURL+"/system/flags", bytes.NewReader(body))
		if token != "" {
			req.Header.Set("Authorization", "Bearer "+token)
		}
		req.Header.Set("Content-Type", "application/json")
		resp, err := http.DefaultClient.Do(req)
		s.Require().NoError(err)
		defer resp.Body.Close()
		return resp.StatusCode
	}

	s.Run("Given no token, When updating a flag, Then it returns 401", func() {
		s.Equal(http.StatusUnauthorized, updateFlag("", "enable_email_sending", false))
	})

	s.Run("Given a regular user, When enabling skip_verification_code, Then it returns 403", func() {
		token, _ := s.registerAndLogin("一般使用者")
		s.Equal(http.StatusForbidden, updateFlag(token, "skip_verification_code", true))
	})

	s.Run("Given an admin, When updating a normal flag, Then it succeeds", func() {
		email := randomEmail()
		authResp := s.registerVerifiedAndLogin(email, "Password123!", "管理員")
		_, err := s.dbPool.Exec(context.Background(),
			"UPDATE users SET role_id = (SELECT id FROM roles WHERE code = 'ADMIN') WHERE email = $1", email)
		s.Require().NoError(err)

		s.Equal(http.StatusNoContent, updateFlag(authResp.Token, "enable_email_sending", true))
	})
}
