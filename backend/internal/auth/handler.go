package auth

import (
	"net/http"
	"strings"

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
	if err := apiutil.DecodeBody(r, &req); err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	user, accessToken, refreshToken, err := h.authService.Register(r.Context(), string(req.Email), req.Password, req.DisplayName, req.Avatar)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	h.writeAuthResponse(w, http.StatusCreated, user, accessToken, refreshToken)
}

// LoginUser 處理 POST /auth/login 請求。
func (h *AuthHandler) LoginUser(w http.ResponseWriter, r *http.Request) {
	var req api.LoginRequest
	if err := apiutil.DecodeBody(r, &req); err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	user, accessToken, refreshToken, err := h.authService.Login(r.Context(), string(req.Email), req.Password)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	h.writeAuthResponse(w, http.StatusOK, user, accessToken, refreshToken)
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
	if err := apiutil.DecodeBody(r, &req); err != nil {
		apiutil.SendError(w, r, err)
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
	if err := apiutil.DecodeBody(r, &req); err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	user, accessToken, newRefreshToken, err := h.authService.RefreshToken(r.Context(), req.RefreshToken)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	h.writeAuthResponse(w, http.StatusOK, user, accessToken, newRefreshToken)
}

// VerifyEmail 處理 POST /auth/verify-email 請求。
func (h *AuthHandler) VerifyEmail(w http.ResponseWriter, r *http.Request) {
	var req api.VerifyEmailRequest
	if err := apiutil.DecodeBody(r, &req); err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	if err := h.authService.VerifyEmail(r.Context(), string(req.Email), req.Code); err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	apiutil.SendJSON(w, http.StatusOK, api.OperationMessageResponse{Message: "驗證成功"})
}

// ResendVerificationCode 處理 POST /auth/resend-verification 請求。
func (h *AuthHandler) ResendVerificationCode(w http.ResponseWriter, r *http.Request) {
	var req api.ResendVerificationRequest
	if err := apiutil.DecodeBody(r, &req); err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	if err := h.authService.ResendVerificationCode(r.Context(), string(req.Email)); err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	apiutil.SendJSON(w, http.StatusOK, api.OperationMessageResponse{Message: "驗證碼已寄出"})
}

// SearchUserByEmail 處理搜尋使用者請求。
func (h *AuthHandler) SearchUserByEmail(w http.ResponseWriter, r *http.Request, email string) {
	_, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

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
	_, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	user, err := h.authService.GetUserByID(r.Context(), userID)
	if err != nil {
		apiutil.SendError(w, r, apperror.ErrUserNotFound)
		return
	}

	apiutil.SendJSON(w, http.StatusOK, ToUserResponse(user))
}

// LogoutUser 處理 POST /auth/logout 請求。
func (h *AuthHandler) LogoutUser(w http.ResponseWriter, r *http.Request) {
	// 從 Authorization 取得 token
	header := r.Header.Get("Authorization")
	parts := strings.SplitN(header, " ", 2)
	if len(parts) != 2 || strings.ToLower(parts[0]) != "bearer" {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}
	tokenStr := strings.TrimSpace(parts[1])

	if err := h.authService.Logout(r.Context(), tokenStr); err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	apiutil.SendJSON(w, http.StatusOK, map[string]string{"message": "登出成功"})
}

// ChangePassword 處理 POST /auth/change-password 請求。
func (h *AuthHandler) ChangePassword(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok || userID == "" {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	// 取得當前 token 以進行註銷
	header := r.Header.Get("Authorization")
	var tokenStr string
	parts := strings.SplitN(header, " ", 2)
	if len(parts) == 2 && strings.ToLower(parts[0]) == "bearer" {
		tokenStr = strings.TrimSpace(parts[1])
	}

	var req api.ChangePasswordRequest
	if err := apiutil.DecodeBody(r, &req); err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	err := h.authService.ChangePassword(r.Context(), userID, req.OldPassword, req.NewPassword, tokenStr)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	apiutil.SendJSON(w, http.StatusOK, map[string]string{"message": "密碼修改成功"})
}

// ClearRateLimit 處理 DELETE /auth/rate-limit/{email} 請求。
// 僅供開發/測試環境使用。
func (h *AuthHandler) ClearRateLimit(w http.ResponseWriter, r *http.Request, email string) {
	if email == "" {
		apiutil.SendError(w, r, apperror.ErrBadRequest.WithMessage("必須提供 email 參數"))
		return
	}

	if err := h.authService.ClearRateLimit(r.Context(), email); err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// --- 回應輔助函式 ---

func (h *AuthHandler) writeAuthResponse(w http.ResponseWriter, statusCode int, user *User, token, refreshToken string) {
	response := ToAuthResponse(user, token, refreshToken)
	apiutil.SendJSON(w, statusCode, response)
}
