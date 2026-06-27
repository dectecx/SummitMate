package log

import (
	"net/http"

	"summitmate/api"
	"summitmate/internal/common/apiutil"
)

type LogHandler struct {
	logService LogService
}

func NewLogHandler(logService LogService) *LogHandler {
	return &LogHandler{logService: logService}
}

// UploadLogs 處理日誌上傳請求
func (h *LogHandler) UploadLogs(w http.ResponseWriter, r *http.Request) {
	var req api.LogUploadRequest
	if err := apiutil.DecodeBody(r, &req); err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	deviceID := ""
	if req.DeviceId != nil {
		deviceID = *req.DeviceId
	}
	deviceName := ""
	if req.DeviceName != nil {
		deviceName = *req.DeviceName
	}

	logs := make([]LogEntry, 0, len(req.Logs))
	for _, e := range req.Logs {
		logs = append(logs, LogEntry{
			Timestamp: e.Timestamp,
			Level:     string(e.Level),
			Message:   e.Message,
			Source:    e.Source,
		})
	}

	count, err := h.logService.UploadLogs(r.Context(), deviceID, deviceName, logs)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	apiutil.SendJSON(w, http.StatusOK, struct {
		Count int `json:"count"`
	}{Count: count})
}
