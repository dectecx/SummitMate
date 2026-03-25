package handler

import (
	"net/http"

	"github.com/go-chi/render"
	"summitmate/internal/model"
	"summitmate/internal/service"
)

type LogHandler struct {
	logService service.LogService
}

func NewLogHandler(logService service.LogService) *LogHandler {
	return &LogHandler{logService: logService}
}

// UploadLogs 處理日誌上傳請求
func (h *LogHandler) UploadLogs(w http.ResponseWriter, r *http.Request) {
	var req struct {
		DeviceID   string           `json:"device_id"`
		DeviceName string           `json:"device_name"`
		Logs       []model.LogEntry `json:"logs"`
	}

	if err := render.DecodeJSON(r.Body, &req); err != nil {
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}

	count, err := h.logService.UploadLogs(r.Context(), req.DeviceID, req.DeviceName, req.Logs)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	render.JSON(w, r, map[string]interface{}{
		"count": count,
	})
}
