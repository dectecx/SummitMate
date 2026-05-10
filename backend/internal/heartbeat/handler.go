package heartbeat

import (
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
	if err := apiutil.DecodeBody(r, &req); err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	// 處理統計數據
	viewStats := make(map[string]int)
	if req.ViewStats != nil {
		viewStats = *req.ViewStats
	}

	svcReq := &HeartbeatRequest{
		UserType:  req.UserType,
		ViewStats: viewStats,
		Platform:  req.Platform,
	}
	if req.View != nil {
		svcReq.View = *req.View
	}

	syncedHb, err := h.svc.HandleHeartbeat(r.Context(), userID, svcReq)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	// 回傳同步後的統計數據給客戶端 (Server-side Win)
	status := "ok"
	apiutil.SendJSON(w, http.StatusOK, api.HeartbeatResponse{
		Status:    &status,
		ViewStats: &syncedHb.ViewStats,
	})
}
