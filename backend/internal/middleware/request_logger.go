package middleware

import (
	"log/slog"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5/middleware"
)

// RequestLogger 結構化 HTTP 請求日誌 middleware，替代 chi 預設 Logger。
// 須放在 ContextLogger 之後使用，以取得帶有 request_id 的 logger。
func RequestLogger(logger *slog.Logger) func(next http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			start := time.Now()
			ww := middleware.NewWrapResponseWriter(w, r.ProtoMajor)

			next.ServeHTTP(ww, r)

			duration := time.Since(start)
			status := ww.Status()

			// 依照狀態碼選擇 log level
			l := LoggerFromContext(r.Context())
			attrs := []slog.Attr{
				slog.String("method", r.Method),
				slog.String("path", r.URL.Path),
				slog.Int("status", status),
				slog.Int64("duration_ms", duration.Milliseconds()),
				slog.Int("bytes", ww.BytesWritten()),
			}

			switch {
			case status >= 500:
				l.LogAttrs(r.Context(), slog.LevelError, "http request", attrs...)
			case status >= 400:
				l.LogAttrs(r.Context(), slog.LevelWarn, "http request", attrs...)
			default:
				l.LogAttrs(r.Context(), slog.LevelInfo, "http request", attrs...)
			}
		})
	}
}
