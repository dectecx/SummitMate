// Package httpx holds small HTTP helpers shared by all handlers.
package httpx

import (
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"
	"runtime/debug"
	"time"

	"summitmate/internal/platform/apperror"
)

// WriteJSON writes v as JSON with the given status.
func WriteJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if v != nil {
		_ = json.NewEncoder(w).Encode(v)
	}
}

// WriteError maps err to an API error response. Unknown errors become 500 and are logged.
func WriteError(w http.ResponseWriter, r *http.Request, err error) {
	ae, ok := apperror.As(err)
	if !ok {
		ae = apperror.ErrInternal.Wrap(err)
	}
	if ae.Status >= 500 {
		slog.ErrorContext(r.Context(), "request failed", "error", err, "path", r.URL.Path)
	}
	WriteJSON(w, ae.Status, ae)
}

// Decode reads a JSON body into v, rejecting unknown trailing data and oversized bodies.
func Decode(w http.ResponseWriter, r *http.Request, v any) error {
	if err := json.NewDecoder(r.Body).Decode(v); err != nil {
		var mbe *http.MaxBytesError
		if errors.As(err, &mbe) {
			return apperror.ErrPayloadTooLarge
		}
		return apperror.ErrBadRequest.Wrap(err)
	}
	return nil
}

// BodyLimit caps request body size.
func BodyLimit(max int64) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			r.Body = http.MaxBytesReader(w, r.Body, max)
			next.ServeHTTP(w, r)
		})
	}
}

// Recoverer turns panics into 500 responses.
func Recoverer(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if rec := recover(); rec != nil {
				slog.ErrorContext(r.Context(), "panic", "panic", rec, "stack", string(debug.Stack()))
				WriteError(w, r, apperror.ErrInternal)
			}
		}()
		next.ServeHTTP(w, r)
	})
}

type statusWriter struct {
	http.ResponseWriter
	status int
}

func (s *statusWriter) WriteHeader(code int) { s.status = code; s.ResponseWriter.WriteHeader(code) }

// RequestLogger logs one line per request (never bodies or headers).
func RequestLogger(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		sw := &statusWriter{ResponseWriter: w, status: http.StatusOK}
		next.ServeHTTP(sw, r)
		slog.InfoContext(r.Context(), "request", "method", r.Method, "path", r.URL.Path, "status", sw.status, "ms", time.Since(start).Milliseconds())
	})
}
