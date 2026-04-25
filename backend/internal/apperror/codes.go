package apperror

import "net/http"

// Auth 相關
var (
	ErrUnauthorized            = New(http.StatusUnauthorized, TypeAuth, "unauthorized", "未登入")
	ErrInvalidCredentials      = New(http.StatusUnauthorized, TypeAuth, "invalid_credentials", "帳號或密碼錯誤")
	ErrEmailExists             = New(http.StatusConflict, TypeBusinessLogic, "email_already_exists", "此 Email 已經被註冊")
	ErrAccessDenied            = New(http.StatusForbidden, TypeAuth, "permission_denied", "無權限執行此操作")
	ErrUserNotFound            = New(http.StatusNotFound, TypeInvalidReq, "user_not_found", "找不到使用者")
	ErrTokenExpired            = New(http.StatusUnauthorized, TypeAuth, "token_expired", "Token 已過期")
	ErrInvalidVerificationCode = New(http.StatusBadRequest, TypeBusinessLogic, "invalid_verification_code", "驗證碼錯誤")
	ErrVerificationCodeExpired = New(http.StatusBadRequest, TypeBusinessLogic, "verification_code_expired", "驗證碼已過期，請重新發送")
)

// Trip 相關
var (
	ErrTripNotFound      = New(http.StatusNotFound, TypeInvalidReq, "trip_not_found", "找不到行程")
	ErrCannotRemoveOwner = New(http.StatusBadRequest, TypeBusinessLogic, "cannot_remove_owner", "無法移除行程建立者")
	ErrUpdateConflict    = New(http.StatusConflict, TypeBusinessLogic, "update_conflict", "資料已被他人修改，請重新載入後再試一次")
)

// 通用資源
var (
	ErrResourceNotFound = New(http.StatusNotFound, TypeInvalidReq, "resource_not_found", "找不到該資源")
	ErrBadRequest       = New(http.StatusBadRequest, TypeInvalidReq, "invalid_body", "參數格式錯誤")
)

// GroupEvent 相關
var (
	ErrEventNotFound     = New(http.StatusNotFound, TypeInvalidReq, "event_not_found", "找不到該活動")
	ErrEventAccessDenied = New(http.StatusForbidden, TypeAuth, "event_permission_denied", "無權限操作此活動")
)

// Validation 相關
var (
	ErrPasswordTooShort = New(http.StatusBadRequest, TypeValidation, "password_too_short", "密碼長度至少需要 8 個字元")
	ErrPasswordTooWeak  = New(http.StatusBadRequest, TypeValidation, "password_too_weak", "密碼強度不足，請包含字母與數字")
	ErrInvalidEmail     = New(http.StatusBadRequest, TypeValidation, "invalid_email", "Email 格式不正確")
)
