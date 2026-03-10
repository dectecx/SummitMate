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
	appMiddleware "summitmate/internal/middleware"
	"summitmate/internal/repository"
	"summitmate/internal/service"

	openapi_types "github.com/oapi-codegen/runtime/types"
)

// server 實作 api.ServerInterface，串接各模組的 Handler。
type server struct {
	authHandler  *handler.AuthHandler // 認證相關 Handler
	tripHandler  *handler.TripHandler // 行程相關 Handler
	tokenManager *auth.TokenManager   // JWT Token 管理器 (供 middleware 使用)
}

// GetHealth 處理 GET /health — 健康檢查端點。
func (srv server) GetHealth(writer http.ResponseWriter, request *http.Request) {
	writer.Header().Set("Content-Type", "application/json")
	writer.WriteHeader(http.StatusOK)
	json.NewEncoder(writer).Encode(api.HealthResponse{
		Status:  "ok",
		Version: "0.1.0",
	})
}

// RegisterUser 處理 POST /auth/register — 使用者註冊。
func (srv server) RegisterUser(writer http.ResponseWriter, request *http.Request) {
	srv.authHandler.RegisterUser(writer, request)
}

// LoginUser 處理 POST /auth/login — 使用者登入。
func (srv server) LoginUser(writer http.ResponseWriter, request *http.Request) {
	srv.authHandler.LoginUser(writer, request)
}

// GetCurrentUser 處理 GET /auth/me — 取得當前登入使用者 (需 JWT)。
// 使用 inline middleware 進行 JWT 驗證，以避免影響公開端點。
func (srv server) GetCurrentUser(writer http.ResponseWriter, request *http.Request) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(srv.authHandler.GetCurrentUser)).ServeHTTP(writer, request)
}

// --- Trips ---

func (srv server) ListTrips(w http.ResponseWriter, r *http.Request) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(srv.tripHandler.ListTrips)).ServeHTTP(w, r)
}

func (srv server) CreateTrip(w http.ResponseWriter, r *http.Request) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(srv.tripHandler.CreateTrip)).ServeHTTP(w, r)
}

func (srv server) GetTrip(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.tripHandler.GetTrip(w, r, tripId)
	})).ServeHTTP(w, r)
}

func (srv server) UpdateTrip(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.tripHandler.UpdateTrip(w, r, tripId)
	})).ServeHTTP(w, r)
}

func (srv server) DeleteTrip(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.tripHandler.DeleteTrip(w, r, tripId)
	})).ServeHTTP(w, r)
}

// --- Trip Members ---

func (srv server) ListTripMembers(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.tripHandler.ListTripMembers(w, r, tripId)
	})).ServeHTTP(w, r)
}

func (srv server) AddTripMember(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.tripHandler.AddTripMember(w, r, tripId)
	})).ServeHTTP(w, r)
}

func (srv server) RemoveTripMember(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, userId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.tripHandler.RemoveTripMember(w, r, tripId, userId)
	})).ServeHTTP(w, r)
}

// --- Itinerary ---

func (srv server) ListItinerary(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.tripHandler.ListItinerary(w, r, tripId)
	})).ServeHTTP(w, r)
}

func (srv server) AddItineraryItem(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.tripHandler.AddItineraryItem(w, r, tripId)
	})).ServeHTTP(w, r)
}

func (srv server) UpdateItineraryItem(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, itemId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.tripHandler.UpdateItineraryItem(w, r, tripId, itemId)
	})).ServeHTTP(w, r)
}

func (srv server) DeleteItineraryItem(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, itemId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.tripHandler.DeleteItineraryItem(w, r, tripId, itemId)
	})).ServeHTTP(w, r)
}

func main() {
	// 載入設定 (環境變數 + 預設值)
	cfg := config.Load()

	// 連線資料庫
	ctx := context.Background()
	pool, err := database.Connect(ctx, cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("❌ 資料庫連線失敗: %v", err)
	}
	defer pool.Close()

	// 初始化各層依賴
	userRepo := repository.NewUserRepository(pool)
	tripRepo := repository.NewTripRepository(pool)
	memberRepo := repository.NewTripMemberRepository(pool)
	itineraryRepo := repository.NewItineraryRepository(pool)

	tokenManager := auth.NewTokenManager(cfg.JWTSecret)

	authService := service.NewAuthService(userRepo, tokenManager)
	tripService := service.NewTripService(tripRepo, memberRepo, itineraryRepo, userRepo)

	authHandler := handler.NewAuthHandler(authService)
	tripHandler := handler.NewTripHandler(tripService)

	srv := server{
		authHandler:  authHandler,
		tripHandler:  tripHandler,
		tokenManager: tokenManager,
	}

	// 設定 Router
	router := chi.NewRouter()
	router.Use(middleware.Logger)
	router.Use(middleware.Recoverer)
	router.Use(middleware.RequestID)

	// OpenAPI 規格端點 (供 Scalar UI 使用)
	router.Get("/openapi.json", func(writer http.ResponseWriter, request *http.Request) {
		swagger, err := api.GetSwagger()
		if err != nil {
			http.Error(writer, err.Error(), http.StatusInternalServerError)
			return
		}
		writer.Header().Set("Content-Type", "application/json")
		json.NewEncoder(writer).Encode(swagger)
	})

	// Scalar API Reference UI
	router.Get("/docs", func(writer http.ResponseWriter, request *http.Request) {
		writer.Header().Set("Content-Type", "text/html; charset=utf-8")
		writer.Write([]byte(`<!doctype html>
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

	// 掛載 API 路由 (前綴 /api/v1)
	router.Route("/api/v1", func(router chi.Router) {
		api.HandlerFromMux(srv, router)
	})

	log.Printf("🚀 SummitMate API 已啟動: %s", cfg.Addr())
	log.Printf("📖 API 文件: http://localhost%s/docs", cfg.Addr())
	if err := http.ListenAndServe(cfg.Addr(), router); err != nil {
		log.Fatalf("伺服器啟動失敗: %v", err)
	}
}
