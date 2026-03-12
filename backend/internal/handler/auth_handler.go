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

// AuthHandler 處理認證相關的 HTTP 請求。
type AuthHandler struct {
	authService *service.AuthService
}

// NewAuthHandler 建立 AuthHandler 實例。
func NewAuthHandler(authService *service.AuthService) *AuthHandler {
	return &AuthHandler{authService: authService}
}

// RegisterUser 處理 POST /auth/register 請求。
// 驗證輸入 → 呼叫 AuthService.Register → 回傳 JWT Token + 使用者資料。
func (handler *AuthHandler) RegisterUser(writer http.ResponseWriter, request *http.Request) {
	var req api.RegisterRequest
	if err := json.NewDecoder(request.Body).Decode(&req); err != nil {
		writeError(writer, http.StatusBadRequest, "無效的請求內容")
		return
	}

	// 基本驗證：密碼長度至少 8 碼
	if len(req.Password) < 8 {
		writeError(writer, http.StatusBadRequest, "密碼長度至少需要 8 個字元")
		return
	}

	user, token, err := handler.authService.Register(request.Context(), string(req.Email), req.Password, req.DisplayName)
	if err != nil {
		if errors.Is(err, service.ErrEmailAlreadyExists) {
			writeError(writer, http.StatusBadRequest, "此 Email 已經被註冊")
			return
		}
		writeError(writer, http.StatusInternalServerError, "註冊失敗")
		return
	}

	writeAuthResponse(writer, http.StatusCreated, user, token)
}

// LoginUser 處理 POST /auth/login 請求。
// 驗證帳密 → 呼叫 AuthService.Login → 回傳 JWT Token + 使用者資料。
func (handler *AuthHandler) LoginUser(writer http.ResponseWriter, request *http.Request) {
	var req api.LoginRequest
	if err := json.NewDecoder(request.Body).Decode(&req); err != nil {
		writeError(writer, http.StatusBadRequest, "無效的請求內容")
		return
	}

	user, token, err := handler.authService.Login(request.Context(), string(req.Email), req.Password)
	if err != nil {
		if errors.Is(err, service.ErrInvalidCredentials) {
			writeError(writer, http.StatusUnauthorized, "帳號或密碼錯誤")
			return
		}
		writeError(writer, http.StatusInternalServerError, "登入失敗")
		return
	}

	writeAuthResponse(writer, http.StatusOK, user, token)
}

// GetCurrentUser 處理 GET /auth/me 請求。
// 從 context 取得 user_id (由 JWT middleware 注入) → 查詢使用者資料。
func (handler *AuthHandler) GetCurrentUser(writer http.ResponseWriter, request *http.Request) {
	// 從 context 取得 JWT middleware 注入的 user_id
	userID, ok := request.Context().Value(mw.UserIDKey).(string)
	if !ok || userID == "" {
		writeError(writer, http.StatusUnauthorized, "未授權")
		return
	}

	user, err := handler.authService.GetUserByID(request.Context(), userID)
	if err != nil {
		writeError(writer, http.StatusUnauthorized, "使用者不存在")
		return
	}

	// Convert model.User to api.User
	apiUser := convertToAPIUser(user)
	writer.Header().Set("Content-Type", "application/json")
	json.NewEncoder(writer).Encode(apiUser)
}

// --- 回應輔助函式 ---

// writeAuthResponse 寫出認證成功的 JSON 回應 (含 Token 和使用者資料)。
func writeAuthResponse(writer http.ResponseWriter, statusCode int, user *model.User, token string) {
	response := api.AuthResponse{
		Token: token,
		User:  convertToAPIUser(user),
	}
	writer.Header().Set("Content-Type", "application/json")
	writer.WriteHeader(statusCode)
	json.NewEncoder(writer).Encode(response)
}

// writeError 寫出錯誤 JSON 回應。
func writeError(writer http.ResponseWriter, statusCode int, message string) {
	response := api.ErrorResponse{Message: message}
	writer.Header().Set("Content-Type", "application/json")
	writer.WriteHeader(statusCode)
	json.NewEncoder(writer).Encode(response)
}

// convertToAPIUser 將資料庫 model.User 轉換為 API 回應用的 api.User。
func convertToAPIUser(user *model.User) api.User {
	parsedID, _ := uuid.Parse(user.ID)

	// TODO: 未來應透過查詢或快取將 role_id 轉為實際角色代碼
	role := "MEMBER"

	return api.User{
		Id:          parsedID,
		Email:       types.Email(user.Email),
		DisplayName: user.DisplayName,
		Avatar:      user.Avatar,
		IsActive:    user.IsActive,
		IsVerified:  user.IsVerified,
		Role:        role,
		CreatedAt:   user.CreatedAt,
		CreatedBy:   toOpenAPIUUIDPtr(user.CreatedBy),
		UpdatedAt:   user.UpdatedAt,
		UpdatedBy:   toOpenAPIUUIDPtr(user.UpdatedBy),
	}
}
