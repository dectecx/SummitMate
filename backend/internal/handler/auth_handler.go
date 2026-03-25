package handler

import (
	"encoding/json"
	"net/http"

	"summitmate/api"
	"summitmate/internal/apperror"
	"summitmate/internal/handler/mapping"
	mw "summitmate/internal/middleware"
	"summitmate/internal/model"
	"summitmate/internal/service"
)

// AuthHandler 處理認證相關的 HTTP 請求。
type AuthHandler struct {
	authService *service.AuthService
}

// NewAuthHandler 建立 AuthHandler 實例。
func NewAuthHandler(authService *service.AuthService) *AuthHandler {
	return &AuthHandler{authService: authService}
}

// RegisterUser 處理 POST /auth/register 請求。
func (handler *AuthHandler) RegisterUser(writer http.ResponseWriter, request *http.Request) {
	var req api.RegisterRequest
	if err := json.NewDecoder(request.Body).Decode(&req); err != nil {
		sendError(writer, request, apperror.ErrBadRequest.WithMessage("無效的請求內容"))
		return
	}

	if len(req.Password) < 8 {
		sendError(writer, request, apperror.ErrPasswordTooShort)
		return
	}

	user, token, err := handler.authService.Register(request.Context(), string(req.Email), req.Password, req.DisplayName)
	if err != nil {
		sendError(writer, request, err)
		return
	}

	writeAuthResponse(writer, http.StatusCreated, user, token)
}

// LoginUser 處理 POST /auth/login 請求。
func (handler *AuthHandler) LoginUser(writer http.ResponseWriter, request *http.Request) {
	var req api.LoginRequest
	if err := json.NewDecoder(request.Body).Decode(&req); err != nil {
		sendError(writer, request, apperror.ErrBadRequest.WithMessage("無效的請求內容"))
		return
	}

	user, token, err := handler.authService.Login(request.Context(), string(req.Email), req.Password)
	if err != nil {
		sendError(writer, request, err)
		return
	}

	writeAuthResponse(writer, http.StatusOK, user, token)
}

// GetCurrentUser 處理 GET /auth/me 請求。
func (handler *AuthHandler) GetCurrentUser(writer http.ResponseWriter, request *http.Request) {
	userID, ok := request.Context().Value(mw.UserIDKey).(string)
	if !ok || userID == "" {
		sendError(writer, request, apperror.ErrUnauthorized)
		return
	}

	user, err := handler.authService.GetUserByID(request.Context(), userID)
	if err != nil {
		sendError(writer, request, apperror.ErrUnauthorized.WithMessage("使用者不存在"))
		return
	}

	sendJSON(writer, http.StatusOK, mapping.ToUserResponse(user))
}

// UpdateCurrentUser 處理 PUT /auth/me 請求。
func (handler *AuthHandler) UpdateCurrentUser(writer http.ResponseWriter, request *http.Request) {
	userID, ok := request.Context().Value(mw.UserIDKey).(string)
	if !ok || userID == "" {
		sendError(writer, request, apperror.ErrUnauthorized)
		return
	}

	var req api.UpdateProfileRequest
	if err := json.NewDecoder(request.Body).Decode(&req); err != nil {
		sendError(writer, request, apperror.ErrBadRequest.WithMessage("無效的請求內容"))
		return
	}

	user, err := handler.authService.UpdateProfile(request.Context(), userID, req.DisplayName, req.Avatar)
	if err != nil {
		sendError(writer, request, err)
		return
	}

	sendJSON(writer, http.StatusOK, mapping.ToUserResponse(user))
}

// DeleteCurrentUser 處理 DELETE /auth/me 請求。
func (handler *AuthHandler) DeleteCurrentUser(writer http.ResponseWriter, request *http.Request) {
	userID, ok := request.Context().Value(mw.UserIDKey).(string)
	if !ok || userID == "" {
		sendError(writer, request, apperror.ErrUnauthorized)
		return
	}

	if err := handler.authService.DeleteAccount(request.Context(), userID); err != nil {
		sendError(writer, request, err)
		return
	}

	writer.WriteHeader(http.StatusNoContent)
}

// RefreshToken 處理 POST /auth/refresh 請求。
func (handler *AuthHandler) RefreshToken(writer http.ResponseWriter, request *http.Request) {
	var req api.RefreshTokenRequest
	if err := json.NewDecoder(request.Body).Decode(&req); err != nil {
		sendError(writer, request, apperror.ErrBadRequest.WithMessage("無效的請求內容"))
		return
	}

	user, token, err := handler.authService.RefreshToken(request.Context(), req.Token)
	if err != nil {
		sendError(writer, request, err)
		return
	}

	writeAuthResponse(writer, http.StatusOK, user, token)
}

// VerifyEmail 處理 POST /auth/verify-email 請求。
func (handler *AuthHandler) VerifyEmail(writer http.ResponseWriter, request *http.Request) {
	var req api.VerifyEmailRequest
	if err := json.NewDecoder(request.Body).Decode(&req); err != nil {
		sendError(writer, request, apperror.ErrBadRequest.WithMessage("無效的請求內容"))
		return
	}

	if err := handler.authService.VerifyEmail(request.Context(), string(req.Email), req.Code); err != nil {
		sendError(writer, request, err)
		return
	}

	sendJSON(writer, http.StatusOK, map[string]string{"message": "驗證成功"})
}

// ResendVerificationCode 處理 POST /auth/resend-verification 請求。
func (handler *AuthHandler) ResendVerificationCode(writer http.ResponseWriter, request *http.Request) {
	var req api.ResendVerificationRequest
	if err := json.NewDecoder(request.Body).Decode(&req); err != nil {
		sendError(writer, request, apperror.ErrBadRequest.WithMessage("無效的請求內容"))
		return
	}

	if err := handler.authService.ResendVerificationCode(request.Context(), string(req.Email)); err != nil {
		sendError(writer, request, err)
		return
	}

	sendJSON(writer, http.StatusOK, map[string]string{"message": "驗證碼已寄出"})
}

// --- 回應輔助函式 ---

func writeAuthResponse(writer http.ResponseWriter, statusCode int, user *model.User, token string) {
	response := mapping.ToAuthResponse(user, token)
	writer.Header().Set("Content-Type", "application/json")
	writer.WriteHeader(statusCode)
	json.NewEncoder(writer).Encode(response)
}
