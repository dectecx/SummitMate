package apiutil

import (
	"encoding/json"
	"errors"
	"net/http"
	"runtime/debug"
	"summitmate/internal/apperror"
	"summitmate/internal/middleware"
)

// SendJSON 送出成功回應 (2xx)
func SendJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

// ErrorBody 是錯誤回應的 JSON 結構
type ErrorBody struct {
	Type    string `json:"type"`
	Code    string `json:"code"`
	Message string `json:"message"`
	Param   string `json:"param,omitempty"`
}

type ErrorEnvelope struct {
	Error ErrorBody `json:"error"`
}

// SendError 送出標準化的錯誤回應。
func SendError(w http.ResponseWriter, r *http.Request, err error) {
	logger := middleware.LoggerFromContext(r.Context())

	var appErr *apperror.AppError
	if errors.As(err, &appErr) {
		if appErr.HTTPStatus >= 500 {
			logger.ErrorContext(r.Context(), "server error",
				"code", appErr.Code,
				"message", appErr.Message,
				"error", err,
				"stack", string(debug.Stack()),
			)
		}
		SendJSON(w, appErr.HTTPStatus, ErrorEnvelope{
			Error: ErrorBody{
				Type:    appErr.Type,
				Code:    appErr.Code,
				Message: appErr.Message,
				Param:   appErr.Param,
			},
		})
		return
	}

	// 未預期錯誤 → 500 server_error
	logger.ErrorContext(r.Context(), "unexpected error",
		"error", err,
		"stack", string(debug.Stack()),
	)
	SendJSON(w, http.StatusInternalServerError, ErrorEnvelope{
		Error: ErrorBody{
			Type:    apperror.TypeServer,
			Code:    "internal_error",
			Message: "伺服器內部錯誤",
		},
	})
}

// GetUserIDFromRequest 從 http.Request 的 Context 中取得由 Middleware 注入的 UserID。
func GetUserIDFromRequest(r *http.Request) (string, bool) {
	return middleware.GetUserIDFromContext(r.Context())
}
