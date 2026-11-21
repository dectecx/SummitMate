package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestCORS_Middleware(t *testing.T) {
	allowedOrigins := []string{
		"https://summitmate-tw.netlify.app",
		"http://localhost",
		"http://127.0.0.1",
		"http://10.0.2.2",
	}

	nextHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte("ok"))
	})

	handlerToTest := CORS(allowedOrigins)(nextHandler)

	// allowedCases 涵蓋正式網域與任意 port 的 localhost / 模擬器來源。
	allowedCases := []struct {
		name   string
		origin string
	}{
		{"Given exact production origin", "https://summitmate-tw.netlify.app"},
		{"Given localhost without port", "http://localhost"},
		{"Given localhost with dynamic port", "http://localhost:5173"},
		{"Given localhost with another port", "http://localhost:3000"},
		{"Given 127.0.0.1 with port", "http://127.0.0.1:8080"},
		{"Given android emulator host with port", "http://10.0.2.2:8081"},
	}

	for _, tc := range allowedCases {
		t.Run(tc.name+", When sending request, Then origin is allowed", func(t *testing.T) {
			req := httptest.NewRequest("GET", "/api/health", nil)
			req.Header.Set("Origin", tc.origin)
			w := httptest.NewRecorder()

			handlerToTest.ServeHTTP(w, req)

			assert.Equal(t, http.StatusOK, w.Code)
			assert.Equal(t, tc.origin, w.Header().Get("Access-Control-Allow-Origin"))
		})
	}

	// blockedCases 涵蓋利用 prefix 繞過或 scheme 不符的惡意來源。
	blockedCases := []struct {
		name   string
		origin string
	}{
		{"Given prefix bypass with evil suffix", "http://localhost.evil.com"},
		{"Given prefix bypass on 127.0.0.1", "http://127.0.0.1.evil.com"},
		{"Given mismatched scheme for localhost", "https://localhost:5173"},
		{"Given unrelated external origin", "https://evil.example.com"},
	}

	for _, tc := range blockedCases {
		t.Run(tc.name+", When sending request, Then origin is not allowed", func(t *testing.T) {
			req := httptest.NewRequest("GET", "/api/health", nil)
			req.Header.Set("Origin", tc.origin)
			w := httptest.NewRecorder()

			handlerToTest.ServeHTTP(w, req)

			assert.Empty(t, w.Header().Get("Access-Control-Allow-Origin"))
		})
	}

	t.Run("Given disallowed origin and OPTIONS preflight, When sending request, Then it returns 403 Forbidden", func(t *testing.T) {
		req := httptest.NewRequest("OPTIONS", "/api/health", nil)
		req.Header.Set("Origin", "http://localhost.evil.com")
		w := httptest.NewRecorder()

		handlerToTest.ServeHTTP(w, req)

		assert.Equal(t, http.StatusForbidden, w.Code)
		assert.Empty(t, w.Header().Get("Access-Control-Allow-Origin"))
	})

	t.Run("Given allowed origin and OPTIONS preflight, When sending request, Then it returns 204 No Content", func(t *testing.T) {
		req := httptest.NewRequest("OPTIONS", "/api/health", nil)
		req.Header.Set("Origin", "http://localhost:5173")
		w := httptest.NewRecorder()

		handlerToTest.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNoContent, w.Code)
		assert.Equal(t, "http://localhost:5173", w.Header().Get("Access-Control-Allow-Origin"))
	})
}
