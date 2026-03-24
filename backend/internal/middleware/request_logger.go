package middleware

import (
	"bytes"
	"io"
	"log/slog"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5/middleware"
)

// bodyLogWriter 捕捉回傳內容的 ResponseWriter 包裝器
type bodyLogWriter struct {
	middleware.WrapResponseWriter
	body *bytes.Buffer
}

func (w *bodyLogWriter) Write(b []byte) (int, error) {
	w.body.Write(b)
	return w.WrapResponseWriter.Write(b)
}

// RequestLogger 結構化 HTTP 請求日誌 middleware，替代 chi 預設 Logger。
// 須放在 ContextLogger 之後使用，以取得帶有 request_id 的 logger。
func RequestLogger(logger *slog.Logger) func(next http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			start := time.Now()

			// 讀取並捕捉 Request Body
			var reqBody []byte
			if r.Body != nil {
				reqBody, _ = io.ReadAll(r.Body)
				r.Body = io.NopCloser(bytes.NewBuffer(reqBody))
			}

			// 包裝 ResponseWriter 以捕捉回傳內容
			ww := middleware.NewWrapResponseWriter(w, r.ProtoMajor)
			bw := &bodyLogWriter{
				WrapResponseWriter: ww,
				body:               bytes.NewBufferString(""),
			}

			next.ServeHTTP(bw, r)

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

			// 記錄 Request & Response Body
			if len(reqBody) > 0 {
				attrs = append(attrs, slog.String("request_body", string(reqBody)))
			}
			if bw.body.Len() > 0 {
				attrs = append(attrs, slog.String("response_body", bw.body.String()))
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
