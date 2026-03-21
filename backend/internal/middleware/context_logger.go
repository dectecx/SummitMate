package middleware

import (
	"context"
	"log/slog"
	"net/http"

	"github.com/go-chi/chi/v5/middleware"
)

type ctxKeyLogger struct{}

// ContextLogger 將 slog.Logger 附帶 request_id 注入 context。
// 須放在 chi middleware.RequestID 之後使用。
func ContextLogger(logger *slog.Logger) func(next http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			reqID := middleware.GetReqID(r.Context())
			ctxLogger := logger.With("request_id", reqID)
			ctx := context.WithValue(r.Context(), ctxKeyLogger{}, ctxLogger)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

// LoggerFromContext 從 context 取得 logger，若不存在則回傳 slog.Default()。
func LoggerFromContext(ctx context.Context) *slog.Logger {
	if l, ok := ctx.Value(ctxKeyLogger{}).(*slog.Logger); ok {
		return l
	}
	return slog.Default()
}
