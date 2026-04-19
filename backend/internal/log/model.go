package log

import "time"

// Log 對應 DB logs 資料表
type Log struct {
	ID         string    `json:"id"`
	UploadTime time.Time `json:"upload_time"`
	DeviceID   string    `json:"device_id"`
	DeviceName string    `json:"device_name"`
	Timestamp  time.Time `json:"timestamp"`
	Level      string    `json:"level"`
	Source     string    `json:"source"`
	Message    string    `json:"message"`
}

// LogUploadRequest 對應前端上傳請求
type LogUploadRequest struct {
	DeviceID   string     `json:"device_id"`
	DeviceName string     `json:"device_name"`
	Logs       []LogEntry `json:"logs"`
}

// LogEntry 對應單條日誌內容
type LogEntry struct {
	Timestamp time.Time `json:"timestamp"`
	Level     string    `json:"level"`
	Message   string    `json:"message"`
	Source    *string   `json:"source"`
}
