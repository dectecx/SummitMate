package main

import (
	"fmt"
	"log"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	httpSwagger "github.com/swaggo/http-swagger/v2"

	_ "summitmate/docs" // Swagger generated docs
)

// @title       SummitMate API
// @version     0.1.0
// @description 嘉明湖登山行程助手 - 後端 API

// @host     localhost:8080
// @BasePath /api/v1
func main() {
	r := chi.NewRouter()

	// Middleware
	r.Use(middleware.Logger)
	r.Use(middleware.Recoverer)
	r.Use(middleware.RequestID)

	// Swagger UI: http://localhost:8080/swagger/index.html
	r.Get("/swagger/*", httpSwagger.Handler(
		httpSwagger.URL("/swagger/doc.json"),
	))

	// API Routes
	r.Route("/api/v1", func(r chi.Router) {
		// Health Check
		r.Get("/health", healthCheck)
	})

	port := ":8080"
	log.Printf("🚀 SummitMate API starting on %s", port)
	log.Printf("📖 Swagger UI: http://localhost%s/swagger/index.html", port)
	if err := http.ListenAndServe(port, r); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}

// healthCheck godoc
//
//	@Summary	Health Check
//	@Description	檢查 API 服務是否正常運作
//	@Tags		system
//	@Produce	json
//	@Success	200	{object}	map[string]string	"status: ok"
//	@Router		/health [get]
func healthCheck(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, `{"status":"ok","version":"0.1.0"}`)
}
