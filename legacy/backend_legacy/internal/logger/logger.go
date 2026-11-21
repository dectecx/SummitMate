package logger

import (
	"io"
	"log/slog"
	"os"
	"path/filepath"
)

// NewLogger 根據環境建立 Logger
// 1. 正式環境: JSON 格式, 輸出至 stdout
// 2. 開發環境: Text 格式, 同時輸出至 stdout 與 logs/app.log
func NewLogger(env string) *slog.Logger {
	var handler slog.Handler
	level := slog.LevelInfo
	var writer io.Writer = os.Stdout

	if env == "development" {
		level = slog.LevelDebug

		// 開發環境：試圖建立 logs 目錄並開啟檔案
		logDir := "logs"
		if err := os.MkdirAll(logDir, 0755); err == nil {
			logFilePath := filepath.Join(logDir, "app.log")
			// 使用 Append 模式開啟，不存在則建立 (0666)
			if file, err := os.OpenFile(logFilePath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666); err == nil {
				// 將 stdout 與 file 合併為 MultiWriter
				writer = io.MultiWriter(os.Stdout, file)
			}
		}

		handler = slog.NewTextHandler(writer, &slog.HandlerOptions{Level: level})
	} else {
		// 正式環境：維持 JSON
		handler = slog.NewJSONHandler(writer, &slog.HandlerOptions{Level: level})
	}

	return slog.New(handler)
}
