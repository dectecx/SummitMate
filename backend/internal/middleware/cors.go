package middleware

import (
	"net/http"
	"net/url"
)

// localhostHosts are the host names whose origins are allowed on any port so
// that local development and emulator setups keep working when the port changes.
var localhostHosts = map[string]bool{
	"localhost": true,
	"127.0.0.1": true,
	"10.0.2.2":  true,
}

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

				// For localhost / emulator origins we allow any port so that
				// changing dev ports keeps working, but we match scheme and host
				// exactly via URL parsing instead of a string prefix. This
				// prevents bypasses such as "http://localhost.evil.com" which
				// would satisfy a HasPrefix(origin, "http://localhost") check.
				if isLocalhostMarker(ao) && sameSchemeAndHost(ao, origin) {
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

// isLocalhostMarker reports whether the configured allowed origin refers to a
// localhost / emulator host (e.g. "http://localhost"), for which any port is
// accepted.
func isLocalhostMarker(allowedOrigin string) bool {
	u, err := url.Parse(allowedOrigin)
	if err != nil {
		return false
	}
	return localhostHosts[u.Hostname()]
}

// sameSchemeAndHost reports whether two origins share the same scheme and host
// name, ignoring the port. The host is taken from the parsed URL so that only
// an exact host name (not a prefix) is considered a match.
func sameSchemeAndHost(allowedOrigin, origin string) bool {
	a, err := url.Parse(allowedOrigin)
	if err != nil {
		return false
	}
	o, err := url.Parse(origin)
	if err != nil {
		return false
	}
	return a.Scheme == o.Scheme && a.Hostname() == o.Hostname()
}
