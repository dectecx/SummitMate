// Package server wires handlers, middleware and the router together.
package server

import (
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"

	"summitmate/api"
	"summitmate/internal/auth"
	"summitmate/internal/platform/apperror"
	"summitmate/internal/platform/httpx"
	"summitmate/internal/sync"
	"summitmate/internal/weather"
)

// Server implements api.ServerInterface by combining the feature handlers.
type Server struct {
	authHandler
	syncHandler
	weatherHandler
}

// Wrapper types give each embedded handler a distinct field name.
type (
	authHandler    struct{ *auth.Handler }
	syncHandler    struct{ *sync.Handler }
	weatherHandler struct{ *weather.Handler }
)

func (Server) GetHealth(w http.ResponseWriter, _ *http.Request) {
	httpx.WriteJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

// Options configures the router.
type Options struct {
	Auth           *auth.Handler
	Sync           *sync.Handler
	Weather        *weather.Handler
	Tokens         *auth.TokenManager
	MaxBodyBytes   int64
	RequestTimeout time.Duration
}

// NewRouter builds the HTTP handler for the whole API.
func NewRouter(o Options) http.Handler {
	r := chi.NewRouter()
	r.Use(httpx.Recoverer, httpx.RequestLogger, middleware.Timeout(o.RequestTimeout), httpx.BodyLimit(o.MaxBodyBytes))
	r.Mount(auth.BasePath, api.HandlerWithOptions(Server{authHandler{o.Auth}, syncHandler{o.Sync}, weatherHandler{o.Weather}}, api.ChiServerOptions{
		Middlewares: []api.MiddlewareFunc{auth.Middleware(o.Tokens)},
		ErrorHandlerFunc: func(w http.ResponseWriter, r *http.Request, err error) {
			httpx.WriteError(w, r, apperror.ErrBadRequest.Wrap(err))
		},
	}))
	return r
}
