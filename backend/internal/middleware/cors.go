package middleware

import (
	"net/http"
	"strings"
)

// CORS returns a middleware that checks the request origin against allowedOrigins.
func CORS(allowedOrigins []string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			origin := r.Header.Get("Origin")
			if origin == "" {
				next.ServeHTTP(w, r)
				return
			}

			allowed := false
			for _, ao := range allowedOrigins {
				if ao == origin {
					allowed = true
					break
				}

				// Rigorous check: Allow prefix matching for localhost and emulator origins
				// to support dynamic ports while avoiding the use of a global wildcard "*".
				if (ao == "http://localhost" || ao == "http://127.0.0.1" || ao == "http://10.0.2.2") &&
					strings.HasPrefix(origin, ao) {
					allowed = true
					break
				}
			}

			if !allowed {
				if r.Method == "OPTIONS" {
					w.WriteHeader(http.StatusForbidden)
					return
				}
				next.ServeHTTP(w, r)
				return
			}

			// Set CORS headers
			w.Header().Set("Access-Control-Allow-Origin", origin)
			w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With, Accept")
			w.Header().Set("Access-Control-Allow-Credentials", "true")
			w.Header().Set("Access-Control-Max-Age", "3600")

			// Handle Preflight request
			if r.Method == "OPTIONS" {
				w.WriteHeader(http.StatusNoContent)
				return
			}

			next.ServeHTTP(w, r)
		})
	}
}
