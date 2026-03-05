package main

import (
	"context"
	"encoding/json"
	"log"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"

	"summitmate/api"
	"summitmate/internal/auth"
	"summitmate/internal/config"
	"summitmate/internal/database"
	"summitmate/internal/handler"
	mw "summitmate/internal/middleware"
	"summitmate/internal/repository"
	"summitmate/internal/service"
)

// server implements api.ServerInterface
type server struct {
	authHandler *handler.AuthHandler
	tokenMgr    *auth.TokenManager
}

// GetHealth implements api.ServerInterface
func (s server) GetHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(api.HealthResponse{
		Status:  "ok",
		Version: "0.1.0",
	})
}

// RegisterUser implements api.ServerInterface
func (s server) RegisterUser(w http.ResponseWriter, r *http.Request) {
	s.authHandler.RegisterUser(w, r)
}

// LoginUser implements api.ServerInterface
func (s server) LoginUser(w http.ResponseWriter, r *http.Request) {
	s.authHandler.LoginUser(w, r)
}

// GetCurrentUser implements api.ServerInterface (JWT protected)
func (s server) GetCurrentUser(w http.ResponseWriter, r *http.Request) {
	// Apply JWT middleware inline for this protected endpoint
	jwtMiddleware := mw.JWTAuth(s.tokenMgr)
	jwtMiddleware(http.HandlerFunc(s.authHandler.GetCurrentUser)).ServeHTTP(w, r)
}

func main() {
	// Load config
	cfg := config.Load()

	// Connect to database
	ctx := context.Background()
	pool, err := database.Connect(ctx, cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("❌ Database connection failed: %v", err)
	}
	defer pool.Close()

	// Dependencies
	userRepo := repository.NewUserRepository(pool)
	tokenMgr := auth.NewTokenManager(cfg.JWTSecret)

	authService := service.NewAuthService(userRepo, tokenMgr)
	authHandler := handler.NewAuthHandler(authService)

	srv := server{
		authHandler: authHandler,
		tokenMgr:    tokenMgr,
	}

	r := chi.NewRouter()

	// Middleware
	r.Use(middleware.Logger)
	r.Use(middleware.Recoverer)
	r.Use(middleware.RequestID)

	// Serve OpenAPI spec (for Scalar UI)
	r.Get("/openapi.json", func(w http.ResponseWriter, r *http.Request) {
		swagger, err := api.GetSwagger()
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(swagger)
	})

	// Scalar API Reference UI
	r.Get("/docs", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/html; charset=utf-8")
		w.Write([]byte(`<!doctype html>
<html>
<head>
  <title>SummitMate API Reference</title>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
</head>
<body>
  <div id="app"></div>
  <script src="https://cdn.jsdelivr.net/npm/@scalar/api-reference"></script>
  <script>
    Scalar.createApiReference('#app', {
      url: '/openapi.json',
      theme: 'kepler',
    })
  </script>
</body>
</html>`))
	})

	// API Routes (mounted at /api/v1)
	r.Route("/api/v1", func(r chi.Router) {
		api.HandlerFromMux(srv, r)
	})

	log.Printf("🚀 SummitMate API starting on %s", cfg.Addr())
	log.Printf("📖 API Docs: http://localhost%s/docs", cfg.Addr())
	if err := http.ListenAndServe(cfg.Addr(), r); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}
