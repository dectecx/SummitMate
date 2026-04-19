package heartbeat

import (
	"encoding/json"
	"net/http"

	"summitmate/api"
	"summitmate/internal/apperror"
	"summitmate/internal/common/apiutil"
	"summitmate/internal/middleware"
)

type HeartbeatHandler struct {
	svc HeartbeatService
}

func NewHeartbeatHandler(svc HeartbeatService) *HeartbeatHandler {
	return &HeartbeatHandler{svc: svc}
}

// Heartbeat 發送心跳訊號
// (POST /heartbeat)
func (h *HeartbeatHandler) Heartbeat(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var req api.HeartbeatRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apiutil.SendError(w, r, apperror.ErrBadRequest)
		return
	}

	svcReq := &HeartbeatRequest{
		UserType: req.UserType,
		View:     req.View,
		Platform: req.Platform,
	}

	if err := h.svc.HandleHeartbeat(r.Context(), userID, svcReq); err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	w.WriteHeader(http.StatusOK)
}
