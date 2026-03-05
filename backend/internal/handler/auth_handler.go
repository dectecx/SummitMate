package handler

import (
	"encoding/json"
	"errors"
	"net/http"

	"github.com/google/uuid"

	"github.com/oapi-codegen/runtime/types"

	"summitmate/api"
	mw "summitmate/internal/middleware"
	"summitmate/internal/model"
	"summitmate/internal/service"
)

type AuthHandler struct {
	authService *service.AuthService
}

func NewAuthHandler(authService *service.AuthService) *AuthHandler {
	return &AuthHandler{
		authService: authService,
	}
}

// RegisterUser handles POST /auth/register
func (h *AuthHandler) RegisterUser(w http.ResponseWriter, r *http.Request) {
	var req api.RegisterRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	// Basic Validation
	if len(req.Password) < 8 {
		writeError(w, http.StatusBadRequest, "Password must be at least 8 characters")
		return
	}

	user, token, err := h.authService.Register(r.Context(), string(req.Email), req.Password, req.DisplayName)
	if err != nil {
		if errors.Is(err, service.ErrEmailAlreadyExists) {
			writeError(w, http.StatusBadRequest, "此 Email 已經被註冊")
			return
		}
		writeError(w, http.StatusInternalServerError, "Registration failed")
		return
	}

	writeAuthResponse(w, http.StatusCreated, user, token)
}

// LoginUser handles POST /auth/login
func (h *AuthHandler) LoginUser(w http.ResponseWriter, r *http.Request) {
	var req api.LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	user, token, err := h.authService.Login(r.Context(), string(req.Email), req.Password)
	if err != nil {
		if errors.Is(err, service.ErrInvalidCredentials) {
			writeError(w, http.StatusUnauthorized, "帳號或密碼錯誤")
			return
		}
		writeError(w, http.StatusInternalServerError, "Login failed")
		return
	}

	writeAuthResponse(w, http.StatusOK, user, token)
}

// GetCurrentUser handles GET /auth/me
func (h *AuthHandler) GetCurrentUser(w http.ResponseWriter, r *http.Request) {
	userID, ok := r.Context().Value(mw.UserIDKey).(string)
	if !ok || userID == "" {
		writeError(w, http.StatusUnauthorized, "未授權")
		return
	}

	user, err := h.authService.GetUserByID(r.Context(), userID)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "使用者不存在")
		return
	}

	// Convert model.User to api.User
	apiUser := convertToAPIUser(user)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(apiUser)
}

// Helper: Response Formatter
func writeAuthResponse(w http.ResponseWriter, status int, user *model.User, token string) {
	resp := api.AuthResponse{
		Token: token,
		User:  convertToAPIUser(user),
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(resp)
}

func writeError(w http.ResponseWriter, status int, message string) {
	resp := api.ErrorResponse{Message: message}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(resp)
}

func convertToAPIUser(u *model.User) api.User {
	var uId, _ = uuid.Parse(u.ID)

	role := "MEMBER"
	// if u.RoleID != nil {
	// 	// typically we would resolve role ID to code via query or cache
	// }

	return api.User{
		Id:          uId,
		Email:       types.Email(u.Email),
		DisplayName: u.DisplayName,
		Avatar:      u.Avatar,
		IsActive:    u.IsActive,
		IsVerified:  u.IsVerified,
		Role:        role,
		CreatedAt:   u.CreatedAt,
	}
}
