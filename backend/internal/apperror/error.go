package apperror

import "net/http"

// 錯誤類型常量
const (
	TypeValidation    = "validation_error"
	TypeAuth          = "auth_error"
	TypeBusinessLogic = "business_logic_error"
	TypeInvalidReq    = "invalid_request_error"
	TypeServer        = "server_error"
)

// AppError 結構化的 API 錯誤
type AppError struct {
	HTTPStatus int    `json:"-"`
	Type       string `json:"type"`
	Code       string `json:"code"`
	Message    string `json:"message"`
	Param      string `json:"param,omitempty"`
}

func (e *AppError) Error() string {
	return e.Message
}

// New 建立 AppError
func New(status int, errType, code, message string) *AppError {
	return &AppError{
		HTTPStatus: status,
		Type:       errType,
		Code:       code,
		Message:    message,
	}
}

// WithParam 複製並附加 param 欄位
func (e *AppError) WithParam(param string) *AppError {
	return &AppError{
		HTTPStatus: e.HTTPStatus,
		Type:       e.Type,
		Code:       e.Code,
		Message:    e.Message,
		Param:      param,
	}
}

// WithMessage 複製並替換 message 欄位
func (e *AppError) WithMessage(message string) *AppError {
	return &AppError{
		HTTPStatus: e.HTTPStatus,
		Type:       e.Type,
		Code:       e.Code,
		Message:    message,
		Param:      e.Param,
	}
}

// InternalError 建立 500 錯誤
func InternalError(message string) *AppError {
	return New(http.StatusInternalServerError, TypeServer, "internal_error", message)
}
