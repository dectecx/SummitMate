package handler

import (
	"encoding/json"
	"errors"
	"net/http"
	"time"

	"summitmate/internal/apperror"

	"github.com/google/uuid"
	openapi_types "github.com/oapi-codegen/runtime/types"
)

// sendJSON 送出成功回應 (2xx)
func sendJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

// errorBody 是錯誤回應的 JSON 結構 (包裝在 "error" 根物件中)
type errorBody struct {
	Type    string `json:"type"`
	Code    string `json:"code,omitempty"`
	Message string `json:"message"`
	Param   string `json:"param,omitempty"`
}

type errorEnvelope struct {
	Error errorBody `json:"error"`
}

// sendError 送出標準化的錯誤回應。
// 自動辨識 *apperror.AppError，未知錯誤預設為 500。
func sendError(w http.ResponseWriter, err error) {
	var appErr *apperror.AppError
	if errors.As(err, &appErr) {
		sendJSON(w, appErr.HTTPStatus, errorEnvelope{
			Error: errorBody{
				Type:    appErr.Type,
				Code:    appErr.Code,
				Message: appErr.Message,
				Param:   appErr.Param,
			},
		})
		return
	}

	// 未預期錯誤 → 500 server_error
	sendJSON(w, http.StatusInternalServerError, errorEnvelope{
		Error: errorBody{
			Type:    apperror.TypeServer,
			Message: "伺服器內部錯誤",
		},
	})
}

func toOpenAPIUUID(s string) openapi_types.UUID {
	u, _ := uuid.Parse(s)
	return u
}

func toOpenAPIUUIDPtr(s *string) *openapi_types.UUID {
	if s == nil || *s == "" {
		return nil
	}
	u, _ := uuid.Parse(*s)
	return &u
}

func toOpenAPITime(t time.Time) time.Time {
	return t
}

func toOpenAPITimePtr(t *time.Time) *time.Time {
	return t
}

func toServiceTimePtr(d *openapi_types.Date) *time.Time {
	if d == nil {
		return nil
	}
	t := d.Time
	return &t
}

func toOpenAPIDate(t time.Time) openapi_types.Date {
	return openapi_types.Date{Time: t}
}

func toOpenAPIDatePtr(t *time.Time) *openapi_types.Date {
	if t == nil {
		return nil
	}
	d := openapi_types.Date{Time: *t}
	return &d
}

func toServiceDate(s string) (time.Time, error) {
	return time.Parse("2006-01-02", s)
}

func toServiceDatePtr(s *string) *time.Time {
	if s == nil || *s == "" {
		return nil
	}
	t, err := time.Parse("2006-01-02", *s)
	if err != nil {
		return nil
	}
	return &t
}
