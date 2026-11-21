package middleware

import "net/http"

// MaxBodySize 限制每個請求 body 的大小。超過上限時，讀取 body 會回傳
// *http.MaxBytesError，並由 apiutil.DecodeBody 轉成 413 回應。
func MaxBodySize(maxBytes int64) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if r.Body != nil {
				r.Body = http.MaxBytesReader(w, r.Body, maxBytes)
			}
			next.ServeHTTP(w, r)
		})
	}
}
