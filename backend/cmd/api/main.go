package main

import (
	"encoding/json"
	"log"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"

	"summitmate/api"
)

// server implements api.ServerInterface
type server struct{}

// GetHealth implements api.ServerInterface
func (s server) GetHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(api.HealthResponse{
		Status:  "ok",
		Version: "0.1.0",
	})
}

func main() {
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
		api.HandlerFromMux(server{}, r)
	})

	port := ":8080"
	log.Printf("🚀 SummitMate API starting on %s", port)
	log.Printf("📖 API Docs: http://localhost%s/docs", port)
	if err := http.ListenAndServe(port, r); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}
