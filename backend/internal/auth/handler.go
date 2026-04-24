package auth

import (
	"encoding/json"
	"net/http"

	"summitmate/api"
	"summitmate/internal/apperror"
	"summitmate/internal/common/apiutil"
	"summitmate/internal/middleware"
)

// AuthHandler 處理認證相關的 HTTP 請求。
type AuthHandler struct {
	authService AuthService
}

// NewAuthHandler 建立 AuthHandler 實例。
func NewAuthHandler(authService AuthService) *AuthHandler {
	return &AuthHandler{authService: authService}
}

// RegisterUser 處理 POST /auth/register 請求。
func (h *AuthHandler) RegisterUser(w http.ResponseWriter, r *http.Request) {
	var req api.RegisterRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apiutil.SendError(w, r, apperror.ErrBadRequest.WithMessage("無效的請求內容"))
		return
	}

	if len(req.Password) < 8 {
		apiutil.SendError(w, r, apperror.ErrPasswordTooShort)
		return
	}

	user, token, err := h.authService.Register(r.Context(), string(req.Email), req.Password, req.DisplayName, req.Avatar)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	h.writeAuthResponse(w, http.StatusCreated, user, token)
}

// LoginUser 處理 POST /auth/login 請求。
func (h *AuthHandler) LoginUser(w http.ResponseWriter, r *http.Request) {
	var req api.LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apiutil.SendError(w, r, apperror.ErrBadRequest.WithMessage("無效的請求內容"))
		return
	}

	user, token, err := h.authService.Login(r.Context(), string(req.Email), req.Password)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	h.writeAuthResponse(w, http.StatusOK, user, token)
}

// GetCurrentUser 處理 GET /auth/me 請求。
func (h *AuthHandler) GetCurrentUser(w http.ResponseWriter, r *http.Request) {
	userID, ok := r.Context().Value(middleware.UserIDKey).(string)
	if !ok || userID == "" {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	user, err := h.authService.GetUserByID(r.Context(), userID)
	if err != nil {
		apiutil.SendError(w, r, apperror.ErrUnauthorized.WithMessage("使用者不存在"))
		return
	}

	apiutil.SendJSON(w, http.StatusOK, ToUserResponse(user))
}

// UpdateCurrentUser 處理 PUT /auth/me 請求。
func (h *AuthHandler) UpdateCurrentUser(w http.ResponseWriter, r *http.Request) {
	userID, ok := r.Context().Value(middleware.UserIDKey).(string)
	if !ok || userID == "" {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var req api.UpdateProfileRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apiutil.SendError(w, r, apperror.ErrBadRequest.WithMessage("無效的請求內容"))
		return
	}

	user, err := h.authService.UpdateProfile(r.Context(), userID, req.DisplayName, req.Avatar)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	apiutil.SendJSON(w, http.StatusOK, ToUserResponse(user))
}

// DeleteCurrentUser 處理 DELETE /auth/me 請求。
func (h *AuthHandler) DeleteCurrentUser(w http.ResponseWriter, r *http.Request) {
	userID, ok := r.Context().Value(middleware.UserIDKey).(string)
	if !ok || userID == "" {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	if err := h.authService.DeleteAccount(r.Context(), userID); err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// RefreshToken 處理 POST /auth/refresh 請求。
func (h *AuthHandler) RefreshToken(w http.ResponseWriter, r *http.Request) {
	var req api.RefreshTokenRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apiutil.SendError(w, r, apperror.ErrBadRequest.WithMessage("無效的請求內容"))
		return
	}

	user, token, err := h.authService.RefreshToken(r.Context(), req.Token)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	h.writeAuthResponse(w, http.StatusOK, user, token)
}

// VerifyEmail 處理 POST /auth/verify-email 請求。
func (h *AuthHandler) VerifyEmail(w http.ResponseWriter, r *http.Request) {
	var req api.VerifyEmailRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apiutil.SendError(w, r, apperror.ErrBadRequest.WithMessage("無效的請求內容"))
		return
	}

	if err := h.authService.VerifyEmail(r.Context(), string(req.Email), req.Code); err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	apiutil.SendJSON(w, http.StatusOK, map[string]string{"message": "驗證成功"})
}

// ResendVerificationCode 處理 POST /auth/resend-verification 請求。
func (h *AuthHandler) ResendVerificationCode(w http.ResponseWriter, r *http.Request) {
	var req api.ResendVerificationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apiutil.SendError(w, r, apperror.ErrBadRequest.WithMessage("無效的請求內容"))
		return
	}

	if err := h.authService.ResendVerificationCode(r.Context(), string(req.Email)); err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	apiutil.SendJSON(w, http.StatusOK, map[string]string{"message": "驗證碼已寄出"})
}

// SearchUserByEmail 處理搜尋使用者請求。
func (h *AuthHandler) SearchUserByEmail(w http.ResponseWriter, r *http.Request, email string) {
	if email == "" {
		apiutil.SendError(w, r, apperror.ErrBadRequest.WithMessage("必須提供 email 參數"))
		return
	}

	user, err := h.authService.SearchUserByEmail(r.Context(), email)
	if err != nil {
		apiutil.SendError(w, r, apperror.ErrUserNotFound)
		return
	}

	apiutil.SendJSON(w, http.StatusOK, ToUserResponse(user))
}

// GetUserByID 處理 GET /users/{userId} 請求。
func (h *AuthHandler) GetUserByID(w http.ResponseWriter, r *http.Request, userID string) {
	user, err := h.authService.GetUserByID(r.Context(), userID)
	if err != nil {
		apiutil.SendError(w, r, apperror.ErrUserNotFound)
		return
	}

	apiutil.SendJSON(w, http.StatusOK, ToUserResponse(user))
}


// --- 回應輔助函式 ---

func (h *AuthHandler) writeAuthResponse(w http.ResponseWriter, statusCode int, user *User, token string) {
	response := ToAuthResponse(user, token)
	apiutil.SendJSON(w, statusCode, response)
}
