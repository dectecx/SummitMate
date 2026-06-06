package auth_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"summitmate/api"
	"summitmate/internal/apperror"
	"summitmate/internal/auth"
	authmocks "summitmate/internal/auth/mocks"
	"summitmate/internal/common/apiutil"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

func TestAuthHandler_LoginUser(t *testing.T) {
	mockService := new(authmocks.MockAuthService)
	handler := auth.NewAuthHandler(mockService)

	t.Run("Given valid credentials, When logging in, Then it returns 200 OK and auth tokens", func(t *testing.T) {
		reqBody := api.LoginRequest{
			Email:    "test@example.com",
			Password: "password123",
		}
		jsonBody, _ := json.Marshal(reqBody)

		user := &auth.User{ID: "00000000-0000-0000-0000-000000000001", Email: "test@example.com", DisplayName: "Tester"}
		token := "jwt-token"

		mockService.On("Login", mock.Anything, "test@example.com", "password123").Return(user, token, "refresh-token", nil).Once()

		req := httptest.NewRequest("POST", "/auth/login", bytes.NewBuffer(jsonBody))
		w := httptest.NewRecorder()

		handler.LoginUser(w, req)

		assert.Equal(t, http.StatusOK, w.Code)

		var resp api.AuthResponse
		json.NewDecoder(w.Body).Decode(&resp)
		assert.Equal(t, user.ID, resp.User.Id.String())
		assert.Equal(t, token, resp.Token)
		mockService.AssertExpectations(t)
	})

	t.Run("Given invalid credentials, When logging in, Then it returns 401 Unauthorized", func(t *testing.T) {
		reqBody := api.LoginRequest{
			Email:    "test@example.com",
			Password: "wrong",
		}
		jsonBody, _ := json.Marshal(reqBody)

		mockService.On("Login", mock.Anything, "test@example.com", "wrong").Return((*auth.User)(nil), "", "", apperror.ErrInvalidCredentials).Once()

		req := httptest.NewRequest("POST", "/auth/login", bytes.NewBuffer(jsonBody))
		w := httptest.NewRecorder()

		handler.LoginUser(w, req)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
	})
}

func TestAuthHandler_RegisterUser(t *testing.T) {
	mockService := new(authmocks.MockAuthService)
	handler := auth.NewAuthHandler(mockService)

	t.Run("Given valid registration info, When registering, Then it returns 201 Created and auth tokens", func(t *testing.T) {
		reqBody := api.RegisterRequest{
			Email:       "new@example.com",
			Password:    "password123",
			DisplayName: "New User",
		}
		jsonBody, _ := json.Marshal(reqBody)

		user := &auth.User{ID: "00000000-0000-0000-0000-000000000002", Email: "new@example.com", DisplayName: "New User"}
		token := "jwt-token"

		mockService.On("Register", mock.Anything, "new@example.com", "password123", "New User", (*string)(nil)).Return(user, token, "refresh-token", nil).Once()

		req := httptest.NewRequest("POST", "/auth/register", bytes.NewBuffer(jsonBody))
		w := httptest.NewRecorder()

		handler.RegisterUser(w, req)

		assert.Equal(t, http.StatusCreated, w.Code)
		mockService.AssertExpectations(t)
	})

	t.Run("Given short password, When registering, Then it returns 400 Bad Request", func(t *testing.T) {
		reqBody := api.RegisterRequest{
			Email:    "new@example.com",
			Password: "short",
		}
		jsonBody, _ := json.Marshal(reqBody)

		mockService.On("Register", mock.Anything, "new@example.com", "short", "", (*string)(nil)).Return((*auth.User)(nil), "", "", apperror.ErrPasswordTooShort).Once()

		req := httptest.NewRequest("POST", "/auth/register", bytes.NewBuffer(jsonBody))
		w := httptest.NewRecorder()

		handler.RegisterUser(w, req)

		assert.Equal(t, http.StatusBadRequest, w.Code)
		// Error message check
		var errResp apiutil.ErrorEnvelope
		json.NewDecoder(w.Body).Decode(&errResp)
		assert.Equal(t, "password_too_short", errResp.Error.Code)
	})
}

func TestAuthHandler_RefreshToken(t *testing.T) {
	mockService := new(authmocks.MockAuthService)
	handler := auth.NewAuthHandler(mockService)

	t.Run("Given valid refresh token, When refreshing token, Then it returns 200 OK and new tokens", func(t *testing.T) {
		reqBody := api.RefreshTokenRequest{
			RefreshToken: "old-refresh-token",
		}
		jsonBody, _ := json.Marshal(reqBody)

		user := &auth.User{ID: "00000000-0000-0000-0000-000000000001", Email: "test@example.com"}
		newAccessToken := "new-access-token"
		newRefreshToken := "new-refresh-token"

		mockService.On("RefreshToken", mock.Anything, "old-refresh-token").Return(user, newAccessToken, newRefreshToken, nil).Once()

		req := httptest.NewRequest("POST", "/auth/refresh", bytes.NewBuffer(jsonBody))
		w := httptest.NewRecorder()

		handler.RefreshToken(w, req)

		assert.Equal(t, http.StatusOK, w.Code)

		var resp api.AuthResponse
		json.NewDecoder(w.Body).Decode(&resp)
		assert.Equal(t, newAccessToken, resp.Token)
		assert.Equal(t, newRefreshToken, resp.RefreshToken)
		mockService.AssertExpectations(t)
	})

	t.Run("Given invalid refresh token, When refreshing token, Then it returns 401 Unauthorized", func(t *testing.T) {
		reqBody := api.RefreshTokenRequest{
			RefreshToken: "invalid-token",
		}
		jsonBody, _ := json.Marshal(reqBody)

		mockService.On("RefreshToken", mock.Anything, "invalid-token").Return((*auth.User)(nil), "", "", apperror.ErrUnauthorized).Once()

		req := httptest.NewRequest("POST", "/auth/refresh", bytes.NewBuffer(jsonBody))
		w := httptest.NewRecorder()

		handler.RefreshToken(w, req)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
	})
}
