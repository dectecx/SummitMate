package handler

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/google/uuid"
	openapi_types "github.com/oapi-codegen/runtime/types"
)

func sendJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

func sendErrorResponse(w http.ResponseWriter, status int, message string) {
	sendJSON(w, status, struct {
		Message string `json:"message"`
	}{Message: message})
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
