package middleware

import (
	"bytes"
	"encoding/json"
	"io"
	"log/slog"
	"net/http"
	"strings"
	"time"

	"github.com/go-chi/chi/v5/middleware"
)

// maxBodyLogBytes 限制單筆 request/response body 寫入日誌的最大長度，
// 避免大型 payload 灌爆日誌或拖慢序列化。
const maxBodyLogBytes = 4 << 10 // 4 KB

// redactedPlaceholder 取代敏感欄位的值。
const redactedPlaceholder = "[REDACTED]"

// sensitiveBodyKeys 為記錄 body 時需遮蔽的 JSON 欄位名稱（小寫比對）。
// 涵蓋登入／註冊密碼、auth token 與 email 驗證碼，避免憑證外洩至日誌。
var sensitiveBodyKeys = map[string]struct{}{
	"password":      {},
	"old_password":  {},
	"new_password":  {},
	"token":         {},
	"refresh_token": {},
	"code":          {},
}

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

			// 讀取並捕捉 Request Body（完整讀取後還原，供後續 handler 使用）
			var reqBody []byte
			var reqBodyErr error
			if r.Body != nil {
				reqBody, reqBodyErr = io.ReadAll(r.Body)
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

			// 記錄 Request Body（敏感欄位遮蔽、限制大小）；讀取失敗僅記錄標記
			switch {
			case reqBodyErr != nil:
				attrs = append(attrs, slog.String("request_body_error", reqBodyErr.Error()))
			case len(reqBody) > 0:
				attrs = append(attrs, slog.String("request_body", sanitizeBody(reqBody)))
			}

			// 記錄 Response Body（敏感欄位遮蔽、限制大小）
			if bw.body.Len() > 0 {
				attrs = append(attrs, slog.String("response_body", sanitizeBody(bw.body.Bytes())))
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

// sanitizeBody 嘗試將 body 視為 JSON 並遮蔽敏感欄位，再限制記錄長度。
// 非 JSON body 無法逐欄位遮蔽，僅做長度截斷以避免外洩過長內容。
func sanitizeBody(raw []byte) string {
	var parsed any
	if err := json.Unmarshal(raw, &parsed); err == nil {
		redactSensitive(parsed)
		if cleaned, err := json.Marshal(parsed); err == nil {
			return truncateForLog(cleaned)
		}
	}
	return truncateForLog(raw)
}

// redactSensitive 遞迴走訪 JSON 結構，將敏感欄位值替換為遮蔽字串。
func redactSensitive(v any) {
	switch node := v.(type) {
	case map[string]any:
		for k, child := range node {
			if _, ok := sensitiveBodyKeys[strings.ToLower(k)]; ok {
				node[k] = redactedPlaceholder
				continue
			}
			redactSensitive(child)
		}
	case []any:
		for _, child := range node {
			redactSensitive(child)
		}
	}
}

// truncateForLog 在超過上限時截斷 body 並附上標記。
func truncateForLog(b []byte) string {
	if len(b) <= maxBodyLogBytes {
		return string(b)
	}
	return string(b[:maxBodyLogBytes]) + "...(truncated)"
}
