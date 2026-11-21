// Package apperror defines the structured errors returned by the API.
package apperror

import (
	"errors"
	"net/http"
)

const (
	TypeValidation    = "validation_error"
	TypeAuth          = "auth_error"
	TypeBusinessLogic = "business_logic_error"
	TypeInvalidReq    = "invalid_request_error"
	TypeServer        = "server_error"
)

// Error is an API error. The wrapped cause is for logs only and never serialized.
type Error struct {
	Status  int    `json:"-"`
	Type    string `json:"type"`
	Code    string `json:"code"`
	Message string `json:"message"`
	Param   string `json:"param,omitempty"`
	cause   error
}

func (e *Error) Error() string { return e.Message }
func (e *Error) Unwrap() error { return e.cause }

func New(status int, typ, code, message string) *Error {
	return &Error{Status: status, Type: typ, Code: code, Message: message}
}

// WithParam returns a copy that names the offending parameter.
func (e *Error) WithParam(p string) *Error { c := *e; c.Param = p; return &c }

// WithMessage returns a copy with a different message.
func (e *Error) WithMessage(m string) *Error { c := *e; c.Message = m; return &c }

// Wrap returns a copy that records the underlying cause for logging.
func (e *Error) Wrap(err error) *Error { c := *e; c.cause = err; return &c }

// As extracts an *Error from err.
func As(err error) (*Error, bool) {
	var e *Error
	if errors.As(err, &e) {
		return e, true
	}
	return nil, false
}

var (
	ErrInternal            = New(http.StatusInternalServerError, TypeServer, "internal_error", "伺服器發生錯誤")
	ErrBadRequest          = New(http.StatusBadRequest, TypeInvalidReq, "invalid_body", "參數格式錯誤")
	ErrPayloadTooLarge     = New(http.StatusRequestEntityTooLarge, TypeInvalidReq, "payload_too_large", "請求內容過大")
	ErrUnauthorized        = New(http.StatusUnauthorized, TypeAuth, "unauthorized", "未登入或登入已失效")
	ErrInvalidCredentials  = New(http.StatusUnauthorized, TypeAuth, "invalid_credentials", "帳號或密碼錯誤")
	ErrInvalidRefreshToken = New(http.StatusUnauthorized, TypeAuth, "invalid_refresh_token", "登入已失效，請重新登入")
	ErrEmailNotVerified    = New(http.StatusForbidden, TypeAuth, "email_not_verified", "Email 尚未驗證")
	ErrAccountDisabled     = New(http.StatusForbidden, TypeAuth, "account_disabled", "帳號已停用")
	ErrEmailExists         = New(http.StatusConflict, TypeBusinessLogic, "email_already_exists", "此 Email 已經被註冊")
	ErrInvalidCode         = New(http.StatusBadRequest, TypeBusinessLogic, "invalid_verification_code", "驗證碼錯誤")
	ErrCodeExpired         = New(http.StatusBadRequest, TypeBusinessLogic, "verification_code_expired", "驗證碼已過期，請重新發送")
	ErrTooManyRequests     = New(http.StatusTooManyRequests, TypeAuth, "too_many_requests", "請求次數過多，請稍後再試")
	ErrInvalidEmail        = New(http.StatusBadRequest, TypeValidation, "invalid_email", "Email 格式不正確").WithParam("email")
	ErrPasswordTooShort    = New(http.StatusBadRequest, TypeValidation, "password_too_short", "密碼長度至少需要 8 個字元").WithParam("password")
	ErrPasswordTooWeak     = New(http.StatusBadRequest, TypeValidation, "password_too_weak", "密碼需同時包含字母與數字").WithParam("password")
	ErrPasswordMismatch    = New(http.StatusBadRequest, TypeValidation, "wrong_current_password", "目前密碼不正確").WithParam("current_password")
)
