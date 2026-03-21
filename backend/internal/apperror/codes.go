package apperror

import "net/http"

// Auth 相關
var (
	ErrUnauthorized       = New(http.StatusUnauthorized, TypeAuth, "unauthorized", "未登入")
	ErrInvalidCredentials = New(http.StatusUnauthorized, TypeAuth, "invalid_credentials", "帳號或密碼錯誤")
	ErrEmailExists        = New(http.StatusConflict, TypeBusinessLogic, "email_already_exists", "此 Email 已經被註冊")
	ErrAccessDenied       = New(http.StatusForbidden, TypeAuth, "permission_denied", "無權限執行此操作")
)

// Trip 相關
var (
	ErrTripNotFound      = New(http.StatusNotFound, TypeInvalidReq, "trip_not_found", "找不到行程")
	ErrCannotRemoveOwner = New(http.StatusBadRequest, TypeBusinessLogic, "cannot_remove_owner", "無法移除行程建立者")
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
)
