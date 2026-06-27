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
	ErrTripAccessDenied  = New(http.StatusForbidden, TypeAuth, "trip_permission_denied", "無權限操作此行程")
	ErrUpdateConflict    = New(http.StatusConflict, TypeBusinessLogic, "update_conflict", "資料已被他人修改，請重新載入後再試一次")
	ErrLinkedDayNotFound = New(http.StatusBadRequest, TypeInvalidReq, "linked_day_not_found", "綁定的行程天數不存在")

	ErrLinkedDayDeletionForbidden = New(http.StatusBadRequest, TypeInvalidReq, "linked_day_deletion_forbidden", "此天數已綁定行程，請至行程管理中修改或刪除").WithParam("linked_itinerary_day")
)

// 通用資源
var (
	ErrResourceNotFound = New(http.StatusNotFound, TypeInvalidReq, "resource_not_found", "找不到該資源")
	ErrBadRequest       = New(http.StatusBadRequest, TypeInvalidReq, "invalid_body", "參數格式錯誤")
)

// GroupEvent 相關
var (
	ErrEventNotFound       = New(http.StatusNotFound, TypeInvalidReq, "event_not_found", "找不到該活動")
	ErrEventAccessDenied   = New(http.StatusForbidden, TypeAuth, "event_permission_denied", "無權限操作此活動")
	ErrAlreadyApplied      = New(http.StatusConflict, TypeBusinessLogic, "already_applied", "您已經報名過此活動")
	ErrApplicationNotFound = New(http.StatusNotFound, TypeInvalidReq, "application_not_found", "找不到報名紀錄")
)

// Validation 相關
var (
	ErrPasswordTooShort = New(http.StatusBadRequest, TypeValidation, "password_too_short", "密碼長度至少需要 8 個字元")
	ErrPasswordTooWeak  = New(http.StatusBadRequest, TypeValidation, "password_too_weak", "密碼強度不足，請包含字母與數字")
	ErrInvalidEmail     = New(http.StatusBadRequest, TypeValidation, "invalid_email", "Email 格式不正確")
)

// 分頁相關
var (
	ErrInvalidPage  = New(http.StatusBadRequest, TypeValidation, "invalid_page", "page 參數必須為大於 0 的整數").WithParam("page")
	ErrInvalidLimit = New(http.StatusBadRequest, TypeValidation, "invalid_limit", "limit 參數必須介於 1 到 200 之間").WithParam("limit")
)
