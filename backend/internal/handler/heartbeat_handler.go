package handler

import (
	"encoding/json"
	"net/http"

	"summitmate/api"
	"summitmate/internal/apperror"
	"summitmate/internal/middleware"
	"summitmate/internal/service"
)

type HeartbeatHandler struct {
	svc *service.HeartbeatService
}

func NewHeartbeatHandler(svc *service.HeartbeatService) *HeartbeatHandler {
	return &HeartbeatHandler{svc: svc}
}

// Heartbeat 發送心跳訊號
// (POST /heartbeat)
func (h *HeartbeatHandler) Heartbeat(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, apperror.ErrUnauthorized)
		return
	}

	var req api.HeartbeatRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendError(w, apperror.ErrBadRequest)
		return
	}

	svcReq := &service.HeartbeatRequest{
		UserType: req.UserType,
		View:     req.View,
		Platform: req.Platform,
	}

	if err := h.svc.HandleHeartbeat(r.Context(), userID, svcReq); err != nil {
		sendError(w, err)
		return
	}

	w.WriteHeader(http.StatusOK)
}
