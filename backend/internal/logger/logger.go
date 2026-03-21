package logger

import (
	"log/slog"
	"os"
)

// NewLogger 根據環境建立 slog.Logger。
// 所有環境統一使用 JSONHandler，僅 log level 不同：
//   - development → Debug
//   - 其餘 (production 等) → Info
func NewLogger(env string) *slog.Logger {
	level := slog.LevelInfo
	if env == "development" {
		level = slog.LevelDebug
	}
	handler := slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: level})
	return slog.New(handler)
}
